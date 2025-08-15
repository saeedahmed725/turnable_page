import 'dart:math' as math;
import '../enums/flip_corner.dart';
import '../enums/flip_direction.dart';
import '../helpers/helper.dart';
import '../model/point.dart';
import '../model/rect.dart';
import '../model/rect_points.dart';
import '../model/segment.dart';

class FlipCalculation {
  /// Calculated rotation angle to flipping page
  late double angle;

  /// Calculated position to flipping page
  late Point position;

  late RectPoints rect;

  /// The point of intersection of the page with the borders of the book
  Point? topIntersectPoint; // With top border
  Point? sideIntersectPoint; // With side border
  Point? bottomIntersectPoint; // With bottom border

  final double pageWidth;
  final double pageHeight;

  final FlipDirection direction;
  final FlipCorner corner;

  /// Constructor
  FlipCalculation(this.direction, this.corner, this.pageWidth, this.pageHeight);

  /// The main calculation method
  bool calc(Point localPos) {
    try {
      position = calcAngleAndPosition(localPos);
      calculateIntersectPoint(position);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the crop area for the flipping page
  List<Point> getFlippingClipArea() {
    final result = <Point>[];
    bool clipBottom = false;

    result.add(rect.topLeft);
    if (topIntersectPoint != null) {
      result.add(topIntersectPoint!);
    }

    if (sideIntersectPoint == null) {
      clipBottom = true;
    } else {
      result.add(sideIntersectPoint!);

      if (bottomIntersectPoint == null) clipBottom = false;
    }

    if (bottomIntersectPoint != null) {
      result.add(bottomIntersectPoint!);
    }

    if (clipBottom || corner == FlipCorner.bottom) {
      result.add(rect.bottomLeft);
    }

    return result;
  }

  /// Get the crop area for the page that is below the page to be flipped
  List<Point> getBottomClipArea() {
    final result = <Point>[];

    if (topIntersectPoint != null) {
      result.add(topIntersectPoint!);
    }

    if (corner == FlipCorner.top) {
      result.add(Point(pageWidth, 0));
    } else {
      if (topIntersectPoint != null) {
        result.add(Point(pageWidth, 0));
      }
      result.add(Point(pageWidth, pageHeight));
    }

    if (sideIntersectPoint != null && topIntersectPoint != null) {
      if (Helper.getDistanceBetweenTwoPoint(
        sideIntersectPoint!,
        topIntersectPoint!,
      ) >=
          10) {
        result.add(sideIntersectPoint!);
      }
    } else {
      if (corner == FlipCorner.top) {
        result.add(Point(pageWidth, pageHeight));
      }
    }

    if (bottomIntersectPoint != null) {
      result.add(bottomIntersectPoint!);
    }
    if (topIntersectPoint != null) {
      result.add(topIntersectPoint!);
    }

    return result;
  }

  /// Get page rotation angle
  double getAngle() {
    if (direction == FlipDirection.forward) {
      return -angle;
    }

    return angle;
  }

  /// Get page area while flipping
  RectPoints getRect() {
    return rect;
  }

  /// Get the position of the active angle when turning
  Point getPosition() {
    return position;
  }

  /// Get the active corner of the page (which pull)
  Point getActiveCorner() {
    if (direction == FlipDirection.forward) {
      return rect.topLeft;
    }

    return rect.topRight;
  }

  /// Get flipping direction
  FlipDirection getDirection() {
    return direction;
  }

  /// Get flipping progress (0-100)
  double getFlippingProgress() {
    return ((position.x - pageWidth) / (2 * pageWidth) * 100).abs();
  }

  /// Get flipping corner position (top, bottom)
  FlipCorner getCorner() {
    return corner;
  }

  /// Get start position for the page that is below the page to be flipped
  Point getBottomPagePosition() {
    if (direction == FlipDirection.back) {
      return Point(pageWidth, 0);
    }

    return Point(0, 0);
  }

  /// Get the starting position of the shadow
  Point getShadowStartPoint() {
    if (corner == FlipCorner.top) {
      return topIntersectPoint ?? Point(0, 0);
    } else {
      if (sideIntersectPoint != null) return sideIntersectPoint!;

      return topIntersectPoint ?? Point(0, 0);
    }
  }

  /// Get the rotate angle of the shadow
  double getShadowAngle() {
    final angle = Helper.getAngleBetweenTwoLine(
      getSegmentToShadowLine(),
      Segment(Point(0, 0), Point(pageWidth, 0)),
    );

    if (direction == FlipDirection.forward) {
      return angle;
    }

    return math.pi - angle;
  }

  Point calcAngleAndPosition(Point pos) {
    Point result = pos;

    updateAngleAndGeometry(result);

    if (corner == FlipCorner.top) {
      result = checkPositionAtCenterLine(
        result,
        Point(0, 0),
        Point(0, pageHeight),
      );
    } else {
      result = checkPositionAtCenterLine(
        result,
        Point(0, pageHeight),
        Point(0, 0),
      );
    }

    if ((result.x - pageWidth).abs() < 1 && result.y.abs() < 1) {
      throw Exception('Point is too small');
    }

    return result;
  }

  void updateAngleAndGeometry(Point pos) {
    angle = calculateAngle(pos);
    rect = getPageRect(pos);
  }

  double calculateAngle(Point pos) {
    final left = pageWidth - pos.x + 1;
    final top = corner == FlipCorner.bottom ? pageHeight - pos.y : pos.y;

    double angle = 2 * math.acos(left / math.sqrt(top * top + left * left));

    if (top < 0) angle = -angle;

    final da = math.pi - angle;
    if (!angle.isFinite || (da >= 0 && da < 0.003)) {
      throw Exception('The G point is too small');
    }

    if (corner == FlipCorner.bottom) angle = -angle;

    return angle;
  }

  RectPoints getPageRect(Point localPos) {
    if (corner == FlipCorner.top) {
      return getRectFromBasePoint([
        Point(0, 0),
        Point(pageWidth, 0),
        Point(0, pageHeight),
        Point(pageWidth, pageHeight),
      ], localPos);
    }

    return getRectFromBasePoint([
      Point(0, -pageHeight),
      Point(pageWidth, -pageHeight),
      Point(0, 0),
      Point(pageWidth, 0),
    ], localPos);
  }

  RectPoints getRectFromBasePoint(List<Point> points, Point localPos) {
    return RectPoints(
      topLeft: getRotatedPoint(points[0], localPos),
      topRight: getRotatedPoint(points[1], localPos),
      bottomLeft: getRotatedPoint(points[2], localPos),
      bottomRight: getRotatedPoint(points[3], localPos),
    );
  }

  Point getRotatedPoint(Point transformedPoint, Point startPoint) {
    return Point(
      transformedPoint.x * math.cos(angle) +
          transformedPoint.y * math.sin(angle) +
          startPoint.x,
      transformedPoint.y * math.cos(angle) -
          transformedPoint.x * math.sin(angle) +
          startPoint.y,
    );
  }

  void calculateIntersectPoint(Point pos) {
    final boundRect = Rect(
      left: -1,
      top: -1,
      width: pageWidth + 2,
      height: pageHeight + 2,
    );

    if (corner == FlipCorner.top) {
      topIntersectPoint = Helper.getIntersectBetweenTwoSegment(
        boundRect,
        Segment(pos, rect.topRight),
        Segment(Point(0, 0), Point(pageWidth, 0)),
      );

      sideIntersectPoint = Helper.getIntersectBetweenTwoSegment(
        boundRect,
        Segment(pos, rect.bottomLeft),
        Segment(Point(pageWidth, 0), Point(pageWidth, pageHeight)),
      );

      bottomIntersectPoint = Helper.getIntersectBetweenTwoSegment(
        boundRect,
        Segment(rect.bottomLeft, rect.bottomRight),
        Segment(Point(0, pageHeight), Point(pageWidth, pageHeight)),
      );
    } else {
      topIntersectPoint = Helper.getIntersectBetweenTwoSegment(
        boundRect,
        Segment(rect.topLeft, rect.topRight),
        Segment(Point(0, 0), Point(pageWidth, 0)),
      );

      sideIntersectPoint = Helper.getIntersectBetweenTwoSegment(
        boundRect,
        Segment(pos, rect.topLeft),
        Segment(Point(pageWidth, 0), Point(pageWidth, pageHeight)),
      );

      bottomIntersectPoint = Helper.getIntersectBetweenTwoSegment(
        boundRect,
        Segment(rect.bottomLeft, rect.bottomRight),
        Segment(Point(0, pageHeight), Point(pageWidth, pageHeight)),
      );
    }
  }

  Point checkPositionAtCenterLine(
      Point checkedPos,
      Point centerOne,
      Point centerTwo,
      ) {
    Point result = checkedPos;

    final tmp = Helper.limitPointToCircle(centerOne, pageWidth, result);
    if (result != tmp) {
      result = tmp;
      updateAngleAndGeometry(result);
    }

    final rad = math.sqrt(math.pow(pageWidth, 2) + math.pow(pageHeight, 2));

    Point checkPointOne = rect.bottomRight;
    Point checkPointTwo = rect.topLeft;

    if (corner == FlipCorner.bottom) {
      checkPointOne = rect.topRight;
      checkPointTwo = rect.bottomLeft;
    }

    if (checkPointOne.x <= 0) {
      final bottomPoint = Helper.limitPointToCircle(
        centerTwo,
        rad,
        checkPointTwo,
      );

      if (bottomPoint != result) {
        result = bottomPoint;
        updateAngleAndGeometry(result);
      }
    }

    return result;
  }

  Segment getSegmentToShadowLine() {
    final first = getShadowStartPoint();

    final second = first != sideIntersectPoint && sideIntersectPoint != null
        ? sideIntersectPoint!
        : bottomIntersectPoint ?? Point(pageWidth, pageHeight);

    return Segment(first, second);
  }
}
