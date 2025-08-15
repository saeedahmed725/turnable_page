import '../enums/flip_direction.dart';
import 'point.dart';

/// Type describing calculated values for drop shadows
class Shadow {
  /// Shadow Position Start Point
  final Point pos;

  /// The angle of the shadows relative to the book
  final double angle;

  /// Base width shadow
  final double width;

  /// Base shadow opacity
  final double opacity;

  /// Flipping Direction, the direction of the shadow gradients
  final FlipDirection direction;

  /// Flipping progress in percent (0 - 100)
  final double progress;

  const Shadow({
    required this.pos,
    required this.angle,
    required this.width,
    required this.opacity,
    required this.direction,
    required this.progress,
  });
}
