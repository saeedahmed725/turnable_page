import '../page/widget_page.dart';
import 'page_collection.dart';
import '../page/page.dart';
import 'dart:ui' as ui;

/// Class representing a collection of pages as widgets that get converted to images
class WidgetPageCollection extends PageCollection {
  final List<ui.Image> images;

  WidgetPageCollection(super.app, super.render, this.images);

  @override
  void load() {
    for (int i = 0; i < images.length; i++) {
      final page = WidgetPage(render, images[i], i, PageDensity.soft);

      page.load();
      pages.add(page);
    }

    createSpread();
  }
}
