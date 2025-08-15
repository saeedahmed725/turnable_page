import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';

// Base class for all custom UI elements
abstract class CustomUIWidget {
  Offset offset;
  Size size;
  List<CustomUIWidget> children;
  EdgeInsets? padding;
  EdgeInsets? margin;

  CustomUIWidget({
    this.offset = Offset.zero,
    this.size = Size.zero,
    this.children = const [],
    this.padding,
    this.margin,
  });

  void paint(Canvas canvas, Size containerSize);

  Rect get bounds => Rect.fromLTWH(
    offset.dx + (margin?.left ?? 0),
    offset.dy + (margin?.top ?? 0),
    math.max(0, size.width - (margin?.horizontal ?? 0)),
    math.max(0, size.height - (margin?.vertical ?? 0)),
  );

  Rect get contentBounds {
    final rect = bounds;
    return Rect.fromLTWH(
      rect.left + (padding?.left ?? 0),
      rect.top + (padding?.top ?? 0),
      math.max(0, rect.width - (padding?.horizontal ?? 0)),
      math.max(0, rect.height - (padding?.vertical ?? 0)),
    );
  }

  void layout(Size availableSize);
}

// Container equivalent
class ContainerPainter extends CustomUIWidget {
  final Color? color;
  final double? borderRadius;
  final Border? border;

  ContainerPainter({
    super.offset,
    super.size,
    super.children,
    super.padding,
    super.margin,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  void paint(Canvas canvas, Size containerSize) {
    final rect = bounds;
    if (rect.width <= 0 || rect.height <= 0 || rect.hasNaN) {
      log('⚠️ Skipping paint due to invalid rect: $rect');
      return;
    }

    if (color != null) {
      final paint = Paint()..color = color!;
      if (borderRadius != null && borderRadius!.isNaN) {
        log('⚠️ borderRadius is NaN: $borderRadius');
      }

      if (borderRadius != null && !borderRadius!.isNaN) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius!)),
          paint,
        );
      } else {
        canvas.drawRect(rect, paint);
      }
    }

    if (border != null) {
      final borderPaint = Paint()
        ..color = border!.top.color
        ..strokeWidth = border!.top.width
        ..style = PaintingStyle.stroke;

      if (borderRadius != null && borderRadius! > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius!)),
          borderPaint,
        );
      } else {
        canvas.drawRect(rect, borderPaint);
      }
    }

    for (final child in children) {
      child.paint(canvas, size);
    }
  }

  @override
  void layout(Size availableSize) {
    size = Size(
      math.max(0, availableSize.width),
      math.max(0, availableSize.height),
    );

    if (children.isNotEmpty) {
      final contentArea = contentBounds;
      final child = children.first;
      child.offset = Offset(contentArea.left, contentArea.top);
      child.layout(
        Size(math.max(0, contentArea.width), math.max(0, contentArea.height)),
      );
      log(
        'ContainerPainter layout: availableSize=$availableSize, contentArea=$contentArea, child.size=${child.size}',
      );
      size = Size(
        math.max(
          size.width,
          child.size.width +
              (padding?.horizontal ?? 0) +
              (margin?.horizontal ?? 0),
        ),
        math.max(
          size.height,
          child.size.height +
              (padding?.vertical ?? 0) +
              (margin?.vertical ?? 0),
        ),
      );
    }
  }
}

// Text equivalent
class CTextPainter extends CustomUIWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  late final TextPainter _textPainter;

  CTextPainter({
    required this.text,
    this.style = const TextStyle(color: Colors.black, fontSize: 16),
    this.textAlign = TextAlign.left,
    super.offset,
    super.padding,
    super.margin,
  }) {
    _textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
  }

  @override
  void layout(Size availableSize) {
    _textPainter.layout(
      minWidth: 0,
      maxWidth: math.max(0, availableSize.width - (padding?.horizontal ?? 0)),
    );
    size = Size(
      _textPainter.width +
          (padding?.horizontal ?? 0) +
          (margin?.horizontal ?? 0),
      _textPainter.height + (padding?.vertical ?? 0) + (margin?.vertical ?? 0),
    );
    log(
      'CTextPainter layout: text=$text, size=$size, availableSize=$availableSize',
    );
  }

  @override
  void paint(Canvas canvas, Size containerSize) {
    final dx = offset.dx + (margin?.left ?? 0) + (padding?.left ?? 0);
    final dy = offset.dy + (margin?.top ?? 0) + (padding?.top ?? 0);
    _textPainter.paint(canvas, Offset(dx, dy));
  }
}

