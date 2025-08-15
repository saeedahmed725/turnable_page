import '../enums/flip_corner.dart';
import '../event/event_object.dart';
import '../page/page_flip.dart';

class PageFlipController {
  late PageFlip _pageFlip;

  initializeController({required PageFlip pageFlip}) {
    _pageFlip = pageFlip;
  }

  /// Internal setter for the PageFlip instance
  set pageFlip(PageFlip pageFlip) => _pageFlip = pageFlip;

  /// Get the current page index (0-based)
  int get currentPageIndex => _pageFlip.getCurrentPageIndex();

  /// Get the total number of pages
  int get pageCount => _pageFlip.getPageCount();

  /// Check if there is a next page available
  bool get hasNextPage =>
      currentPageIndex + (_pageFlip.getSettings.usePortrait ? 0 : 1) <
      (pageCount - 1);

  /// Check if there is a previous page available
  bool get hasPreviousPage => currentPageIndex > 0;

  /// Flip to the next page
  ///
  /// [corner] - The corner to flip from (default: top)
  /// Returns true if the flip was successful, false if already at the last page
  bool nextPage([FlipCorner corner = FlipCorner.top]) {
    if (!hasNextPage) return false;
    _pageFlip.flipNext(corner);

    return true;
  }

  /// Flip to the previous page
  /// [corner] - The corner to flip from (default: top)
  /// Returns true if the flip was successful, false if already at the first page
  bool previousPage([FlipCorner corner = FlipCorner.top]) {
    if (!hasPreviousPage) return false;
    _pageFlip.flipPrev(corner);

    return true;
  }

  /// Go to a specific page
  /// [pageIndex] - The page index to navigate to (0-based)
  /// Returns true if the navigation was successful, false if the page index is invalid
  bool goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageCount) return false;
    _pageFlip.flip(pageIndex, FlipCorner.top);

    return true;
  }

  /// Go to the first page
  bool goToFirstPage() => goToPage(0);

  /// Go to the last page
  bool goToLastPage() => goToPage(pageCount - 1);

  /// Register an event listener
  /// [event] - The event name ('flip', 'changeOrientation', etc.)
  /// [callback] - The callback function to execute
  void addEventListener(String event, EventCallback callback) {
    _pageFlip.on(event, callback);
  }

  /// Remove an event listener
  /// [event] - The event name
  void removeEventListener(String event) {
    _pageFlip.off(event);
  }

  /// Get the underlying PageFlip instance for advanced operations
  /// Use this only when you need direct access to PageFlip methods
  /// not exposed through this controller
  PageFlip? get pageFlipInstance => _pageFlip;
}
