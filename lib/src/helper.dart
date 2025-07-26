import 'dart:math' as math;
import 'basic_types.dart';

/// A class containing helping mathematical methods
class Helper {
  /// Get the distance between two points
  ///
  /// @param {Point} point1
  /// @param {Point} point2
  static double getDistanceBetweenTwoPoint(Point? point1, Point? point2) {
    if (point1 == null || point2 == null) {
      return double.infinity;
    }

    return math.sqrt(math.pow(point2.x - point1.x, 2) + math.pow(point2.y - point1.y, 2));
  }

  /// Get the length of the line segment
  ///
  /// @param {Segment} segment
  static double getSegmentLength(Segment segment) {
    return getDistanceBetweenTwoPoint(segment.start, segment.end);
  }

  /// Get the angle between two lines
  ///
  /// @param {Segment} line1
  /// @param {Segment} line2
  static double getAngleBetweenTwoLine(Segment line1, Segment line2) {
    final A1 = line1.start.y - line1.end.y;
    final A2 = line2.start.y - line2.end.y;

    final B1 = line1.end.x - line1.start.x;
    final B2 = line2.end.x - line2.start.x;

    return math.acos((A1 * A2 + B1 * B2) / (math.sqrt(A1 * A1 + B1 * B1) * math.sqrt(A2 * A2 + B2 * B2)));
  }

  /// Check for a point in a rectangle
  ///
  /// @param {Rect} rect
  /// @param {Point} pos
  ///
  /// @returns {Point} If the point enters the rectangle its coordinates will be returned, otherwise - null
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

  /// Transform point coordinates to a given angle
  ///
  /// @param {Point} transformedPoint - Point to rotate
  /// @param {Point} startPoint - Transformation reference point
  /// @param {number} angle - Rotation angle (in radians)
  ///
  /// @returns {Point} Point coordinates after rotation
  static Point getRotatedPoint(Point transformedPoint, Point startPoint, double angle) {
    return Point(
      transformedPoint.x * math.cos(angle) + transformedPoint.y * math.sin(angle) + startPoint.x,
      transformedPoint.y * math.cos(angle) - transformedPoint.x * math.sin(angle) + startPoint.y,
    );
  }

  /// Limit a point "linePoint" to a given circle centered at point "startPoint" and a given radius
  ///
  /// @param {Point} startPoint - Circle center
  /// @param {number} radius - Circle radius
  /// @param {Point} limitedPoint - Сhecked point
  ///
  /// @returns {Point} If "linePoint" enters the circle, then its coordinates are returned.
  /// Else will be returned the intersection point between the line ([startPoint, linePoint]) and the circle
  static Point limitPointToCircle(Point startPoint, double radius, Point limitedPoint) {
    // If "linePoint" enters the circle, do nothing
    if (getDistanceBetweenTwoPoint(startPoint, limitedPoint) <= radius) {
      return limitedPoint;
    }

    final a = startPoint.x;
    final b = startPoint.y;
    final n = limitedPoint.x;
    final m = limitedPoint.y;

    // Find the intersection between the line at two points: (startPoint and limitedPoint) and the circle.
    double x = math.sqrt((math.pow(radius, 2) * math.pow(a - n, 2)) / (math.pow(a - n, 2) + math.pow(b - m, 2))) + a;
    if (limitedPoint.x < 0) {
      x *= -1;
    }

    double y = ((x - a) * (b - m)) / (a - n) + b;
    if (a - n + b == 0) {
      y = radius;
    }

    return Point(x, y);
  }

  /// Find the intersection of two lines bounded by a rectangle "rectBorder"
  ///
  /// @param {Rect} rectBorder
  /// @param {Segment} one
  /// @param {Segment} two
  ///
  /// @returns {Point} The intersection point, or "null" if it does not exist, or it lies outside the rectangle "rectBorder"
  static Point? getIntersectBetweenTwoSegment(Rect rectBorder, Segment one, Segment two) {
    return pointInRect(rectBorder, getIntersectBetweenTwoLine(one, two));
  }

  /// Find the intersection point of two lines
  ///
  /// @param one
  /// @param two
  ///
  /// @returns {Point} The intersection point, or "null" if it does not exist
  /// @throws Error if the segments are on the same line
  static Point? getIntersectBetweenTwoLine(Segment one, Segment two) {
    final A1 = one.start.y - one.end.y;
    final A2 = two.start.y - two.end.y;

    final B1 = one.end.x - one.start.x;
    final B2 = two.end.x - two.start.x;

    final C1 = one.start.x * one.end.y - one.end.x * one.start.y;
    final C2 = two.start.x * two.end.y - two.end.x * two.start.y;

    final det1 = A1 * C2 - A2 * C1;
    final det2 = B1 * C2 - B2 * C1;

    final x = -((C1 * B2 - C2 * B1) / (A1 * B2 - A2 * B1));
    final y = -((A1 * C2 - A2 * C1) / (A1 * B2 - A2 * B1));

    if (x.isFinite && y.isFinite) {
      return Point(x, y);
    } else {
      if ((det1 - det2).abs() < 0.1) throw Exception('Segment included');
    }

    return null;
  }

  /// Get a list of coordinates (step: 1px) between two points
  ///
  /// @param pointOne
  /// @param pointTwo
  ///
  /// @returns {Point[]}
  static List<Point> getCordsFromTwoPoint(Point pointOne, Point pointTwo) {
    final sizeX = (pointOne.x - pointTwo.x).abs();
    final sizeY = (pointOne.y - pointTwo.y).abs();

    final lengthLine = math.max(sizeX, sizeY);

    final result = <Point>[pointOne];

    double getCord(double c1, double c2, double size, double length, int index) {
      if (c2 > c1) {
        return c1 + index * (size / length);
      } else if (c2 < c1) {
        return c1 - index * (size / length);
      }

      return c1;
    }

    for (int i = 1; i <= lengthLine; i += 1) {
      result.add(Point(
        getCord(pointOne.x, pointTwo.x, sizeX, lengthLine, i),
        getCord(pointOne.y, pointTwo.y, sizeY, lengthLine, i),
      ));
    }

    return result;
  }
}
