import 'dart:math' as math;

import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flip_direction.dart';
import '../enums/flipping_state.dart';
import '../enums/page_flip_event.dart';
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
    // If the process has not started yet, determine initial direction and start
    if (calc == null) {
      final bookPos = render.convertToBook(globalPos);
      final direction = getDirectionByPoint(bookPos);
      if (!checkDirection(direction)) return;
      if (!start(globalPos)) return;
    }

    setState(FlippingState.userFold);

    if (calc != null) {
      doCalculation(render.convertToPage(globalPos));
    }
  }

  /// Page turning with animation
  ///
  /// @param globalPos - Touch Point Coordinates (relative window)
  void flip(Point globalPos) {
    // Allow tap-based flips from both top and bottom regions (previous corner restriction removed)

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

    // In single-page mode the previous page enters from the spine, and
    // positions with x > 0 (back coordinates) are off-screen. Starting there
    // wasted the first part of the animation on an invisible page and then
    // rushed the visible part, so start right at the spine instead.
    final isPortraitBack =
        render.getOrientation() == BookOrientation.portrait &&
        calc!.getDirection() == FlipDirection.back;
    final xStart = isPortraitBack ? -1.0 : rect.pageWidth - topMargins;

    // Calculations for these points
    calc!.calc(Point(xStart, yStart));

    // Run flipping animation
    animateFlippingTo(
      Point(xStart, yStart),
      Point(-rect.pageWidth.toDouble(), yDest.toDouble()),
      true,
    );
  }

  /// Start the flipping process. Find direction and corner of flipping. Creating an object for calculation.
  bool start(Point globalPos) {
    reset();

    final bookPos = render.convertToBook(globalPos);
    final rect = getBoundsRect();

    final direction = getDirectionByPoint(bookPos);

    final flipCorner = bookPos.y >= rect.height / 2
        ? FlipCorner.bottom
        : FlipCorner.top;

    if (!checkDirection(direction)) return false;

    try {
      final pageCollection = app.getPageCollection();
      flippingPage = pageCollection?.getFlippingPage(direction);
      bottomPage = pageCollection?.getBottomPage(direction);

      if (render.getOrientation() == BookOrientation.landscape) {
        if (direction == FlipDirection.back) {
          final nextPage = pageCollection?.nextBy(flippingPage!);
          if (nextPage != null && flippingPage != null) {
            if (flippingPage!.getDensity() != nextPage.getDensity()) {
              flippingPage!.setDrawingDensity(PageDensity.hard);
              nextPage.setDrawingDensity(PageDensity.hard);
            }
          }
        } else {
          final prevPage = pageCollection?.prevBy(flippingPage!);
          if (prevPage != null && flippingPage != null) {
            if (flippingPage!.getDensity() != prevPage.getDensity()) {
              flippingPage!.setDrawingDensity(PageDensity.hard);
              prevPage.setDrawingDensity(PageDensity.hard);
            }
          }
        }
      }

      render.setDirection(direction);

      calc = FlipCalculation(
        direction,
        flipCorner,
        rect.pageWidth,
        rect.height,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Perform calculations for the current page position. Pass data to render object
  void doCalculation(Point pagePos) {
    if (calc == null) return;

    if (calc!.calc(pagePos)) {
      final progress = calc!.getFlippingProgress();
      final settings = app.getSettings;

      bottomPage?.setArea(calc!.getBottomClipArea());
      bottomPage?.setPosition(calc!.getBottomPagePosition());
      bottomPage?.setAngle(0);
      bottomPage?.setHardAngle(0);

      flippingPage?.setArea(calc!.getFlippingClipArea());
      flippingPage?.setPosition(calc!.getActiveCorner());
      flippingPage?.setAngle(calc!.getAngle());

      if (state == FlippingState.userFold ||
          state == FlippingState.foldCorner) {
        final normalizedProgress = progress / 100.0;
        final bendMultiplier = settings.bendStrength;

        final easedProgress = settings.enableEasing
            ? _easeOutCubic(normalizedProgress)
            : normalizedProgress;

        final maxAngle = 90.0;
        final bendAngle = maxAngle * (1 - easedProgress * bendMultiplier);

        if (calc!.getDirection() == FlipDirection.forward) {
          flippingPage?.setHardAngle(bendAngle);
        } else {
          flippingPage?.setHardAngle(-bendAngle);
        }
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

    final progress = _releaseProgress();

    // If user holds near bottom and releases with small horizontal movement but high progress,
    // force completion to avoid page freezing visually at bottom corner.
    if (progress > 0.35 && calc!.getCorner() == FlipCorner.bottom) {
      animateFlippingTo(
        pos,
        Point(-rect.pageWidth.toDouble(), y.toDouble()),
        true,
      );
      return;
    }

    final threshold = render.getOrientation() == BookOrientation.portrait
        ? 0.35
        : 0.5;

    if (progress >= threshold) {
      animateFlippingTo(
        pos,
        Point(-rect.pageWidth.toDouble(), y.toDouble()),
        true,
      );
    } else {
      animateFlippingTo(pos, Point(_cancelX(rect), y.toDouble()), false);
    }
  }

  bool get _isPortraitBack =>
      render.getOrientation() == BookOrientation.portrait &&
      calc?.getDirection() == FlipDirection.back;

  /// Share (0..1) of the incoming page the user has revealed, used to decide
  /// whether a released drag completes.
  ///
  /// For a back turn in single-page mode the corner starts at the spine,
  /// which is already 50% of [FlipCalculation.getFlippingProgress]. Using the
  /// raw value there made every back drag pass the completion threshold, so
  /// even a tiny drag turned the page. The visible share is `-x / pageWidth`.
  double _releaseProgress() {
    final progress = calc!.getFlippingProgress() / 100.0;
    if (!_isPortraitBack) return progress;
    return (2 * progress - 1).clamp(0.0, 1.0).toDouble();
  }

  /// Where a cancelled drag returns the corner. For a back turn in
  /// single-page mode the page leaves at the spine (x = 0): going on to
  /// +pageWidth only animated an invisible page and rushed the visible part.
  double _cancelX(PageRect rect) =>
      _isPortraitBack ? 2.0 : rect.pageWidth.toDouble();

  /// Stop move with inertia consideration
  void stopMoveWithInertia(bool fastSwipe, double velocity) {
    if (calc == null) return;

    final pos = calc!.getPosition();
    final rect = getBoundsRect();
    final y = calc!.getCorner() == FlipCorner.bottom ? rect.height : 0;

    final progress = _releaseProgress();
    bool complete;

    final dirForward = calc!.getDirection() == FlipDirection.forward;
    final swipeTowardsCenter = dirForward ? velocity < 0 : velocity > 0;

    // A fast flick towards center completes the flip seamlessly from current dragged pos.
    // A flick away from center (back towards starting edge) cancels the flip.
    final isFlick = fastSwipe || velocity.abs() > 300.0;

    final threshold = render.getOrientation() == BookOrientation.portrait
        ? 0.35
        : 0.5;

    if (isFlick && progress > 0.05) {
      complete = swipeTowardsCenter;
    } else {
      complete = progress >= threshold;
    }

    if (complete) {
      animateFlippingTo(
        pos,
        Point(-rect.pageWidth.toDouble(), y.toDouble()),
        true,
      );
    } else {
      animateFlippingTo(pos, Point(_cancelX(rect), y.toDouble()), false);
    }
  }

  /// Fold the corners of the book when the mouse pointer is over them.
  /// Called when the mouse pointer is over the book without clicking
  ///
  /// [cornerSize] is how far the corner folds, in pixels.
  void showCorner(Point globalPos, {double cornerSize = 50.0}) {
    if (!checkState([FlippingState.read, FlippingState.foldCorner])) return;

    final rect = getBoundsRect();
    final pageWidth = rect.pageWidth;

    if (isPointOnCorners(globalPos)) {
      final bookPos = render.convertToBook(globalPos);
      final direction = getDirectionByPoint(bookPos);
      if (!checkDirection(direction)) {
        if (state == FlippingState.foldCorner) {
          abortFlip();
        }
        return;
      }

      if (calc == null) {
        if (!start(globalPos)) return;

        setState(FlippingState.foldCorner);

        calc!.calc(Point(pageWidth - 1, 1));

        final fixedCornerSize = cornerSize;
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
      releaseCorner();
    }
  }

  /// Lets a folded corner (hover or peek) fall back smoothly. Does nothing
  /// unless a corner is folded.
  void releaseCorner() {
    final c = calc;
    if (state != FlippingState.foldCorner || c == null) return;
    // Not foldCorner any more: hovering cannot grab the corner while it
    // falls back.
    setState(FlippingState.flipping);
    final rect = getBoundsRect();
    final y = c.getCorner() == FlipCorner.bottom ? rect.height : 0;
    animateFlippingTo(
      c.getPosition(),
      Point(_cancelX(rect), y.toDouble()),
      false,
    );
  }

  /// Folds the corner under a hovering mouse. The fold starts from nothing
  /// at the edge of a small [zone] around the corner and deepens smoothly,
  /// up to [maxFold], as the mouse gets closer, so it never jumps and never
  /// rolls far into the page. Outside the zone the corner falls back.
  void hoverCorner(Point globalPos, {required double zone, double? maxFold}) {
    if (!checkState([FlippingState.read, FlippingState.foldCorner])) return;
    final rect = getBoundsRect();
    final bookPos = render.convertToBook(globalPos);
    if (bookPos.x <= 0 ||
        bookPos.y <= 0 ||
        bookPos.x >= rect.width ||
        bookPos.y >= rect.height) {
      releaseCorner();
      return;
    }
    final direction = getDirectionByPoint(bookPos);
    if (!checkDirection(direction)) {
      releaseCorner();
      return;
    }

    final r = math.min(zone, rect.pageWidth * 0.35);
    final fold = maxFold ?? r * 0.75;
    final page = render.convertToPage(globalPos, direction);
    final bottom = bookPos.y >= rect.height / 2;
    final cy = bottom ? rect.height : 0.0;
    final dx = rect.pageWidth - page.x; // >= 0 inside the page
    final dy = (page.y - cy).abs();
    final d = math.sqrt(dx * dx + dy * dy);
    if (dx < 0 || d >= r) {
      releaseCorner();
      return;
    }

    final t = 1 - d / r;
    final len = fold * t * t * (3 - 2 * t);
    if (len < 1) {
      // Too far to fold anything yet.
      if (state == FlippingState.foldCorner) releaseCorner();
      return;
    }

    final corner = bottom ? FlipCorner.bottom : FlipCorner.top;
    final c = calc;
    if (c != null &&
        (c.getCorner() != corner || c.getDirection() != direction)) {
      abortFlip();
    }
    if (calc == null) {
      if (!start(globalPos)) return;
      setState(FlippingState.foldCorner);
    }

    // Fold along the corner's diagonal, leaning toward the mouse.
    final mx = d > 0 ? -dx / d : 0.0;
    final my = d > 0 ? (page.y - cy).sign * dy / d : 0.0;
    var ux = mx - 0.7071;
    var uy = my + (bottom ? -0.7071 : 0.7071);
    final ul = math.sqrt(ux * ux + uy * uy);
    ux /= ul;
    uy /= ul;
    render.finishAnimation();
    doCalculation(Point(rect.pageWidth + ux * len, cy + uy * len));
  }

  /// Animation function. Animates flipping process with improved physics and easing
  void animateFlippingTo(
    Point start,
    Point dest,
    bool isTurned, [
    bool needReset = true,
  ]) {
    final settings = app.getSettings;

    // A turn is committed: report it once, before it animates (sound,
    // haptics). Cancelled drags and corner peeks pass isTurned = false.
    final turning = calc;
    if (isTurned && turning != null) {
      app.trigger(PageFlipEvent.turn, app, turning.getDirection());
    }

    final distance = Helper.getDistanceBetweenTwoPoint(start, dest);

    // In single-page mode a forward turn reveals the next page at the fold
    // line, which moves at HALF the corner's speed. A backward turn reveals
    // the previous page directly under the corner (1:1). Counting only
    // corner distance therefore made back turns look about twice as fast
    // ("snatched"). Give them ~1.8x the frame budget (measured) so both
    // directions reveal the page at the same pace.
    final isPortraitBack =
        render.getOrientation() == BookOrientation.portrait &&
        calc?.getDirection() == FlipDirection.back;
    // Forward turn in single-page mode: the corner travels two page widths
    // but only the first one is on screen. With a strong ease-out the flap
    // crossed the whole page in ~75 ms (vs ~300 ms for the edge of a back
    // turn), so forward turns looked snatched. Completed forward turns use a
    // gentler curve and a bigger frame budget so the visible edge moves at
    // the same pace in both directions.
    final isPortraitForwardTurn =
        isTurned &&
        render.getOrientation() == BookOrientation.portrait &&
        calc?.getDirection() == FlipDirection.forward;
    final speedFactor = isPortraitBack
        ? 1.8
        : (isPortraitForwardTurn ? _forwardSpeedFactor : 1.0);

    // At least 300 frames (= 30% of flippingTime): short moves, like releasing
    // a small corner fold, used to snap back in ~3 frames.
    final estFrames = (distance * speedFactor).clamp(300, 1000).toInt();
    final frames = <void Function()>[];

    // The sag (downward arc of the corner) is scaled by how far the corner
    // travels. A fixed 8%-of-height arc on a short return made a small fold
    // grow before shrinking back, which looked broken; a full turn
    // (~2 page widths) keeps the full arc.
    final rectForSag = getBoundsRect();
    final sagScale = (distance / (2 * rectForSag.pageWidth))
        .clamp(0.0, 1.0)
        .toDouble();
    final sagAmp = settings.sagAmplitude * rectForSag.height * sagScale;

    // Scratch calculation used to validate every frame up-front. Frames whose
    // geometry cannot be computed, or whose clip areas collapse to zero-area
    // lines (this always happens on the last few frames of a completed turn,
    // when the fold becomes collinear with the page edge), are dropped.
    // Rendering them would hide the incoming page for a frame and flash the
    // old page right before the turn completes.
    final liveCalc = calc;
    final probe = liveCalc == null
        ? null
        : FlipCalculation(
            liveCalc.getDirection(),
            liveCalc.getCorner(),
            liveCalc.pageWidth,
            liveCalc.pageHeight,
          );

    for (int i = 0; i <= estFrames; i++) {
      final tRaw = i / estFrames; // 0..1

      final t = !settings.enableEasing
          ? tRaw
          : (isPortraitForwardTurn ? _forwardEase(tRaw) : _easeOutCubic(tRaw));

      final x = start.x + (dest.x - start.x) * t;

      final baseY = start.y + (dest.y - start.y) * t;
      final sag = math.sin(math.pi * t) * sagAmp;

      final corner = calc?.getCorner() ?? FlipCorner.top;
      final y = corner == FlipCorner.top ? baseY + sag : baseY - sag;

      if (probe != null &&
          (!probe.calc(Point(x, y)) || !probe.hasDrawableClipAreas())) {
        continue;
      }

      frames.add(() {
        doCalculation(Point(x, y));

        if (flippingPage != null && calc != null) {
          final prog = calc!.getFlippingProgress();
          final bend = settings.bendStrength;
          final eased = settings.enableEasing
              ? _easeOutCubic(prog / 100)
              : prog / 100;
          final targetHard = 90 * (1 - eased * bend);

          flippingPage!.setHardAngle(
            calc!.getDirection() == FlipDirection.forward
                ? targetHard
                : -targetHard,
          );
        }
      });
    }

    // Duration is proportional to the frame count, so dropping the degenerate
    // tail keeps the per-frame speed unchanged.
    final duration = _getAnimationDuration(math.max(frames.length, 300));

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

  static const double _forwardSpeedFactor = 1.6;

  /// Easing for completed forward turns in single-page mode.
  /// Near-linear so the flap does not shoot across the page, with a mild
  /// slow-down at the end (start speed 1.4x, end speed 0.6x of average).
  double _forwardEase(double t) => t * (1.4 - 0.4 * t);

  /// Cubic easing function for smooth animations
  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  /// Get animation duration for the given number of frames
  double _getAnimationDuration(int frameCount) {
    final defaultTime = app.getSettings.flippingTime.toDouble();

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
    final collection = app.getPageCollection();
    if (collection == null) return false;
    final spreads = collection.getSpread();
    if (spreads.isEmpty) return false;
    if (direction == FlipDirection.forward) {
      return collection.getCurrentSpreadIndex() < spreads.length - 1;
    }
    return collection.getCurrentSpreadIndex() > 0;
  }

  /// Immediately abort/cancel any ongoing flip and return to clean read state
  void abortFlip() {
    render.finishAnimation();
    render.setBottomPage(null);
    render.setFlippingPage(null);
    render.clearShadow();
    setState(FlippingState.read);
    reset();
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
    final settings = app.getSettings;

    final bookPos = render.convertToBook(globalPos);
    final direction = getDirectionByPoint(bookPos);
    if (!checkDirection(direction)) return false;

    final operatingDistance = settings.cornerTriggerAreaSize > 0
        ? math.sqrt(math.pow(pageWidth, 2) + math.pow(rect.height, 2)) *
              settings.cornerTriggerAreaSize
        : math.sqrt(math.pow(pageWidth, 2) + math.pow(rect.height, 2)) / 5;

    if (bookPos.x <= 0 ||
        bookPos.y <= 0 ||
        bookPos.x >= rect.width ||
        bookPos.y >= rect.height) {
      return false;
    }

    final isVerticalCorner =
        bookPos.y < operatingDistance ||
        bookPos.y > rect.height - operatingDistance;
    if (!isVerticalCorner) return false;

    if (render.getOrientation() == BookOrientation.landscape) {
      // In landscape, corners near the center spine cannot be folded:
      // Left page: corners only on the outer left edge
      // Right page: corners only on the outer right edge
      if (bookPos.x < rect.width / 2) {
        return bookPos.x < operatingDistance;
      } else {
        return bookPos.x > rect.width - operatingDistance;
      }
    } else {
      return bookPos.x < operatingDistance ||
          bookPos.x > rect.width - operatingDistance;
    }
  }
}
