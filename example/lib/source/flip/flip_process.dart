import 'dart:math' as math;

import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flip_direction.dart';
import '../enums/flipping_state.dart';
import '../enums/page_density.dart';
import '../helpers/helper.dart';
import '../model/page_rect.dart';
import '../model/point.dart';
import '../page/book_page.dart';
import '../page/page_flip.dart';
import '../render/render_page.dart';
import 'flip_calculation.dart';

/// Class representing the flipping process
class FlipProcess {
  late RenderPage render;
  late PageFlip app;

  BookPage? flippingPage;
  BookPage? bottomPage;

  FlipCalculation? calc;

  FlippingState state = FlippingState.read;

  FlipProcess(this.app, this.render) {
    reset();
  }

  void updateApp(PageFlip app, RenderPage render) {
    this.render = render;
    this.app = app;
  }

  /// Called when the page folding (User drags page corner)
  ///
  /// @param globalPos - Touch Point Coordinates (relative window)
  void fold(Point globalPos) {
    setState(FlippingState.userFold);

    // If the process has not started yet
    if (calc == null) start(globalPos);

    doCalculation(render.convertToPage(globalPos));
  }

  /// Page turning with animation
  ///
  /// @param globalPos - Touch Point Coordinates (relative window)
  void flip(Point globalPos) {
    if (app.getSettings.disableFlipByClick && !isPointOnCorners(globalPos)) {
      return;
    }

    // the flipping process is already running
    if (calc != null) render.finishAnimation();

    if (!start(globalPos)) return;

    final rect = getBoundsRect();

    setState(FlippingState.flipping);

    // Margin from top to start flipping
    final topMargins = rect.height / 10;

    // Defining animation start points
    final yStart = calc!.getCorner() == FlipCorner.bottom
        ? rect.height - topMargins
        : topMargins;

    final yDest = calc!.getCorner() == FlipCorner.bottom ? rect.height : 0;

    // Calculations for these points
    calc!.calc(Point(rect.pageWidth - topMargins, yStart));

    // Run flipping animation
    animateFlippingTo(
      Point(rect.pageWidth - topMargins, yStart),
      Point(-rect.pageWidth.toDouble(), yDest.toDouble()),
      true,
    );
  }

  /// Start the flipping process. Find direction and corner of flipping. Creating an object for calculation.
  ///
  /// @param {Point} globalPos - Touch Point Coordinates (relative window)
  ///
  /// @returns {bool} True if flipping is possible, false otherwise
  bool start(Point globalPos) {
    reset();

    // Convert the global position to book coordinates
    final bookPos = render.convertToBook(globalPos);
    final rect = getBoundsRect();

    // Determine the flipping direction based on the touch position
    final direction = getDirectionByPoint(bookPos);

    // Determine the active corner (top or bottom)
    final flipCorner = bookPos.y >= rect.height / 2
        ? FlipCorner.bottom
        : FlipCorner.top;

    // Check if flipping in this direction is allowed
    if (!checkDirection(direction)) return false;

    try {
      // Get the flipping and bottom pages from the page collection
      final pageCollection = app.getPageCollection();
      flippingPage = pageCollection?.getFlippingPage(direction);
      bottomPage = pageCollection?.getBottomPage(direction);

      // Handle page density for landscape and portrait modes
      if (render.getOrientation() == BookOrientation.landscape) {
        if (direction == FlipDirection.back) {
          // In landscape, for back direction, check the next page's density
          final nextPage = pageCollection?.nextBy(flippingPage!);
          if (nextPage != null && flippingPage != null) {
            if (flippingPage!.getDensity() != nextPage.getDensity()) {
              flippingPage!.setDrawingDensity(PageDensity.hard);
              nextPage.setDrawingDensity(PageDensity.hard);
            }
          }
        } else {
          // In landscape, for forward direction, check the previous page's density
          final prevPage = pageCollection?.prevBy(flippingPage!);
          if (prevPage != null && flippingPage != null) {
            if (flippingPage!.getDensity() != prevPage.getDensity()) {
              flippingPage!.setDrawingDensity(PageDensity.hard);
              prevPage.setDrawingDensity(PageDensity.hard);
            }
          }
        }
      }

      // Set the flipping direction in the render
      render.setDirection(direction);

      // Create the calculation object for flipping
      calc = FlipCalculation(
        direction,
        flipCorner,
        rect.pageWidth,
        rect.height,
      );

      return true;
    } catch (e) {
      // If any error occurs, flipping is not possible
      return false;
    }
  }

