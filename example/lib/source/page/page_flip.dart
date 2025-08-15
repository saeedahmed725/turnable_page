import 'dart:math' hide Point;

import '../collection/page_collection.dart';
import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flipping_state.dart';
import '../event/event_object.dart';
import '../flip/flip_process.dart';
import '../flip/flip_settings.dart';
import '../model/page_rect.dart';
import '../model/point.dart';
import '../render/render_page.dart';
import 'book_page.dart';

/// Class representing a main PageFlip object
class PageFlip extends EventObject {
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

  PageCollection? pages;

  /// Create a new PageFlip instance with FlipSetting object
  ///  FlipSetting [setting] - Configuration object
  PageFlip(this.setting, {RenderPage? customRender}) : super() {
    if (customRender != null) {
      render = customRender; // triggers flipProcess creation
    }
  }

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
    trigger('updateSettings', this, {
      'settings': setting,
      'mode': _render?.getOrientation(),
    });
  }



  /// Clear all pages
  void clear() {
    pages?.destroy();
    trigger('clear', this, {});
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

      trigger('flip', this, {'page': pageNum, 'mode': render.getOrientation()});
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
      trigger('flip', this, {'page': currentIndex + 1, 'direction': 'next'});
    }
  }

  /// Flip previous page with animation
  void flipPrev([FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;

    final currentIndex = getCurrentPageIndex();

    if (currentIndex > 0) {
      flipProcess.flipPrev(corner);
      trigger('flip', this, {'page': currentIndex - 1, 'direction': 'prev'});
    }
  }

  /// Flip to specific page with animation
  void flip(int page, [FlipCorner corner = FlipCorner.top]) {
    if (pages == null) return;

    final totalPages = getPageCount();

    if (page >= 0 && page < totalPages) {
      final currentIndex = getCurrentPageIndex();

      flipProcess.flipToPage(page, corner);

      trigger('flip', this, {
        'page': page,
        'direction': page > currentIndex ? 'next' : 'prev',
      });
    }
  }

  /// Update flipping state
  void updateState(FlippingState newState) {
    trigger('changeState', this, newState);
  }

  /// Update current page index
  void updatePageIndex(int newPage) {
    trigger('flip', this, newPage);
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
  double _getDistanceBetweenPoints(Point point1, Point point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Start user touch interaction
  void startUserTouch(Point pos) {
    isUserTouch = true;
    isUserMove = false;
    mousePosition = pos;
  _samples.clear();
  _recordSample(pos);
    flipProcess.fold(pos);
  }

  /// Handle user move
  void userMove(Point pos, bool isTouch) {
    if (isUserTouch) {
      if (mousePosition != null &&
          _getDistanceBetweenPoints(mousePosition!, pos) > 5) {
        isUserMove = true;
        flipProcess.fold(pos);
  _recordSample(pos);
      }
    }
  }

  /// Handle user stop interaction
  void userStop(Point pos, [bool isSwipe = false]) {
    if (isUserTouch) {
      isUserTouch = false;

      if (!isSwipe) {
        final velocity = _computeVelocity();
        final settings = getSettings;
        final fastSwipe = settings.enableInertia &&
            velocity.abs() > settings.inertiaVelocityThreshold;
        if (!isUserMove) {
          flipProcess.flip(pos);
        } else {
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
    final dt = (b.t - a.t) / 1000.0;
    if (dt <= 0) return 0;
    final dx = b.p.x - a.p.x;
    return dx / dt;
  }
}

class _MotionSample {
  final double t;
  final Point p;
  _MotionSample(this.t, this.p);
}
