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

  Path? cachedClipPath;
  List<Point>? _lastAreaSnapshot;

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
      cachedClipPath = null;
      _lastAreaSnapshot = null;
      return null;
    }
    bool unchanged =
        _lastAreaSnapshot != null &&
        _lastAreaSnapshot!.length == state.area.length;
    if (unchanged) {
      for (int i = 0; i < state.area.length; i++) {
        final a = state.area[i];
        final b = _lastAreaSnapshot![i];
        if ((a.x - b.x).abs() > 0.01 || (a.y - b.y).abs() > 0.01) {
          unchanged = false;
          break;
        }
      }
    }
    if (unchanged && cachedClipPath != null) return cachedClipPath;
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
      cachedClipPath = path;
      _lastAreaSnapshot = List.from(state.area);
    } else {
      cachedClipPath = null;
      _lastAreaSnapshot = null;
    }
    return cachedClipPath;
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
}
