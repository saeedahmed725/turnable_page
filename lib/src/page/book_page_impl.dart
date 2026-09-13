import 'package:flutter/widgets.dart';

import '../enums/page_density.dart';
import '../enums/page_orientation.dart';
import '../model/page_state.dart';
import '../model/point.dart';
import 'book_page.dart';

class BookPageImpl extends BookPage {
  final int index;
  final PageState state = PageState();
  PageDensity createdDensity;
  PageDensity drawingDensity;
  PageOrientation orientation = PageOrientation.right;

  BookPageImpl({required this.index, this.createdDensity = PageDensity.hard})
    : drawingDensity = createdDensity;

  @override
  void setDensity(PageDensity density) => createdDensity = density;

  @override
  void setDrawingDensity(PageDensity density) => drawingDensity = density;

  @override
  void setPosition(Point pagePos) => state.position = pagePos;

  @override
  void setAngle(double angle) => state.angle = angle;

  @override
  void setArea(List<Point> area) => state.area = area;

  Path? buildOrGetClipPath(
    Point? globalOrigin,
    Point Function(Point) toGlobal,
  ) {
    if (state.area.isEmpty || globalOrigin == null) {
      return null;
    }
    final path = Path();
    bool first = true;
    for (final p in state.area) {
      final gp = toGlobal(p);
      final local = Offset(gp.x - globalOrigin.x, gp.y - globalOrigin.y);
      if (first) {
        path.moveTo(local.dx, local.dy);
        first = false;
      } else {
        path.lineTo(local.dx, local.dy);
      }
    }
    if (!first) {
      path.close();
      return path;
    }
    return null;
  }

  @override
  void setHardAngle(double angle) {
    state.hardAngle = angle;
    state.hardDrawingAngle = angle;
  }

  @override
  void setOrientation(PageOrientation orientation) =>
      this.orientation = orientation;

  @override
  PageDensity getDensity() => createdDensity;

  @override
  BookPage getTemporaryCopy() => this;
  // Create a lightweight temporary copy with independent state to avoid shared
  // mutation artifacts during flipping (prevents flicker from double painting).
  BookPage createDetachedCopy() {
    final copy = BookPageImpl(index: index, createdDensity: createdDensity)
      ..orientation = orientation;
    return copy;
  }
}
