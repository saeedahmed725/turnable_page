import 'point.dart';

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
