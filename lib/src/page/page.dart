import '../basic_types.dart';
import '../render/render.dart';

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
  })  : area = area ?? [],
        position = position ?? const Point(0, 0);
}

enum PageOrientation {
  /// Left side page
  left,

  /// Right side page
  right,
}

enum PageDensity {
  soft('soft'),
  hard('hard');

  const PageDensity(this.value);
  final String value;
}

/// Class representing a book page
abstract class BookPage {
  /// State of the page on the basis of which rendering
  late final PageState state;
  /// Render object
  late final Render render;

  /// Page Orientation
  late PageOrientation orientation;

  /// Density at creation
  late final PageDensity createdDensity;
  /// Density at the time of rendering (Depends on neighboring pages)
  late PageDensity nowDrawingDensity;

  BookPage(this.render, PageDensity density) {
    state = PageState();
    createdDensity = density;
    nowDrawingDensity = createdDensity;
  }

  /// Render static page
  /// 
  /// @param {PageOrientation} orient - Static page orientation
  void simpleDraw(PageOrientation orient);

  /// Render dynamic page, using state
  /// 
  /// @param {PageDensity} tempDensity - Density at the time of rendering 
  void draw([PageDensity? tempDensity]);

  /// Page loading
  void load();

  /// Set a constant page density
  /// 
  /// @param {PageDensity} density 
  void setDensity(PageDensity density) {
    // Note: In Dart, we can't modify final fields after initialization
    // This would need to be handled differently in the concrete implementations
    nowDrawingDensity = density;
  }

  /// Set temp page density to next render
  /// 
  /// @param {PageDensity}  density 
  void setDrawingDensity(PageDensity density) {
    nowDrawingDensity = density;
  }

  /// Set page position
  /// 
  /// @param {Point} pagePos 
  void setPosition(Point pagePos) {
    state.position = pagePos;
  }

  /// Set page angle
  /// 
  /// @param {double} angle 
  void setAngle(double angle) {
    state.angle = angle;
  }

  /// Set page crop area
  /// 
  /// @param {List<Point>} area 
  void setArea(List<Point> area) {
    state.area = area;
  }

  /// Rotate angle for hard pages to next render
  /// 
  /// @param {double} angle 
  void setHardDrawingAngle(double angle) {
    state.hardDrawingAngle = angle;
  }

  /// Rotate angle for hard pages
  /// 
  /// @param {double} angle 
  void setHardAngle(double angle) {
    state.hardAngle = angle;
    state.hardDrawingAngle = angle;
  }

  /// Set page orientation
  /// 
  /// @param {PageOrientation} orientation 
  void setOrientation(PageOrientation orientation) {
    this.orientation = orientation;
  }

  /// Get temp page density
  PageDensity getDrawingDensity() {
    return nowDrawingDensity;
  }

  /// Get a constant page density
  PageDensity getDensity() {
    return createdDensity;
  }
  
  /// Get rotate angle for hard pages
  double getHardAngle() {
    return state.hardAngle;
  }

  BookPage newTemporaryCopy();
  BookPage getTemporaryCopy();
  void hideTemporaryCopy();
}
