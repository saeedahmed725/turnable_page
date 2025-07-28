import 'dart:math' as math;

import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flip_direction.dart';
import '../enums/flipping_state.dart';
import '../enums/page_density.dart';
import '../model/page_rect.dart';
import '../model/point.dart';
import '../page/book_page.dart';
import '../render/render.dart';
import 'flip_calculation.dart';
import '../page/page_flip.dart';

/// Class representing the flipping process
class FlipProcess {
  late Render render;
  late PageFlip app;

  BookPage? flippingPage;
  BookPage? bottomPage;

  FlipCalculation? calc;

  FlippingState state = FlippingState.read;

  FlipProcess(this.app, this.render) {
    // Initialize the flipping process
    reset();
  }

  void updateApp(PageFlip app, Render render) {
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
        rect.pageWidth.toString(),
        rect.height.toString(),
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

      bottomPage?.setArea(calc!.getBottomClipArea());
      bottomPage?.setPosition(calc!.getBottomPagePosition());
      bottomPage?.setAngle(0);
      bottomPage?.setHardAngle(0);

      flippingPage?.setArea(calc!.getFlippingClipArea());
      flippingPage?.setPosition(calc!.getActiveCorner());
      flippingPage?.setAngle(calc!.getAngle());

      if (calc!.getDirection() == FlipDirection.forward) {
        flippingPage?.setHardAngle((90 * (200 - progress * 2)) / 100);
      } else {
        flippingPage?.setHardAngle((-90 * (200 - progress * 2)) / 100);
      }

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
    final current = app.getCurrentPageIndex();

    if (page == current || app.getPageCount() == 0) return;

    if (page > current) {
      app.getPageCollection()?.show(page - 1);
      flipNext(corner);
    } else {
      app.getPageCollection()?.show(page + 1);
      flipPrev(corner);
    }
  }

  /// Turn to the next page (with animation)
  ///
  /// @param {FlipCorner} corner - Active page corner when turning
  void flipNext(FlipCorner corner) {
    startFlipping(FlipDirection.forward, corner);
  }

  /// Turn to the previous page (with animation)
  ///
  /// @param {FlipCorner} corner - Active page corner when turning
  void flipPrev(FlipCorner corner) {
    startFlipping(FlipDirection.back, corner);
  }

