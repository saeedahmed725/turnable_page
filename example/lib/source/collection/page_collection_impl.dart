import '../enums/book_orientation.dart';
import '../enums/flip_direction.dart';
import '../enums/page_density.dart';
import '../page/book_page.dart';
import '../page/book_page_impl.dart';
import '../page/page_flip.dart';
import '../render/render_page.dart';
import 'page_collection.dart';

class PageCollectionImpl extends PageCollection {
  final int pageCount;
  late final PageFlip app;
  late final RenderPage render;
  late final bool isShowCover;

  final List<BookPage> pages = [];
  int currentPageIndex = 0;
  int currentSpreadIndex = 0;
  final List<NumberArray> landscapeSpread = [];
  final List<NumberArray> portraitSpread = [];

  PageCollectionImpl(this.app, this.render, this.pageCount) {
    isShowCover = app.getSettings.showCover;
  }

  @override
  void loadBookPages() {
    for (int i = 0; i < pageCount; i++) {
      pages.add(BookPageImpl(index: i, createdDensity: PageDensity.hard));
    }
    createSpread();
  }

  @override
  void destroy() {
    pages.clear();
  }

  @override
  void createSpread() {
    landscapeSpread.clear();
    portraitSpread.clear();
    for (int i = 0; i < pages.length; i++) {
      portraitSpread.add([i]);
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

  @override
  List<NumberArray> getSpread() =>
      render.getOrientation() == BookOrientation.landscape
      ? landscapeSpread
      : portraitSpread;

  @override
  int? getSpreadIndexByPage(int pageNum) {
    final spread = getSpread();
    for (int i = 0; i < spread.length; i++) {
      final s = spread[i];
      if (pageNum == s[0] || (s.length > 1 && pageNum == s[1])) return i;
    }
    return null;
  }

  @override
  int getPageCount() => pages.length;

  @override
  List<BookPage> getPages() => pages;

  @override
  BookPage getPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < pages.length) return pages[pageIndex];
    throw Exception('Invalid page number');
  }

  @override
  BookPage? nextBy(BookPage current) {
    final idx = pages.indexOf(current);
    if (idx < pages.length - 1) return pages[idx + 1];
    return null;
  }

  @override
  BookPage? prevBy(BookPage current) {
    final idx = pages.indexOf(current);
    if (idx > 0) return pages[idx - 1];
    return null;
  }

  @override
  BookPage? getFlippingPage(FlipDirection direction) {
    final current = currentSpreadIndex;
    if (render.getOrientation() == BookOrientation.portrait) {
      return direction == FlipDirection.forward
          ? pages[current].getTemporaryCopy()
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

  @override
  void showNext() {
    if (currentSpreadIndex < getSpread().length - 1) {
      currentSpreadIndex++;
      showSpread();
    }
  }

  @override
  void showPrev() {
    if (currentSpreadIndex > 0) {
      currentSpreadIndex--;
      showSpread();
    }
  }

  @override
  int getCurrentPageIndex() => currentPageIndex;

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

  @override
  int getCurrentSpreadIndex() => currentSpreadIndex;

  @override
  void setCurrentSpreadIndex(int newIndex) {
    if (newIndex >= 0 && newIndex < getSpread().length) {
      currentSpreadIndex = newIndex;
    } else {
      throw Exception('Invalid page');
    }
  }

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