// Column equivalent
class ColumnPainter extends CustomUIWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  ColumnPainter({
    super.children,
    super.offset,
    super.size,
    super.padding,
    super.margin,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  void paint(Canvas canvas, Size containerSize) {
    for (final child in children) {
      child.paint(canvas, containerSize);
    }
  }

  @override
  void layout(Size availableSize) {
    final contentArea = Rect.fromLTWH(
      offset.dx + (margin?.left ?? 0) + (padding?.left ?? 0),
      offset.dy + (margin?.top ?? 0) + (padding?.top ?? 0),
      math.max(
        0,
        availableSize.width -
            (margin?.horizontal ?? 0) -
            (padding?.horizontal ?? 0),
      ),
      math.max(
        0,
        availableSize.height -
            (margin?.vertical ?? 0) -
            (padding?.vertical ?? 0),
      ),
    );

    log(
      'ColumnPainter layout: availableSize=$availableSize, contentArea=$contentArea',
    );

    double totalHeight = 0;
    double maxWidth = 0;

    for (final child in children) {
      child.layout(Size(contentArea.width, contentArea.height));
      totalHeight += child.size.height;
      maxWidth = math.max(maxWidth, child.size.width);
    }

    if (mainAxisSize == MainAxisSize.min) {
      size = Size(
        maxWidth + (margin?.horizontal ?? 0) + (padding?.horizontal ?? 0),
        totalHeight + (margin?.vertical ?? 0) + (padding?.vertical ?? 0),
      );
    } else {
      size = Size(
        math.max(0, availableSize.width),
        math.max(0, availableSize.height),
      );
    }

    double currentY = contentArea.top;

    if (mainAxisAlignment == MainAxisAlignment.center) {
      currentY += (contentArea.height - totalHeight) / 2;
    } else if (mainAxisAlignment == MainAxisAlignment.end) {
      currentY += contentArea.height - totalHeight;
    } else if (mainAxisAlignment == MainAxisAlignment.spaceEvenly) {
      final spacing =
          (contentArea.height - totalHeight) / (children.length + 1);
      currentY += spacing;
    }

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      double childX = contentArea.left;

      if (crossAxisAlignment == CrossAxisAlignment.center) {
        childX += (contentArea.width - child.size.width) / 2;
      } else if (crossAxisAlignment == CrossAxisAlignment.end) {
        childX += contentArea.width - child.size.width;
      }

      child.offset = Offset(childX, currentY);
      currentY += child.size.height;

      if (mainAxisAlignment == MainAxisAlignment.spaceEvenly &&
          i < children.length - 1) {
        final spacing =
            (contentArea.height - totalHeight) / (children.length + 1);
        currentY += spacing;
      }
    }
  }
}

