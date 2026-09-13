import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import '../collection/page_collection_impl.dart';
import '../enums/animation_process.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flip_direction.dart';
import '../enums/page_flip_event.dart';
import '../enums/page_orientation.dart';
import '../enums/size_type.dart';
import '../flip/flip_settings.dart';
import '../model/page_rect.dart';
import '../model/point.dart' as model;
import '../model/rect_points.dart';
import '../model/shadow.dart';
import '../page/book_page.dart';
import '../page/book_page_impl.dart';
import '../page/page_flip.dart';
import '../render/render_page.dart';
import '../render/turnable_parent_data.dart';

class RenderTurnableBook extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TurnableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TurnableParentData>
    implements RenderPage, GestureArenaMember {
  static const double _minMoveThreshold = 10.0;
  bool get _needsWhitePage {
    if (settings.usePortrait) return false;
    return settings.showCover ? false : childCount % 2 == 1;
  }

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
    calculateBoundsRect();
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
      final totalPages = _needsWhitePage ? childCount + 1 : childCount;
      collection = PageCollectionImpl(pageFlip, this, totalPages);
      pageFlip.pages = collection;
      collection.loadBookPages();
      collection.show(settings.startPageIndex);
      _initialized = true;
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
    final count = childCount;
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
  }

  RenderBox? _childByIndex(int index) {
    if (_needsWhitePage && index == childCount) {
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
      double elapsed = _timeMs - animation!.startedAt;
      if (elapsed < 0) elapsed = 0;
      final frameIndex = (elapsed / animation!.durationFrame).floor();
      if (frameIndex < animation!.frames.length) {
        animation!.frames[frameIndex]();
      } else {
        animation!.onAnimateEnd();
        pageFlip.trigger(PageFlipEvent.animationComplete, pageFlip, null);
        animation = null;
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
      startedAt: _timeMs > 0 ? -1 : 0,
    );
    _scheduleFrame();
  }

  @override
  void finishAnimation() {
    if (animation != null) {
      if (animation!.frames.isNotEmpty) {
        animation!.frames.last();
      }
      animation!.onAnimateEnd();
      pageFlip.trigger(PageFlipEvent.animationComplete, pageFlip, null);
      animation = null;
    }
  }

  @override
  BookOrientation calculateBoundsRect() {
    BookOrientation orientation = BookOrientation.landscape;
    final blockWidth = size.width;
    final middlePoint = model.Point(blockWidth / 2, size.height / 2);
    final ratio = settings.width / settings.height;
    double pageWidth = settings.width;
    double pageHeight = settings.height;
    double left = middlePoint.x - pageWidth;
    if (settings.size == SizeType.stretch) {
      if (blockWidth < settings.width * 2 && settings.usePortrait) {
        orientation = BookOrientation.portrait;
      }
      pageWidth = orientation == BookOrientation.portrait
          ? blockWidth
          : blockWidth / 2;
      if (pageWidth > settings.width) pageWidth = settings.width;
      pageHeight = pageWidth / ratio;
      if (pageHeight > size.height) {
        pageHeight = size.height;
        pageWidth = pageHeight * ratio;
      }
      left = orientation == BookOrientation.portrait
          ? middlePoint.x - pageWidth / 2 - pageWidth
          : middlePoint.x - pageWidth;
    } else {
      if (blockWidth < pageWidth * 2) {
        if (settings.usePortrait) {
          orientation = BookOrientation.portrait;
          left = middlePoint.x - pageWidth / 2 - pageWidth;
        }
      }
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

  @override
  void paint(PaintingContext context, Offset offset) {
    final rect = getRect();

    // Background fill — safe: pure canvas draw with no compositing children around it.
    context.canvas.drawRect(
      Rect.fromLTWH(
        rect.left + offset.dx,
        rect.top + offset.dy,
        rect.width,
        rect.height,
      ),
      Paint()..color = const ui.Color(0xFFFFFFFF),
    );

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

    if (_orientation != BookOrientation.portrait) {
      paintStatic(leftPage, true);
      // In two-page mode, do not double-paint rightPage if it is already being flipped
      if (flippingPage is! BookPageImpl ||
          (flippingPage as BookPageImpl).index !=
              (rightPage as BookPageImpl?)?.index) {
        paintStatic(rightPage, false);
      }
    } else {
      // In portrait mode, flippingPage and bottomPage partition the entire page area.
      // Painting rightPage statically while it is also flippingPage causes Flutter's compositor
      // to steal and ping-pong compositing layers between two locations every frame.
      if (flippingPage == null && bottomPage == null) {
        paintStatic(rightPage, false);
      }
    }

    if (bottomPage is BookPageImpl) {
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

    if (flippingPage is BookPageImpl) {
      _paintDynamicPage(context, offset, flippingPage as BookPageImpl);
    }

    if (shadow != null && settings.drawShadow) {
      _drawOuterShadow(context.canvas, rect, offset);
      if (pageRect != null) {
        _drawInnerShadow(context.canvas, rect, offset);
      }
    }
  }

  void _paintDynamicPage(
    PaintingContext context,
    Offset rootOffset,
    BookPageImpl page, {
    bool isBottom = false,
  }) {
    if (_isWhitePageIndex(page.index)) {
      _paintDynamicWhitePage(context.canvas, rootOffset, page);
      return;
    }
    final child = _childByIndex(page.index);
    if (child == null) return;

    final position = page.state.position;
    final globalPos = convertToGlobal(position) ?? model.Point(0, 0);
    final rect = getRect();
    final angle = page.state.angle;

    // The clip path is built relative to globalOrigin (page-anchor-local).
    // See BookPageImpl.buildOrGetClipPath: path(0,0) = top-left of page at globalPos.
    final origin = convertToGlobal(position);
    final clipPath = page.buildOrGetClipPath(
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
      pageAnchor.dx, pageAnchor.dy, 0.0,
    )..rotateZ(angle);

    // Inner painter: background fill (prevents transparent-widget flicker) + child.
    // `off` = Offset.zero throughout; after childTransform the child lands at
    // pageAnchor on screen, rotated by `angle`.
    void paintPageChild(PaintingContext ctx, Offset off) {
      ctx.canvas.drawRect(
        Rect.fromLTWH(off.dx, off.dy, rect.pageWidth, rect.height),
        Paint()
          ..color = const Color(0xFFFFFFFF)
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
        Offset.zero & size,          // ← full render-box area, NOT clip bounds
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
    } else if (!isBottom) {
      // No clip: just translate + rotate then paint (flipping page only).
      context.pushTransform(
        needsCompositing,
        Offset.zero,
        childTransform,
        paintPageChild,
      );
    }
  }

  void _paintDynamicWhitePage(
    Canvas canvas,
    Offset rootOffset,
    BookPageImpl page,
  ) {
    final position = page.state.position;
    final globalPos = convertToGlobal(position) ?? model.Point(0, 0);
    final rect = getRect();
    canvas.save();
    canvas.translate(globalPos.x + rootOffset.dx, globalPos.y + rootOffset.dy);
    final origin = convertToGlobal(position);
    final path = page.buildOrGetClipPath(
      origin,
      (model.Point p) => convertToGlobal(p)!,
    );
    if (path != null) canvas.clipPath(path);
    final angle = page.state.angle;
    if (angle.abs() > 0.001) {
      canvas.rotate(angle);
    }
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, rect.pageWidth, rect.height), paint);
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, rect.pageWidth, rect.height),
      borderPaint,
    );
    canvas.restore();
  }

  void _drawBookShadow(Canvas canvas, PageRect rect, Offset root) {
    if (!settings.drawShadow) return;
    if (_orientation != BookOrientation.portrait && !settings.showCenterShadow) {
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
    final baseColor = settings.centerShadowColor;
    final baseAlpha = (baseColor.a * settings.maxShadowOpacity).clamp(0.0, 1.0);

    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(shadowSize, 0),
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
    final paint = Paint()..shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, shadowSize, rect.height * 2), paint);
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
    final targetAlpha = (s.opacity * outerColor.a * settings.maxShadowOpacity)
        .clamp(0.0, 1.0);

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
    final baseAlpha = (s.opacity * innerColor.a * settings.maxShadowOpacity)
        .clamp(0.0, 1.0);

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
    canvas.restore();
  }

  bool _childConsumedHit = false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Reset child consumed hit state for each new hit test
    _childConsumedHit = false;

    // Touches on turnable page corners are reserved for book page flipping.
    // Do not route them to child scroll views or child buttons on the corner.
    final point = model.Point(position.dx, position.dy);
    if (pageFlip.isPointOnCorners(point)) {
      return false;
    }

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
      _arenaEntry = GestureBinding.instance.gestureArena.add(event.pointer, this);
      _handlePointerDown(getPointerOffset(event: event), timeMs);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(getPointerOffset(event: event), timeMs);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handlePointerUp(getPointerOffset(event: event), timeMs);
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
    if (isLandscape && absDeltaX > 5.0) {
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
    if (!isLandscape && absDeltaX > 5.0) {
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
            pageFlip.startUserTouch(_initialTouchPoint!, timeMs);
            ensureAnimating();
          } else {
            return;
          }
        }
      } else {
        if (absDeltaX > _minMoveThreshold || deltaY > _minMoveThreshold) {
          // Priority 1: Vertical movement intent -> lock to child scroll view completely
          if (!settings.onlyVerticalPageFlip && deltaY > absDeltaX) {
            _isVerticalScrollLocked = true;
            _arenaEntry?.resolve(GestureDisposition.rejected);
            _arenaEntry = null;
            if (_isDragging) {
              _isDragging = false;
              pageFlip.abortFlip();
            }
            return;
          }

          // Priority 2: Clear horizontal page flip intent
          if (!_isDragging) {
            if (absDeltaX > deltaY * settings.swipeAngleThreshold) {
              _isDragging = true;
              _arenaEntry?.resolve(GestureDisposition.accepted);
              pageFlip.startUserTouch(_initialTouchPoint!, timeMs);
              ensureAnimating();
            } else {
              return; // Ambiguous or vertical motion, yield to child
            }
          }
        }

        if (!_isDragging) return;
      }
    } else {
      // Normal drag (no interactive child consumed hit):
      if (!_isDragging) {
        if (absDeltaX > _minMoveThreshold || deltaY > _minMoveThreshold) {
          if (!settings.onlyVerticalPageFlip && !isOnCorner && deltaY > absDeltaX) {
            _isVerticalScrollLocked = true;
            _arenaEntry?.resolve(GestureDisposition.rejected);
            _arenaEntry = null;
            return;
          }
          if (absDeltaX >= _minMoveThreshold || (isOnCorner && deltaY >= _minMoveThreshold)) {
            _isDragging = true;
            _arenaEntry?.resolve(GestureDisposition.accepted);
            pageFlip.startUserTouch(_initialTouchPoint!, timeMs);
            ensureAnimating();
          } else {
            return;
          }
        } else {
          return;
        }
      }
    }

    // Now actively dragging in a valid direction:
    pageFlip.userMove(point, true, timeMs);
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

    // Process page flip gesture
    if (_isDragging) {
      pageFlip.userStop(point, false, timeMs);
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
            final corner = point.y < rect.height * 0.5 ? FlipCorner.top : FlipCorner.bottom;
            pageFlip.flipPrev(corner);
            ensureAnimating();
          }
        } else {
          if (pageFlip.canFlipNext()) {
            final corner = point.y < rect.height * 0.5 ? FlipCorner.top : FlipCorner.bottom;
            pageFlip.flipNext(corner);
            ensureAnimating();
          }
        }
      } else {
        final halfWidth = rect.left + rect.pageWidth * 0.5;
        if (point.x < halfWidth) {
          if (pageFlip.canFlipPrev()) {
            final corner = point.y < rect.height * 0.5 ? FlipCorner.top : FlipCorner.bottom;
            pageFlip.flipPrev(corner);
            ensureAnimating();
          }
        } else {
          if (pageFlip.canFlipNext()) {
            final corner = point.y < rect.height * 0.5 ? FlipCorner.top : FlipCorner.bottom;
            pageFlip.flipNext(corner);
            ensureAnimating();
          }
        }
      }
    }

    _resetGestureState();
  }

  void _resetGestureState() {
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
    return _needsWhitePage && index == childCount;
  }

  void _drawWhitePageStatic(
    Canvas canvas,
    PageRect rect,
    Offset offset,
    bool isLeft,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
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
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(whitePageRect, borderPaint);
  }
}
