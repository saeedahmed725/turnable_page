import '../enums/flip_direction.dart';
import '../page/book_page.dart';

typedef NumberArray = List<int>;

/// Abstract class representing a collection of pages
abstract class PageCollection {
  /// Load pages
  void loadBookPages();

  /// Clear pages list
  void destroy();

  /// Split the book on the two-page spread in landscape mode and one-page spread in portrait mode
  void createSpread();

  /// Get spread by mode (portrait or landscape)
  List<NumberArray> getSpread();

  /// Get spread index by page number
  int? getSpreadIndexByPage(int pageNum);

  /// Get the total number of pages
  int getPageCount();

  /// Get the pages list
  List<BookPage> getPages();

  /// Get page by index
  BookPage getPage(int pageIndex);

  /// Get the next page from the specified
  BookPage? nextBy(BookPage current);

  /// Get previous page from specified
  BookPage? prevBy(BookPage current);

  /// Get flipping page depending on the direction
  BookPage? getFlippingPage(FlipDirection direction);

  /// Get next page at the time of flipping
  BookPage? getBottomPage(FlipDirection direction);

  /// Show next spread
  void showNext();

  /// Show previous spread
  void showPrev();

  /// Get the number of the current spread in book
  int getCurrentPageIndex();

  /// Show specified page
  void show([int? pageNum]);

  /// Index of the current page in list
  int getCurrentSpreadIndex();

  /// Set new spread index as current
  void setCurrentSpreadIndex(int newIndex);

  /// Show current spread
  void showSpread();
}
