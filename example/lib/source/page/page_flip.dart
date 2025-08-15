import 'dart:math' hide Point;

import '../collection/page_collection.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flipping_state.dart';
import '../event/page_flip_notifier.dart';
import '../flip/flip_process.dart';
import '../flip/flip_settings.dart';
import '../model/page_rect.dart';
import '../model/point.dart';
import '../render/render_page.dart';
import 'book_page.dart';

/// Class representing a main PageFlip object
class PageFlip {
  Point? mousePosition;
  bool isUserTouch = false;
  bool isUserMove = false;
  // Simple velocity tracking
  final List<_MotionSample> _samples = [];
  static const int _maxSamples = 5; // keep last few samples

  late FlipSettings setting;
  late FlipProcess flipProcess; // created once a Render is injected
  RenderPage? _render; // lazily injected by RenderTurnableBook
  // Interaction now handled directly by RenderTurnableBook via pointer events

  // Flutter-native event notifiers
  final PageFlipNotifier _changeNotifier = PageFlipNotifier();
  final PageFlipStreamNotifier _streamNotifier = PageFlipStreamNotifier();

  PageCollection? pages;

  /// Create a new PageFlip instance with FlipSetting object
  ///  FlipSetting [setting] - Configuration object
  PageFlip(this.setting, {RenderPage? customRender}) {
    if (customRender != null) {
      render = customRender; // triggers flipProcess creation
    }
  }

  // Public getters for notifiers
  /// Get the ChangeNotifier for listening to events in widgets
  PageFlipNotifier get notifier => _changeNotifier;
  
  /// Get the Stream-based notifier for advanced async event handling
  PageFlipStreamNotifier get streamNotifier => _streamNotifier;

  bool _flipProcessInitialized = false;

  // Render getter/setter with lazy FlipProcess initialization
  RenderPage get render => _render!; // safe after injection by TurnableBook
  set render(RenderPage r) {
    _render = r;
    if (!_flipProcessInitialized) {
      flipProcess = FlipProcess(this, r);
      _flipProcessInitialized = true;
    } else {
      flipProcess.updateApp(this, r);
    }
  }

  void updateSetting(FlipSettings setting) {
    this.setting = setting;
    if (_render != null) {
      render.updateApp(this);
    }
    if (_flipProcessInitialized) {
      flipProcess.updateApp(this, render);
    }
    
    _changeNotifier.notifySettingsUpdate(
      settings: setting,
      mode: _render?.getOrientation(),
    );
    _streamNotifier.notifySettingsUpdate(
      settings: setting,
      mode: _render?.getOrientation(),
    );
  }

  

  /// Clear all pages
  void clear() {
    pages?.destroy();
    _changeNotifier.notifyClear();
    _streamNotifier.notifyClear();
  }

  /// Turn to previous page without animation
  void turnToPrevPage() {
    pages?.showPrev();
  }

  /// Turn to next page without animation
  void turnToNextPage() {
    pages?.showNext();
  }

  /// Turn to specific page
  ///
  /// int [page] - Page index without animation
  void turnToPage(int page) {
    pages?.show(page);
  }

  /// Show page by number with optional corner specification
  ///
  /// @param {int} pageNum - Page number to show (0-based)
  /// @param {String} corner - Corner to flip from ('top' or 'bottom')
  void showPage(int pageNum, [String? corner]) {
    if (pages != null) {
      pages!.show(pageNum);

      _changeNotifier.notifyFlip(
        page: pageNum,
        mode: render.getOrientation(),
      );
      _streamNotifier.notifyFlip(
        page: pageNum,
        mode: render.getOrientation(),
      );
    }
  }

