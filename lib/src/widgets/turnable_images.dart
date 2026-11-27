import 'package:flutter/widgets.dart';

import '../enums/flip_direction.dart';
import '../enums/page_view_mode.dart';
import '../flip/flip_settings.dart';
import 'page_flip_controller.dart';
import 'turnable_page.dart';

/// A page-flip book made of images: comics, manga, magazines, catalogs,
/// scanned books or photo albums.
///
/// Each image is one page. The images of the pages around the current one
/// are loaded ahead ([precacheExtent]) so turning never shows an empty
/// page, and a placeholder is shown while a page is loading.
///
/// ```dart
/// TurnableImages(
///   images: [for (final url in urls) NetworkImage(url)],
///   pageViewMode: PageViewMode.auto,
/// )
/// ```
///
/// [TurnableImages.network] and [TurnableImages.asset] build the list from
/// URLs or asset paths.
class TurnableImages extends StatefulWidget {
  const TurnableImages({
    super.key,
    required this.images,
    this.controller,
    this.pageViewMode,
    this.settings,
    this.fit = BoxFit.contain,
    this.pageColor = const Color(0xFFFFFFFF),
    this.aspectRatio,
    this.textDirection,
    this.precacheExtent = 2,
    this.onPageChanged,
    this.onPageTurn,
    this.coverSideBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.enableZoom,
    this.maxScale,
  });

  /// Pages from image URLs.
  TurnableImages.network(
    List<String> urls, {
    Map<String, String>? headers,
    Key? key,
    PageFlipController? controller,
    PageViewMode? pageViewMode,
    FlipSettings? settings,
    BoxFit fit = BoxFit.contain,
    Color pageColor = const Color(0xFFFFFFFF),
    double? aspectRatio,
    TextDirection? textDirection,
    int precacheExtent = 2,
    TurnablePageCallback? onPageChanged,
    void Function(FlipDirection direction)? onPageTurn,
    Widget Function(BuildContext context, int pageIndex)? loadingBuilder,
    Widget Function(BuildContext context, int pageIndex, Object error)?
    errorBuilder,
    bool? enableZoom,
    double? maxScale,
  }) : this(
         key: key,
         images: [for (final u in urls) NetworkImage(u, headers: headers)],
         controller: controller,
         pageViewMode: pageViewMode,
         settings: settings,
         fit: fit,
         pageColor: pageColor,
         aspectRatio: aspectRatio,
         textDirection: textDirection,
         precacheExtent: precacheExtent,
         onPageChanged: onPageChanged,
         onPageTurn: onPageTurn,
         loadingBuilder: loadingBuilder,
         errorBuilder: errorBuilder,
         enableZoom: enableZoom,
         maxScale: maxScale,
       );

  /// Pages from asset paths.
  TurnableImages.asset(
    List<String> paths, {
    AssetBundle? bundle,
    String? package,
    Key? key,
    PageFlipController? controller,
    PageViewMode? pageViewMode,
    FlipSettings? settings,
    BoxFit fit = BoxFit.contain,
    Color pageColor = const Color(0xFFFFFFFF),
    double? aspectRatio,
    TextDirection? textDirection,
    int precacheExtent = 2,
    TurnablePageCallback? onPageChanged,
    void Function(FlipDirection direction)? onPageTurn,
    Widget Function(BuildContext context, int pageIndex)? loadingBuilder,
    Widget Function(BuildContext context, int pageIndex, Object error)?
    errorBuilder,
    bool? enableZoom,
    double? maxScale,
  }) : this(
         key: key,
         images: [
           for (final p in paths)
             AssetImage(p, bundle: bundle, package: package),
         ],
         controller: controller,
         pageViewMode: pageViewMode,
         settings: settings,
         fit: fit,
         pageColor: pageColor,
         aspectRatio: aspectRatio,
         textDirection: textDirection,
         precacheExtent: precacheExtent,
         onPageChanged: onPageChanged,
         onPageTurn: onPageTurn,
         loadingBuilder: loadingBuilder,
         errorBuilder: errorBuilder,
         enableZoom: enableZoom,
         maxScale: maxScale,
       );

  /// One image per page.
  final List<ImageProvider> images;

  final PageFlipController? controller;
  final PageViewMode? pageViewMode;
  final FlipSettings? settings;

  /// How each image fills its page (default [BoxFit.contain]).
  final BoxFit fit;

  /// Page color behind the image, visible around it with [BoxFit.contain].
  final Color pageColor;

  /// Width ÷ height of one page. Defaults to `2/3`; set it to your images'
  /// ratio so they fill the pages.
  final double? aspectRatio;
  final TextDirection? textDirection;

  /// Images loaded ahead on each side of the current page (default 2).
  final int precacheExtent;
  final TurnablePageCallback? onPageChanged;
  final void Function(FlipDirection direction)? onPageTurn;
  final CoverSideBuilder? coverSideBuilder;

  /// Shown while a page's image loads. Defaults to the page color.
  final Widget Function(BuildContext context, int pageIndex)? loadingBuilder;

  /// Shown when a page's image fails to load.
  final Widget Function(BuildContext context, int pageIndex, Object error)?
  errorBuilder;

  final bool? enableZoom;
  final double? maxScale;

  @override
  State<TurnableImages> createState() => _TurnableImagesState();
}

class _TurnableImagesState extends State<TurnableImages> {
  final Set<int> _precached = <int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAround(widget.settings?.startPageIndex ?? 0);
  }

  @override
  void didUpdateWidget(TurnableImages old) {
    super.didUpdateWidget(old);
    if (!identical(old.images, widget.images)) _precached.clear();
  }

  void _precacheAround(int page) {
    final n = widget.images.length;
    final extent = widget.precacheExtent;
    // A spread shows two pages, so look one page further ahead.
    for (int i = page - extent; i <= page + extent + 1; i++) {
      if (i < 0 || i >= n || !_precached.add(i)) continue;
      precacheImage(widget.images[i], context, onError: (_, _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TurnablePage(
      controller: widget.controller,
      pageCount: widget.images.length,
      pageViewMode: widget.pageViewMode,
      settings: widget.settings,
      aspectRatio: widget.aspectRatio,
      textDirection: widget.textDirection,
      coverSideBuilder: widget.coverSideBuilder,
      onPageTurn: widget.onPageTurn,
      enableZoom: widget.enableZoom,
      maxScale: widget.maxScale,
      onPageChanged: (left, right) {
        _precacheAround(left < 0 ? right : left);
        widget.onPageChanged?.call(left, right);
      },
      builder: (context, index, _) => ColoredBox(
        color: widget.pageColor,
        child: Image(
          image: widget.images[index],
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, sync) {
            if (sync || frame != null) return child;
            return widget.loadingBuilder?.call(context, index) ??
                const SizedBox.expand();
          },
          errorBuilder: (context, error, _) =>
              widget.errorBuilder?.call(context, index, error) ??
              const SizedBox.expand(),
        ),
      ),
    );
  }
}
