import 'package:flutter/material.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_direction.dart';
import '../model/point.dart';
import '../enums/animation_process.dart';
import '../model/page_rect.dart';
import '../model/rect_points.dart';
import '../model/shadow.dart';
import '../page/page_flip.dart';
import '../flip/flip_settings.dart';
import '../page/book_page.dart';

/// Abstract class responsible for rendering the book
abstract class Render {
  late PageFlip app; // PageFlip - will be defined later

  /// Left static book page
  BookPage? leftPage;

  /// Right static book page
  BookPage? rightPage;

  /// Page currently flipping
  BookPage? flippingPage;

  /// Next page at the time of flipping
  BookPage? bottomPage;

  /// Current flipping direction
  FlipDirection? direction;

  /// Current book orientation
  BookOrientation? orientation;

  /// Current state of the shadows
  Shadow? shadow;

  /// Current animation process
  AnimationProcess? animation;

  /// Page borders while flipping
  RectPoints? pageRect;

  /// Current book area
  PageRect? boundsRect;

  /// Timer started from start of rendering
  double timer = 0;

  /// Safari browser definitions for resolving a bug with a css property clip-area

  Render(this.app);

  /// Rendering action on each frame
  void drawFrame();

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
  FlipSetting getSettings();

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

  /// Get the canvas for rendering
  Canvas getCanvas();

  /// Set the canvas and size for rendering
  void setCanvas(Canvas canvas, Size size);

  /// Draw book shadow (spine shadow)
  void drawBookShadow();

  /// Draw outer shadow
  void drawOuterShadow();

  /// Draw inner shadow
  void drawInnerShadow();

  /// Update the app instance
  void updateApp(PageFlip app);
}
