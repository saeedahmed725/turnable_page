import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../enums/page_density.dart';
import '../enums/page_orientation.dart';
import '../model/page_state.dart';
import '../model/point.dart';
import '../render/canvas_render.dart';
import '../render/render.dart';
import 'book_page.dart';

/// Enhanced class representing a book page as a widget that renders directly
/// with improved performance and memory management
class BookPageImp extends BookPage {
  /// Cached image for performance
  final ui.Image _image;

  /// State of the page on the basis of which rendering
  late final PageState state;

  /// Render object
  late final Render render;

  /// Page Orientation
  late PageOrientation orientation;

  /// Density at creation
  late final PageDensity createdDensity;

  /// Density at the time of rendering (Depends on neighboring pages)
  late PageDensity nowDrawingDensity;

  /// Page index for identification
  final int pageIndex;

  /// Cached paint objects for performance
  static final Paint _defaultPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..colorFilter = const ColorFilter.matrix([
      0.95,
      0,
      0,
      0,
      0,
      0,
      0.95,
      0,
      0,
      0,
      0,
      0,
      0.95,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);

  /// Cache for clipping path to avoid recreation
  Path? _cachedClipPath;

  /// Last known area points for cache invalidation
  List<Point>? _lastAreaPoints;

  BookPageImp(this.render, this._image, this.pageIndex, PageDensity density) {
    state = PageState();
    createdDensity = density;
    nowDrawingDensity = createdDensity;
  }

  @override
  void draw() {
    final canvasRender = render as CanvasRender;
    final canvas = canvasRender.getCanvas();
    final rect = render.getRect();
    final pagePos = render.convertToGlobal(state.position);
    if (pagePos == null) return;

    canvas.save();

    try {
      canvas.translate(pagePos.x, pagePos.y);

      // Optimize clipping path creation and caching
      _updateClipPath();
      if (_cachedClipPath != null) {
        canvas.clipPath(_cachedClipPath!);
      }

      // Apply rotation if needed
      if (state.angle.abs() > 0.001) {
        canvas.rotate(state.angle);
      }

      _drawImageOptimized(canvas, 0, 0, rect.pageWidth, rect.height);
    } finally {
      canvas.restore();
    }
  }

  @override
  void simpleDraw(PageOrientation orient) {
    final rect = render.getRect();
    final canvasRender = render as CanvasRender;
    final canvas = canvasRender.getCanvas();

    final x = orient == PageOrientation.right
        ? rect.left + rect.pageWidth
        : rect.left;
    final y = rect.top;
    _drawImageOptimized(canvas, x, y, rect.pageWidth, rect.height);
  }

  // void _drawWhitePage(
  //   Canvas canvas,
  //   double x,
  //   double y,
  //   double width,
  //   double height,
  // ) {
  //   final paint = Paint()
  //     ..color = Colors.white
  //     ..isAntiAlias = true;
  //   canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
  // }

  /// Optimized image drawing with performance enhancements
  void _drawImageOptimized(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
  ) {
    // Use efficient image rect drawing with Flutter's Rect
    canvas.drawImageRect(
      _image,
      ui.Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      ui.Rect.fromLTWH(x, y, width, height),
      _defaultPaint,
    );
  }

  /// Update clipping path with caching for performance
  void _updateClipPath() {
    // Check if area has changed to avoid unnecessary path recreation
    if (_lastAreaPoints != null &&
        _arePointListsEqual(_lastAreaPoints!, state.area)) {
      return; // Use cached path
    }

    if (state.area.isEmpty) {
      _cachedClipPath = null;
      _lastAreaPoints = null;
      return;
    }

    final path = Path();
    bool first = true;

    for (final point in state.area) {
      final globalP = render.convertToGlobal(point);
      if (globalP != null) {
        final pagePos = render.convertToGlobal(state.position);
        if (pagePos != null) {
          final localP = globalP - pagePos;
          if (first) {
            path.moveTo(localP.x, localP.y);
            first = false;
          } else {
            path.lineTo(localP.x, localP.y);
          }
        }
      }
    }

    if (!first) {
      path.close();
      _cachedClipPath = path;
      _lastAreaPoints = List.from(state.area);
    }
  }

  /// Efficient point list comparison
  bool _arePointListsEqual(List<Point> list1, List<Point> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if ((list1[i].x - list2[i].x).abs() > 0.01 ||
          (list1[i].y - list2[i].y).abs() > 0.01) {
        return false;
      }
    }
    return true;
  }

  @override
  void setDensity(PageDensity density) {
    nowDrawingDensity = density;
  }

  @override
  void setDrawingDensity(PageDensity density) {
    nowDrawingDensity = density;
  }

  @override
  void setPosition(Point pagePos) {
    state.position = pagePos;
  }

  @override
  void setAngle(double angle) {
    state.angle = angle;
  }

  @override
  void setArea(List<Point> area) {
    state.area = area;
  }

  @override
  void setHardDrawingAngle(double angle) {
    state.hardDrawingAngle = angle;
  }

  @override
  void setHardAngle(double angle) {
    state.hardAngle = angle;
    state.hardDrawingAngle = angle;
  }

  @override
  void setOrientation(PageOrientation orientation) {
    this.orientation = orientation;
  }

  @override
  PageDensity getDrawingDensity() {
    return nowDrawingDensity;
  }

  @override
  PageDensity getDensity() {
    return createdDensity;
  }

  @override
  BookPage getTemporaryCopy() {
    return this;
  }

  /// Dispose method for proper resource cleanup
  void dispose() {
    _cachedClipPath = null;
    _lastAreaPoints = null;
  }

  /// Get image dimensions
  Size get imageSize => Size(_image.width.toDouble(), _image.height.toDouble());

  /// Get underlying image
  ui.Image get image => _image;

  /// Check if page is ready for rendering
  bool get isReady => !_image.debugDisposed;
}