// Row equivalent
class RowPainter extends CustomUIWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  RowPainter({
    super.children,
    super.offset,
    super.size,
    super.padding,
    super.margin,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  void paint(Canvas canvas, Size containerSize) {
    for (final child in children) {
      child.paint(canvas, containerSize);
    }
  }

  @override
  void layout(Size availableSize) {
    final contentArea = Rect.fromLTWH(
      offset.dx + (margin?.left ?? 0) + (padding?.left ?? 0),
      offset.dy + (margin?.top ?? 0) + (padding?.top ?? 0),
      math.max(
        0,
        availableSize.width -
            (margin?.horizontal ?? 0) -
            (padding?.horizontal ?? 0),
      ),
      math.max(
        0,
        availableSize.height -
            (margin?.vertical ?? 0) -
            (padding?.vertical ?? 0),
      ),
    );

    double totalWidth = 0;
    double maxHeight = 0;

    for (final child in children) {
      child.layout(Size(double.infinity, contentArea.height));
      totalWidth += child.size.width;
      maxHeight = math.max(maxHeight, child.size.height);
    }

    if (mainAxisSize == MainAxisSize.min) {
      size = Size(
        totalWidth + (margin?.horizontal ?? 0) + (padding?.horizontal ?? 0),
        maxHeight + (margin?.vertical ?? 0) + (padding?.vertical ?? 0),
      );
    } else {
      size = Size(
        math.max(0, availableSize.width),
        math.max(0, availableSize.height),
      );
    }

    double currentX = contentArea.left;

    if (mainAxisAlignment == MainAxisAlignment.center) {
      currentX += (contentArea.width - totalWidth) / 2;
    } else if (mainAxisAlignment == MainAxisAlignment.end) {
      currentX += contentArea.width - totalWidth;
    }

    for (final child in children) {
      double childY = contentArea.top;

      if (crossAxisAlignment == CrossAxisAlignment.center) {
        childY += (contentArea.height - child.size.height) / 2;
      } else if (crossAxisAlignment == CrossAxisAlignment.end) {
        childY += contentArea.height - child.size.height;
      }

      child.offset = Offset(currentX, childY);
      currentX += child.size.width;
    }
  }
}

// Stack equivalent
class StackPainter extends CustomUIWidget {
  final AlignmentGeometry alignment;

  StackPainter({
    super.children,
    super.offset,
    super.size,
    super.padding,
    super.margin,
    this.alignment = Alignment.topLeft,
  });

  @override
  void paint(Canvas canvas, Size containerSize) {
    for (final child in children) {
      child.paint(canvas, containerSize);
    }
  }

  @override
  void layout(Size availableSize) {
    size = Size(
      math.max(0, availableSize.width),
      math.max(0, availableSize.height),
    );
    final contentArea = contentBounds;

    for (final child in children) {
      child.layout(Size(contentArea.width, contentArea.height));

      double childX = contentArea.left;
      double childY = contentArea.top;

      if (alignment == Alignment.center) {
        childX += (contentArea.width - child.size.width) / 2;
        childY += (contentArea.height - child.size.height) / 2;
      } else if (alignment == Alignment.topRight) {
        childX += contentArea.width - child.size.width;
      } else if (alignment == Alignment.bottomLeft) {
        childY += contentArea.height - child.size.height;
      } else if (alignment == Alignment.bottomRight) {
        childX += contentArea.width - child.size.width;
        childY += contentArea.height - child.size.height;
      }

      child.offset = Offset(childX, childY);
    }
  }
}

// Custom painter that renders the UI tree
class CustomUIRenderer extends CustomPainter {
  final CustomUIWidget root;

  CustomUIRenderer(this.root);

  @override
  void paint(Canvas canvas, Size size) {
    root.layout(size);
    root.paint(canvas, size);
  }

  @override
  bool shouldRepaint(CustomUIRenderer oldDelegate) {
    return root != oldDelegate.root;
  }
}

// Widget wrapper to use the custom UI system
class CustomUICanvas extends StatelessWidget {
  final CustomUIWidget child;

  const CustomUICanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        log('Canvas size: $canvasSize');
        return CustomPaint(size: canvasSize, painter: CustomUIRenderer(child));
      },
    );
  }
}

// Example usage
class ExampleCustomUI extends StatelessWidget {
  const ExampleCustomUI({super.key});

  @override
  Widget build(BuildContext context) {
    final customUI = ColumnPainter(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      padding: EdgeInsets.all(5),
      children: [
        ContainerPainter(
          color: Colors.blue.shade100,
          borderRadius: 12,
          border: Border.all(color: Colors.blue, width: 2),
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(bottom: 10),
          children: [
            CTextPainter(
              text: "Hello Custom UI!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        ContainerPainter(
          color: Colors.green.shade100,
          borderRadius: 8,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          children: [
            CTextPainter(
              text: "Another container with text",
              style: TextStyle(fontSize: 14, color: Colors.green.shade800),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text('Custom UI Framework')),
      body: CustomUICanvas(child: customUI),
    );
  }
}
