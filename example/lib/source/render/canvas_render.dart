import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:turnable_page/src/page/page_flip.dart';

import '../enums/animation_process.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_direction.dart';
import '../enums/page_orientation.dart';
import '../enums/size_type.dart';
import '../flip/flip_settings.dart';
import '../model/page_rect.dart';
import '../model/point.dart';
import '../model/rect_points.dart';
import '../model/shadow.dart';
import '../page/book_page.dart';
import 'render.dart';

/// Class responsible for rendering the Canvas book
class CanvasRender extends Render {
  Canvas? _canvas;
  Size? _size;
  late PageFlip app; // PageFlip - will be defined later

  /// Left static book page
  BookPage? leftPage;

  /// Right static book page
  BookPage? rightPage;

  /// Page currently flipping
  BookPage? flippingPage;

  /// Next page at the time of flipping
  BookPage? bottomPage;

  /// Current flipping direction
  FlipDirection? direction;

  /// Current book orientation
  BookOrientation? orientation;

  /// Current state of the shadows
  Shadow? shadow;

  /// Current animation process
  AnimationProcess? animation;

  /// Page borders while flipping
  RectPoints? pageRect;

  /// Current book area
  PageRect? boundsRect;

  /// Timer started from start of rendering
  double timer = 0;

  CanvasRender(this.app);

  @override
  Canvas getCanvas() {
    return _canvas!;
  }

  @override
  void updateApp(PageFlip app) {
    this.app = app;
  }

  @override
  void setCanvas(Canvas canvas, Size size) {
    orientation = app.getSettings.usePortrait
        ? BookOrientation.portrait
        : BookOrientation.landscape;
    _canvas = canvas;
    _size = size;
  }

  @override
  void drawFrame() {
    if (_canvas == null || _size == null) return;

    if (orientation != BookOrientation.portrait) {
      if (leftPage != null) {
        leftPage!.simpleDraw(PageOrientation.left);
      }
    }

    if (rightPage != null) {
      rightPage!.simpleDraw(PageOrientation.right);
    }

    if (bottomPage != null) {
      bottomPage!.draw();
    }

    drawBookShadow();

    if (flippingPage != null) {
      flippingPage!.draw();
    }

    if (shadow != null) {
      drawOuterShadow();
      drawInnerShadow();
    }

    final rect = getRect();
    if (orientation == BookOrientation.portrait) {
      _canvas!.clipRect(
        Rect.fromLTWH(
          rect.left + rect.pageWidth,
          rect.top,
          rect.width,
          rect.height,
        ),
      );
    }
  }

