import 'dart:async';
import 'package:flutter/foundation.dart';

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
class PageFlipController {
  late PageFlip _pageFlip;
  VoidCallback? _resetZoomCallback;
  bool Function()? _isZoomedGetter;

  initializeController({required PageFlip pageFlip}) {
    _pageFlip = pageFlip;
  }

  /// Internal setter for the PageFlip instance
  set pageFlip(PageFlip pageFlip) => _pageFlip = pageFlip;

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
  int get currentPageIndex => _pageFlip.getCurrentPageIndex();

  /// Get the total number of pages
  int get pageCount => _pageFlip.getPageCount();

  /// Check if there is a next page available
  bool get hasNextPage {
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
  PageFlip? get pageFlipInstance => _pageFlip;
}
