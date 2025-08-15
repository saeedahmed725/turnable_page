import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../collection/page_collection_live.dart';
import '../enums/animation_process.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_direction.dart';
import '../enums/page_orientation.dart';
import '../enums/size_type.dart';
import '../enums/flipping_state.dart';
import '../enums/flip_corner.dart';
import '../flip/flip_settings.dart';
import '../model/page_rect.dart';
import '../model/point.dart' as model;
import '../model/rect_points.dart';
import '../model/shadow.dart';
import '../model/swipe_data.dart';
import '../page/book_page.dart';
import '../page/live_book_page.dart';
import '../page/page_flip.dart';
import '../render/render_page.dart';
import '../render/turnable_parent_data.dart';

class RenderTurnableBook extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TurnableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TurnableParentData>
    implements RenderPage {
  // === Constants ===
  static const int _swipeTimeout = 250;
  static const double _minMoveThreshold = 10.0;

  // === Core Configuration ===
  FlipSettings settings;
  final PageFlip pageFlip;
  late PageCollectionLive collection;
  bool _initialized = false;

  // === Layout & Positioning ===
  BookOrientation? _orientation;
  PageRect? _boundsRect;
  FlipDirection? direction;
  RectPoints? pageRect;

  // === Page Management ===
  BookPage? leftPage;
  BookPage? rightPage;
  BookPage? flippingPage;
  BookPage? bottomPage;

  // === Animation System ===
  AnimationProcess? animation;
  Shadow? shadow;
  bool _frameScheduled = false;
  double _timeMs = 0;
  double? _lastRawTickerMs;

  // === Child Management (Performance Optimized) ===
  List<RenderBox?> _indexedChildren = <RenderBox?>[];
  bool _needsIndexRebuild = true;

  // === Gesture Handling ===
  SwipeData? _touchPoint;

  // === Computed Properties ===
  double get _swipeDistance => settings.swipeDistance;

  RenderTurnableBook(this.settings, this.pageFlip) {
    pageFlip.render = this;
    collection = PageCollectionLive(pageFlip, this, 0);
  }

  void updateSettings(FlipSettings s) {
    settings = s;
    markNeedsLayout();
  }

  /// Optimized frame scheduling - only schedule when needed
  void _scheduleFrame() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  /// Consolidated frame callback for better performance
  void _onFrame(Duration timestamp) {
    _frameScheduled = false;
    final rawMs = timestamp.inMilliseconds.toDouble();

    // Handle time progression
    _updateTimestamp(rawMs);

    // Process animation if active
    if (animation != null) {
      render(_timeMs);
    } else if (_hasActiveVisualElements) {
      markNeedsPaint();
    }

    // Continue frame scheduling if needed
    if (_shouldContinueAnimating) {
      _scheduleFrame();
    }
  }

  /// Performance: Check if we have active visual elements
  bool get _hasActiveVisualElements =>
      flippingPage != null || shadow != null || bottomPage != null;

  /// Performance: Check if we should continue animating
  bool get _shouldContinueAnimating =>
      animation != null || _hasActiveVisualElements;

  /// Optimized timestamp handling
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
      collection = PageCollectionLive(pageFlip, this, childCount);
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

  /// Optimized child index assignment with batch processing
  void _assignPageIndices() {
    _needsIndexRebuild = false;
    final count = childCount;

    // Resize array only if necessary (performance optimization)
    if (_indexedChildren.length != count) {
      _indexedChildren = List<RenderBox?>.filled(count, null, growable: false);
    }

    // Batch process all children
    int index = 0;
    RenderBox? child = firstChild;
    while (child != null && index < count) {
      final pd = child.parentData as TurnableParentData;
      pd.pageIndex = index;
      _indexedChildren[index] = child;
      index++;
      child = pd.nextSibling;
    }
  }

  /// High-performance child lookup with fallback
  RenderBox? _childByIndex(int index) {
    // Fast path: use indexed array
    if (!_needsIndexRebuild && index >= 0 && index < _indexedChildren.length) {
      final child = _indexedChildren[index];
      if (child != null) return child;
    }

    // Rebuild index if needed
    if (_needsIndexRebuild) {
      _assignPageIndices();
      if (index >= 0 && index < _indexedChildren.length) {
        return _indexedChildren[index];
      }
    }

    // Fallback: linear search (should be rare)
    return _findChildByIndexLinear(index);
  }

  /// Fallback linear search for edge cases
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
        // Execute the frame action (closure)
        animation!.frames[frameIndex]();
      } else {
        // Animation completed - call the completion callback
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
    
    // Use the exact same shadow width calculation as the original canvas_render.dart
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

    // Performance: Single save/restore for entire paint operation
    canvas.save();

    // Paint static pages with inline helper for better performance
    void paintStatic(BookPage? page, bool isLeft) {
      if (page == null) return;
      final lp = page as LiveBookPage;
      final child = _childByIndex(lp.index);
      if (child == null) return;

      final pageOffset = Offset(
        (isLeft ? rect.left : rect.left + rect.pageWidth) + offset.dx,
        rect.top + offset.dy,
      );
      context.paintChild(child, pageOffset);
    }

    // Paint in optimal order for performance
    if (_orientation != BookOrientation.portrait) paintStatic(leftPage, true);
    paintStatic(rightPage, false);

    // Paint dynamic content only if needed
    if (bottomPage is LiveBookPage) {
      _paintDynamicPage(
        context,
        canvas,
        offset,
        bottomPage as LiveBookPage,
        isBottom: true,
      );
    }

    // Draw shadows only if enabled
    if (settings.drawShadow) {
      _drawBookShadow(canvas, rect, offset);
    }

    if (flippingPage is LiveBookPage) {
      _paintDynamicPage(context, canvas, offset, flippingPage as LiveBookPage);
    }

    // Performance: Only draw shadows if they exist and are enabled
    if (shadow != null && settings.drawShadow) {
      _drawOuterShadow(canvas, rect, offset);
      if (pageRect != null) {
        _drawInnerShadow(canvas, rect, offset);
      }
    }

    // Apply clipping only for portrait mode
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

  /// Optimized dynamic page painting with reduced object allocations
  void _paintDynamicPage(
    PaintingContext context,
    Canvas canvas,
    Offset rootOffset,
    LiveBookPage page, {
    bool isBottom = false,
  }) {
    final child = _childByIndex(page.index);
    if (child == null) return;

    // Performance: Get position once and reuse
    final position = page.state.position;
    final globalPos = convertToGlobal(position) ?? model.Point(0, 0);

    canvas.save();
    canvas.translate(globalPos.x + rootOffset.dx, globalPos.y + rootOffset.dy);

    // Performance: Only build clip path if needed
    final origin = convertToGlobal(position);
    final path = page.buildOrGetClipPath(
      origin,
      (model.Point p) => convertToGlobal(p)!,
    );
    if (path != null) canvas.clipPath(path);

    // Performance: Only apply rotation if significant
    final angle = page.state.angle;
    if (angle.abs() > 0.001) {
      canvas.rotate(angle);
    }

    context.paintChild(child, Offset.zero);
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
    
    // Use exact same clipping as original - but account for paint context
    canvas.clipRect(
      Rect.fromLTWH(rect.left + root.dx, rect.top + root.dy, rect.width, rect.height),
    );
    
    // Apply root offset to shadow position to account for paint context
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
    
    // Build path and account for paint context offset
    final path = Path()
      ..moveTo(pr.topLeft.x + root.dx, pr.topLeft.y + root.dy)
      ..lineTo(pr.topRight.x + root.dx, pr.topRight.y + root.dy)
      ..lineTo(pr.bottomRight.x + root.dx, pr.bottomRight.y + root.dy)
      ..lineTo(pr.bottomLeft.x + root.dx, pr.bottomLeft.y + root.dy)
      ..close();
    canvas.clipPath(path);
    
    // Apply root offset to shadow position to account for paint context
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

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final pd = child.parentData as TurnableParentData;
      if (child.hitTest(result, position: position - pd.offset)) return true;
      child = pd.previousSibling;
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (settings.clickEventForward) return;

    if (event is PointerDownEvent) {
      _handlePanStart(event.localPosition);
    } else if (event is PointerMoveEvent) {
      _handlePanUpdate(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handlePanEnd(event.localPosition);
    }
  }

  /// Handle pan start with touch point tracking
  void _handlePanStart(Offset position) {
    final point = model.Point(position.dx, position.dy);

    _touchPoint = SwipeData(
      point: point,
      time: DateTime.now().millisecondsSinceEpoch,
    );

    pageFlip.startUserTouch(point);
    ensureAnimating();
  }

  /// Handle pan update with mobile scroll support and performance optimization
  void _handlePanUpdate(Offset position) {
    final point = model.Point(position.dx, position.dy);

    if (settings.mobileScrollSupport && _touchPoint != null) {
      // Performance: Calculate distance only once
      final deltaX = (_touchPoint!.point.x - point.x).abs();

      if (deltaX > _minMoveThreshold ||
          pageFlip.getState() != FlippingState.read) {
        pageFlip.userMove(point, true);
      }
    } else {
      pageFlip.userMove(point, true);
    }
  }

  /// Handle pan end with optimized swipe detection
  void _handlePanEnd(Offset position) {
    final point = model.Point(position.dx, position.dy);

    if (_touchPoint != null && _isValidSwipe(point)) {
      _processSwipeGesture(point);
      _touchPoint = null;
    } else {
      // Regular drag completion with threshold-based animation
      _touchPoint = null;
      pageFlip.userStop(point, false);
    }
  }

  /// Performance: Extracted swipe validation logic
  bool _isValidSwipe(model.Point point) {
    if (_touchPoint == null) return false;

    final dx = point.x - _touchPoint!.point.x;
    final distY = (point.y - _touchPoint!.point.y).abs();
    final timeDelta = DateTime.now().millisecondsSinceEpoch - _touchPoint!.time;

    return dx.abs() > _swipeDistance &&
        distY < _swipeDistance * 2 &&
        timeDelta < _swipeTimeout;
  }

  /// Performance: Extracted swipe processing logic
  void _processSwipeGesture(model.Point point) {
    final dx = point.x - _touchPoint!.point.x;
    final rect = getRect();
    final halfHeight =
        rect.height * 0.5; // Use multiplication instead of division
    final corner = _touchPoint!.point.y < halfHeight
        ? FlipCorner.top
        : FlipCorner.bottom;

    if (dx > 0) {
      pageFlip.flipPrev(corner);
    } else {
      pageFlip.flipNext(corner);
    }
  }

  void ensureAnimating() => _scheduleFrame();
}
