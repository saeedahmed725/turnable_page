import 'dart:math' as math;
import 'dart:ui';

/// The edges of the stacked pages beside the book
/// (`FlipSettings.showPageEdges`): the pages already read on the left and
/// the pages left to read on the right. The left stack grows and the right
/// one shrinks as the reader moves through the book. A single page shows
/// only the stack of pages left to read, on its outer edge.
///
/// The book paints them against the outer edges of its pages, in
/// [extent] of space reserved beside them, so they never cover a page.
abstract final class PageEdges {
  /// Horizontal space reserved around the book for the two stacks.
  static double extent({required bool enabled, required double maxWidth}) =>
      enabled ? maxWidth * 2 : 0;

  /// Distance between two drawn sheet edges.
  static const double _sheet = 1.5;

  /// Paints both stacks. [leftEdge] and [rightEdge] are the x of the outer
  /// edges of the visible pages, [top] and [height] their vertical extent,
  /// and [read] the part of the book already read (0 to 1). Without
  /// [showRead], only the stack of pages left to read is painted.
  static void paint(
    Canvas canvas, {
    required double leftEdge,
    required double rightEdge,
    required double top,
    required double height,
    required double read,
    bool showRead = true,
    required double maxWidth,
    required Color paperColor,
  }) {
    final r = read.clamp(0.0, 1.0);
    if (showRead) {
      _paintStack(canvas, leftEdge, top, height, maxWidth * r, -1, paperColor);
    }
    _paintStack(
      canvas,
      rightEdge,
      top,
      height,
      maxWidth * (1 - r),
      1,
      paperColor,
    );
  }

  /// Paints a stack of [thickness] from the page edge at [edgeX] outwards
  /// ([dir] -1 = to the left, 1 = to the right).
  static void _paintStack(
    Canvas canvas,
    double edgeX,
    double top,
    double height,
    double thickness,
    int dir,
    Color paperColor,
  ) {
    if (thickness < 0.5) return;
    final count = math.max(1, (thickness / _sheet).ceil());
    final step = thickness / count;
    final dark = paperColor.computeLuminance() < 0.4;
    final shade = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    for (int i = 0; i < count; i++) {
      final x = edgeX + dir * (i + 0.5) * step;
      // Deeper sheets look a bit shorter, like a stack seen from above.
      final inset = 0.5 + (i + 1) * 0.45;
      final t = count == 1 ? 0.0 : i / (count - 1);
      canvas.drawLine(
        Offset(x, top + inset),
        Offset(x, top + height - inset),
        Paint()
          ..color = Color.lerp(
            paperColor,
            shade,
            (i.isEven ? 0.05 : 0.16) + 0.12 * t,
          )!
          ..strokeWidth = step,
      );
    }
    // Outline of the stack.
    final outer = edgeX + dir * thickness;
    final inset = 0.5 + count * 0.45;
    canvas.drawLine(
      Offset(outer, top + inset),
      Offset(outer, top + height - inset),
      Paint()
        ..color = Color.lerp(paperColor, shade, 0.35)!
        ..strokeWidth = 0.6,
    );
  }
}
