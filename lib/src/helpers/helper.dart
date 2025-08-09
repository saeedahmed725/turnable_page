import 'dart:math' as math;

import '../model/point.dart';
import '../model/rect.dart';
import '../model/segment.dart';

/// A class containing helping mathematical methods
class Helper {
  /// Returns the distance between two points.
  ///
  /// [point1] The first point.
  /// [point2] The second point.
  static double getDistanceBetweenTwoPoint(Point? point1, Point? point2) {
    if (point1 == null || point2 == null) {
      return double.infinity;
    }

    return math.sqrt(
      math.pow(point2.x - point1.x, 2) + math.pow(point2.y - point1.y, 2),
    );
  }

  /// Returns the length of the given line segment.
  ///
  /// [segment] The segment whose length is calculated.
  static double getSegmentLength(Segment segment) {
    return getDistanceBetweenTwoPoint(segment.start, segment.end);
  }

  /// Returns the angle (in radians) between two line segments.
  ///
  /// [line1] The first line segment.
  /// [line2] The second line segment.
  static double getAngleBetweenTwoLine(Segment line1, Segment line2) {
    final a1 = line1.start.y - line1.end.y;
    final a2 = line2.start.y - line2.end.y;

    final b1 = line1.end.x - line1.start.x;
    final b2 = line2.end.x - line2.start.x;

    return math.acos(
      (a1 * a2 + b1 * b2) /
          (math.sqrt(a1 * a1 + b1 * b1) * math.sqrt(a2 * a2 + b2 * b2)),
    );
  }

  /// Checks if a point is inside a rectangle.
  ///
  /// Returns the point if it is inside the rectangle, otherwise returns null.
  ///
  /// [rect] The rectangle to check.
  /// [pos] The point to check.
  static Point? pointInRect(Rect rect, Point? pos) {
    if (pos == null) {
      return null;
    }

    if (pos.x >= rect.left &&
        pos.x <= rect.width + rect.left &&
        pos.y >= rect.top &&
        pos.y <= rect.top + rect.height) {
      return pos;
    }
    return null;
  }

  /// Rotates a point around a reference point by a given angle (in radians).
  ///
  /// [transformedPoint] The point to rotate.
  /// [startPoint] The reference point for rotation.
  /// [angle] The rotation angle in radians.
  ///
  /// Returns the new coordinates after rotation.
  static Point getRotatedPoint(
    Point transformedPoint,
    Point startPoint,
    double angle,
  ) {
    return Point(
      transformedPoint.x * math.cos(angle) +
          transformedPoint.y * math.sin(angle) +
          startPoint.x,
      transformedPoint.y * math.cos(angle) -
          transformedPoint.x * math.sin(angle) +
          startPoint.y,
    );
  }

  /// Limits a point to a given circle centered at [startPoint] with the given [radius].
  ///
  /// If [limitedPoint] is inside the circle, returns it. Otherwise, returns the intersection point between the line ([startPoint], [limitedPoint]) and the circle.
  static Point limitPointToCircle(
    Point startPoint,
    double radius,
    Point limitedPoint,
  ) {
    // If "linePoint" enters the circle, do nothing
    if (getDistanceBetweenTwoPoint(startPoint, limitedPoint) <= radius) {
      return limitedPoint;
    }

    final a = startPoint.x;
    final b = startPoint.y;
    final n = limitedPoint.x;
    final m = limitedPoint.y;

    // Find the intersection between the line at two points: (startPoint and limitedPoint) and the circle.
    double x =
        math.sqrt(
          (math.pow(radius, 2) * math.pow(a - n, 2)) /
              (math.pow(a - n, 2) + math.pow(b - m, 2)),
        ) +
        a;
    if (limitedPoint.x < 0) {
      x *= -1;
    }

    double y = ((x - a) * (b - m)) / (a - n) + b;
    if (a - n + b == 0) {
      y = radius;
    }

    return Point(x, y);
  }

  /// Finds the intersection of two line segments, bounded by a rectangle [rectBorder].
  ///
  /// Returns the intersection point, or null if it does not exist or lies outside the rectangle.
  static Point? getIntersectBetweenTwoSegment(
    Rect rectBorder,
    Segment one,
    Segment two,
  ) {
    return pointInRect(rectBorder, getIntersectBetweenTwoLine(one, two));
  }

  /// Finds the intersection point of two lines.
  ///
  /// Returns the intersection point, or null if it does not exist.
  /// Throws an [Exception] if the segments are on the same line.
  static Point? getIntersectBetweenTwoLine(Segment one, Segment two) {
    final a1 = one.start.y - one.end.y;
    final a2 = two.start.y - two.end.y;

    final b1 = one.end.x - one.start.x;
    final b2 = two.end.x - two.start.x;

    final c1 = one.start.x * one.end.y - one.end.x * one.start.y;
    final c2 = two.start.x * two.end.y - two.end.x * two.start.y;

    final det1 = a1 * c2 - a2 * c1;
    final det2 = b1 * c2 - b2 * c1;

    final x = -((c1 * b2 - c2 * b1) / (a1 * b2 - a2 * b1));
    final y = -((a1 * c2 - a2 * c1) / (a1 * b2 - a2 * b1));

    if (x.isFinite && y.isFinite) {
      return Point(x, y);
    } else {
      if ((det1 - det2).abs() < 0.1) throw Exception('Segment included');
    }

    return null;
  }

  /// Returns a list of coordinates (step: 1px) between two points.
  ///
  /// [pointOne] The starting point.
  /// [pointTwo] The ending point.
  ///
  /// Returns a list of [Point] objects between the two points.
  static List<Point> getCordsFromTwoPoint(Point pointOne, Point pointTwo) {
    final sizeX = (pointOne.x - pointTwo.x).abs();
    final sizeY = (pointOne.y - pointTwo.y).abs();

    final lengthLine = math.max(sizeX, sizeY);

    final result = <Point>[pointOne];

    double getCord(
      double c1,
      double c2,
      double size,
      double length,
      int index,
    ) {
      if (c2 > c1) {
        return c1 + index * (size / length);
      } else if (c2 < c1) {
        return c1 - index * (size / length);
      }

      return c1;
    }

    for (int i = 1; i <= lengthLine; i += 1) {
      result.add(
        Point(
          getCord(pointOne.x, pointTwo.x, sizeX, lengthLine, i),
          getCord(pointOne.y, pointTwo.y, sizeY, lengthLine, i),
        ),
      );
    }

    return result;
  }
}
