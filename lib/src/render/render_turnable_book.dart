import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:turnable_page/turnable_page.dart';
import '../collection/page_collection_impl.dart';
import '../enums/animation_process.dart';
import '../enums/book_orientation.dart';
import '../enums/page_orientation.dart';
import '../enums/size_type.dart';
import '../helpers/helper.dart';
import '../model/page_rect.dart';
import '../model/point.dart' as model;
import '../model/rect_points.dart';
import '../model/shadow.dart';
import '../page/book_page.dart';
import '../page/book_page_impl.dart';
import '../page/page_flip.dart';
import '../render/render_page.dart';
import '../render/turnable_parent_data.dart';
import '../widgets/page_edges.dart';

class RenderTurnableBook extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TurnableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TurnableParentData>
    implements RenderPage, GestureArenaMember {
  static const double _minMoveThreshold = 10.0;
  bool get _needsWhitePage {
    if (settings.usePortrait) return false;
    return settings.showCover ? false : _pageCount % 2 == 1;
  }

  /// Number of children after the pages: the [CoverSide.front] and
  /// [CoverSide.back] widgets, or 0 when no cover side builder is set.
  int get coverSideCount => _coverSideCount;
  int _coverSideCount = 0;
  set coverSideCount(int value) {
    if (value == _coverSideCount) return;
    _coverSideCount = value;
    _needsIndexRebuild = true;
    markNeedsLayout();
  }

  RenderBox? _frontSideChild;
  RenderBox? _backSideChild;

  /// Number of book pages (children minus the cover side widgets).
  int get _pageCount => childCount - _coverSideCount;

  FlipSettings settings;
  final PageFlip pageFlip;
  late PageCollectionImpl collection;
  bool _initialized = false;
  BookOrientation? _orientation;
  PageRect? _boundsRect;
  FlipDirection? direction;
  RectPoints? pageRect;
  BookPage? leftPage;
  BookPage? rightPage;
  BookPage? flippingPage;
  BookPage? bottomPage;
  AnimationProcess? animation;
  Shadow? shadow;

  /// Progress (0-100) of the current flip, as last reported by the flip
  /// process. Used to decide how to paint a page whose clip area collapsed.
  double _flipProgress = 0;
  bool _frameScheduled = false;
  double _timeMs = 0;
  double? _lastRawTickerMs;
  List<RenderBox?> _indexedChildren = <RenderBox?>[];
  bool _needsIndexRebuild = true;

  // Auto gesture detection properties
  bool _isDragging = false;
  bool _isVerticalScrollLocked = false;
  bool _isInvalidDirectionLocked = false;
  bool isZoomed = false;
  model.Point? _initialTouchPoint;

  RenderTurnableBook(this.settings, this.pageFlip) {
    pageFlip.render = this;
    collection = PageCollectionImpl(pageFlip, this, 0);
  }

  // Always request compositing so Flutter allocates proper layers for children
  // that push their own compositing layers (e.g. CachedNetworkImage, RepaintBoundary).
  // Without this, canvas.save/restore pairs can reference a stale native canvas
  // peer after a child switches the active PictureLayer.
  @override
  bool get alwaysNeedsCompositing => true;

  void updateSettings(FlipSettings s) {
    // [FlipSettings.startPageIndex] is an initial value only (like
    // PageController.initialPage). Re-applying it here made any rebuild with
    // a stale settings object jump back to an old page, and re-showing the
    // current page emitted a duplicate page-change event.
    settings = s;
    markNeedsLayout();
  }

  void _scheduleFrame() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    _frameScheduled = false;
    // Guard: the render object may have been disposed (e.g. after hot reload or
    // widget removal) while a frame callback was still pending. Calling
    // markNeedsPaint() on a disposed render object triggers !_debugDisposed.
    if (!attached) return;
    final rawMs = timestamp.inMilliseconds.toDouble();
    _updateTimestamp(rawMs);
    if (animation != null) {
      if (animation!.startedAt == -1) {
        animation = AnimationProcess(
          frames: animation!.frames,
          duration: animation!.duration,
          durationFrame: animation!.durationFrame,
          onAnimateEnd: animation!.onAnimateEnd,
          startedAt: _timeMs,
        );
      }
      render(_timeMs);
    } else if (_hasActiveVisualElements) {
      markNeedsPaint();
    }
    if (_shouldContinueAnimating) {
      _scheduleFrame();
    }
  }

  bool get _hasActiveVisualElements =>
      flippingPage != null || shadow != null || bottomPage != null;

  bool get _shouldContinueAnimating => animation != null;

  void _updateTimestamp(double rawMs) {
    if (_lastRawTickerMs == null || rawMs < _lastRawTickerMs!) {
      _lastRawTickerMs = rawMs;
    } else if (rawMs > _lastRawTickerMs!) {
      final delta = rawMs - _lastRawTickerMs!;
      _timeMs += delta;
      _lastRawTickerMs = rawMs;
    }
  }

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : settings.width * 2;
    final maxHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : settings.height;
    size = Size(maxWidth, maxHeight);
    final oldOrientation = _orientation;
    calculateBoundsRect();
    final newOrientation = _orientation;
    final pageWidth = _boundsRect!.pageWidth;
    final pageHeight = _boundsRect!.height;
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(
        BoxConstraints.tight(Size(pageWidth, pageHeight)),
        parentUsesSize: true,
      );
      final pd = child.parentData as TurnableParentData;
      pd.offset = Offset.zero;
      child = pd.nextSibling;
    }
    if (_needsIndexRebuild) {
      _assignPageIndices();
    }
    if (!_initialized) {
      final totalPages = _needsWhitePage ? _pageCount + 1 : _pageCount;
      collection = PageCollectionImpl(pageFlip, this, totalPages);
      pageFlip.pages = collection;
      collection.loadBookPages();
      collection.show(settings.startPageIndex);
      _initialized = true;
    } else if (oldOrientation != null && oldOrientation != newOrientation) {
      finishAnimation();
      flippingPage = null;
      bottomPage = null;
      shadow = null;
      collection.show(collection.getCurrentPageIndex());
    }
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TurnableParentData) {
      child.parentData = TurnableParentData();
    }
  }

  void _assignPageIndices() {
    _needsIndexRebuild = false;
    final count = _pageCount;
    final totalSlots = _needsWhitePage ? count + 1 : count;
    if (_indexedChildren.length != totalSlots) {
      _indexedChildren = List<RenderBox?>.filled(
        totalSlots,
        null,
        growable: false,
      );
    }
    int index = 0;
    RenderBox? child = firstChild;
    while (child != null && index < count) {
      final pd = child.parentData as TurnableParentData;
      pd.pageIndex = index;
      _indexedChildren[index] = child;
      index++;
      child = pd.nextSibling;
    }
    if (_needsWhitePage) {
      _indexedChildren[count] = null;
    }
    // The cover side widgets follow the pages, front first.
    _frontSideChild = _coverSideCount > 0 ? child : null;
    _backSideChild = _coverSideCount > 1
        ? (child?.parentData as TurnableParentData?)?.nextSibling
        : null;
  }

  RenderBox? _childByIndex(int index) {
    if (index < 0) {
      if (_needsIndexRebuild) _assignPageIndices();
      return index == BookPageImpl.frontCoverSideIndex
          ? _frontSideChild
          : _backSideChild;
    }
    if (_needsWhitePage && index == _pageCount) {
      return null;
    }
    if (!_needsIndexRebuild && index >= 0 && index < _indexedChildren.length) {
      final child = _indexedChildren[index];
      if (child != null) return child;
    }
    if (_needsIndexRebuild) {
      _assignPageIndices();
      if (index >= 0 && index < _indexedChildren.length) {
        return _indexedChildren[index];
      }
    }
    return _findChildByIndexLinear(index);
  }

  RenderBox? _findChildByIndexLinear(int index) {
    RenderBox? child = firstChild;
    while (child != null) {
      final pd = child.parentData as TurnableParentData;
      if (pd.pageIndex == index) return child;
      child = pd.nextSibling;
    }
    return null;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _needsIndexRebuild = true;
  }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    _needsIndexRebuild = true;
  }

  @override
  void dropChild(RenderObject child) {
    super.dropChild(child);
    _needsIndexRebuild = true;
  }

  @override
  void render(double timer) {
    if (animation != null) {
      final anim = animation!;
      double elapsed = _timeMs - anim.startedAt;
      if (elapsed < 0) elapsed = 0;
      final lastIndex = anim.frames.length - 1;
      final frameIndex = anim.durationFrame > 0
          ? (elapsed / anim.durationFrame).floor()
          : lastIndex;
      if (frameIndex < lastIndex) {
        anim.frames[frameIndex]();
      } else {
        // Reached the final frame: apply it and complete the turn in the SAME
        // tick. Previously the last frame was painted on its own and the page
        // swap happened one vsync later, leaving a frame on screen where the
        // incoming page was (almost) fully clipped away.
        if (lastIndex >= 0) anim.frames[lastIndex]();
        animation = null;
        anim.onAnimateEnd();
        pageFlip.trigger(PageFlipEvent.animationComplete, pageFlip, null);
      }
      markNeedsPaint();
    }
  }

  @override
  void startAnimation(
    List<FrameAction> frames,
    double duration,
    AnimationSuccessAction onAnimateEnd,
  ) {
    finishAnimation();
    animation = AnimationProcess(
      frames: frames,
      duration: duration,
      durationFrame: duration / (frames.isEmpty ? 1 : frames.length),
      onAnimateEnd: onAnimateEnd,
      // Always take the start time from the first animation tick. Using 0
      // when no tick had advanced the clock yet made the first tick add the
      // whole preceding drag time as "elapsed", so the turn finished at once.
      startedAt: -1,
    );
    _scheduleFrame();
  }

  @override
  void finishAnimation() {
    if (animation != null) {
      final anim = animation!;
      // Clear first so callbacks that start a new animation are not wiped.
      animation = null;
      if (anim.frames.isNotEmpty) {
        anim.frames.last();
      }
      anim.onAnimateEnd();
      pageFlip.trigger(PageFlipEvent.animationComplete, pageFlip, null);
    }
  }

  @override
  BookOrientation calculateBoundsRect() {
    final blockWidth = size.width;
    final middlePoint = model.Point(blockWidth / 2, size.height / 2);
    final ratio = (settings.height > 0)
        ? settings.width / settings.height
        : 1.0;
    double pageWidth = settings.width > 0 ? settings.width : blockWidth;
    double pageHeight = settings.height > 0 ? settings.height : size.height;

    final isSingle =
        settings.pageViewMode == PageViewMode.single ||
        (settings.pageViewMode == PageViewMode.auto &&
            blockWidth < (settings.width > 0 ? settings.width * 2 : 600));

    final BookOrientation orientation = isSingle
        ? BookOrientation.portrait
        : BookOrientation.landscape;

    double left = middlePoint.x - pageWidth;

    if (settings.size == SizeType.stretch) {
      pageWidth = orientation == BookOrientation.portrait
          ? blockWidth
          : blockWidth / 2;
      if (settings.width > 0 && pageWidth > settings.width) {
        pageWidth = settings.width;
      }
      if (ratio.isFinite && ratio > 0) {
        pageHeight = pageWidth / ratio;
      }
      if (pageHeight > size.height) {
        pageHeight = size.height;
        if (ratio.isFinite && ratio > 0) {
          pageWidth = pageHeight * ratio;
        }
      }
      left = orientation == BookOrientation.portrait
          ? middlePoint.x - pageWidth / 2 - pageWidth
          : middlePoint.x - pageWidth;
    } else {
      left = orientation == BookOrientation.portrait
          ? middlePoint.x - pageWidth / 2 - pageWidth
          : middlePoint.x - pageWidth;
    }

    _boundsRect = PageRect(
      left: left,
      top: middlePoint.y - pageHeight / 2,
      width: pageWidth * 2,
      height: pageHeight,
      pageWidth: pageWidth,
    );
    _orientation = orientation;
    return orientation;
  }

  @override
  void setShadowData(
    model.Point pos,
    double angle,
    double progress,
    FlipDirection direction,
  ) {
    _flipProgress = progress;
    if (!settings.drawShadow) return;
    final maxShadowOpacity = 100 * settings.maxShadowOpacity;
    shadow = Shadow(
      pos: pos,
      angle: angle,
      width: (((getRect().pageWidth * 3) / 4) * progress) / 100,
      opacity: ((100 - progress) * maxShadowOpacity) / 100 / 100,
      direction: direction,
      progress: progress * 2,
    );
    if (attached) markNeedsPaint();
  }

  @override
  void clearShadow() {
    shadow = null;
    _flipProgress = 0;
  }

  @override
  double getBlockWidth() => size.width;

  @override
  double getBlockHeight() => size.height;

  @override
  FlipDirection? getDirection() => direction;

  @override
  PageRect getRect() {
    if (_boundsRect == null) {
      calculateBoundsRect();
    }
    return _boundsRect!;
  }

  @override
  FlipSettings getSettings() => settings;

  @override
  BookOrientation? getOrientation() => _orientation;

  @override
  void setPageRect(RectPoints pageRect) {
    this.pageRect = pageRect;
  }

  @override
  void setDirection(FlipDirection direction) {
    this.direction = direction;
  }

  @override
  void setRightPage(BookPage? page) {
    if (page != null) page.setOrientation(PageOrientation.right);
    rightPage = page;
    if (attached) markNeedsPaint();
  }

  @override
  void setLeftPage(BookPage? page) {
    if (page != null) page.setOrientation(PageOrientation.left);
    leftPage = page;
    if (attached) markNeedsPaint();
  }

  @override
  void setBottomPage(BookPage? page) {
    if (page != null) {
      page.setOrientation(
        direction == FlipDirection.back
            ? PageOrientation.left
            : PageOrientation.right,
      );
    }
    bottomPage = page;
    if (attached) markNeedsPaint();
  }

  @override
  void setFlippingPage(BookPage? page) {
    if (page != null) {
      page.setOrientation(
        direction == FlipDirection.forward &&
                _orientation != BookOrientation.portrait
            ? PageOrientation.left
            : PageOrientation.right,
      );
    }
    flippingPage = page;
    if (attached) markNeedsPaint();
  }

  @override
  model.Point convertToBook(model.Point pos) {
    final rect = getRect();
    return model.Point(pos.x - rect.left, pos.y - rect.top);
  }

  @override
  model.Point convertToPage(model.Point pos, [FlipDirection? direction]) {
    direction ??= this.direction;
    final rect = getRect();
    final x = direction == FlipDirection.forward
        ? pos.x - rect.left - rect.width / 2
        : rect.width / 2 - pos.x + rect.left;
    return model.Point(x, pos.y - rect.top);
  }

  @override
  model.Point? convertToGlobal(model.Point? pos, [FlipDirection? direction]) {
    if (pos == null) return null;
    direction ??= this.direction;
    final rect = getRect();
    final x = direction == FlipDirection.forward
        ? pos.x + rect.left + rect.width / 2
        : rect.width / 2 - pos.x + rect.left;
    return model.Point(x, pos.y + rect.top);
  }

  @override
  RectPoints convertRectToGlobal(RectPoints rect, [FlipDirection? direction]) {
    direction ??= this.direction;
    return RectPoints(
      topLeft: convertToGlobal(rect.topLeft, direction)!,
      topRight: convertToGlobal(rect.topRight, direction)!,
      bottomLeft: convertToGlobal(rect.bottomLeft, direction)!,
      bottomRight: convertToGlobal(rect.bottomRight, direction)!,
    );
  }

  @override
  void updateApp(PageFlip app) {}

  /// Paints the page stacks against the outer edges of the visible pages
  /// (FlipSettings.showPageEdges). They follow the reading position, and
  /// move smoothly while a page turns.
  void _paintPageEdges(Canvas canvas, PageRect rect, Offset offset) {
    final spreads = collection.getSpread().length;
    if (spreads < 1) return;
    var read = spreads > 1
        ? collection.getCurrentSpreadIndex() / (spreads - 1)
        : 0.0;
    if (spreads > 1 && flippingPage != null && _flipProgress > 0) {
      final sign = direction == FlipDirection.back ? -1 : 1;
      read += sign * (_flipProgress / 100) / (spreads - 1);
    }
    final landscape = _orientation != BookOrientation.portrait;
    // A single page is the right half of an open book: the pages already
    // read are behind the spine, out of sight, so only the stack of pages
    // left to read shows, on the outer edge (mirrored in right-to-left).
    final spine = rect.left + rect.pageWidth;
    // A cover alone in a spread has its outer edges at the spine side too.
    final leftEdge = landscape && leftPage != null ? rect.left : spine;
    final rightEdge = !landscape || rightPage != null
        ? rect.left + rect.pageWidth * 2
        : spine;
    PageEdges.paint(
      canvas,
      leftEdge: leftEdge + offset.dx,
      rightEdge: rightEdge + offset.dx,
      top: rect.top + offset.dy,
      height: rect.height,
      read: read,
      showRead: landscape,
      maxWidth: settings.pageEdgeWidth,
      paperColor: settings.pageBackgroundColor,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final rect = getRect();

    // Background fill — safe: pure canvas draw with no compositing children around it.
    // In portrait only the right half of the book rect is a visible page.
    final portrait = _orientation == BookOrientation.portrait;
    context.canvas.drawRect(
      Rect.fromLTWH(
        rect.left + (portrait ? rect.pageWidth : 0) + offset.dx,
        rect.top + offset.dy,
        portrait ? rect.pageWidth : rect.width,
        rect.height,
      ),
      Paint()..color = settings.pageBackgroundColor,
    );

    if (settings.showPageEdges) _paintPageEdges(context.canvas, rect, offset);

    // Nested helper: paint a static (non-flipping) page child.
    // We do NOT wrap context.paintChild() in canvas.save/restore because compositing
    // children (e.g. CachedNetworkImage, RepaintBoundary) push their own PictureLayer,
    // which invalidates any previously captured canvas reference and causes a native
    // peer crash on canvas.restore(). The child is placed at its absolute screen offset.
    void paintStatic(BookPage? page, bool isLeft) {
      if (page == null) return;
      final lp = page as BookPageImpl;
      if (_isWhitePageIndex(lp.index)) {
        _drawWhitePageStatic(context.canvas, rect, offset, isLeft);
        return;
      }
      final child = _childByIndex(lp.index);
      if (child == null) return;
      final pageOffset = Offset(
        (isLeft ? rect.left : rect.left + rect.pageWidth) + offset.dx,
        rect.top + offset.dy,
      );
      context.paintChild(child, pageOffset);
    }

    final bool hardTurn = _isHardTurn;
    final bool hardForward = hardTurn && direction == FlipDirection.forward;
    final bool hardBack = hardTurn && direction == FlipDirection.back;

    if (_orientation != BookOrientation.portrait) {
      // Cover side widgets fill the empty side of a lone cover spread.
      if (leftPage == null && _frontSideChild != null) {
        context.paintChild(
          _frontSideChild!,
          Offset(rect.left + offset.dx, rect.top + offset.dy),
        );
      }
      if (rightPage == null && _backSideChild != null) {
        context.paintChild(
          _backSideChild!,
          Offset(rect.left + rect.pageWidth + offset.dx, rect.top + offset.dy),
        );
      }
      // A hard sheet does not reveal the page below progressively: its
      // front is drawn rotating (below), and the page it uncovers is drawn
      // whole.
      if (!hardBack) paintStatic(leftPage, true);
      // In two-page mode, do not double-paint rightPage if it is already being flipped
      if (!hardForward &&
          (flippingPage is! BookPageImpl ||
              (flippingPage as BookPageImpl).index !=
                  (rightPage as BookPageImpl?)?.index)) {
        paintStatic(rightPage, false);
      }
      if (hardTurn && bottomPage is BookPageImpl) {
        _paintFlatPage(context, offset, bottomPage as BookPageImpl, hardBack);
      }
    } else {
      // In portrait mode, rightPage is the static base page (Page N) currently visible.
      // It must always be painted so the unturned content remains visible while curling.
      paintStatic(rightPage, false);
    }

    if (!hardTurn && bottomPage is BookPageImpl) {
      _paintDynamicPage(
        context,
        offset,
        bottomPage as BookPageImpl,
        isBottom: true,
      );
    }

    // Shadow drawing uses context.canvas directly (accessed AFTER all compositing children
    // have been painted, so it is always the current active canvas).
    final bool shouldDrawCenterShadow = _orientation != BookOrientation.portrait
        ? settings.showCenterShadow
        : !settings.hideLeftShadow;
    if (settings.drawShadow && shouldDrawCenterShadow) {
      _drawBookShadow(context.canvas, rect, offset);
    }

    if (hardTurn) {
      _paintHardSheet(context, offset, rect);
      return;
    }

    if (flippingPage is BookPageImpl) {
      if (_orientation == BookOrientation.portrait &&
          direction == FlipDirection.forward) {
        // In portrait mode forward flip, the curled flap being folded over is the
        // physical backside of the current sheet. The backside is white paper.
        _paintDynamicWhitePage(
          context.canvas,
          offset,
          flippingPage as BookPageImpl,
        );
      } else {
        _paintDynamicPage(context, offset, flippingPage as BookPageImpl);
      }

      // The turning sheet covers the spine shadow painted above. Paint the
      // spine shadow on the sheet too, growing as it lands, so the crease is
      // already there when the turn ends instead of popping in on the new page.
      // In single-page mode only a back turn lands a page (the previous one,
      // spine on its left edge); a forward turn lifts the page away.
      if ((_orientation != BookOrientation.portrait ||
              direction == FlipDirection.back) &&
          settings.drawShadow &&
          shouldDrawCenterShadow) {
        _drawSpineShadowOnTurningPage(
          context.canvas,
          rect,
          offset,
          flippingPage as BookPageImpl,
        );
      }
    }

    if (shadow != null && settings.drawShadow) {
      _drawOuterShadow(context.canvas, rect, offset);
      if (pageRect != null) {
        _drawInnerShadow(context.canvas, rect, offset);
      }
    }
  }

  /// Whether the running turn is a hard sheet (see `FlipSettings.hardCover`).
  /// Two-page spreads only. The sheet is hard when its front or its back is
  /// a hard page.
  bool get _isHardTurn {
    if (_orientation == BookOrientation.portrait) return false;
    if (!settings.hardCover && !settings.hardPages) return false;
    final back = flippingPage;
    if (back is! BookPageImpl) return false;
    final front = direction == FlipDirection.forward ? rightPage : leftPage;
    bool hard(BookPage? p) =>
        p is BookPageImpl &&
        !p.isBlank &&
        settings.isHardPage(p.index, _pageCount);
    return hard(back) || hard(front);
  }

  /// Paints [page] whole and unrotated on the left or right side.
  void _paintFlatPage(
    PaintingContext context,
    Offset offset,
    BookPageImpl page,
    bool isLeft,
  ) {
    final rect = getRect();
    if (_isWhitePageIndex(page.index)) {
      _drawWhitePageStatic(context.canvas, rect, offset, isLeft);
      return;
    }
    final child = _childByIndex(page.index);
    if (child == null) return; // plain paper: already filled
    context.paintChild(
      child,
      Offset(
        (isLeft ? rect.left : rect.left + rect.pageWidth) + offset.dx,
        rect.top + offset.dy,
      ),
    );
  }

  /// Paints a hard sheet swinging around the spine.
  ///
  /// Up to 90 degrees the sheet's front is visible on its starting side,
  /// then its back on the other side. The rotation is a real 3D one with a
  /// light perspective, so the free edge grows slightly as it lifts towards
  /// the reader, and the sheet darkens as it turns edge-on.
  void _paintHardSheet(PaintingContext context, Offset offset, PageRect rect) {
    final t = (_flipProgress / 100).clamp(0.0, 1.0);
    final angle = t * math.pi;
    final forward = direction == FlipDirection.forward;
    final showFront = angle < math.pi / 2;
    final w = rect.pageWidth.toDouble();
    final h = rect.height.toDouble();
    final spineX = rect.left + w + offset.dx;
    final top = rect.top + offset.dy;
    final midY = top + h / 2;
    final lift = math.sin(angle);

    // Shadow cast by the lifted sheet on the page it is moving towards.
    if (settings.drawShadow && lift > 0.01) {
      final towardsLeft = forward;
      final reach = w * 0.35 * lift;
      final shadowRect = towardsLeft
          ? Rect.fromLTWH(spineX - reach, top, reach, h)
          : Rect.fromLTWH(spineX, top, reach, h);
      final shadowColor = settings.outerShadowColor;
      final alpha =
          (0.35 * lift * shadowColor.a * settings.effectiveShadowOpacity).clamp(
            0.0,
            1.0,
          );
      context.canvas.drawRect(
        shadowRect,
        Paint()
          ..shader = ui.Gradient.linear(
            towardsLeft ? shadowRect.centerRight : shadowRect.centerLeft,
            towardsLeft ? shadowRect.centerLeft : shadowRect.centerRight,
            [
              shadowColor.withValues(alpha: alpha),
              shadowColor.withValues(alpha: 0.0),
            ],
          ),
      );
    }

    final BookPage? side = showFront
        ? (forward ? rightPage : leftPage)
        : flippingPage;
    if (side is! BookPageImpl) return;

    // Which half of the spine the visible side lies on, and its rotation.
    // The signs keep the free edge towards the reader (drawn bigger).
    final bool onRight = showFront ? forward : !forward;
    final double rotation;
    if (showFront) {
      rotation = forward ? angle : -angle;
    } else {
      rotation = forward ? angle - math.pi : math.pi - angle;
    }

    final transform = Matrix4.translationValues(spineX, midY, 0)
      ..multiply(Matrix4.identity()..setEntry(3, 2, 0.18 / w))
      ..rotateY(rotation)
      ..multiply(Matrix4.translationValues(onRight ? 0.0 : -w, -h / 2, 0));

    final child = side.isBlank ? null : _childByIndex(side.index);
    final white = _isWhitePageIndex(side.index);
    final shade = (0.28 * lift * settings.effectiveShadowOpacity).clamp(
      0.0,
      0.6,
    );

    context.pushTransform(needsCompositing, Offset.zero, transform, (
      PaintingContext ctx,
      Offset off,
    ) {
      final pageRect = Rect.fromLTWH(off.dx, off.dy, w, h);
      ctx.canvas.drawRect(
        pageRect,
        Paint()..color = settings.pageBackgroundColor,
      );
      if (child != null && !white) ctx.paintChild(child, off);
      // Read the canvas again: paintChild may have started a new layer.
      final canvas = ctx.canvas;
      final border = settings.effectivePageBorderColor;
      if (border != null) {
        canvas.drawRect(
          pageRect.deflate(0.5),
          Paint()
            ..color = border
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      if (settings.drawShadow && shade > 0) {
        canvas.drawRect(
          pageRect,
          Paint()..color = const Color(0xFF000000).withValues(alpha: shade),
        );
      }
    });
  }

  void _paintDynamicPage(
    PaintingContext context,
    Offset rootOffset,
    BookPageImpl page, {
    bool isBottom = false,
  }) {
    // An empty cover side without a widget is plain paper; with one, it is
    // painted below like any page.
    if (page.isBlank && _childByIndex(page.index) == null) {
      _paintBlankBottomPage(context.canvas, rootOffset, page);
      return;
    }
    if (_isWhitePageIndex(page.index)) {
      _paintDynamicWhitePage(context.canvas, rootOffset, page);
      return;
    }
    final child = _childByIndex(page.index);
    if (child == null) return;

    // A collapsed (zero-area) clip must never be used: clipping with it hides
    // the page entirely. For the incoming bottom page late in a turn it means
    // the page is fully revealed, so paint it unclipped; otherwise skip it.
    final bool degenerate = Helper.isDegenerateArea(page.state.area);
    if (degenerate && (!isBottom || _flipProgress < 50)) return;

    final position = page.state.position;
    final globalPos = convertToGlobal(position) ?? model.Point(0, 0);
    final rect = getRect();
    final angle = page.state.angle;

    // The clip path is built relative to globalOrigin (page-anchor-local).
    // See BookPageImpl.buildOrGetClipPath: path(0,0) = top-left of page at globalPos.
    final origin = convertToGlobal(position);
    final clipPath = degenerate
        ? null
        : page.buildOrGetClipPath(
            origin,
            (model.Point p) => convertToGlobal(p)!,
          );

    // Page anchor position in world/screen space.
    final Offset pageAnchor = Offset(
      globalPos.x + rootOffset.dx,
      globalPos.y + rootOffset.dy,
    );

    // -------------------------------------------------------------------------
    // WHY THE ORDER MATTERS
    // -------------------------------------------------------------------------
    // Original canvas sequence:
    //   canvas.translate(pageAnchor)  → move origin to page fold-anchor
    //   canvas.clipPath(path)         → clip is FIXED in world space (pre-rotate)
    //   canvas.rotate(angle)          → only the CONTENT rotates, not the clip
    //   context.paintChild(child, 0)  → child drawn inside clip
    //
    // Naïve pushTransform(translate+rotate) → pushClipPath INSIDE would rotate
    // the clip too, producing the coloured artifact line seen on the fold edge.
    //
    // Correct order: pushClipPath (world-space) FIRST, then pushTransform
    // (translate+rotate) for the child content INSIDE the clip.
    // -------------------------------------------------------------------------

    // Transform for the child content: translate to page anchor + rotate.
    // Replicates canvas.translate(pageAnchor) + canvas.rotate(angle).
    // We use Offset.zero for the push* calls so effectiveTransform = childTransform.
    final Matrix4 childTransform = Matrix4.translationValues(
      pageAnchor.dx,
      pageAnchor.dy,
      0.0,
    )..rotateZ(angle);

    // Inner painter: background fill (prevents transparent-widget flicker) + child.
    // `off` = Offset.zero throughout; after childTransform the child lands at
    // pageAnchor on screen, rotated by `angle`.
    void paintPageChild(PaintingContext ctx, Offset off) {
      ctx.canvas.drawRect(
        Rect.fromLTWH(off.dx, off.dy, rect.pageWidth, rect.height),
        Paint()
          ..color = settings.pageBackgroundColor
          ..style = PaintingStyle.fill,
      );
      ctx.paintChild(child, off);
    }

    if (clipPath != null) {
      // Shift the page-anchor-relative clip path to world/screen coordinates so
      // that it clips at the correct screen position WITHOUT any rotation applied.
      // path(0,0) is at the page anchor → shift by pageAnchor.
      final Path worldClipPath = clipPath.shift(pageAnchor);

      // Step 1 ── apply clip in world space (no rotation).
      //   pushClipPath with Offset.zero: Flutter internally does
      //   clipPath.shift(Offset.zero) = worldClipPath unchanged. ✓
      //
      //   IMPORTANT: childPaintBounds must be the FULL render-box size, NOT
      //   worldClipPath.getBounds(). The clip starts as a tiny triangle at the
      //   beginning of a flip. If we use getBounds() here, Flutter computes a
      //   tiny estimatedBounds for the nested TransformLayer via
      //   inverseTransformRect(), which causes the PictureLayer inside it to
      //   allocate an undersized canvas — the child widget (full page size)
      //   gets cropped and the bottom page appears invisible, showing only the
      //   static page through. Using the full render box guarantees the inner
      //   canvas is always large enough; the ClipPathLayer still clips the
      //   VISIBLE output to worldClipPath. ✓
      context.pushClipPath(
        needsCompositing,
        Offset.zero,
        Offset.zero & size, // ← full render-box area, NOT clip bounds
        worldClipPath,
        (PaintingContext clipCtx, Offset clipOff) {
          // Step 2 ── apply translate + rotate for the child content only.
          clipCtx.pushTransform(
            needsCompositing,
            clipOff,
            childTransform,
            paintPageChild,
          );
        },
      );

      // Subtle hairline boundary along curling page perimeter
      if (!isBottom && settings.drawShadow) {
        final borderColor = settings.perimeterBorderColor.withValues(
          alpha: (settings.perimeterBorderColor.a * settings.maxShadowOpacity)
              .clamp(0.0, 1.0),
        );
        context.canvas.drawPath(
          worldClipPath,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    } else {
      // No clip (bottom page fully revealed at the end of a turn).
      context.pushTransform(
        needsCompositing,
        Offset.zero,
        childTransform,
        paintPageChild,
      );
    }
  }

  /// Paints the revealed part of an empty spread side as plain paper, the
  /// same as that side looks once the turn completes (no border).
  void _paintBlankBottomPage(
    Canvas canvas,
    Offset rootOffset,
    BookPageImpl page,
  ) {
    final rect = getRect();
    final paint = Paint()..color = settings.pageBackgroundColor;
    if (Helper.isDegenerateArea(page.state.area)) {
      // Late in a turn the clip collapses: the side is fully revealed.
      if (_flipProgress < 50) return;
      final isLeft = direction == FlipDirection.back;
      canvas.drawRect(
        Rect.fromLTWH(
          (isLeft ? rect.left : rect.left + rect.pageWidth) + rootOffset.dx,
          rect.top + rootOffset.dy,
          rect.pageWidth,
          rect.height,
        ),
        paint,
      );
      return;
    }
    final origin = convertToGlobal(page.state.position);
    if (origin == null) return;
    final path = page.buildOrGetClipPath(
      origin,
      (model.Point p) => convertToGlobal(p)!,
    );
    if (path == null) return;
    canvas.save();
    canvas.translate(origin.x + rootOffset.dx, origin.y + rootOffset.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _paintDynamicWhitePage(
    Canvas canvas,
    Offset rootOffset,
    BookPageImpl page,
  ) {
    // Without a drawable clip area there is nothing sensible to paint: an
    // unclipped full-page rect here would flash a white sheet over the book.
    if (Helper.isDegenerateArea(page.state.area)) return;

    final position = page.state.position;
    final globalPos = convertToGlobal(position) ?? model.Point(0, 0);
    final rect = getRect();
    final origin = convertToGlobal(position);
    final path = page.buildOrGetClipPath(
      origin,
      (model.Point p) => convertToGlobal(p)!,
    );
    if (path == null) return;

    canvas.save();
    canvas.translate(globalPos.x + rootOffset.dx, globalPos.y + rootOffset.dy);
    canvas.clipPath(path);
    final angle = page.state.angle;
    if (angle.abs() > 0.001) {
      canvas.rotate(angle);
    }
    final paint = Paint()
      ..color = settings.pageBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, rect.pageWidth, rect.height), paint);
    final borderColor = settings.effectivePageBorderColor;
    if (borderColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, rect.pageWidth, rect.height),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
    canvas.restore();

    // Subtle hairline boundary along curling white page perimeter
    if (settings.drawShadow) {
      final borderColor = settings.perimeterBorderColor.withValues(
        alpha: (settings.perimeterBorderColor.a * settings.maxShadowOpacity)
            .clamp(0.0, 1.0),
      );
      canvas.save();
      canvas.translate(
        globalPos.x + rootOffset.dx,
        globalPos.y + rootOffset.dy,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
      canvas.restore();
    }
  }

  void _drawSpineShadowOnTurningPage(
    Canvas canvas,
    PageRect rect,
    Offset root,
    BookPageImpl page,
  ) {
    if (Helper.isDegenerateArea(page.state.area)) return;
    final strength = (_flipProgress / 100).clamp(0.0, 1.0);
    if (strength <= 0) return;
    final origin = convertToGlobal(page.state.position);
    if (origin == null) return;
    final clip = page.buildOrGetClipPath(
      origin,
      (model.Point p) => convertToGlobal(p)!,
    );
    if (clip == null) return;

    final anchor = Offset(origin.x + root.dx, origin.y + root.dy);
    canvas.save();
    canvas.clipPath(clip.shift(anchor));
    // Work in the sheet's own coordinates, so the crease follows the paper
    // as it moves and rotates instead of staying at the book's center.
    canvas.translate(anchor.dx, anchor.dy);
    final angle = page.state.angle;
    if (angle.abs() > 0.001) canvas.rotate(angle);
    canvas.clipRect(Rect.fromLTWH(0, 0, rect.pageWidth, rect.height));

    // The sheet lands as the left page on a forward turn (spine on its right
    // edge) and as the right page on a back turn (spine on its left edge),
    // in a spread and in single-page mode.
    final spineX = direction == FlipDirection.forward ? rect.pageWidth : 0.0;
    final shadowSize = rect.width / 20;
    _paintSpineGradient(
      canvas,
      Rect.fromLTWH(spineX - shadowSize / 2, 0, shadowSize, rect.height),
      strength,
    );
    canvas.restore();
  }

  void _paintSpineGradient(Canvas canvas, Rect area, double strength) {
    final baseColor = settings.centerShadowColor;
    final baseAlpha = (baseColor.a * settings.effectiveShadowOpacity * strength)
        .clamp(0.0, 1.0);
    final gradient = ui.Gradient.linear(
      area.centerLeft,
      area.centerRight,
      [
        baseColor.withValues(alpha: 0.0),
        baseColor.withValues(alpha: (0.2 * baseAlpha).clamp(0.0, 1.0)),
        baseColor.withValues(alpha: (0.1 * baseAlpha).clamp(0.0, 1.0)),
        baseColor.withValues(alpha: (0.5 * baseAlpha).clamp(0.0, 1.0)),
        baseColor.withValues(alpha: (0.4 * baseAlpha).clamp(0.0, 1.0)),
        baseColor.withValues(alpha: 0.0),
      ],
      [0.0, 0.4, 0.49, 0.5, 0.51, 1.0],
    );
    canvas.drawRect(area, Paint()..shader = gradient);
  }

  void _drawBookShadow(Canvas canvas, PageRect rect, Offset root) {
    if (!settings.drawShadow) return;
    if (_orientation != BookOrientation.portrait &&
        !settings.showCenterShadow) {
      return;
    }
    if (_orientation == BookOrientation.portrait && settings.hideLeftShadow) {
      return;
    }

    final shadowSize = rect.width / 20;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        rect.left + root.dx,
        rect.top + root.dy,
        rect.width,
        rect.height,
      ),
    );
    final shadowPosX = rect.left + rect.width / 2 - shadowSize / 2 + root.dx;
    final shadowPosY = 0 + root.dy;
    canvas.translate(shadowPosX, shadowPosY);
    _paintSpineGradient(
      canvas,
      Rect.fromLTWH(0, 0, shadowSize, rect.height * 2),
      1.0,
    );
    canvas.restore();
  }

  void _drawOuterShadow(Canvas canvas, PageRect rect, Offset root) {
    if (shadow == null || !settings.drawShadow) return;
    final s = shadow!;
    final shadowPos = convertToGlobal(s.pos);
    if (shadowPos == null) return;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        rect.left + root.dx,
        rect.top + root.dy,
        rect.width,
        rect.height,
      ),
    );
    canvas.translate(shadowPos.x + root.dx, shadowPos.y + root.dy);
    canvas.rotate(math.pi + s.angle + math.pi / 2);
    final paint = Paint();
    late final List<Color> colors;
    late final List<double> stops;

    final outerColor = settings.outerShadowColor;
    final targetAlpha =
        (s.opacity * outerColor.a * settings.effectiveShadowOpacity).clamp(
          0.0,
          1.0,
        );

    if (s.direction == FlipDirection.forward) {
      canvas.translate(0, -100);
      colors = [
        outerColor.withValues(alpha: targetAlpha),
        outerColor.withValues(alpha: 0.0),
      ];
      stops = [0.0, 1.0];
    } else {
      canvas.translate(-s.width, -100);
      colors = [
        outerColor.withValues(alpha: 0.0),
        outerColor.withValues(alpha: targetAlpha),
      ];
      stops = [0.0, 1.0];
    }
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(s.width, 0),
      colors,
      stops,
    );
    paint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, rect.height * 2), paint);
    canvas.restore();
  }

  void _drawInnerShadow(Canvas canvas, PageRect rect, Offset root) {
    if (shadow == null || pageRect == null || !settings.drawShadow) return;
    final s = shadow!;
    final shadowPos = convertToGlobal(s.pos);
    if (shadowPos == null) return;
    final pr = convertRectToGlobal(pageRect!);
    canvas.save();
    final path = Path()
      ..moveTo(pr.topLeft.x + root.dx, pr.topLeft.y + root.dy)
      ..lineTo(pr.topRight.x + root.dx, pr.topRight.y + root.dy)
      ..lineTo(pr.bottomRight.x + root.dx, pr.bottomRight.y + root.dy)
      ..lineTo(pr.bottomLeft.x + root.dx, pr.bottomLeft.y + root.dy)
      ..close();
    canvas.clipPath(path);
    canvas.translate(shadowPos.x + root.dx, shadowPos.y + root.dy);
    canvas.rotate(math.pi + s.angle + math.pi / 2);
    final isw = (s.width * 3) / 4;
    final paint = Paint();
    late final List<Color> colors;
    late final List<double> stops;

    final innerColor = settings.innerShadowColor;
    final baseAlpha =
        (s.opacity * innerColor.a * settings.effectiveShadowOpacity).clamp(
          0.0,
          1.0,
        );

    if (s.direction == FlipDirection.forward) {
      canvas.translate(-isw, -100);
      colors = [
        innerColor.withValues(alpha: 0.0),
        innerColor.withValues(alpha: (baseAlpha * 0.05).clamp(0.0, 1.0)),
        innerColor.withValues(alpha: baseAlpha),
        innerColor.withValues(alpha: baseAlpha),
      ];
      stops = [0.0, 0.7, 0.9, 1.0];
    } else {
      canvas.translate(0, -100);
      colors = [
        innerColor.withValues(alpha: baseAlpha),
        innerColor.withValues(alpha: (baseAlpha * 0.05).clamp(0.0, 1.0)),
        innerColor.withValues(alpha: baseAlpha),
        innerColor.withValues(alpha: 0.0),
      ];
      stops = [0.0, 0.1, 0.3, 1.0];
    }
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(isw, 0),
      colors,
      stops,
    );
    paint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, isw, rect.height * 2), paint);

    // Glossy paper: a soft light band on the curl, beside the fold.
    final gloss = settings.paperGloss.clamp(0.0, 1.0);
    if (gloss > 0 && isw > 1) {
      final forward = s.direction == FlipDirection.forward;
      // The fold is at x = isw (forward) or x = 0 (back).
      final start = forward ? isw * 0.45 : isw * 0.25;
      final band = isw * 0.3;
      final alpha = (0.55 * gloss * (0.4 + 0.6 * s.opacity)).clamp(0.0, 1.0);
      const light = Color(0xFFFFFFFF);
      canvas.drawRect(
        Rect.fromLTWH(start, 0, band, rect.height * 2),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(start, 0),
            Offset(start + band, 0),
            [
              light.withValues(alpha: 0.0),
              light.withValues(alpha: alpha),
              light.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }
    canvas.restore();
  }

  bool _childConsumedHit = false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Reset child consumed hit state for each new hit test
    _childConsumedHit = false;

    // Touches on turnable page corners are reserved for book page flipping.
    // Do not route them to child scroll views or child buttons on the corner.
    // Not with tap-to-flip off: the page's widgets there must stay tappable
    // (a drag from a corner still turns the page, see _handlePointerMove).
    // Buttons, links and fields on a corner (anything with a clickable
    // mouse cursor) stay tappable.
    final point = model.Point(position.dx, position.dy);
    if (settings.flipOnTap &&
        pageFlip.isPointOnCorners(point) &&
        !_isInteractiveAt(position)) {
      return false;
    }
    return _hitTestPages(result, position);
  }

  /// Whether a widget with a clickable mouse cursor (a button, link or text
  /// field) is under [position].
  bool _isInteractiveAt(Offset position) {
    final consumed = _childConsumedHit;
    final probe = BoxHitTestResult();
    _hitTestPages(probe, position);
    _childConsumedHit = consumed;
    for (final entry in probe.path) {
      final Object target = entry.target;
      if (target is MouseTrackerAnnotation && target.validForMouseTracker) {
        final cursor = target.cursor;
        if (cursor != MouseCursor.defer &&
            cursor != MouseCursor.uncontrolled &&
            cursor != SystemMouseCursors.basic) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hitTestPages(BoxHitTestResult result, Offset position) {
    final rect = getRect();

    // Test visible static pages for interactive widgets
    if (_orientation != BookOrientation.portrait && leftPage != null) {
      final leftChild = _childByIndex((leftPage as BookPageImpl).index);
      if (leftChild != null &&
          !_isWhitePageIndex((leftPage as BookPageImpl).index)) {
        final leftOffset = Offset(rect.left, rect.top);
        final bool isHit = result.addWithPaintOffset(
          offset: leftOffset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            if (_isPositionInChildBounds(
              transformed,
              rect.pageWidth,
              rect.height,
            )) {
              return leftChild.hitTest(result, position: transformed);
            }
            return false;
          },
        );
        if (isHit) {
          _childConsumedHit = true;
          return true;
        }
      }
    }

    if (rightPage != null) {
      final rightChild = _childByIndex((rightPage as BookPageImpl).index);
      if (rightChild != null &&
          !_isWhitePageIndex((rightPage as BookPageImpl).index)) {
        final rightOffset = Offset(rect.left + rect.pageWidth, rect.top);
        final bool isHit = result.addWithPaintOffset(
          offset: rightOffset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            if (_isPositionInChildBounds(
              transformed,
              rect.pageWidth,
              rect.height,
            )) {
              return rightChild.hitTest(result, position: transformed);
            }
            return false;
          },
        );
        if (isHit) {
          _childConsumedHit = true;
          return true;
        }
      }
    }

    // Cover side widgets fill the empty side of a lone cover spread.
    if (_orientation != BookOrientation.portrait) {
      bool hitSide(RenderBox? side, bool isLeft) {
        if (side == null) return false;
        return result.addWithPaintOffset(
          offset: Offset(
            isLeft ? rect.left : rect.left + rect.pageWidth,
            rect.top,
          ),
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            if (!_isPositionInChildBounds(
              transformed,
              rect.pageWidth,
              rect.height,
            )) {
              return false;
            }
            return side.hitTest(result, position: transformed);
          },
        );
      }

      if ((leftPage == null && hitSide(_frontSideChild, true)) ||
          (rightPage == null && hitSide(_backSideChild, false))) {
        _childConsumedHit = true;
        return true;
      }
    }

    return false;
  }

  bool _isPositionInChildBounds(Offset position, double width, double height) {
    return position.dx >= 0 &&
        position.dx < width &&
        position.dy >= 0 &&
        position.dy < height;
  }

  @override
  bool hitTestSelf(Offset position) {
    // Always participate in hit testing to detect gestures
    return true;
  }

  Offset getPointerOffset({required PointerEvent event}) {
    return settings.onlyVerticalPageFlip
        ? Offset(event.localPosition.dx, size.height - 1)
        : event.localPosition;
  }

  GestureArenaEntry? _arenaEntry;

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    final timeMs = event.timeStamp.inMicroseconds / 1000.0;
    if (event is PointerDownEvent) {
      _arenaEntry = GestureBinding.instance.gestureArena.add(
        event.pointer,
        this,
      );
      _handlePointerDown(getPointerOffset(event: event), timeMs);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(getPointerOffset(event: event), timeMs);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handlePointerUp(getPointerOffset(event: event), timeMs);
    } else if (event is PointerHoverEvent) {
      // A mouse over a page corner folds it a little (showPageCorners).
      if (settings.showPageCorners &&
          !isZoomed &&
          event.kind == PointerDeviceKind.mouse) {
        if (_isInteractiveAt(event.localPosition)) {
          pageFlip.releaseCorner();
        } else {
          pageFlip.hoverCorner(
            model.Point(event.localPosition.dx, event.localPosition.dy),
          );
        }
      }
    }
  }

  void _handlePointerDown(Offset position, [double? timeMs]) {
    if (isZoomed) return;

    final point = model.Point(position.dx, position.dy);

    // Reset dragging & scroll lock state
    _isDragging = false;
    _isVerticalScrollLocked = false;
    _isInvalidDirectionLocked = false;
    _initialTouchPoint = point;
  }

  void _handlePointerMove(Offset position, [double? timeMs]) {
    if (isZoomed || _isInvalidDirectionLocked) return;

    final point = model.Point(position.dx, position.dy);
    if (_initialTouchPoint == null) return;

    final deltaX = point.x - _initialTouchPoint!.x; // signed delta
    final deltaY = (point.y - _initialTouchPoint!.y).abs();
    final absDeltaX = deltaX.abs();

    final rect = getRect();
    final isLandscape = _orientation == BookOrientation.landscape;
    final spineX = isLandscape ? rect.left + rect.pageWidth : rect.left;
    final isTouchOnLeftSide = _initialTouchPoint!.x < spineX;

    // ── Direction & Boundary validation ──────────────────────────────
    // In Landscape (Two-page spread):
    // - Left page can ONLY drag to the RIGHT (deltaX > 0) to turn backward.
    //   Dragging to the LEFT (deltaX < 0) is an invalid reverse drag -> FORBIDDEN!
    //   Also, dragging to the right requires canFlipPrev() -> if false, FORBIDDEN!
    // - Right page can ONLY drag to the LEFT (deltaX < 0) to turn forward.
    //   Dragging to the RIGHT (deltaX > 0) is an invalid reverse drag -> FORBIDDEN!
    //   Also, dragging to the left requires canFlipNext() -> if false, FORBIDDEN!
    // These checks decide whether a drag may START. Once the page is in the
    // user's hand (_isDragging) it must follow the finger anywhere: moving
    // back past the start point just un-curls the page, it never drops it.
    if (!_isDragging && isLandscape && absDeltaX > 5.0) {
      if (isTouchOnLeftSide) {
        if (deltaX < 0 || !pageFlip.canFlipPrev()) {
          _isInvalidDirectionLocked = true;
          pageFlip.abortFlip();
          return;
        }
      } else {
        if (deltaX > 0 || !pageFlip.canFlipNext()) {
          _isInvalidDirectionLocked = true;
          pageFlip.abortFlip();
          return;
        }
      }
    }

    // In Portrait (Single page):
    // - Dragging to the RIGHT (deltaX > 0) turns PREV -> disallowed if !canFlipPrev!
    // - Dragging to the LEFT (deltaX < 0) turns NEXT -> disallowed if !canFlipNext!
    if (!_isDragging && !isLandscape && absDeltaX > 5.0) {
      if (deltaX > 0 && !pageFlip.canFlipPrev()) {
        _isInvalidDirectionLocked = true;
        pageFlip.abortFlip();
        return;
      }
      if (deltaX < 0 && !pageFlip.canFlipNext()) {
        _isInvalidDirectionLocked = true;
        pageFlip.abortFlip();
        return;
      }
    }

    final isOnCorner = pageFlip.isPointOnCorners(_initialTouchPoint!);

    // ── Child widget / Scroll conflict resolution ───────────────────
    if (_childConsumedHit) {
      if (_isVerticalScrollLocked) return;

      if (isOnCorner) {
        // Corner touches are dedicated page flips; resolve arena as accepted immediately
        // and do not lock to vertical scroll even if movement has a vertical component.
        if (!_isDragging) {
          if (absDeltaX > _minMoveThreshold || deltaY > _minMoveThreshold) {
            _isDragging = true;
            _arenaEntry?.resolve(GestureDisposition.accepted);
            _beginUserDrag(deltaX, timeMs);
          } else {
            return;
          }
        }
      } else if (!_isDragging) {
        if (absDeltaX > _minMoveThreshold || deltaY > _minMoveThreshold) {
          // Priority 1: Vertical movement intent -> lock to child scroll view
          // completely. Only decided BEFORE the flip starts: once the user
          // holds the page, steering it up/down (deltaY > deltaX measured
          // from the first touch) used to abort the flip and drop the page
          // out of the finger.
          if (!settings.onlyVerticalPageFlip && deltaY > absDeltaX) {
            _isVerticalScrollLocked = true;
            _arenaEntry?.resolve(GestureDisposition.rejected);
            _arenaEntry = null;
            return;
          }

          // Priority 2: Clear horizontal page flip intent
          if (absDeltaX > deltaY * settings.swipeAngleThreshold) {
            _isDragging = true;
            _arenaEntry?.resolve(GestureDisposition.accepted);
            _beginUserDrag(deltaX, timeMs);
          } else {
            return; // Ambiguous or vertical motion, yield to child
          }
        }

        if (!_isDragging) return;
      }
    } else {
      // Normal drag (no interactive child consumed hit):
      if (!_isDragging) {
        if (absDeltaX > _minMoveThreshold || deltaY > _minMoveThreshold) {
          if (!settings.onlyVerticalPageFlip &&
              !isOnCorner &&
              deltaY > absDeltaX) {
            _isVerticalScrollLocked = true;
            _arenaEntry?.resolve(GestureDisposition.rejected);
            _arenaEntry = null;
            return;
          }
          if (absDeltaX >= _minMoveThreshold ||
              (isOnCorner && deltaY >= _minMoveThreshold)) {
            _isDragging = true;
            _arenaEntry?.resolve(GestureDisposition.accepted);
            _beginUserDrag(deltaX, timeMs);
          } else {
            return;
          }
        } else {
          return;
        }
      }
    }

    // Now actively dragging in a valid direction:
    pageFlip.userMove(_shiftDrag(point), true, timeMs);
    markNeedsPaint();
  }

  void _handlePointerUp(Offset position, [double? timeMs]) {
    if (isZoomed || _isVerticalScrollLocked || _isInvalidDirectionLocked) {
      pageFlip.abortFlip();
      _resetGestureState();
      return;
    }

    final point = model.Point(position.dx, position.dy);

    // If child consumed the hit and user didn't drag horizontally, let the child handle it
    if (_childConsumedHit && !_isDragging) {
      pageFlip.abortFlip();
      _resetGestureState();
      return;
    }

    // A tap (no drag) turns nothing when tap-to-flip is off.
    if (!_isDragging && !settings.flipOnTap) {
      pageFlip.abortFlip();
      _resetGestureState();
      return;
    }

    // Process page flip gesture
    if (_isDragging) {
      pageFlip.userStop(_shiftDrag(point), false, timeMs);
      ensureAnimating();
    } else {
      // Pure tap on book canvas (not on interactive child):
      final rect = getRect();
      final isLandscape = _orientation == BookOrientation.landscape;
      final spineX = isLandscape ? rect.left + rect.pageWidth : rect.left;
      final isTouchOnLeftSide = point.x < spineX;

      if (isLandscape) {
        if (isTouchOnLeftSide) {
          if (pageFlip.canFlipPrev()) {
            final corner = point.y < rect.height * 0.5
                ? FlipCorner.top
                : FlipCorner.bottom;
            pageFlip.flipPrev(corner);
            ensureAnimating();
          }
        } else {
          if (pageFlip.canFlipNext()) {
            final corner = point.y < rect.height * 0.5
                ? FlipCorner.top
                : FlipCorner.bottom;
            pageFlip.flipNext(corner);
            ensureAnimating();
          }
        }
      } else {
        final halfWidth = rect.left + rect.pageWidth * 0.5;
        if (point.x < halfWidth) {
          if (pageFlip.canFlipPrev()) {
            final corner = point.y < rect.height * 0.5
                ? FlipCorner.top
                : FlipCorner.bottom;
            pageFlip.flipPrev(corner);
            ensureAnimating();
          }
        } else {
          if (pageFlip.canFlipNext()) {
            final corner = point.y < rect.height * 0.5
                ? FlipCorner.top
                : FlipCorner.bottom;
            pageFlip.flipNext(corner);
            ensureAnimating();
          }
        }
      }
    }

    _resetGestureState();
  }

  /// Shift applied to drag points when [FlipSettings.directionFromDrag]
  /// re-anchors the curl to the page edge matching the drag direction.
  model.Point _dragShift = const model.Point(0, 0);

  /// With [FlipSettings.keepGrabOffset]: which corner is being dragged
  /// (null = no clamping) and the minimum lift of that corner off its edge.
  bool? _dragTopCorner;
  double _dragMinLift = 0;

  /// A drag that starts away from the page edge: the fold starts at the
  /// edge and closes this horizontal gap to the finger gradually, as the
  /// finger moves [_catchUpDistance], instead of jumping to the finger.
  double _catchUpGap = 0;
  double _catchUpDistance = 1;
  double _catchUpStartX = 0;

  /// How far the fold has caught up (0 to 1). It never goes back, so the
  /// fold does not drift away if the finger returns towards its start.
  double _catchUp = 1;

  model.Point _shiftDrag(model.Point p) {
    double y = p.y + _dragShift.y;
    final top = _dragTopCorner;
    if (top != null) {
      // Keep the corner slightly off its edge: a corner exactly on the
      // top/bottom edge makes the fold geometry collapse (zero-area clip).
      final rect = getRect();
      if (top) {
        y = math.max(y, rect.top + _dragMinLift);
      } else {
        y = math.min(y, rect.top + rect.height - _dragMinLift);
      }
    }
    double x = p.x + _dragShift.x;
    if (_catchUpGap != 0) {
      final t = ((p.x - _catchUpStartX).abs() / _catchUpDistance).clamp(
        0.0,
        1.0,
      );
      _catchUp = math.max(_catchUp, t);
      // Smoothstep: the fold starts by moving with the finger and speeds up
      // gently until it reaches it.
      final u = _catchUp;
      x += _catchUpGap * (1 - u * u * (3 - 2 * u));
    }
    return model.Point(x, y);
  }

  /// Starts a user drag. Local coordinates are already mirrored for RTL
  /// books (the whole book is flipped with a Transform), so a negative
  /// [deltaX] always means "towards the next page".
  void _beginUserDrag(double deltaX, double? timeMs) {
    final start = _initialTouchPoint!;
    _dragShift = const model.Point(0, 0);
    _dragTopCorner = null;
    double shiftY = 0;
    if (settings.keepGrabOffset) {
      // The flip is driven by the corner on the grabbed half of the page.
      // Offset the finger so that corner starts at its resting place and
      // then moves exactly with the finger: the grabbed spot stays under the
      // finger instead of the corner jumping to it (and then being held back
      // by the paper's reach when steered up or down).
      final rect = getRect();
      final top = start.y - rect.top < rect.height / 2;
      _dragTopCorner = top;
      _dragMinLift = math.max(4.0, rect.height * 0.02);
      final restY = top ? rect.top : rect.top + rect.height;
      shiftY = restY - start.y;
    }
    _dragShift = model.Point(0, shiftY);
    if (settings.directionFromDrag &&
        _orientation == BookOrientation.portrait &&
        deltaX != 0) {
      final rect = getRect();
      final forward = deltaX < 0;
      if (forward ? pageFlip.canFlipNext() : pageFlip.canFlipPrev()) {
        // Forward: curl from the outer (right) edge. Back: the previous page
        // enters from the inner (left) edge. The finger's movement is then
        // applied relative to that anchor, so the curl follows the drag
        // without jumping.
        final anchorX = forward
            ? rect.left + rect.width - 2
            : rect.left + rect.pageWidth + 2;
        _dragShift = model.Point(anchorX - start.x, shiftY);
      }
    } else if (_orientation == BookOrientation.portrait &&
        pageFlip.canFlipPrev() &&
        pageFlip.flipProcess.getDirectionByPoint(convertToBook(start)) ==
            FlipDirection.back) {
      // Legacy direction-by-position back turn: the previous page enters at
      // the spine. Without this anchor it jumped straight to the touch point
      // (e.g. 150px of the page appeared on touch), and that head start made
      // even a tiny drag complete the turn on release.
      final rect = getRect();
      _dragShift = model.Point(
        rect.left + rect.pageWidth + 2 - start.x,
        shiftY,
      );
    }
    _catchUpGap = 0;
    _catchUp = 1;
    if (_dragShift.x == 0) {
      // Grabbed away from the edge: start the fold at the edge rather than
      // under the finger, then let it catch up with the finger.
      final rect = getRect();
      final forward =
          pageFlip.flipProcess.getDirectionByPoint(convertToBook(start)) ==
          FlipDirection.forward;
      final edgeX = forward
          ? rect.left + rect.pageWidth * 2 - 2
          : rect.left + 2;
      final gap = edgeX - start.x;
      if (gap.abs() > 8 &&
          (forward ? pageFlip.canFlipNext() : pageFlip.canFlipPrev())) {
        _catchUpGap = gap;
        _catchUpDistance = math.max(48.0, gap.abs() * 0.7);
        _catchUpStartX = start.x;
        _catchUp = 0;
      }
    }
    pageFlip.startUserTouch(_shiftDrag(start), timeMs);
    ensureAnimating();
  }

  void _resetGestureState() {
    _dragShift = const model.Point(0, 0);
    _catchUpGap = 0;
    _catchUp = 1;
    _dragTopCorner = null;
    _isDragging = false;
    _isVerticalScrollLocked = false;
    _isInvalidDirectionLocked = false;
    _initialTouchPoint = null;
    _arenaEntry?.resolve(GestureDisposition.rejected);
    _arenaEntry = null;
    // Note: _childConsumedHit is reset in hitTestChildren for each new gesture
  }

  @override
  void detach() {
    _arenaEntry?.resolve(GestureDisposition.rejected);
    _arenaEntry = null;
    super.detach();
  }

  void ensureAnimating() => _scheduleFrame();

  bool _isWhitePageIndex(int index) {
    return _needsWhitePage && index == _pageCount;
  }

  void _drawWhitePageStatic(
    Canvas canvas,
    PageRect rect,
    Offset offset,
    bool isLeft,
  ) {
    final paint = Paint()
      ..color = settings.pageBackgroundColor
      ..style = PaintingStyle.fill;
    final pageX = (isLeft ? rect.left : rect.left + rect.pageWidth) + offset.dx;
    final pageY = rect.top + offset.dy;
    final whitePageRect = Rect.fromLTWH(
      pageX,
      pageY,
      rect.pageWidth,
      rect.height,
    );
    canvas.drawRect(whitePageRect, paint);
    final borderColor = settings.effectivePageBorderColor;
    if (borderColor != null) {
      canvas.drawRect(
        whitePageRect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }
}
