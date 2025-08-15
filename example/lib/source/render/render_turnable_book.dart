import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import '../collection/page_collection_impl.dart';
import '../enums/animation_process.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flip_direction.dart';
import '../enums/flipping_state.dart';
import '../enums/page_orientation.dart';
import '../enums/size_type.dart';
import '../flip/flip_settings.dart';
import '../model/page_rect.dart';
import '../model/point.dart' as model;
import '../model/rect_points.dart';
import '../model/shadow.dart';
import '../model/swipe_data.dart';
import '../page/book_page.dart';
import '../page/book_page_impl.dart';
import '../page/page_flip.dart';
import '../render/render_page.dart';
import '../render/turnable_parent_data.dart';

class RenderTurnableBook extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TurnableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TurnableParentData>
    implements RenderPage {
  static const int _swipeTimeout = 250;
  static const double _minMoveThreshold = 10.0;
  bool get _needsWhitePage {
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
  SwipeData? _touchPoint;
  double get _swipeDistance => settings.swipeDistance;
  
  // Auto gesture detection properties
  bool _isDragging = false;
  model.Point? _initialTouchPoint;

  RenderTurnableBook(this.settings, this.pageFlip) {
    pageFlip.render = this;
    collection = PageCollectionImpl(pageFlip, this, 0);
  }

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
    final rawMs = timestamp.inMilliseconds.toDouble();
    _updateTimestamp(rawMs);
    if (animation != null) {
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
  bool get _shouldContinueAnimating =>
      animation != null || _hasActiveVisualElements;

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
      collection.loadBookPages();
      collection.show(settings.startPageIndex);
      _initialized = true;
      pageFlip.pages = collection;
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
        pageFlip.trigger('animationComplete', pageFlip, null);
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
      startedAt: _timeMs,
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
      pageFlip.trigger('animationComplete', pageFlip, null);
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
    markNeedsPaint();
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
    markNeedsPaint();
  }

  @override
  void setLeftPage(BookPage? page) {
    if (page != null) page.setOrientation(PageOrientation.left);
    leftPage = page;
    markNeedsPaint();
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
    markNeedsPaint();
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
    markNeedsPaint();
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
    final canvas = context.canvas;
    canvas.save();
    void paintStatic(BookPage? page, bool isLeft) {
      if (page == null) return;
      final lp = page as BookPageImpl;
      final child = _childByIndex(lp.index);
      if (_isWhitePageIndex(lp.index)) {
        _drawWhitePageStatic(canvas, rect, offset, isLeft);
        return;
      }
      if (child == null) return;
      final pageOffset = Offset(
        (isLeft ? rect.left : rect.left + rect.pageWidth) + offset.dx,
        rect.top + offset.dy,
      );
      context.paintChild(child, pageOffset);
    }

    if (_orientation != BookOrientation.portrait) paintStatic(leftPage, true);
    paintStatic(rightPage, false);
    if (bottomPage is BookPageImpl) {
      _paintDynamicPage(
        context,
        canvas,
        offset,
        bottomPage as BookPageImpl,
        isBottom: true,
      );
    }
    if (settings.drawShadow) {
      _drawBookShadow(canvas, rect, offset);
    }
    if (flippingPage is BookPageImpl) {
      _paintDynamicPage(context, canvas, offset, flippingPage as BookPageImpl);
    }
    if (shadow != null && settings.drawShadow) {
      _drawOuterShadow(canvas, rect, offset);
      if (pageRect != null) {
        _drawInnerShadow(canvas, rect, offset);
      }
    }
    if (_orientation == BookOrientation.portrait) {
      canvas.clipRect(
        Rect.fromLTWH(
          rect.left + rect.pageWidth + offset.dx,
          rect.top + offset.dy,
          rect.pageWidth,
          rect.height,
        ),
      );
    }
    canvas.restore();
  }

  void _paintDynamicPage(
    PaintingContext context,
    Canvas canvas,
    Offset rootOffset,
    BookPageImpl page, {
    bool isBottom = false,
  }) {
    if (_isWhitePageIndex(page.index)) {
      _paintDynamicWhitePage(canvas, rootOffset, page);
      return;
    }
    final child = _childByIndex(page.index);
    if (child == null) return;
    final position = page.state.position;
    final globalPos = convertToGlobal(position) ?? model.Point(0, 0);
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
    context.paintChild(child, Offset.zero);
    canvas.restore();
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
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(shadowSize, 0),
      [
        const ui.Color.fromARGB(0, 0, 0, 0),
        ui.Color.fromARGB((0.2 * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((0.1 * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((0.5 * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((0.4 * 255).round(), 0, 0, 0),
        const ui.Color.fromARGB(0, 0, 0, 0),
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
    if (s.direction == FlipDirection.forward) {
      canvas.translate(0, -100);
      colors = [
        ui.Color.fromARGB((s.opacity * 255).round(), 0, 0, 0),
        const ui.Color.fromARGB(0, 0, 0, 0),
      ];
      stops = [0.0, 1.0];
    } else {
      canvas.translate(-s.width, -100);
      colors = [
        const ui.Color.fromARGB(0, 0, 0, 0),
        ui.Color.fromARGB((s.opacity * 255).round(), 0, 0, 0),
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
    if (s.direction == FlipDirection.forward) {
      canvas.translate(-isw, -100);
      colors = [
        const ui.Color.fromARGB(0, 0, 0, 0),
        ui.Color.fromARGB((s.opacity * 0.05 * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((s.opacity * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((s.opacity * 255).round(), 0, 0, 0),
      ];
      stops = [0.0, 0.7, 0.9, 1.0];
    } else {
      canvas.translate(0, -100);
      colors = [
        ui.Color.fromARGB((s.opacity * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((s.opacity * 0.05 * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((s.opacity * 255).round(), 0, 0, 0),
        const ui.Color.fromARGB(0, 0, 0, 0),
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
    
    final rect = getRect();
    
    // Test visible static pages for interactive widgets
    if (_orientation != BookOrientation.portrait && leftPage != null) {
      final leftChild = _childByIndex((leftPage as BookPageImpl).index);
      if (leftChild != null && !_isWhitePageIndex((leftPage as BookPageImpl).index)) {
        final leftOffset = Offset(rect.left, rect.top);
        final adjustedPosition = position - leftOffset;
        if (_isPositionInChildBounds(adjustedPosition, rect.pageWidth, rect.height) &&
            leftChild.hitTest(result, position: adjustedPosition)) {
          _childConsumedHit = true;
          return true;
        }
      }
    }
    
    if (rightPage != null) {
      final rightChild = _childByIndex((rightPage as BookPageImpl).index);
      if (rightChild != null && !_isWhitePageIndex((rightPage as BookPageImpl).index)) {
        final rightOffset = Offset(rect.left + rect.pageWidth, rect.top);
        final adjustedPosition = position - rightOffset;
        if (_isPositionInChildBounds(adjustedPosition, rect.pageWidth, rect.height) &&
            rightChild.hitTest(result, position: adjustedPosition)) {
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

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (settings.clickEventForward) return;
    
    if (event is PointerDownEvent) {
      _handlePointerDown(event.localPosition);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handlePointerUp(event.localPosition);
    }
  }

  void _handlePointerDown(Offset position) {
    final point = model.Point(position.dx, position.dy);
    
    // Reset only dragging state, keep _childConsumedHit as set by hitTestChildren
    _isDragging = false;
    _initialTouchPoint = point;
    
    _touchPoint = SwipeData(
      point: point,
      time: DateTime.now().millisecondsSinceEpoch,
    );
    
    // If a child widget consumed the hit and this is just a tap, don't start page flip immediately
    // We'll check again during movement or up event
    if (!_childConsumedHit) {
      // Start page flip interaction for dragging
      pageFlip.startUserTouch(point);
      ensureAnimating();
    }
  }

  void _handlePointerMove(Offset position) {
    final point = model.Point(position.dx, position.dy);
    
    if (_initialTouchPoint != null) {
      final deltaX = (point.x - _initialTouchPoint!.x).abs();
      final deltaY = (point.y - _initialTouchPoint!.y).abs();
      
      // Check if user is dragging (moved more than threshold)
      if (deltaX > _minMoveThreshold || deltaY > _minMoveThreshold) {
        if (!_isDragging) {
          _isDragging = true;
          
          // If we didn't start pageFlip before because of child hit, start it now for dragging
          if (_childConsumedHit) {
            pageFlip.startUserTouch(_initialTouchPoint!);
          }
        }
        
        // Ensure animation continues during dragging
        ensureAnimating();
      }
    }
    
    // Process move if we're dragging or no child consumed the initial hit
    if (_isDragging || !_childConsumedHit) {
      if (settings.mobileScrollSupport && _touchPoint != null) {
        final deltaX = (_touchPoint!.point.x - point.x).abs();
        if (deltaX > _minMoveThreshold ||
            pageFlip.getState() != FlippingState.read) {
          pageFlip.userMove(point, true);
        }
      } else {
        pageFlip.userMove(point, true);
      }
      
      // Mark for repaint during interaction
      markNeedsPaint();
    }
  }

  void _handlePointerUp(Offset position) {
    final point = model.Point(position.dx, position.dy);
    
    // If child consumed the hit and user didn't drag, let the child handle it
    if (_childConsumedHit && !_isDragging) {
      _resetGestureState();
      return;
    }
    
    // Process page flip gesture
    if (_touchPoint != null && _isValidSwipe(point)) {
      _processSwipeGesture(point);
      _touchPoint = null;
    } else {
      _touchPoint = null;
      // Only trigger flip on tap if user didn't interact with a child widget
      if (!_childConsumedHit || _isDragging) {
        pageFlip.userStop(point, false);
        // Ensure animation continues for completion
        ensureAnimating();
      }
    }
    
    _resetGestureState();
  }

  void _resetGestureState() {
    _isDragging = false;
    _initialTouchPoint = null;
    // Note: _childConsumedHit is reset in hitTestChildren for each new gesture
  }

  bool _isValidSwipe(model.Point point) {
    if (_touchPoint == null) return false;
    final dx = point.x - _touchPoint!.point.x;
    final distY = (point.y - _touchPoint!.point.y).abs();
    final timeDelta = DateTime.now().millisecondsSinceEpoch - _touchPoint!.time;
    return dx.abs() > _swipeDistance &&
        distY < _swipeDistance * 2 &&
        timeDelta < _swipeTimeout;
  }

  void _processSwipeGesture(model.Point point) {
    final dx = point.x - _touchPoint!.point.x;
    final rect = getRect();
    final halfHeight = rect.height * 0.5;
    final corner = _touchPoint!.point.y < halfHeight
        ? FlipCorner.top
        : FlipCorner.bottom;
    if (dx > 0) {
      pageFlip.flipPrev(corner);
    } else {
      pageFlip.flipNext(corner);
    }
    // Ensure animation continues for swipe gesture
    ensureAnimating();
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
