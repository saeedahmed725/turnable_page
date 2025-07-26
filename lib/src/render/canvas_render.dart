import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../basic_types.dart' as book_types;
import '../page_flip.dart';
import '../page/page.dart';
import '../flip/flip_enums.dart';
import 'render.dart';

/// Class responsible for rendering the Canvas book
class CanvasRender extends Render {
  Canvas? _canvas;
  Size? _size;
  bool _isDirty = true; // Track if content has changed

  CanvasRender(PageFlip super.app, super.setting);

  Canvas getCanvas() {
    return _canvas!;
  }

  void setCanvas(Canvas canvas, Size size) {
    _canvas = canvas;
    _size = size;
  }

  @override
  double getBlockWidth() {
    // Return the actual widget/canvas width, not the page width
    return _size?.width ?? (setting.width * 2);  // Total book width = 2 * page width
  }

  @override
  double getBlockHeight() {
    // Return the actual widget/canvas height
    return _size?.height ?? setting.height;
  }

  @override
  void reload() {
    // Clear current state and prepare for redraw
    _isDirty = true;
    if (_canvas != null) {
      clear();
    }
  }

  /// Mark content as dirty to trigger repaint
  void markDirty() {
    _isDirty = true;
  }

  @override
  void drawFrame() {
    if (_canvas == null || _size == null) return;

    // Only clear and redraw if content has changed
    if (_isDirty) {
      clear();
      _isDirty = false;
    }

    // Draw left page in landscape mode
    if (orientation != BookOrientation.portrait) {
      if (leftPage != null) {
        leftPage!.simpleDraw(PageOrientation.left);
      }
    }

    // Draw right page
    if (rightPage != null) {
      rightPage!.simpleDraw(PageOrientation.right);
    }

    // Draw bottom page (static page behind the flipping page)
    if (bottomPage != null) {
      bottomPage!.draw();
      _isDirty = true; // Animation in progress
    }

    // Draw book shadow (spine shadow)
    drawBookShadow();

    // Draw flipping page
    if (flippingPage != null) {
      flippingPage!.draw();
      _isDirty = true; // Animation in progress
    }

    // Draw page shadows
    if (shadow != null) {
      drawOuterShadow();
      drawInnerShadow();
      _isDirty = true; // Animation in progress
    }

    // Clip for portrait mode
    final rect = getRect();
    if (orientation == BookOrientation.portrait) {
      _canvas!.clipRect(Rect.fromLTWH(
        rect.left + rect.pageWidth,
        rect.top,
        rect.width,
        rect.height,
      ));
    }
  }

  void drawBookShadow() {
    if (_canvas == null || _size == null || !setting.drawShadow) return;

    final rect = getRect();
    final paint = Paint();

    _canvas!.save();

    final shadowSize = rect.width / 20;
    _canvas!.clipRect(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height));

    final shadowPos = book_types.Point(rect.left + rect.width / 2 - shadowSize / 2, 0);
    _canvas!.translate(shadowPos.x, shadowPos.y);

    // Create gradient for book spine shadow
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

  void drawOuterShadow() {
    if (_canvas == null || shadow == null || !setting.drawShadow) return;

    final rect = getRect();
    _canvas!.save();

    _canvas!.clipRect(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height));

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
    _canvas!.drawRect(Rect.fromLTWH(0, 0, shadow!.width, rect.height * 2), paint);

    _canvas!.restore();
  }

  void drawInnerShadow() {
    if (_canvas == null || shadow == null || pageRect == null || !setting.drawShadow) return;

    final rect = getRect();
    _canvas!.save();

    final shadowPos = convertToGlobal(shadow!.pos);
    if (shadowPos == null) {
      _canvas!.restore();
      return;
    }

    final pageRectGlobal = convertRectToGlobal(pageRect!);
    
    // Create clipping path for the page
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

  void clear() {
    if (_canvas == null || _size == null) return;
    
    final paint = Paint()..color = Colors.white;
    _canvas!.drawRect(Rect.fromLTWH(0, 0, _size!.width, _size!.height), paint);
  }
}
