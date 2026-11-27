import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../enums/book_orientation.dart';
import '../enums/flip_corner.dart';
import '../enums/flipping_state.dart';
import '../enums/page_flip_event.dart';
import '../event/event_object.dart';
import '../page/page_flip.dart';

/// Controller to programmatically inspect and control a [TurnablePage] or [TurnablePageView].
///
/// Provides both animated page-turn methods (`nextPage`, `previousPage`, `animateToPage`)
/// which return a [Future<bool>] completing when the turn finishes, and instant jump methods
/// (`jumpToPage`) without animation.
///
/// It is a [ChangeNotifier]: listeners are notified when the page changes,
/// when a book attaches or detaches, and when auto-play starts or stops, so
/// widgets outside the book (a page counter, a [PageScrubber]) can rebuild
/// with `ListenableBuilder`.
class PageFlipController extends ChangeNotifier {
  PageFlip? _attached;

  /// Whether a [TurnablePage] / [TurnablePageView] is attached to this
  /// controller. Until then the getters return neutral values
  /// (`currentPageIndex` 0, `pageCount` 0, no next/previous page), the
  /// navigation methods do nothing and return `false`, and
  /// [addEventListener] / [removeEventListener] throw a [StateError].
  ///
  /// Note that the page count is known only after the book's first layout;
  /// to open on a given page prefer `FlipSettings.startPageIndex` over
  /// jumping after the first frame.
  bool get hasClients => _attached != null;

  PageFlip get _pageFlip {
    final p = _attached;
    if (p == null) {
      throw StateError(
        'PageFlipController is not attached to a TurnablePage yet. '
        'Check hasClients first.',
      );
    }
    return p;
  }

  VoidCallback? _resetZoomCallback;
  bool Function()? _isZoomedGetter;

  void initializeController({required PageFlip pageFlip}) {
    if (identical(_attached, pageFlip)) return;
    _attached?.off(PageFlipEvent.flip, _onFlip);
    _attached?.off(PageFlipEvent.changeState, _onState);
    _attached = pageFlip;
    pageFlip.on(PageFlipEvent.flip, _onFlip);
    pageFlip.on(PageFlipEvent.changeState, _onState);
    _notifySafely();
  }

  /// Detaches [pageFlip] if it is the one attached (called by the view on
  /// dispose).
  void detach(PageFlip pageFlip) {
    if (identical(_attached, pageFlip)) {
      pageFlip.off(PageFlipEvent.flip, _onFlip);
      pageFlip.off(PageFlipEvent.changeState, _onState);
      _attached = null;
      _resetZoomCallback = null;
      _isZoomedGetter = null;
      _notifySafely();
    }
  }

  bool _disposed = false;

  void _onFlip(WidgetEvent _) => _notifySafely();

  void _onState(WidgetEvent e) {
    // The reader grabbed a page: auto-play gives way.
    if (_autoPlaying &&
        _autoPlayStopOnTouch &&
        e.data == FlippingState.userFold) {
      stopAutoPlay();
    }
  }

  /// Page changes are reported while a frame is painted; listeners may call
  /// setState, so they are notified after the frame.
  void _notifySafely() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopAutoPlay();
    _disposed = true;
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AUTO-PLAY
  // ─────────────────────────────────────────────────────────────────────────────

  bool _autoPlaying = false;
  bool _autoPlayLoop = false;
  bool _autoPlayStopOnTouch = true;
  Duration _autoPlayInterval = const Duration(seconds: 4);
  Timer? _autoPlayTimer;

  /// Whether auto-play is running (see [startAutoPlay]).
  bool get isAutoPlaying => _autoPlaying;

  /// Turns to the next page every [interval], like a slideshow.
  ///
  /// At the last page it stops, or goes back to the first page when [loop]
  /// is true. With [stopOnTouch] (default), it stops when the reader grabs
  /// a page. While a turn is running the next tick waits for it.
  void startAutoPlay({
    Duration interval = const Duration(seconds: 4),
    bool loop = false,
    bool stopOnTouch = true,
  }) {
    _autoPlayTimer?.cancel();
    _autoPlaying = true;
    _autoPlayInterval = interval;
    _autoPlayLoop = loop;
    _autoPlayStopOnTouch = stopOnTouch;
    _scheduleAutoPlay();
    _notifySafely();
  }

