/// Type representing a book area
class PageRect {
  final double left;
  final double top;
  final double width;
  final double height;

  /// Page width. If portrait mode is equal to the width of the book. In landscape mode - half of the total width.
  final double pageWidth;

  const PageRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.pageWidth,
  });

  double get right => left + width;
  double get bottom => top + height;
}
