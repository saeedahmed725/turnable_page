import 'package:flutter/widgets.dart';

import '../enums/cover_side.dart';
import '../enums/page_view_mode.dart';
import '../flip/flip_settings.dart';
import '../model/paper_boundary_decoration.dart';
import 'page_flip_controller.dart';
import 'paper_widget.dart';
import 'turnable_page_view.dart';

class TurnablePage extends StatelessWidget {
  final PageFlipController? controller;
  final TurnableBuilder builder;
  final int pageCount;
  final TurnablePageCallback? onPageChanged;
  final FlipSettings settings;
  final PageViewMode pageViewMode;
  final bool autoResponseSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final double? aspectRatio;
  final bool pagesBoundaryIsEnabled;
  final TextDirection? textDirection;

  /// Pages kept built on each side of the current page for large books.
  /// See [TurnablePageView.pageCacheExtent].
  final int pageCacheExtent;

  /// Builds the widgets shown on the empty sides next to the covers, when
  /// `FlipSettings.showCover` is on and two pages are shown: left of the
  /// front cover ([CoverSide.front]) and right of the last page when it is
  /// alone ([CoverSide.back]). Use it for endpapers, a logo or a table of
  /// contents. Without it, these sides are plain paper.
  final CoverSideBuilder? coverSideBuilder;

  TurnablePage({
    super.key,
    this.controller,
    this.aspectRatio,
    required this.builder,
    required this.pageCount,
    this.onPageChanged,
    PageViewMode? pageViewMode,
    this.autoResponseSize = true,
    this.paperBoundaryDecoration = PaperBoundaryDecoration.vintage,
    FlipSettings? settings,
    this.pagesBoundaryIsEnabled = true,
    this.textDirection,
    this.pageCacheExtent = 4,
    this.coverSideBuilder,
    bool? enableZoom,
    bool? enableDoubleTapZoom,
    double? minScale,
    double? maxScale,
  }) : pageViewMode =
           pageViewMode ?? settings?.pageViewMode ?? PageViewMode.single,
       settings = (settings ?? FlipSettings()).copyWith(
         pageViewMode:
             pageViewMode ?? settings?.pageViewMode ?? PageViewMode.single,
         enableZoom: enableZoom,
         enableDoubleTapZoom: enableDoubleTapZoom,
         minScale: minScale,
         maxScale: maxScale,
       ) {
    assert(
      this.settings.startPageIndex >= 0,
      'Page count must be greater than 0',
    );
    assert(
      this.settings.startPageIndex < pageCount,
      'Start page index must be less than page count',
    );
  }

  Size _calculateBookSize({
    required double maxWidth,
    required double maxHeight,
    required double aspectRatio,
  }) {
    double height = maxWidth / aspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      maxWidth = height * aspectRatio;
    }
    return Size(maxWidth, height);
  }

  PageViewMode _resolveMode(bool isMobile) {
    if (pageViewMode == PageViewMode.auto) {
      return isMobile ? PageViewMode.single : PageViewMode.double;
    }
    return pageViewMode;
  }

  double _getAspectRatio(bool isMobile) {
    final mode = _resolveMode(isMobile);
    if (mode == PageViewMode.single) {
      return aspectRatio ?? 2 / 3;
    }
    return aspectRatio ?? (2 / 3) * 2;
  }

  FlipSettings _getAdjustedSetting(bool isMobile) {
    final mode = _resolveMode(isMobile);
    return settings.copyWith(pageViewMode: mode);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final aspectRatio = _getAspectRatio(isMobile);
        FlipSettings adjustedSettings = _getAdjustedSetting(isMobile);

        // The paper frame is drawn around the book, so the book gets the
        // space left after it (otherwise the frame overflows the parent).
        final frame = PaperWidget.frameExtent(
          isEnabled: pagesBoundaryIsEnabled,
          decoration: paperBoundaryDecoration,
          isSinglePage: _resolveMode(isMobile) == PageViewMode.single,
        );
        final bookSize = _calculateBookSize(
          maxWidth: constraints.maxWidth - frame.width,
          maxHeight: constraints.maxHeight - frame.height,
          aspectRatio: aspectRatio,
        );
        adjustedSettings = adjustedSettings.copyWith(
          width: bookSize.width,
          height: bookSize.height,
        );

        return TurnablePageView(
          builder: (context, index) => builder(context, index, constraints),
          bookSize: bookSize,
          settings: adjustedSettings,
          pageCount: pageCount,
          controller: controller,
          aspectRatio: aspectRatio,
          onPageChanged: onPageChanged,
          pagesBoundaryIsEnabled: pagesBoundaryIsEnabled,
          paperBoundaryDecoration: paperBoundaryDecoration,
          textDirection: textDirection,
          pageCacheExtent: pageCacheExtent,
          coverSideBuilder: coverSideBuilder == null
              ? null
              : (context, side) =>
                    coverSideBuilder!(context, side, constraints),
        );
      },
    );
  }
}

typedef TurnableBuilder =
    Widget Function(
      BuildContext context,
      int pageIndex,
      BoxConstraints constraints,
    );
typedef TurnablePageCallback =
    void Function(int leftPageIndex, int rightPageIndex);
typedef CoverSideBuilder =
    Widget Function(
      BuildContext context,
      CoverSide side,
      BoxConstraints constraints,
    );
typedef PageWidgetBuilder = Widget Function(BuildContext context, int index);
