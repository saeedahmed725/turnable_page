/// Type representing a point on a plane
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator -(Point other) => Point(x - other.x, y - other.y);
  Point operator *(double scalar) => Point(x * scalar, y * scalar);
  Point operator /(double scalar) => Point(x / scalar, y / scalar);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Point($x, $y)';
}

/// Type representing a coordinates of the rectangle on the plane
class RectPoints {
  /// Coordinates of the top left corner
  final Point topLeft;
  /// Coordinates of the top right corner
  final Point topRight;
  /// Coordinates of the bottom left corner
  final Point bottomLeft;
  /// Coordinates of the bottom right corner
  final Point bottomRight;

  const RectPoints({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });
}

/// Type representing a rectangle
class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  const Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;
}

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

/// Type representing a line segment contains two points: start and end
class Segment {
  final Point start;
  final Point end;

  const Segment(this.start, this.end);
}
