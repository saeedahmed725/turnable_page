import 'dart:async';

import 'package:example/source/widgets/page_flip_controller.dart';
import 'package:example/source/widgets/turnable_book_render_object_widget.dart';
import 'package:example/source/widgets/turnable_page.dart';
import 'package:flutter/material.dart';

import '../flip/flip_settings.dart';
import '../model/paper_boundary_decoration.dart';
import '../page/page_flip.dart';
import 'paper_widget.dart';

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

  void _updateSize() {
    _pageFlip.updateSetting(_settings);
  }

  Timer? _resizeTimer;

  @override
  void didUpdateWidget(covariant TurnablePageView oldWidget) {
    final hasWidthChanged = widget.bookSize.width != oldWidget.bookSize.width;
    final hasHeightChanged =
        widget.bookSize.height != oldWidget.bookSize.height;
    if (hasWidthChanged || hasHeightChanged) {
      _resizeTimer?.cancel();
      _resizeTimer = Timer(const Duration(milliseconds: 100), () {
        _updateSize();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _setupPageFlipEventsAndController() async {
    widget.controller?.initializeController(pageFlip: _pageFlip);
    // Set up event listeners using Flutter-native notifiers
    _pageFlip.notifier.addListener(() {
      final flipEvent = _pageFlip.notifier.currentFlipEvent;
      if (flipEvent != null) {
        final newIndex = _pageFlip.getCurrentPageIndex();
        final left = newIndex.clamp(0, widget.pageCount - 1);
        final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
        // Don't call updateSetting here as it creates infinite loop
        // Just update the widget settings directly if needed
        widget.onPageChanged?.call(left, right);
      }
    });
  }

  @override
  void dispose() {
    _resizeTimer?.cancel();
    _pageFlip.dispose(); // Clean up the notifier streams
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSinglePage = widget.settings.usePortrait;

    return PaperWidget(
      size: widget.bookSize,
      isSinglePage: isSinglePage,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      child: RepaintBoundary(
        child: TurnableBookRenderObjectWidget(
          pageCount: widget.pageCount,
          builder: (ctx, index) => widget.builder(ctx, index),
          settings: _settings,
          pageFlip: _pageFlip,
        ),
      ),
    );
  }
}
