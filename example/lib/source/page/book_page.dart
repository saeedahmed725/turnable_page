import '../enums/page_density.dart';
import '../enums/page_orientation.dart';
import '../model/point.dart';

/// Class representing a book page
abstract class BookPage {
  /// Set a constant page density
  void setDensity(PageDensity density);

  /// Set temp page density to next render
  void setDrawingDensity(PageDensity density);

  /// Set page position
  void setPosition(Point pagePos);

  /// Set page angle
  void setAngle(double angle);

  /// Set page crop area
  void setArea(List<Point> area);

  /// Rotate angle for hard pages
  void setHardAngle(double angle);

  /// Set page orientation
  void setOrientation(PageOrientation orientation);

  /// Get a constant page density
  PageDensity getDensity();

  /// Get the temporary copy of the book page
  BookPage getTemporaryCopy();
}