  /// Stops auto-play.
  void stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (!_autoPlaying) return;
    _autoPlaying = false;
    _notifySafely();
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer = Timer(_autoPlayInterval, () async {
      if (!_autoPlaying) return;
      final book = _attached;
      if (book == null) {
        stopAutoPlay();
        return;
      }
      final state = book.getState();
      if (state != null && state != FlippingState.read) {
        _scheduleAutoPlay(); // a turn is running: try again later
        return;
      }
      if (hasNextPage) {
        await nextPage();
      } else if (_autoPlayLoop && pageCount > 0) {
        await animateToPage(0);
      } else {
        stopAutoPlay();
        return;
      }
      if (_autoPlaying) _scheduleAutoPlay();
    });
  }

  /// Internal setter for the PageFlip instance
  set pageFlip(PageFlip pageFlip) => _attached = pageFlip;

  /// Attach zoom callbacks from TurnablePageView
  void attachZoom({
    required VoidCallback resetZoom,
    required bool Function() isZoomed,
  }) {
    _resetZoomCallback = resetZoom;
    _isZoomedGetter = isZoomed;
  }

  /// Whether the page/book is currently zoomed in (scale > 1.05)
  bool get isZoomed => _isZoomedGetter?.call() ?? false;

  /// Programmatically reset zoom back to 1.0
  void resetZoom() {
    _resetZoomCallback?.call();
  }

  /// Get the current page index (0-based)
  int get currentPageIndex => _attached?.getCurrentPageIndex() ?? 0;

  /// Get the total number of pages
  int get pageCount => _attached?.getPageCount() ?? 0;

  /// Check if there is a next page available
  bool get hasNextPage {
    if (!hasClients) return false;
    final orientation = _pageFlip.renderNullable?.getOrientation();
    final isPortrait = orientation != null
        ? orientation == BookOrientation.portrait
        : _pageFlip.getSettings.usePortrait;
    return currentPageIndex + (isPortrait ? 0 : 1) < (pageCount - 1);
  }

  /// Check if there is a previous page available
  bool get hasPreviousPage => currentPageIndex > 0;

  // ─────────────────────────────────────────────────────────────────────────────
  // ANIMATED NAVIGATION (Returns Future<bool> completing on animation finish)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Flip to the next page with a page-curl animation.
  ///
  /// [corner] - The corner to flip from (default: [FlipCorner.top]).
  /// Returns a [Future] that resolves to `true` when the page flip completes,
  /// or `false` if the flip could not be started (e.g. already on the last page).
  Future<bool> nextPage([FlipCorner corner = FlipCorner.top]) {
    if (!hasNextPage) return Future.value(false);

    final completer = Completer<bool>();
    late void Function(WidgetEvent) listener;
    listener = (WidgetEvent event) {
      if (event.data == FlippingState.read) {
        _pageFlip.off(PageFlipEvent.changeState, listener);
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    };

    _pageFlip.on(PageFlipEvent.changeState, listener);
    _pageFlip.flipNext(corner);

    return completer.future;
  }

  /// Flip to the previous page with a page-curl animation.
  ///
  /// [corner] - The corner to flip from (default: [FlipCorner.top]).
  /// Returns a [Future] that resolves to `true` when the page flip completes,
  /// or `false` if the flip could not be started (e.g. already on the first page).
  Future<bool> previousPage([FlipCorner corner = FlipCorner.top]) {
    if (!hasPreviousPage) return Future.value(false);

    final completer = Completer<bool>();
    late void Function(WidgetEvent) listener;
    listener = (WidgetEvent event) {
      if (event.data == FlippingState.read) {
        _pageFlip.off(PageFlipEvent.changeState, listener);
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    };

    _pageFlip.on(PageFlipEvent.changeState, listener);
    _pageFlip.flipPrev(corner);

    return completer.future;
  }

  /// Animate to a specific page index with a page-turn animation.
  ///
  /// [pageIndex] - Target page index (0-based).
  /// [corner] - Corner to initiate the flip from.
  /// Returns a [Future] that resolves to `true` when navigation completes,
  /// or `false` if [pageIndex] is invalid or already on that page.
  Future<bool> animateToPage(
    int pageIndex, [
    FlipCorner corner = FlipCorner.top,
  ]) {
    if (pageIndex < 0 || pageIndex >= pageCount) return Future.value(false);
    if (pageIndex == currentPageIndex) return Future.value(true);

    final completer = Completer<bool>();
    late void Function(WidgetEvent) listener;
    listener = (WidgetEvent event) {
      if (event.data == FlippingState.read) {
        _pageFlip.off(PageFlipEvent.changeState, listener);
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    };

    _pageFlip.on(PageFlipEvent.changeState, listener);
    _pageFlip.flip(pageIndex, corner);

    return completer.future;
  }

  /// Animate to the first page (index 0).
  Future<bool> animateToFirstPage() => animateToPage(0);

  /// Animate to the last page (index [pageCount] - 1).
  Future<bool> animateToLastPage() => animateToPage(pageCount - 1);

  // ─────────────────────────────────────────────────────────────────────────────
  // INSTANT JUMP NAVIGATION (Without animation)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Jump to a specific page immediately without animation.
  ///
  /// [pageIndex] - Target page index (0-based).
  /// Returns `true` if the navigation was successful, or `false` if the index is out of bounds.
  bool jumpToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageCount) return false;
    if (pageIndex == currentPageIndex) return true;
    _pageFlip.turnToPage(pageIndex);
    return true;
  }

  /// Folds the corner of the next page a little and lets it fall back, to
  /// show the reader that pages turn. Returns `false` when no book is
  /// attached, a turn is running, or there is no next page.
  bool peek() => _attached?.peek() ?? false;

  /// Jump to the first page immediately without animation.
  bool jumpToFirstPage() => jumpToPage(0);

  /// Jump to the last page immediately without animation.
  bool jumpToLastPage() => jumpToPage(pageCount - 1);

  // ─────────────────────────────────────────────────────────────────────────────
  // EVENTS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Register an event listener.
  /// [event] - The [PageFlipEvent] to listen to.
  /// [callback] - Callback function to execute when the event triggers.
  /// Throws a [StateError] if the controller is not attached ([hasClients]).
  void addEventListener(PageFlipEvent event, EventCallback callback) {
    _pageFlip.on(event, callback);
  }

  /// Remove an event listener.
  /// [event] - The [PageFlipEvent] to remove handlers for.
  /// [callback] - Optional specific callback to remove. If omitted, all callbacks for [event] are removed.
  void removeEventListener(PageFlipEvent event, [EventCallback? callback]) {
    _pageFlip.off(event, callback);
  }

  /// Get the underlying [PageFlip] instance for advanced operations.
  PageFlip? get pageFlipInstance => _attached;
}
