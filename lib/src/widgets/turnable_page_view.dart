import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../turnable_page.dart';
import '../page/page_flip.dart';
import '../page/page_host.dart';
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
  late final TransformationController _transformationController;
  bool _isZoomed = false;
  late int _currentPageIndex;

  /// Get the adjusted settings for the PageFlip instance
  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: widget.settings.startPageIndex,
  );

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.settings.startPageIndex;
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _pageFlip = PageFlip(_settings);
    _setupPageFlipEventsAndController();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.persistentCallbacks ||
          phase == SchedulerPhase.midFrameMicrotasks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && zoomed != _isZoomed) {
            setState(() {
              _isZoomed = zoomed;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isZoomed = zoomed;
          });
        }
      }
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    if (_isZoomed) {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.persistentCallbacks ||
          phase == SchedulerPhase.midFrameMicrotasks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isZoomed) {
            setState(() {
              _isZoomed = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isZoomed = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _setupPageFlipEventsAndController() async {
    widget.controller?.initializeController(pageFlip: _pageFlip);
    widget.controller?.attachZoom(
      resetZoom: _resetZoom,
      isZoomed: () => _isZoomed,
    );

    // Set up event listeners
    _pageFlip.on(PageFlipEvent.flip, (event) {
      if (!mounted) return;
      final effectiveDir =
          widget.textDirection ??
          Directionality.maybeOf(context) ??
          TextDirection.ltr;
      final isRtl = effectiveDir == TextDirection.rtl;

      final newIndex = (event.data is int)
          ? (event.data as int)
          : _pageFlip.getCurrentPageIndex();
      final left = newIndex.clamp(0, widget.pageCount - 1);
      final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
      widget.settings.startPageIndex = left;
      _pageFlip.updateSetting(_settings);

      void applyPageChange() {
        if (!mounted) return;
        if (_currentPageIndex != newIndex && widget.pageCount > 20) {
          setState(() {
            _currentPageIndex = newIndex;
          });
        } else {
          _currentPageIndex = newIndex;
        }
        if (isRtl && !widget.settings.usePortrait) {
          widget.onPageChanged?.call(right, left);
        } else {
          widget.onPageChanged?.call(left, right);
        }
      }

      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.persistentCallbacks ||
          phase == SchedulerPhase.midFrameMicrotasks) {
        SchedulerBinding.instance.addPostFrameCallback((_) => applyPageChange());
      } else {
        applyPageChange();
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

    // Virtual windowing: enabled only for large books (> 20 pages) to prevent OOM.
    // For normal/small books, all pages stay stable in the tree to eliminate rebuild/drop flicker.
    final bool enableVirtualWindowing = widget.pageCount > 20;
    final windowStart = enableVirtualWindowing
        ? (_currentPageIndex - 4).clamp(0, widget.pageCount - 1)
        : 0;
    final windowEnd = enableVirtualWindowing
        ? (_currentPageIndex + 5).clamp(0, widget.pageCount - 1)
        : widget.pageCount - 1;

    final children = List<Widget>.generate(
      widget.pageCount,
      (index) {
        if (enableVirtualWindowing &&
            (index < windowStart || index > windowEnd)) {
          return PageHost(
            key: ValueKey('page_host_$index'),
            index: index,
            child: const SizedBox.shrink(),
          );
        }

        final rawChild = widget.builder(context, index);
        final content = isRtl
            ? Directionality(
                textDirection: effectiveDir,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                  child: rawChild,
                ),
              )
            : rawChild;

        return PageHost(
          key: ValueKey('page_host_$index'),
          index: index,
          child: content,
        );
      },
      growable: false,
    );

    Widget bookWidget = TurnableBookRenderObjectWidget(
      pageCount: widget.pageCount,
      settings: _settings,
      pageFlip: _pageFlip,
      isZoomed: _isZoomed,
      children: children,
    );

    if (isRtl) {
      bookWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: bookWidget,
      );
    }

    Widget content = PaperWidget(
      size: widget.bookSize,
      isSinglePage: widget.settings.usePortrait,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      isEnabled: widget.pagesBoundaryIsEnabled,
      child: bookWidget,
    );

    if (_settings.enableZoom) {
      content = GestureDetector(
        onDoubleTap: () {
          if (_isZoomed) {
            _resetZoom();
          } else {
            _transformationController.value =
                Matrix4.diagonal3Values(2.0, 2.0, 1.0);
          }
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: _settings.minScale,
          maxScale: _settings.maxScale,
          panEnabled: _isZoomed,
          scaleEnabled: true,
          child: content,
        ),
      );
    }

    return content;
  }
}