  /// Finish flipping. Hide flipping page
  void stopMove() {
    if (calc == null) return;

    final pos = calc!.getPosition();
    final rect = getBoundsRect();

    final y = calc!.getCorner() == FlipCorner.bottom ? rect.height : 0;

    // React logic: check if position is beyond the center threshold
    // If pos.x <= 0 (dragged past center), complete the flip
    // If pos.x > 0 (still near the edge), snap back
    if (pos.x <= 0) {
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

  /// Get current flipping state
  FlippingState getState() {
    return state;
  }

  /// Set flipping state and call state change event
  void setState(FlippingState newState) {
    if (state != newState) {
      state = newState;
      app.updateState(newState);
    }
  }

  /// Animation function. Animates flipping process
  void animateFlippingTo(
    Point start,
    Point dest,
    bool isTurned, [
    bool needReset = true,
  ]) {
    final frames = <void Function()>[];

    // Use the same logic as React's GetCordsFromTwoPoint
    final points = _getCordsFromTwoPoint(start, dest);

    // Create frames for each point
    for (final point in points) {
      frames.add(() {
        doCalculation(point);
      });
    }

    final duration = _getAnimationDuration(points.length);

    render.startAnimation(frames, duration, () {
      if (isTurned) {
        if (calc!.getDirection() == FlipDirection.forward) {
          app.getPageCollection()?.showNext();
        } else {
          app.getPageCollection()?.showPrev();
        }
      }

      if (needReset) {
        reset();
        setState(FlippingState.read);
      }

      // Notify the app that animation is complete
      app.trigger('animationComplete', app, {});
    });
  }

  /// Generate interpolated points between two points (React's GetCordsFromTwoPoint logic)
  List<Point> _getCordsFromTwoPoint(Point pointOne, Point pointTwo) {
    final sizeX = (pointOne.x - pointTwo.x).abs();
    final sizeY = (pointOne.y - pointTwo.y).abs();

    final lengthLine = math.max(sizeX, sizeY).toInt();

    final result = <Point>[pointOne];

    double getCord(double c1, double c2, double size, int length, int index) {
      if (c2 > c1) {
        return c1 + index * (size / length);
      } else if (c2 < c1) {
        return c1 - index * (size / length);
      }
      return c1;
    }

    for (int i = 1; i <= lengthLine; i++) {
      result.add(
        Point(
          getCord(pointOne.x, pointTwo.x, sizeX, lengthLine, i),
          getCord(pointOne.y, pointTwo.y, sizeY, lengthLine, i),
        ),
      );
    }

    return result;
  }

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

  /// Get current flipping direction
  FlipDirection getDirectionByPoint(Point touchPos) {
    final rect = getBoundsRect();

    if (render.getOrientation() == BookOrientation.portrait) {
      return touchPos.x < rect.pageWidth
          ? FlipDirection.back
          : FlipDirection.forward;
    }

    return touchPos.x < rect.width / 2
        ? FlipDirection.back
        : FlipDirection.forward;
  }

  /// Check if the flipping direction is available
  bool checkDirection(FlipDirection direction) {
    if (direction == FlipDirection.forward) {
      return app.getCurrentPageIndex() < app.getPageCount() - 1;
    }

    return app.getCurrentPageIndex() > 0;
  }

  /// Reset the current flipping process
  void reset() {
    calc = null;
    flippingPage = null;
    bottomPage = null;

    render.clearShadow();
    render.setBottomPage(null);
    render.setFlippingPage(null);
  }

  /// Get book bounds rectangle
  PageRect getBoundsRect() {
    return render.getRect();
  }

  /// Check current state
  bool checkState(List<FlippingState> states) {
    return states.contains(state);
  }

  /// Check if point is on page corners
  bool isPointOnCorners(Point globalPos) {
    final bookPos = render.convertToBook(globalPos);
    final rect = getBoundsRect();

    const cornerSize = 100.0; // Size of the corner detection area

    // In portrait mode, only check left and right edges
    if (render.getOrientation() == BookOrientation.portrait) {
      // Left edge corners (back direction)
      if (bookPos.x <= cornerSize) {
        return (bookPos.y <= cornerSize ||
            bookPos.y >= rect.height - cornerSize);
      }
      // Right edge corners (forward direction)
      if (bookPos.x >= rect.width - cornerSize) {
        return (bookPos.y <= cornerSize ||
            bookPos.y >= rect.height - cornerSize);
      }
    } else {
      // In landscape mode, check corners on both pages
      final isLeftPage = bookPos.x < rect.width / 2;
      final pageWidth = rect.width / 2;

      if (isLeftPage) {
        // Left page - only right edge corners (forward direction)
        final pageX = bookPos.x;
        if (pageX >= pageWidth - cornerSize) {
          return (bookPos.y <= cornerSize ||
              bookPos.y >= rect.height - cornerSize);
        }
      } else {
        // Right page - only left edge corners (back direction)
        final pageX = bookPos.x - pageWidth;
        if (pageX <= cornerSize) {
          return (bookPos.y <= cornerSize ||
              bookPos.y >= rect.height - cornerSize);
        }
      }
    }

    return false;
  }

  /// Start flipping animation
  void startFlipping(FlipDirection direction, FlipCorner corner) {
    if (!checkDirection(direction)) return;

    if (calc != null) render.finishAnimation();

    final rect = getBoundsRect();

    // Create a realistic touch position for the given direction and corner
    // This simulates where a user would touch to initiate a flip
    final touchPos = direction == FlipDirection.forward
        ? Point(
            rect.width - 10,
            corner == FlipCorner.top ? 10 : rect.height - 10,
          )
        : Point(10, corner == FlipCorner.top ? 10 : rect.height - 10);

    // Use the standard flip process which handles all the logic
    if (!start(touchPos)) return;

    setState(FlippingState.flipping);

    // Calculate animation positions like the standard flip() method
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
}
