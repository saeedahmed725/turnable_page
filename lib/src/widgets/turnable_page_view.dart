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
  final double pixelRatio;
  final Size bookSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;

  const TurnablePageView({
    super.key,
    this.controller,
    this.onPageChanged,
    required this.builder,
    required this.pageCount,
    required this.aspectRatio,
    required this.pixelRatio,
    required this.bookSize,
    required this.settings,
    required this.paperBoundaryDecoration,
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
        final newIndex = _pageFlip.getCurrentPageIndex();
        final left = newIndex.clamp(0, widget.pageCount - 1);
        final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
        widget.settings.startPageIndex = left;
        _pageFlip.updateSetting(_settings);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged?.call(left, right);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PaperWidget(
      size: widget.bookSize,
      isSinglePage: widget.settings.usePortrait,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      child: TurnableBookRenderObjectWidget(
        pageCount: widget.pageCount,
        builder: (ctx, index) => widget.builder(ctx, index),
        settings: _settings,
        pageFlip: _pageFlip,
      ),
    );
  }
}
