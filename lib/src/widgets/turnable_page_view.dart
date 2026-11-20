import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../turnable_page.dart';
import '../enums/book_orientation.dart';
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

  /// Number of pages kept built on EACH side of the current page when the
  /// book is large (more than [virtualWindowingThreshold] pages). Pages
  /// outside `current - pageCacheExtent .. current + pageCacheExtent` are
  /// replaced by empty placeholders to bound memory. Pages that stay inside
  /// the window are never rebuilt because of a page change.
  final int pageCacheExtent;

  /// Books with more pages than this use virtual windowing (see
  /// [pageCacheExtent]); smaller books keep every page built.
  static const int virtualWindowingThreshold = 20;

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
    this.pageCacheExtent = 4,
  }) : assert(pageCacheExtent >= 1, 'pageCacheExtent must be at least 1');

  @override
  State<TurnablePageView> createState() => _TurnablePageViewState();
}

class _TurnablePageViewState extends State<TurnablePageView> {
  /// PageFlip core logic
  late PageFlip _pageFlip;
  late final TransformationController _transformationController;
  bool _isZoomed = false;

  /// Page currently shown (source of truth for the widget layer).
  late int _currentPageIndex;

  /// Center of the virtual window. Follows [_currentPageIndex], updated one
  /// frame after a page change so the turn's final frame is not slowed down
  /// by building/tearing down off-screen pages.
  late int _windowCenter;
  bool _windowUpdateScheduled = false;

  /// Built page widgets, reused across rebuilds caused by page changes or
  /// zoom so pages that stay in the window are not rebuilt. Cleared whenever
  /// the parent rebuilds us or an inherited dependency changes.
  final Map<int, Widget> _pageCache = <int, Widget>{};

  /// Get the adjusted settings for the PageFlip instance.
  ///
  /// `startPage` is the CURRENT page: the render object only reads it on its
  /// first layout, so a recreated render object resumes where the user was
  /// instead of jumping back to the original start page.
  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: _currentPageIndex,
  );

  bool get _isSingleMode {
    final orientation = _pageFlip.renderNullable?.getOrientation();
    if (orientation != null) {
      return orientation == BookOrientation.portrait;
    }
    if (widget.settings.pageViewMode == PageViewMode.auto) {
      return widget.bookSize.width <
          (widget.settings.width > 0 ? widget.settings.width * 2 : 600);
    }
    return widget.settings.pageViewMode == PageViewMode.single;
  }

  @override
  void didUpdateWidget(covariant TurnablePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent rebuilt us (new builder closure, settings, ...): page
    // content may have changed, so drop cached page widgets.
    _pageCache.clear();
    if (widget.controller != oldWidget.controller) {
      widget.controller?.initializeController(pageFlip: _pageFlip);
      widget.controller?.attachZoom(
        resetZoom: _resetZoom,
        isZoomed: () => _isZoomed,
      );
    }
    if (widget.pageCount != oldWidget.pageCount) {
      _currentPageIndex = _currentPageIndex.clamp(0, widget.pageCount - 1);
      _windowCenter = _currentPageIndex;
    }
    if (widget.settings != oldWidget.settings ||
        widget.bookSize != oldWidget.bookSize) {
      _pageFlip.updateSetting(_settings);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The page builder runs with our context; inherited changes (theme,
    // media query, ...) must reach the pages.
    _pageCache.clear();
  }

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.settings.startPageIndex;
    _windowCenter = _currentPageIndex;
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
    // Fired exactly once per page change, after the turn completed, with the
    // new page index (see PageFlip.updatePageIndex).
    _pageFlip.on(PageFlipEvent.flip, (event) {
      if (!mounted) return;
      final data = event.data;
      if (data is! int) return;
      final effectiveDir =
          widget.textDirection ??
          Directionality.maybeOf(context) ??
          TextDirection.ltr;
      final isRtl = effectiveDir == TextDirection.rtl;

      final newIndex = data.clamp(0, widget.pageCount - 1);
      final left = newIndex;
      final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;

      void applyPageChange() {
        if (!mounted) return;
        _currentPageIndex = newIndex;
        _updateWindowFor(newIndex);
        if (isRtl && !_isSingleMode) {
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

  bool get _usesWindowing =>
      widget.pageCount > TurnablePageView.virtualWindowingThreshold;

  /// Moves the virtual window to follow [page].
  ///
  /// If [page] or its direct neighbours (needed as the bottom/back page of
  /// the next turn) are outside the current window, the window moves now.
  /// Otherwise the move is deferred by one frame, so the frame that completes
  /// a turn does not also pay for building/disposing off-screen pages.
  void _updateWindowFor(int page) {
    if (!_usesWindowing || page == _windowCenter) return;
    final needsNow =
        (page - _windowCenter).abs() + 1 > widget.pageCacheExtent;
    if (needsNow) {
      setState(() => _windowCenter = page);
      return;
    }
    if (_windowUpdateScheduled) return;
    _windowUpdateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _windowUpdateScheduled = false;
      if (!mounted || _windowCenter == _currentPageIndex) return;
      setState(() => _windowCenter = _currentPageIndex);
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  Widget _buildPage(
    BuildContext context,
    int index,
    bool isRtl,
    TextDirection effectiveDir,
  ) {
    final rawChild = widget.builder(context, index);
    if (!isRtl) return rawChild;
    return Directionality(
      textDirection: effectiveDir,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: rawChild,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDir =
        widget.textDirection ??
        Directionality.maybeOf(context) ??
        TextDirection.ltr;
    final isRtl = effectiveDir == TextDirection.rtl;

    // Virtual windowing: enabled only for large books to bound memory. The
    // window is symmetric around the current page ([pageCacheExtent] pages on
    // each side). For small books all pages stay in the tree.
    final bool enableVirtualWindowing = _usesWindowing;
    final extent = widget.pageCacheExtent;
    final windowStart = enableVirtualWindowing
        ? (_windowCenter - extent).clamp(0, widget.pageCount - 1)
        : 0;
    final windowEnd = enableVirtualWindowing
        ? (_windowCenter + extent).clamp(0, widget.pageCount - 1)
        : widget.pageCount - 1;

    if (enableVirtualWindowing) {
      _pageCache.removeWhere((i, _) => i < windowStart || i > windowEnd);
    }

    final children = List<Widget>.generate(
      widget.pageCount,
      (index) {
        if (index < windowStart || index > windowEnd) {
          return PageHost(
            key: ValueKey('page_host_$index'),
            index: index,
            child: const SizedBox.shrink(),
          );
        }

        // Reusing the identical widget instance lets the framework skip
        // rebuilding pages that were already built.
        final content = _pageCache.putIfAbsent(
          index,
          () => _buildPage(context, index, isRtl, effectiveDir),
        );

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
      isSinglePage: _isSingleMode,
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

