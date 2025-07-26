import '../page_flip.dart';
import '../flip/flip_enums.dart';

/// Controller for managing PageFlip widget state and operations.
///
/// This controller provides a clean API for controlling page flip operations
/// without directly exposing the underlying PageFlip instance.
///
/// Example usage:
/// ```dart
/// final controller = PageFlipController();
///
/// // Control the widget
/// controller.nextPage();
/// controller.previousPage();
/// controller.goToPage(5);
/// ```
class PageFlipController {
  PageFlip? _pageFlip;

  initializeController({
    required PageFlip pageFlip,
    void Function([FlipCorner corner])? onNextPage,
    void Function([FlipCorner corner])? onPreviousPage,
    void Function(int pageIndex)? onGoToPage,
  }) {
    _pageFlip = pageFlip;
    _onNextPage = onNextPage;
    _onPreviousPage = onPreviousPage;
    _onGoToPage = onGoToPage;
  }

  // Callbacks to widget methods for animation control
  void Function([FlipCorner corner])? _onNextPage;
  void Function([FlipCorner corner])? _onPreviousPage;
  void Function(int pageIndex)? _onGoToPage;

  /// Internal setter for the PageFlip instance
  set pageFlip(PageFlip pageFlip) => _pageFlip = pageFlip;

  /// Internal setters for control callbacks
  set onNextPage(void Function([FlipCorner corner])? callback) => _onNextPage = callback;
  set onPreviousPage(void Function([FlipCorner corner])? callback) => _onPreviousPage = callback;
  set onGoToPage(void Function(int pageIndex)? callback) => _onGoToPage = callback;

  /// Get the current page index (0-based)
  int get currentPageIndex => _pageFlip?.getCurrentPageIndex() ?? 0;

  /// Get the total number of pages
  int get pageCount => _pageFlip?.getPageCount() ?? 0;

  /// Check if there is a next page available
  bool get hasNextPage => currentPageIndex < pageCount - 1;

  /// Check if there is a previous page available
  bool get hasPreviousPage => currentPageIndex > 0;

  /// Flip to the next page
  ///
  /// [corner] - The corner to flip from (default: top)
  /// Returns true if the flip was successful, false if already at the last page
  bool nextPage([FlipCorner corner = FlipCorner.top]) {
    if (_pageFlip == null || !hasNextPage) return false;
    _onNextPage?.call(corner);
    return true;
  }

  /// Flip to the previous page
  ///
  /// [corner] - The corner to flip from (default: top)
  /// Returns true if the flip was successful, false if already at the first page
  bool previousPage([FlipCorner corner = FlipCorner.top]) {
    if (_pageFlip == null || !hasPreviousPage) return false;
    _onPreviousPage?.call(corner);
    return true;
  }

  /// Go to a specific page
  ///
  /// [pageIndex] - The page index to navigate to (0-based)
  /// Returns true if the navigation was successful, false if the page index is invalid
  bool goToPage(int pageIndex) {
    if (_pageFlip == null || pageIndex < 0 || pageIndex >= pageCount)return false;
    _onGoToPage?.call(pageIndex);
    return true;
  }

  /// Go to the first page
  bool goToFirstPage() => goToPage(0);

  /// Go to the last page
  bool goToLastPage() => goToPage(pageCount - 1);

  /// Register an event listener
  ///
  /// [event] - The event name ('flip', 'changeOrientation', etc.)
  /// [callback] - The callback function to execute
  void addEventListener(String event, Function(dynamic) callback) {
    _pageFlip?.on(event, callback);
  }

  /// Remove an event listener
  ///
  /// [event] - The event name
  void removeEventListener(String event) {
    _pageFlip?.off(event);
  }

  /// Get the underlying PageFlip instance for advanced operations
  ///
  /// Use this only when you need direct access to PageFlip methods
  /// not exposed through this controller
  PageFlip? get pageFlipInstance => _pageFlip;

  /// Check if the controller is properly initialized
  bool get isInitialized => _pageFlip != null;
}
