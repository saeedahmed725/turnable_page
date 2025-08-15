import '../enums/animation_process.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_direction.dart';
import '../flip/flip_settings.dart';
import '../model/page_rect.dart';
import '../model/point.dart';
import '../model/rect_points.dart';
import '../page/book_page.dart';
import '../page/page_flip.dart';

abstract class RenderPage {
  /// Executed when animation frame is called
  void render(double timer);

  /// Start a new animation process
  void startAnimation(
    List<FrameAction> frames,
    double duration,
    AnimationSuccessAction onAnimateEnd,
  );

  /// End the current animation process and call the callback
  void finishAnimation();

  /// Calculate the size and position of the book
  BookOrientation calculateBoundsRect();

  /// Set the current parameters of the drop shadow
  void setShadowData(
    Point pos,
    double angle,
    double progress,
    FlipDirection direction,
  );

  /// Clear shadow
  void clearShadow();

  /// Get parent block offset width
  double getBlockWidth();

  /// Get parent block offset height
  double getBlockHeight();

  /// Get current flipping direction
  FlipDirection? getDirection();

  /// Current size and position of the book
  PageRect getRect();

  /// Get configuration object
  FlipSettings getSettings();

  /// Get current book orientation
  BookOrientation? getOrientation();

  /// Set page area while flipping
  void setPageRect(RectPoints pageRect);

  /// Set flipping direction
  void setDirection(FlipDirection direction);

  /// Set right static book page
  void setRightPage(BookPage? page);

  /// Set left static book page
  void setLeftPage(BookPage? page);

  /// Set next page at the time of flipping
  void setBottomPage(BookPage? page);

  /// Set currently flipping page
  void setFlippingPage(BookPage? page);

  /// Coordinate conversion: Window coordinates -> book coordinates
  Point convertToBook(Point pos);

  /// Coordinate conversion: Window coordinates -> current page coordinates
  Point convertToPage(Point pos, [FlipDirection? direction]);

  /// Coordinate conversion: Page coordinates -> window coordinates
  Point? convertToGlobal(Point? pos, [FlipDirection? direction]);

  /// Casting rectangle corners to window coordinates
  RectPoints convertRectToGlobal(RectPoints rect, [FlipDirection? direction]);

  /// Update the app instance
  void updateApp(PageFlip app);
}
