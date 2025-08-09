
import 'package:flutter/material.dart';

import '../render/render.dart';

class PageFlipPainter extends CustomPainter {
  final Render? render;
  final bool needsRepaint;

  PageFlipPainter(this.render, this.needsRepaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (render != null) {
      // Use the provided size which should match the widget's canvas size
      render!.setCanvas(canvas, size);
      // Call render with current time to process animations
      final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
      render!.render(currentTime);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is PageFlipPainter) {
      return needsRepaint || oldDelegate.needsRepaint;
    }
    return true;
  }
}