  @override
  void render(double timer) {
    if (animation != null) {
      final frameIndex =
          ((timer - animation!.startedAt) / animation!.durationFrame).round();

      if (frameIndex < animation!.frames.length) {
        animation!.frames[frameIndex]();
      } else {
        animation!.onAnimateEnd();
        app.trigger('animationComplete', app, null);
        animation = null;
      }
    }

    this.timer = timer;
    drawFrame();
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
      durationFrame: duration / frames.length,
      onAnimateEnd: onAnimateEnd,
      startedAt: timer,
    );
  }

  @override
  void finishAnimation() {
    if (animation != null) {
      animation!.frames[animation!.frames.length - 1]();
      animation!.onAnimateEnd();
      app.trigger('animationComplete', app, null);
    }

    animation = null;
  }

  @override
  BookOrientation calculateBoundsRect() {
    BookOrientation orientation = BookOrientation.landscape;

    final blockWidth = getBlockWidth();
    final middlePoint = Point(blockWidth / 2, getBlockHeight() / 2);

    final ratio = app.getSettings.width / app.getSettings.height;

    double pageWidth = app.getSettings.width;
    double pageHeight = app.getSettings.height;

    double left = middlePoint.x - pageWidth;

    if (app.getSettings.size == SizeType.stretch) {
      if (blockWidth < app.getSettings.width * 2 &&
          app.getSettings.usePortrait) {
        orientation = BookOrientation.portrait;
      }

      pageWidth = orientation == BookOrientation.portrait
          ? getBlockWidth()
          : getBlockWidth() / 2;

      if (pageWidth > app.getSettings.width) {
        pageWidth = app.getSettings.width;
      }

      pageHeight = pageWidth / ratio;
      if (pageHeight > getBlockHeight()) {
        pageHeight = getBlockHeight();
        pageWidth = pageHeight * ratio;
      }

      left = orientation == BookOrientation.portrait
          ? middlePoint.x - pageWidth / 2 - pageWidth
          : middlePoint.x - pageWidth;
    } else {
      if (blockWidth < pageWidth * 2) {
        if (app.getSettings.usePortrait) {
          orientation = BookOrientation.portrait;
          left = middlePoint.x - pageWidth / 2 - pageWidth;
        }
      }
    }

    boundsRect = PageRect(
      left: left,
      top: middlePoint.y - pageHeight / 2,
      width: pageWidth * 2,
      height: pageHeight,
      pageWidth: pageWidth,
    );

    return orientation;
  }

  @override
  void setShadowData(
    Point pos,
    double angle,
    double progress,
    FlipDirection direction,
  ) {
    if (!app.getSettings.drawShadow) return;

    final maxShadowOpacity = 100 * getSettings().maxShadowOpacity;

    shadow = Shadow(
      pos: pos,
      angle: angle,
      width: (((getRect().pageWidth * 3) / 4) * progress) / 100,
      opacity: ((100 - progress) * maxShadowOpacity) / 100 / 100,
      direction: direction,
      progress: progress * 2,
    );
  }

  @override
  void clearShadow() {
    shadow = null;
  }

  @override
  double getBlockWidth() {
    return _size?.width ?? (app.getSettings.width * 2);
  }

  @override
  double getBlockHeight() {
    return _size?.height ?? app.getSettings.height;
  }

  @override
  FlipDirection? getDirection() {
    return direction;
  }

  @override
  PageRect getRect() {
    calculateBoundsRect();
    return boundsRect!;
  }

  @override
  FlipSettings getSettings() {
    return app.getSettings;
  }

  @override
  BookOrientation? getOrientation() {
    return orientation;
  }

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
  }

  @override
  void setLeftPage(BookPage? page) {
    if (page != null) page.setOrientation(PageOrientation.left);
    leftPage = page;
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
  }

  @override
  void setFlippingPage(BookPage? page) {
    if (page != null) {
      page.setOrientation(
        direction == FlipDirection.forward &&
                orientation != BookOrientation.portrait
            ? PageOrientation.left
            : PageOrientation.right,
      );
    }
    flippingPage = page;
  }

  @override
  Point convertToBook(Point pos) {
    final rect = getRect();
    return Point(pos.x - rect.left, pos.y - rect.top);
  }

  @override
  Point convertToPage(Point pos, [FlipDirection? direction]) {
    direction ??= this.direction;

    final rect = getRect();
    final x = direction == FlipDirection.forward
        ? pos.x - rect.left - rect.width / 2
        : rect.width / 2 - pos.x + rect.left;

    return Point(x, pos.y - rect.top);
  }

  @override
  Point? convertToGlobal(Point? pos, [FlipDirection? direction]) {
    direction ??= this.direction;

    if (pos == null) return null;

    final rect = getRect();

    final x = direction == FlipDirection.forward
        ? pos.x + rect.left + rect.width / 2
        : rect.width / 2 - pos.x + rect.left;

    return Point(x, pos.y + rect.top);
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
  void drawBookShadow() {
    if (_canvas == null || _size == null || !app.getSettings.drawShadow) return;

    final rect = getRect();
    final paint = Paint();

    _canvas!.save();

    final shadowSize = rect.width / 20;
    _canvas!.clipRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
    );

    final shadowPos = Point(rect.left + rect.width / 2 - shadowSize / 2, 0);
    _canvas!.translate(shadowPos.x, shadowPos.y);

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

    paint.shader = gradient;
    _canvas!.drawRect(Rect.fromLTWH(0, 0, shadowSize, rect.height * 2), paint);

    _canvas!.restore();
  }

  @override
  void drawOuterShadow() {
    if (_canvas == null || shadow == null || !app.getSettings.drawShadow) {
      return;
    }

    final rect = getRect();
    _canvas!.save();

    _canvas!.clipRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
    );

    final shadowPos = convertToGlobal(shadow!.pos);
    if (shadowPos == null) {
      _canvas!.restore();
      return;
    }

    _canvas!.translate(shadowPos.x, shadowPos.y);
    _canvas!.rotate(math.pi + shadow!.angle + math.pi / 2);

    final paint = Paint();
    final List<Color> colors;
    final List<double> stops;

    if (shadow!.direction == FlipDirection.forward) {
      _canvas!.translate(0, -100);
      colors = [
        ui.Color.fromARGB((shadow!.opacity * 255).round(), 0, 0, 0),
        const ui.Color.fromARGB(0, 0, 0, 0),
      ];
      stops = [0.0, 1.0];
    } else {
      _canvas!.translate(-shadow!.width, -100);
      colors = [
        const ui.Color.fromARGB(0, 0, 0, 0),
        ui.Color.fromARGB((shadow!.opacity * 255).round(), 0, 0, 0),
      ];
      stops = [0.0, 1.0];
    }

    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(shadow!.width, 0),
      colors,
      stops,
    );

    paint.shader = gradient;
    _canvas!.drawRect(
      Rect.fromLTWH(0, 0, shadow!.width, rect.height * 2),
      paint,
    );

    _canvas!.restore();
  }

  @override
  void drawInnerShadow() {
    if (_canvas == null ||
        shadow == null ||
        pageRect == null ||
        !app.getSettings.drawShadow) {
      return;
    }

    final rect = getRect();
    _canvas!.save();

    final shadowPos = convertToGlobal(shadow!.pos);
    if (shadowPos == null) {
      _canvas!.restore();
      return;
    }

    final pageRectGlobal = convertRectToGlobal(pageRect!);

    final path = Path();
    path.moveTo(pageRectGlobal.topLeft.x, pageRectGlobal.topLeft.y);
    path.lineTo(pageRectGlobal.topRight.x, pageRectGlobal.topRight.y);
    path.lineTo(pageRectGlobal.bottomRight.x, pageRectGlobal.bottomRight.y);
    path.lineTo(pageRectGlobal.bottomLeft.x, pageRectGlobal.bottomLeft.y);
    path.close();

    _canvas!.clipPath(path);

    _canvas!.translate(shadowPos.x, shadowPos.y);
    _canvas!.rotate(math.pi + shadow!.angle + math.pi / 2);

    final isw = (shadow!.width * 3) / 4;
    final paint = Paint();
    final List<Color> colors;
    final List<double> stops;

    if (shadow!.direction == FlipDirection.forward) {
      _canvas!.translate(-isw, -100);
      colors = [
        const ui.Color.fromARGB(0, 0, 0, 0),
        ui.Color.fromARGB((shadow!.opacity * 0.05 * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((shadow!.opacity * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((shadow!.opacity * 255).round(), 0, 0, 0),
      ];
      stops = [0.0, 0.7, 0.9, 1.0];
    } else {
      _canvas!.translate(0, -100);
      colors = [
        ui.Color.fromARGB((shadow!.opacity * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((shadow!.opacity * 0.05 * 255).round(), 0, 0, 0),
        ui.Color.fromARGB((shadow!.opacity * 255).round(), 0, 0, 0),
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
    _canvas!.drawRect(Rect.fromLTWH(0, 0, isw, rect.height * 2), paint);

    _canvas!.restore();
  }
}