  /// Perform calculations for the current page position. Pass data to render object
  ///
  /// @param {Point} pagePos - Touch Point Coordinates (relative active page)
  void doCalculation(Point pagePos) {
    if (calc == null) return; // Flipping process not started

    if (calc!.calc(pagePos)) {
      // Perform calculations for a specific position
      final progress = calc!.getFlippingProgress();
      final settings = app.getSettings;

      bottomPage?.setArea(calc!.getBottomClipArea());
      bottomPage?.setPosition(calc!.getBottomPagePosition());
      bottomPage?.setAngle(0);
      bottomPage?.setHardAngle(0);

      flippingPage?.setArea(calc!.getFlippingClipArea());
      flippingPage?.setPosition(calc!.getActiveCorner());
      flippingPage?.setAngle(calc!.getAngle());

      // Enhanced hard angle calculation with bend strength and smoother progression
      if (state == FlippingState.userFold || state == FlippingState.foldCorner) {
        // During user interaction, apply realistic bending based on progress and settings
        final normalizedProgress = progress / 100.0; // 0-1 range
        final bendMultiplier = settings.bendStrength;
        
        // Create smoother bend progression with easing
        final easedProgress = settings.enableEasing 
            ? _easeOutCubic(normalizedProgress) 
            : normalizedProgress;
        
        // Calculate hard angle with improved physics
        final maxAngle = 90.0;
        final bendAngle = maxAngle * (1 - easedProgress * bendMultiplier);
        
        if (calc!.getDirection() == FlipDirection.forward) {
          flippingPage?.setHardAngle(bendAngle);
        } else {
          flippingPage?.setHardAngle(-bendAngle);
        }
      }
      // Note: During animation, hard angle is set in animateFlippingTo for frame-by-frame control

      render.setPageRect(calc!.getRect());
      render.setBottomPage(bottomPage);
      render.setFlippingPage(flippingPage);
      render.setShadowData(
        calc!.getShadowStartPoint(),
        calc!.getShadowAngle(),
        progress,
        calc!.getDirection(),
      );
    }
  }

  /// Flip to specific page with animation
  ///
  /// @param {int} page - Page number
  /// @param {FlipCorner} corner - Active corner when turning
  void flipToPage(int page, FlipCorner corner) {
    final current = app.getPageCollection()?.getCurrentSpreadIndex() ?? 0;
    final next = app.getPageCollection()?.getSpreadIndexByPage(page) ?? 0;

    try {
      if (next > current) {
        app.getPageCollection()?.setCurrentSpreadIndex(next - 1);
        flipNext(corner);
      }
      if (next < current) {
        app.getPageCollection()?.setCurrentSpreadIndex(next + 1);
        flipPrev(corner);
      }
    } catch (e) {
      // ignore
    }
  }

  /// Turn to the next page (with animation)
  ///
  /// @param {FlipCorner} corner - Active page corner when turning
  void flipNext(FlipCorner corner) {
    final rect = getBoundsRect();
    flip(
      Point(
        rect.left + rect.pageWidth * 2 - 10,
        corner == FlipCorner.top ? 1 : rect.height - 2,
      ),
    );
  }

  /// Turn to the previous page (with animation)
  ///
  /// @param {FlipCorner} corner - Active page corner when turning
  void flipPrev(FlipCorner corner) {
    final rect = getBoundsRect();
    flip(Point(10, corner == FlipCorner.top ? 1 : rect.height - 2));
  }

