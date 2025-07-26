import '../basic_types.dart';
import '../settings.dart';
import '../page/page.dart';
import '../flip/flip_enums.dart';

typedef FrameAction = void Function();
typedef AnimationSuccessAction = void Function();

/// Type describing calculated values for drop shadows
class Shadow {
  /// Shadow Position Start Point
  final Point pos;
  /// The angle of the shadows relative to the book
  final double angle;
  /// Base width shadow
  final double width;
  /// Base shadow opacity
  final double opacity;
  /// Flipping Direction, the direction of the shadow gradients
  final FlipDirection direction;
  /// Flipping progress in percent (0 - 100)
  final double progress;

  const Shadow({
    required this.pos,
    required this.angle,
    required this.width,
    required this.opacity,
    required this.direction,
    required this.progress,
  });
}

/// Type describing the animation process
/// Only one animation process can be started at a same time
class AnimationProcess {
  /// List of frames in playback order. Each frame is a function.
  final List<FrameAction> frames;
  /// Total animation duration
  final double duration;
  /// Animation duration of one frame
  final double durationFrame;
  /// Callback at the end of the animation
  final AnimationSuccessAction onAnimateEnd;
  /// Animation start time (Global Timer)
  final double startedAt;

  const AnimationProcess({
    required this.frames,
    required this.duration,
    required this.durationFrame,
    required this.onAnimateEnd,
    required this.startedAt,
  });
}

/// Book orientation
enum BookOrientation {
  portrait('portrait'),
  landscape('landscape');

  const BookOrientation(this.value);
  final String value;
}

/// Class responsible for rendering the book
abstract class Render {
  late final FlipSetting setting;
  late final dynamic app; // PageFlip - will be defined later

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
  PageRect? _boundsRect;

  /// Timer started from start of rendering
  double timer = 0;

  /// Safari browser definitions for resolving a bug with a css property clip-area
  /// https://bugs.webkit.org/show_bug.cgi?id=126207
  bool safari = false;

  Render(this.app, this.setting) {
    // In Flutter, we don't need browser detection like in the original JS
    safari = false;
  }

  /// Rendering action on each frame. The entire rendering process is performed only in this method
  void drawFrame();

  /// Reload the render area, after update pages
  void reload();

  /// Executed when animation frame is called. Performs the current animation process and call drawFrame()
  void render(double timer) {
    if (animation != null) {
      // Find current frame of animation
      final frameIndex = ((timer - animation!.startedAt) / animation!.durationFrame).round();

      if (frameIndex < animation!.frames.length) {
        animation!.frames[frameIndex]();
      } else {
        animation!.onAnimateEnd();
        
        // Trigger animation complete event
        app.trigger('animationComplete', app, null);
        
        animation = null;
      }
    }

    this.timer = timer;
    drawFrame();
  }

  /// Running animation frame, and rendering process
  void start() {
    update();
    // In Flutter, we would use something like Ticker or AnimationController
    // This is a simplified version - actual implementation would depend on Flutter's animation system
  }

  /// Start a new animation process
  ///
  /// @param {List<FrameAction>} frames - Frame list
  /// @param {double} duration - total animation duration
  /// @param {AnimationSuccessAction} onAnimateEnd - Animation callback function
  void startAnimation(
    List<FrameAction> frames,
    double duration,
    AnimationSuccessAction onAnimateEnd,
  ) {
    finishAnimation(); // finish the previous animation process

    animation = AnimationProcess(
      frames: frames,
      duration: duration,
      durationFrame: duration / frames.length,
      onAnimateEnd: onAnimateEnd,
      startedAt: timer,
    );
  }

  /// End the current animation process and call the callback
  void finishAnimation() {
    if (animation != null) {
      animation!.frames[animation!.frames.length - 1]();

      animation!.onAnimateEnd();
      
      // Trigger animation complete event
      app.trigger('animationComplete', app, null);
    }

    animation = null;
  }

  /// Recalculate the size of the displayed area, and update the page orientation
  void update() {
    _boundsRect = null;
    final newOrientation = calculateBoundsRect();

    if (orientation != newOrientation) {
      orientation = newOrientation;
      app.updateOrientation(newOrientation);
    }
  }

  /// Calculate the size and position of the book depending on the parent element and configuration parameters
  BookOrientation calculateBoundsRect() {
    BookOrientation orientation = BookOrientation.landscape;

    final blockWidth = getBlockWidth();
    final middlePoint = Point(
      blockWidth / 2,
      getBlockHeight() / 2,
    );

    final ratio = setting.width / setting.height;

    double pageWidth = setting.width;
    double pageHeight = setting.height;

    double left = middlePoint.x - pageWidth;

    if (setting.size == SizeType.stretch) {
      if (blockWidth < setting.minWidth * 2 && app.getSettings().usePortrait) {
        orientation = BookOrientation.portrait;
      }

      pageWidth = orientation == BookOrientation.portrait
          ? getBlockWidth()
          : getBlockWidth() / 2;

      if (pageWidth > setting.maxWidth) pageWidth = setting.maxWidth;

      pageHeight = pageWidth / ratio;
      if (pageHeight > getBlockHeight()) {
        pageHeight = getBlockHeight();
        pageWidth = pageHeight * ratio;
      }

      left = orientation == BookOrientation.portrait
          ? middlePoint.x - pageWidth / 2 - pageWidth
          : middlePoint.x - pageWidth;
    } else {
      if (blockWidth < pageWidth * 2) {
        if (app.getSettings().usePortrait) {
          orientation = BookOrientation.portrait;
          left = middlePoint.x - pageWidth / 2 - pageWidth;
        }
      }
    }

    _boundsRect = PageRect(
      left: left,
      top: middlePoint.y - pageHeight / 2,
      width: pageWidth * 2,
      height: pageHeight,
      pageWidth: pageWidth,
    );

    return orientation;
  }

