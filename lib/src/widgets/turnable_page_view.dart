import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../turnable_page.dart';
import '../page/page_flip.dart';
import 'paper_widget.dart';
import 'turnable_book_render_object_widget.dart';

class TurnablePageView extends StatefulWidget {
  final PageFlipController? controller;
  final PageWidgetBuilder builder;
  final int pageCount;
  final TurnablePageCallback? onPageChanged;
  final FlipSettings settings;
  final double aspectRatio;
  final Size bookSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final bool pagesBoundaryIsEnabled;
  final TextDirection? textDirection;

  const TurnablePageView({
    super.key,
    this.controller,
    this.onPageChanged,
    required this.builder,
    required this.pageCount,
    required this.aspectRatio,
    required this.bookSize,
    required this.settings,
    required this.paperBoundaryDecoration,
    this.pagesBoundaryIsEnabled = true,
    this.textDirection,
  });

  @override
  State<TurnablePageView> createState() => _TurnablePageViewState();
}

class _TurnablePageViewState extends State<TurnablePageView> {
  /// PageFlip core logic
  late PageFlip _pageFlip;

  /// Get the adjusted settings for the PageFlip instance
  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: widget.settings.startPageIndex,
  );

  @override
  void initState() {
    _pageFlip = PageFlip(_settings);
    _setupPageFlipEventsAndController();
    super.initState();
  }

  Future<void> _setupPageFlipEventsAndController() async {
    widget.controller?.initializeController(pageFlip: _pageFlip);
    // Set up event listeners
    _pageFlip.on('flip', (_) {
      if (mounted) {
        final effectiveDir =
            widget.textDirection ??
            Directionality.maybeOf(context) ??
            TextDirection.ltr;
        final isRtl = effectiveDir == TextDirection.rtl;

        final newIndex = _pageFlip.getCurrentPageIndex();
        final left = newIndex.clamp(0, widget.pageCount - 1);
        final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
        widget.settings.startPageIndex = left;
        _pageFlip.updateSetting(_settings);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (isRtl && !widget.settings.usePortrait) {
              widget.onPageChanged?.call(right, left);
            } else {
              widget.onPageChanged?.call(left, right);
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDir =
        widget.textDirection ??
        Directionality.maybeOf(context) ??
        TextDirection.ltr;
    final isRtl = effectiveDir == TextDirection.rtl;

    Widget bookWidget = TurnableBookRenderObjectWidget(
      pageCount: widget.pageCount,
      builder: (ctx, index) {
        final child = widget.builder(ctx, index);
        if (isRtl) {
          return Directionality(
            textDirection: effectiveDir,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
              child: child,
            ),
          );
        }
        return child;
      },
      settings: _settings,
      pageFlip: _pageFlip,
    );

    if (isRtl) {
      bookWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: bookWidget,
      );
    }

    return PaperWidget(
      size: widget.bookSize,
      isSinglePage: widget.settings.usePortrait,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      isEnabled: widget.pagesBoundaryIsEnabled,
      child: bookWidget,
    );
  }
}