  /// Called when the user has stopped flipping
  void stopMove() {
    if (calc == null) return;

    final pos = calc!.getPosition();
    final rect = getBoundsRect();

    final y = calc!.getCorner() == FlipCorner.bottom ? rect.height : 0;

    // Use proper progress-based threshold for smooth page turning
    final progress = calc!.getFlippingProgress() / 100.0; // Convert to 0-1 range
    
    // Apply threshold-based flipping:
    // If progress > 50%, complete the flip animation smoothly
    // If progress <= 50%, animate back to original position smoothly
    if (progress > 0.5) {
      // Complete the flip - animate to the opposite side
      animateFlippingTo(
        pos,
        Point(-rect.pageWidth.toDouble(), y.toDouble()),
        true,
      );
    } else {
      // Snap back - animate back to original position
      animateFlippingTo(
        pos,
        Point(rect.pageWidth.toDouble(), y.toDouble()),
        false,
      );
    }
  }

  /// Stop move with inertia consideration
  void stopMoveWithInertia(bool fastSwipe, double velocity) {
    if (calc == null) return;
    
    final pos = calc!.getPosition();
    final rect = getBoundsRect();
    final y = calc!.getCorner() == FlipCorner.bottom ? rect.height : 0;
    final settings = app.getSettings;
    
    double progress = calc!.getFlippingProgress() / 100.0; // 0-1
    bool complete;
    
    if (fastSwipe) {
      // For fast swipes, project additional progress based on velocity direction
      final dirForward = calc!.getDirection() == FlipDirection.forward;
      final swipeTowardsCenter = dirForward ? velocity < 0 : velocity > 0;
      if (swipeTowardsCenter) {
        progress += settings.inertiaProgressBoost;
      }
      complete = progress >= 0.5;
    } else {
      // Use same progress-based threshold for consistency with stopMove
      complete = progress > 0.5;
    }
    
    if (complete) {
      animateFlippingTo(
        pos,
        Point(-rect.pageWidth.toDouble(), y.toDouble()),
        true,
      );
    } else {
      animateFlippingTo(
        pos,
        Point(rect.pageWidth.toDouble(), y.toDouble()),
        false,
      );
    }
  }

  /// Fold the corners of the book when the mouse pointer is over them.
  /// Called when the mouse pointer is over the book without clicking
  ///
  /// @param globalPos - Touch Point Coordinates (relative window)
  void showCorner(Point globalPos) {
    if (!checkState([FlippingState.read, FlippingState.foldCorner])) return;

    final rect = getBoundsRect();
    final pageWidth = rect.pageWidth;

    if (isPointOnCorners(globalPos)) {
      if (calc == null) {
        if (!start(globalPos)) return;

        setState(FlippingState.foldCorner);

        calc!.calc(Point(pageWidth - 1, 1));

        const fixedCornerSize = 50.0;
        final yStart = calc!.getCorner() == FlipCorner.bottom
            ? rect.height - 1
            : 1;

        final yDest = calc!.getCorner() == FlipCorner.bottom
            ? rect.height - fixedCornerSize
            : fixedCornerSize;

        animateFlippingTo(
          Point(pageWidth - 1, yStart.toDouble()),
          Point(pageWidth - fixedCornerSize, yDest),
          false,
          false,
        );
      } else {
        doCalculation(render.convertToPage(globalPos));
      }
    } else {
      setState(FlippingState.read);
      render.finishAnimation();
      stopMove();
    }
  }