  /// Set the current parameters of the drop shadow
  ///
  /// @param {Point} pos - Shadow Position Start Point
  /// @param {double} angle - The angle of the shadows relative to the book
  /// @param {double} progress - Flipping progress in percent (0 - 100)
  /// @param {FlipDirection} direction - Flipping Direction, the direction of the shadow gradients
  void setShadowData(
    Point pos,
    double angle,
    double progress,
    FlipDirection direction,
  ) {
    if (!app.getSettings().drawShadow) return;

    final maxShadowOpacity = 100 * getSettings().maxShadowOpacity;

    shadow = Shadow(
      pos: pos,
      angle: angle,
      width: (((getRect().pageWidth * 3) / 4) * progress) / 100,
      opacity: ((100 - progress) * maxShadowOpacity) / 100 / 100,
      direction: direction,
      progress: progress * 2,
    );
  }

  /// Clear shadow
  void clearShadow() {
    shadow = null;
  }

  /// Get parent block offset width
  double getBlockWidth() {
    // In Flutter, we get size from settings rather than DOM elements
    return app.getSettings().width;
  }

  /// Get parent block offset height
  double getBlockHeight() {
    // In Flutter, we get size from settings rather than DOM elements
    return app.getSettings().height;
  }

  /// Get current flipping direction
  FlipDirection? getDirection() {
    return direction;
  }

  /// Current size and position of the book
  PageRect getRect() {
    if (_boundsRect == null) calculateBoundsRect();
    return _boundsRect!;
  }

  /// Get configuration object
  FlipSetting getSettings() {
    return app.getSettings();
  }

  /// Get current book orientation
  BookOrientation? getOrientation() {
    return orientation;
  }

  /// Set page area while flipping
  void setPageRect(RectPoints pageRect) {
    this.pageRect = pageRect;
  }

  /// Set flipping direction
  void setDirection(FlipDirection direction) {
    this.direction = direction;
  }

  /// Set right static book page
  void setRightPage(BookPage? page) {
    if (page != null) page.setOrientation(PageOrientation.right);
    rightPage = page;
  }

  /// Set left static book page
  void setLeftPage(BookPage? page) {
    if (page != null) page.setOrientation(PageOrientation.left);
    leftPage = page;
  }

  /// Set next page at the time of flipping
  void setBottomPage(BookPage? page) {
    if (page != null) {
      page.setOrientation(
        direction == FlipDirection.back ? PageOrientation.left : PageOrientation.right,
      );
    }
    bottomPage = page;
  }

  /// Set currently flipping page
  void setFlippingPage(BookPage? page) {
    if (page != null) {
      page.setOrientation(
        direction == FlipDirection.forward && orientation != BookOrientation.portrait
            ? PageOrientation.left
            : PageOrientation.right,
      );
    }
    flippingPage = page;
  }

  /// Coordinate conversion function. Window coordinates -> to book coordinates
  ///
  /// @param {Point} pos - Global coordinates relative to the window
  /// @returns {Point} Coordinates relative to the book
  Point convertToBook(Point pos) {
    final rect = getRect();
    return Point(
      pos.x - rect.left,
      pos.y - rect.top,
    );
  }

  bool isSafari() {
    return safari;
  }

  /// Coordinate conversion function. Window coordinates -> to current coordinates of the working page
  ///
  /// @param {Point} pos - Global coordinates relative to the window
  /// @param {FlipDirection} direction - Current flipping direction
  ///
  /// @returns {Point} Coordinates relative to the work page
  Point convertToPage(Point pos, [FlipDirection? direction]) {
    direction ??= this.direction;

    final rect = getRect();
    final x = direction == FlipDirection.forward
        ? pos.x - rect.left - rect.width / 2
        : rect.width / 2 - pos.x + rect.left;

    return Point(x, pos.y - rect.top);
  }

  /// Coordinate conversion function. Coordinates relative to the work page -> Window coordinates
  ///
  /// @param {Point} pos - Coordinates relative to the work page
  /// @param {FlipDirection} direction - Current flipping direction
  ///
  /// @returns {Point} Global coordinates relative to the window
  Point? convertToGlobal(Point? pos, [FlipDirection? direction]) {
    direction ??= this.direction;

    if (pos == null) return null;

    final rect = getRect();

    final x = direction == FlipDirection.forward
        ? pos.x + rect.left + rect.width / 2
        : rect.width / 2 - pos.x + rect.left;

    return Point(x, pos.y + rect.top);
  }

  /// Casting the coordinates of the corners of the rectangle in the coordinates relative to the window
  ///
  /// @param {RectPoints} rect - Coordinates of the corners of the rectangle relative to the work page
  /// @param {FlipDirection} direction - Current flipping direction
  ///
  /// @returns {RectPoints} Coordinates of the corners of the rectangle relative to the window
  RectPoints convertRectToGlobal(RectPoints rect, [FlipDirection? direction]) {
    direction ??= this.direction;

    return RectPoints(
      topLeft: convertToGlobal(rect.topLeft, direction)!,
      topRight: convertToGlobal(rect.topRight, direction)!,
      bottomLeft: convertToGlobal(rect.bottomLeft, direction)!,
      bottomRight: convertToGlobal(rect.bottomRight, direction)!,
    );
  }
}
