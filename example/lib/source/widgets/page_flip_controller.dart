import '../enums/flip_corner.dart';
import '../event/page_flip_notifier.dart';
import '../page/page_flip.dart';

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
  late PageFlip _pageFlip;

  initializeController({required PageFlip pageFlip}) {
    _pageFlip = pageFlip;
  }

  /// Internal setter for the PageFlip instance
  set pageFlip(PageFlip pageFlip) => _pageFlip = pageFlip;

  /// Get the current page index (0-based)
  int get currentPage => _pageFlip.getCurrentPageIndex();

  /// Get the total number of pages
  int get pageCount => _pageFlip.getPageCount();

  /// Check if there is a next page available
  bool get hasNextPage =>
      currentPage + (_pageFlip.getSettings.usePortrait ? 0 : 1) <
      (pageCount - 1);

  /// Check if there is a previous page available
  bool get hasPreviousPage => currentPage > 0;

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
  ///
  /// [corner] - The corner to flip from (default: top)
  /// Returns true if the flip was successful, false if already at the first page
  bool previousPage([FlipCorner corner = FlipCorner.top]) {
    if (!hasPreviousPage) return false;
    _pageFlip.flipPrev(corner);

    return true;
  }

  /// Go to a specific page
  ///
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

  /// Get the ChangeNotifier for listening to page flip events
  ///
  /// Use this with Flutter widgets like AnimatedBuilder, ValueListenableBuilder, etc.
  /// Example:
  /// ```dart
  /// AnimatedBuilder(
  ///   animation: controller.notifier,
  ///   builder: (context, child) {
  ///     // React to page flip events
  ///     final flipEvent = controller.notifier.currentFlipEvent;
  ///     return Text('Current page: ${flipEvent?.page ?? 0}');
  ///   },
  /// )
  /// ```
  PageFlipNotifier get notifier => _pageFlip.notifier;

  /// Get the Stream-based notifier for advanced async event handling
  ///
  /// Use this for reactive programming with streams
  /// Example:
  /// ```dart
  /// controller.streamNotifier.onFlip.listen((event) {
  ///   print('Page flipped to: ${event.page}');
  /// });
  /// ```
  PageFlipStreamNotifier get streamNotifier => _pageFlip.streamNotifier;

  /// Get the underlying PageFlip instance for advanced operations
  ///
  /// Use this only when you need direct access to PageFlip methods
  /// not exposed through this controller
  PageFlip? get pageFlipInstance => _pageFlip;
}
