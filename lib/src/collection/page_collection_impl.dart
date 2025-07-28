import '../enums/book_orientation.dart';
import '../enums/flip_direction.dart';
import '../enums/page_density.dart';
import '../page/book_page_impl.dart';
import '../page/book_page.dart';
import 'page_collection.dart';
import 'dart:ui' as ui;


/// Class representing a collection of pages as widgets that get converted to images
class PageCollectionImpl extends PageCollection {
  final List<ui.Image> images;

  PageCollectionImpl(super.app, super.render, this.images);

  @override
  void loadBookPages() {
    for (int i = 0; i < images.length; i++) {
      final page = BookPageImp(render, images[i], i, PageDensity.hard);
      page.loadPage();
      pages.add(page);
    }

    createSpread();
  }

  /// Clear pages list
  @override
  void destroy() {
    pages.clear();
  }

  /// Split the book on the two-page spread in landscape mode and one-page spread in portrait mode
  @override
  void createSpread() {
    landscapeSpread.clear();
    portraitSpread.clear();

    for (int i = 0; i < pages.length; i++) {
      portraitSpread.add([i]); // In portrait mode - (one spread = one page)
    }

    int start = 0;
    if (isShowCover) {
      pages[0].setDensity(PageDensity.hard);
      landscapeSpread.add([start]);
      start++;
    }

    for (int i = start; i < pages.length; i += 2) {
      if (i < pages.length - 1) {
        landscapeSpread.add([i, i + 1]);
      } else {
        landscapeSpread.add([i]);
        pages[i].setDensity(PageDensity.hard);
      }
    }
  }

  /// Get spread by mode (portrait or landscape)
  @override
  List<NumberArray> getSpread() {
    return render.getOrientation() == BookOrientation.landscape
        ? landscapeSpread
        : portraitSpread;
  }

  /// Get spread index by page number
  ///
  /// @param {int} pageNum - page index
  @override
  int? getSpreadIndexByPage(int pageNum) {
    final spread = getSpread();

    for (int i = 0; i < spread.length; i++) {
      if (pageNum == spread[i][0] || (spread[i].length > 1 && pageNum == spread[i][1])) {
        return i;
      }
    }

    return null;
  }

  /// Get the total number of pages
  @override
  int getPageCount() {
    return pages.length;
  }

  /// Get the pages list
  @override
  List<BookPage> getPages() {
    return pages;
  }

  /// Get page by index
  ///
  /// @param {int} pageIndex
  @override
  BookPage getPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < pages.length) {
      return pages[pageIndex];
    }

    throw Exception('Invalid page number');
  }

  /// Get the next page from the specified
  ///
  /// @param {BookPage} current
  @override
  BookPage? nextBy(BookPage current) {
    final idx = pages.indexOf(current);

    if (idx < pages.length - 1) return pages[idx + 1];

    return null;
  }

  /// Get previous page from specified
  ///
  /// @param {BookPage} current
  @override
  BookPage? prevBy(BookPage current) {
    final idx = pages.indexOf(current);

    if (idx > 0) return pages[idx - 1];

    return null;
  }

  /// Get flipping page depending on the direction
  ///
  /// @param {FlipDirection} direction
  @override
  BookPage? getFlippingPage(FlipDirection direction) {
    final current = currentSpreadIndex;

    if (render.getOrientation() == BookOrientation.portrait) {
      return direction == FlipDirection.forward
          ? pages[current].newTemporaryCopy()
          : pages[current - 1];
    } else {
      final spread = direction == FlipDirection.forward
          ? getSpread()[current + 1]
          : getSpread()[current - 1];

      if (spread.length == 1) return pages[spread[0]];

      return direction == FlipDirection.forward
          ? pages[spread[0]]
          : pages[spread[1]];
    }
  }

  /// Get Next page at the time of flipping
  ///
  /// @param {FlipDirection} direction
  @override
  BookPage? getBottomPage(FlipDirection direction) {
    final current = currentSpreadIndex;

    if (render.getOrientation() == BookOrientation.portrait) {
      return direction == FlipDirection.forward
          ? pages[current + 1]
          : pages[current - 1];
    } else {
      final spread = direction == FlipDirection.forward
          ? getSpread()[current + 1]
          : getSpread()[current - 1];

      if (spread.length == 1) return pages[spread[0]];

      return direction == FlipDirection.forward
          ? pages[spread[1]]
          : pages[spread[0]];
    }
  }

  /// Show next spread
  @override
  void showNext() {
    if (currentSpreadIndex < getSpread().length - 1) {
      currentSpreadIndex++;
      showSpread();
    }
  }

  /// Show prev spread
  @override
  void showPrev() {
    if (currentSpreadIndex > 0) {
      currentSpreadIndex--;
      showSpread();
    }
  }

  /// Get the number of the current spread in book
  @override
  int getCurrentPageIndex() {
    return currentPageIndex;
  }

  /// Show specified page
  /// @param {int} pageNum - Page index (from 0)
  @override
  void show([int? pageNum]) {
    pageNum ??= currentPageIndex;

    if (pageNum < 0 || pageNum >= pages.length) return;

    final spreadIndex = getSpreadIndexByPage(pageNum);
    if (spreadIndex != null) {
      currentSpreadIndex = spreadIndex;
      showSpread();
    }
  }

  /// Index of the current page in list
  @override
  int getCurrentSpreadIndex() {
    return currentSpreadIndex;
  }

  /// Set new spread index as current
  ///
  /// @param {int} newIndex - new spread index
  @override
  void setCurrentSpreadIndex(int newIndex) {
    if (newIndex >= 0 && newIndex < getSpread().length) {
      currentSpreadIndex = newIndex;
    } else {
      throw Exception('Invalid page');
    }
  }

  /// Show current spread
  @override
  void showSpread() {
    final spread = getSpread()[currentSpreadIndex];

    if (spread.length == 2) {
      render.setLeftPage(pages[spread[0]]);
      render.setRightPage(pages[spread[1]]);
    } else {
      if (render.getOrientation() == BookOrientation.landscape) {
        if (spread[0] == pages.length - 1) {
          render.setLeftPage(pages[spread[0]]);
          render.setRightPage(null);
        } else {
          render.setLeftPage(null);
          render.setRightPage(pages[spread[0]]);
        }
      } else {
        render.setLeftPage(null);
        render.setRightPage(pages[spread[0]]);
      }
    }

    currentPageIndex = spread[0];
    app.updatePageIndex(currentPageIndex);
  }
}