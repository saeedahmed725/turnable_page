import '../enums/page_density.dart';
import '../enums/page_orientation.dart';
import '../model/point.dart';

/// Class representing a book page
abstract class BookPage {
  // (Removed legacy drawing hooks: simpleDraw, draw) Rendering handled centrally by RenderTurnableBook.

  /// Set a constant page density
  ///
  /// @param {PageDensity} density
  void setDensity(PageDensity density);

  /// Set temp page density to next render
  ///
  /// @param {PageDensity}  density
  void setDrawingDensity(PageDensity density);

  /// Set page position
  ///
  /// @param {Point} pagePos
  void setPosition(Point pagePos);

  /// Set page angle
  ///
  /// @param {double} angle
  void setAngle(double angle);

  /// Set page crop area
  ///
  void setArea(List<Point> area);

  /// Rotate angle for hard pages to next render
  ///
  /// @param {double} angle
  void setHardDrawingAngle(double angle);

  /// Rotate angle for hard pages
  ///
  /// @param {double} angle
  void setHardAngle(double angle);

  /// Set page orientation
  ///
  /// @param {PageOrientation} orientation
  void setOrientation(PageOrientation orientation);

  /// Get temp page density
  PageDensity getDrawingDensity();

  /// Get a constant page density
  PageDensity getDensity();

  /// Get the temporary copy of the book page
  BookPage getTemporaryCopy();
}