  /// Flip next page with animation
  ///
  /// @param {FlipCorner} corner - Corner to flip from
  void flipNext([FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;

    final currentIndex = getCurrentPageIndex();
    final totalPages = getPageCount();

    if (currentIndex < totalPages - 1) {
      flipProcess.flipNext(corner);
      _changeNotifier.notifyFlip(
        page: currentIndex + 1,
        direction: 'next',
      );
      _streamNotifier.notifyFlip(
        page: currentIndex + 1,
        direction: 'next',
      );
    }
  }

  /// Flip previous page with animation
  ///
  /// @param {FlipCorner} corner - Corner to flip from
  void flipPrev([FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;

    final currentIndex = getCurrentPageIndex();

    if (currentIndex > 0) {
      // Use flip controller for animation if available
      flipProcess.flipPrev(corner);
      _changeNotifier.notifyFlip(
        page: currentIndex - 1,
        direction: 'prev',
      );
      _streamNotifier.notifyFlip(
        page: currentIndex - 1,
        direction: 'prev',
      );
    }
  }

  /// Flip to specific page with animation
  ///
  /// @param {int} page - Page index
  /// @param {FlipCorner} corner - Corner to flip from
  void flip(int page, [FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;

    final totalPages = getPageCount();

    if (page >= 0 && page < totalPages) {
      final currentIndex = getCurrentPageIndex();

      flipProcess.flipToPage(page, corner);

      _changeNotifier.notifyFlip(
        page: page,
        direction: page > currentIndex ? 'next' : 'prev',
      );
      _streamNotifier.notifyFlip(
        page: page,
        direction: page > currentIndex ? 'next' : 'prev',
      );
    }
  }

  /// Update flipping state
  ///
  /// @param {FlippingState} newState - New flipping state
  void updateState(FlippingState newState) {
    _changeNotifier.notifyStateChange(newState: newState);
    _streamNotifier.notifyStateChange(newState: newState);
  }

  /// Update current page index
  ///
  /// @param {int} newPage - New page index
  void updatePageIndex(int newPage) {
    _changeNotifier.notifyFlip(page: newPage);
    _streamNotifier.notifyFlip(page: newPage);
  }

  /// Get total page count
  int getPageCount() {
    return pages?.getPageCount() ?? 0;
  }

  /// Get current page index
  int getCurrentPageIndex() {
    return pages?.getCurrentPageIndex() ?? 0;
  }

  /// Get page by index
  ///
  /// @param {int} pageIndex - Page index
  BookPage? getPage(int pageIndex) {
    return pages?.getPage(pageIndex);
  }

  /// Get render object
  RenderPage? getRender() => _render;

  /// Get flip controller
  dynamic getFlipController() {
    return flipProcess;
  }

  /// Get current orientation
  BookOrientation? getOrientation() => _render?.getOrientation();

  /// Get bounds rectangle
  PageRect? getBoundsRect() {
    if (_render == null) return null;
    return render.getRect();
  }

  /// Get settings
  FlipSettings get getSettings {
    return setting;
  }

  /// Get current flipping state
  FlippingState? getState() {
    return flipProcess.getState();
  }

  /// Get page collection
  PageCollection? getPageCollection() {
    return pages;
  }

  /// Calculate distance between two points
  ///
  /// @param {Point} point1 - First point
  /// @param {Point} point2 - Second point
  /// @returns {double} Distance between points
  double _getDistanceBetweenPoints(Point point1, Point point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Start user touch interaction
  ///
  /// @param {Point} pos - Touch position
  void startUserTouch(Point pos) {
    isUserTouch = true;
    isUserMove = false;
    mousePosition = pos;
  _samples.clear();
  _recordSample(pos);
    flipProcess.fold(pos);
  }

  /// Handle user move
  ///
  /// @param {Point} pos - Current position
  /// @param {bool} isTouch - Whether this is a touch event
  void userMove(Point pos, bool isTouch) {
    if (isUserTouch) {
      if (mousePosition != null &&
          _getDistanceBetweenPoints(mousePosition!, pos) > 5) {
        isUserMove = true;
        // Continue flip interaction
        flipProcess.fold(pos);
  _recordSample(pos);
      }
    }
  }

  /// Handle user stop interaction
  ///
  /// @param {Point} pos - End position
  /// @param {bool} isSwipe - Whether this was a swipe gesture
  void userStop(Point pos, [bool isSwipe = false]) {
    if (isUserTouch) {
      isUserTouch = false;

      if (!isSwipe) {
        final velocity = _computeVelocity();
        final settings = getSettings;
        final fastSwipe = settings.enableInertia &&
            velocity.abs() > settings.inertiaVelocityThreshold;
        if (!isUserMove) {
          // Single click/tap - trigger flip
          flipProcess.flip(pos);
        } else {
          // End drag movement: inertia if fast
          flipProcess.stopMoveWithInertia(fastSwipe, velocity);
        }
      }
    }
  }

  void _recordSample(Point p) {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    _samples.add(_MotionSample(now, p));
    if (_samples.length > _maxSamples) {
      _samples.removeAt(0);
    }
  }

  double _computeVelocity() {
    if (_samples.length < 2) return 0;
    final a = _samples.first;
    final b = _samples.last;
    final dt = (b.t - a.t) / 1000.0; // seconds
    if (dt <= 0) return 0;
    final dx = b.p.x - a.p.x;
    // Horizontal velocity only (logical px/s)
    return dx / dt;
  }

  /// Dispose resources and clean up notifiers
  void dispose() {
    _streamNotifier.dispose();
    // Note: ChangeNotifier doesn't need explicit disposal unless it has listeners
    // that need to be removed. The garbage collector will handle it.
  }
}

class _MotionSample {
  final double t; // ms timestamp
  final Point p;
  _MotionSample(this.t, this.p);
}