  /// Animation function. Animates flipping process with improved physics and easing
  void animateFlippingTo(
    Point start,
    Point dest,
    bool isTurned, [
    bool needReset = true,
  ]) {
    final settings = app.getSettings;
    
    // Build parametric path with physics-based animation instead of linear pixel steps
    final distance = Helper.getDistanceBetweenTwoPoint(start, dest);
    
    // Calculate optimal frame count based on distance and settings
    final estFrames = distance.clamp(120, 900).toInt();
    final frames = <void Function()>[];
    
    // Get visual enhancement settings
    final sagAmp = settings.sagAmplitude * getBoundsRect().height;
    
    for (int i = 0; i <= estFrames; i++) {
      final tRaw = i / estFrames; // 0..1
      
      // Apply easing curve for smooth animation
      final t = settings.enableEasing ? _easeOutCubic(tRaw) : tRaw;
      
      // Interpolate x position linearly
      final x = start.x + (dest.x - start.x) * t;
      
      // Add realistic page sag effect for y position
      final baseY = start.y + (dest.y - start.y) * t;
      final sag = math.sin(math.pi * t) * sagAmp;
      
      // Direction of sag depends on corner (top => positive downward)
      final corner = calc?.getCorner() ?? FlipCorner.top;
      final y = corner == FlipCorner.top ? baseY + sag : baseY - sag;
      
      frames.add(() {
        doCalculation(Point(x, y));
        
        // Adjust hard angle bending progressively to simulate paper stiffness
        if (flippingPage != null && calc != null) {
          final prog = calc!.getFlippingProgress(); // 0-100
          final bend = settings.bendStrength;
          final eased = settings.enableEasing ? _easeOutCubic(prog / 100) : prog / 100;
          final targetHard = 90 * (1 - eased * bend);
          
          flippingPage!.setHardAngle(
            calc!.getDirection() == FlipDirection.forward ? targetHard : -targetHard,
          );
        }
      });
    }
    
    final duration = _getAnimationDuration(frames.length);
    
    render.startAnimation(frames, duration, () {
      if (calc == null) return;

      if (isTurned) {
        if (calc!.getDirection() == FlipDirection.back) {
          app.turnToPrevPage();
        } else {
          app.turnToNextPage();
        }
      }

      if (needReset) {
        render.setBottomPage(null);
        render.setFlippingPage(null);
        render.clearShadow();

        setState(FlippingState.read);
        reset();
      }
    });
  }

  /// Cubic easing function for smooth animations
  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  /// Get animation duration for the given number of frames
  double _getAnimationDuration(int frameCount) {
    final defaultTime = app.getSettings.flippingTime.toDouble(); // milliseconds

    if (frameCount >= 1000) {
      return defaultTime;
    }

    return (frameCount / 1000) * defaultTime;
  }

  /// Get flip calculation object
  FlipCalculation? getCalculation() {
    return calc;
  }

  /// Get current flipping state
  FlippingState getState() {
    return state;
  }

  /// Set flipping state and call state change event
  void setState(FlippingState newState) {
    if (state != newState) {
      app.updateState(newState);
      state = newState;
    }
  }

  /// Get current flipping direction
  FlipDirection getDirectionByPoint(Point touchPos) {
    final rect = getBoundsRect();

    if (render.getOrientation() == BookOrientation.portrait) {
      if (touchPos.x - rect.pageWidth <= rect.width / 5) {
        return FlipDirection.back;
      }
    } else if (touchPos.x < rect.width / 2) {
      return FlipDirection.back;
    }

    return FlipDirection.forward;
  }

  /// Check if the flipping direction is available
  bool checkDirection(FlipDirection direction) {
    if (direction == FlipDirection.forward) {
      return app.getCurrentPageIndex() < app.getPageCount() - 1;
    }
    return app.getCurrentPageIndex() >= 1;
  }

  /// Reset the current flipping process
  void reset() {
    calc = null;
    flippingPage = null;
    bottomPage = null;
  }

  /// Get book bounds rectangle
  PageRect getBoundsRect() {
    return render.getRect();
  }

  /// Check current state - supports multiple states like TypeScript version
  bool checkState(List<FlippingState> states) {
    return states.contains(state);
  }

  /// Check if point is on page corners
  bool isPointOnCorners(Point globalPos) {
    final rect = getBoundsRect();
    final pageWidth = rect.pageWidth;

    final operatingDistance =
        math.sqrt(math.pow(pageWidth, 2) + math.pow(rect.height, 2)) / 5;

    final bookPos = render.convertToBook(globalPos);

    return bookPos.x > 0 &&
        bookPos.y > 0 &&
        bookPos.x < rect.width &&
        bookPos.y < rect.height &&
        (bookPos.x < operatingDistance ||
            bookPos.x > rect.width - operatingDistance) &&
        (bookPos.y < operatingDistance ||
            bookPos.y > rect.height - operatingDistance);
  }
}
