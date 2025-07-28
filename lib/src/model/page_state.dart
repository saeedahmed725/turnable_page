import 'point.dart';

/// State of the page on the basis of which rendering
class PageState {
  /// Page rotation angle
  double angle;

  /// Page scope
  List<Point> area;

  /// Page position
  Point position;

  /// Rotate angle for hard pages
  double hardAngle;

  /// Rotate angle for hard pages at rendering time
  double hardDrawingAngle;

  PageState({
    this.angle = 0,
    List<Point>? area,
    Point? position,
    this.hardAngle = 0,
    this.hardDrawingAngle = 0,
  }) : area = area ?? [],
       position = position ?? const Point(0, 0);
}
