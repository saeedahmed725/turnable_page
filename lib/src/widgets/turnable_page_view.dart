import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../turnable_page.dart';
import '../enums/book_orientation.dart';
import '../enums/flipping_state.dart';
import '../page/book_page_impl.dart';
import '../page/page_flip.dart';
import '../page/page_host.dart';
import 'page_edges.dart';
import 'turnable_book_render_object_widget.dart';

class TurnablePageView extends StatefulWidget {
  final PageFlipController? controller;
  final PageWidgetBuilder builder;
  final int pageCount;
  final TurnablePageCallback? onPageChanged;
  final FlipSettings settings;
  final double aspectRatio;
  final Size bookSize;
  final TextDirection? textDirection;

  /// Called once for each page turn that is going to complete (see
  /// [PageFlipEvent.turn]). Use it to play a page-turn sound.
  final void Function(FlipDirection direction)? onPageTurn;

  /// Text read by screen readers for the current page. Defaults to
  /// "Page 3 of 10".
  final String Function(int pageIndex, int pageCount)? semanticsValueBuilder;

  /// Builds the widgets shown on the empty sides of a lone cover spread
  /// (see [CoverSide]). Only used with `FlipSettings.showCover`.
  final Widget Function(BuildContext context, CoverSide side)? coverSideBuilder;

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
    this.textDirection,
    this.pageCacheExtent = 4,
    this.coverSideBuilder,
    this.onPageTurn,
    this.semanticsValueBuilder,
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

  /// Sequence number of the latest page-change report (see the flip handler).
  int _pageReportSeq = 0;
  bool _windowUpdateScheduled = false;

  /// Built page widgets, reused across rebuilds caused by page changes or
  /// zoom so pages that stay in the window are not rebuilt. Cleared whenever
  /// the parent rebuilds us or an inherited dependency changes.
  final Map<int, Widget> _pageCache = <int, Widget>{};

  /// Focus for keyboard navigation ([FlipSettings.keyboardNavigation]).
  final FocusNode _focusNode = FocusNode(debugLabel: 'TurnablePage');

  Timer? _peekOnOpenTimer;

  /// Current page, for the screen reader value.
  late final ValueNotifier<int> _pageNotifier;

  /// Time stamp of the last mouse wheel turn, to turn one page per wheel
  /// gesture.
  Duration? _lastWheelTurn;

  /// Get the adjusted settings for the PageFlip instance.
  ///
  /// `startPage` is the CURRENT page: the render object only reads it on its
  /// first layout, so a recreated render object resumes where the user was
  /// instead of jumping back to the original start page.
  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: _currentPageIndex,
    flippingTime: _reduceMotion
        ? math.min(widget.settings.flippingTime, 200)
        : null,
  );

  /// The system asks for less motion (see
  /// [FlipSettings.respectReducedMotion]).
  bool _reduceMotion = false;

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
      oldWidget.controller?.detach(_pageFlip);
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
    final reduce =
        widget.settings.respectReducedMotion &&
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _pageFlip.updateSetting(_settings);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.settings.startPageIndex;
    _windowCenter = _currentPageIndex;
    _pageNotifier = ValueNotifier<int>(_currentPageIndex);
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _pageFlip = PageFlip(_settings);
    _setupPageFlipEventsAndController();
    if (widget.settings.peekOnOpen) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _peekOnOpenTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) _pageFlip.peek();
        });
      });
    }
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
    widget.controller?.detach(_pageFlip);
    _peekOnOpenTimer?.cancel();
    _pageFlip.cancelPeek();
    _focusNode.dispose();
    _pageNotifier.dispose();
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
    _pageFlip.on(PageFlipEvent.turn, (event) {
      if (!mounted) return;
      final direction = event.data;
      if (direction is! FlipDirection) return;
      if (widget.settings.hapticFeedback) HapticFeedback.lightImpact();
      widget.onPageTurn?.call(direction);
    });

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

      // Each report gets a sequence number. A report deferred to a post-frame
      // callback may be overtaken by a newer one that is applied immediately
      // (e.g. `jumpToPage` called from another post-frame callback right
      // after the initial `show(startPageIndex)`). Applying the stale one
      // afterwards moved the window back to the old page and left the visible
      // page blank, so superseded reports are dropped.
      final seq = ++_pageReportSeq;

      void applyPageChange() {
        if (!mounted || seq != _pageReportSeq) return;
        _currentPageIndex = newIndex;
        _pageNotifier.value = newIndex;
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
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => applyPageChange(),
        );
      } else {
        applyPageChange();
      }
    });
  }

  bool get _isIdle {
    final state = _pageFlip.getState();
    return state == null ||
        state == FlippingState.read ||
        state == FlippingState.foldCorner;
  }

  void _turnNext() {
    if (_isIdle) _pageFlip.flipNext();
  }

  void _turnPrev() {
    if (_isIdle) _pageFlip.flipPrev();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event, bool isRtl) {
    if (!widget.settings.keyboardNavigation) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final forwardArrow = isRtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final backArrow = isRtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == forwardArrow ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.space) {
      _turnNext();
    } else if (key == backArrow ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      _turnPrev();
    } else if (key == LogicalKeyboardKey.home) {
      if (_isIdle) _pageFlip.turnToPage(0);
    } else if (key == LogicalKeyboardKey.end) {
      if (_isIdle) _pageFlip.turnToPage(widget.pageCount - 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!widget.settings.mouseWheelNavigation || _isZoomed) return;
    if (event is! PointerScrollEvent) return;
    // Scroll views inside a page register first and win.
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final scroll = e as PointerScrollEvent;
      final delta = scroll.scrollDelta.dy.abs() >= scroll.scrollDelta.dx.abs()
          ? scroll.scrollDelta.dy
          : scroll.scrollDelta.dx;
      if (delta.abs() < 1) return;
      // One page per wheel gesture: a trackpad sends many small events.
      final now = scroll.timeStamp;
      final last = _lastWheelTurn;
      if (last != null &&
          (now - last).inMilliseconds.abs() < widget.settings.flippingTime) {
        return;
      }
      if (!_isIdle) return;
      _lastWheelTurn = now;
      delta > 0 ? _turnNext() : _turnPrev();
    });
  }

  void _requestKeyboardFocus(PointerDownEvent _) {
    if (!widget.settings.keyboardNavigation) return;
    final primary = FocusManager.instance.primaryFocus;
    // Keep focus on a field or button inside a page.
    if (primary == _focusNode ||
        (primary != null && primary.ancestors.contains(_focusNode))) {
      return;
    }
    _focusNode.requestFocus();
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
    final needsNow = (page - _windowCenter).abs() + 1 > widget.pageCacheExtent;
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

    List<Widget> children = List<Widget>.generate(widget.pageCount, (index) {
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
    }, growable: false);

    // The cover side widgets go after the pages, front first.
    final sideBuilder = _settings.showCover ? widget.coverSideBuilder : null;
    if (sideBuilder != null) {
      Widget side(CoverSide s, int index) {
        Widget child = sideBuilder(context, s);
        if (isRtl) {
          child = Directionality(
            textDirection: effectiveDir,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
              child: child,
            ),
          );
        }
        return PageHost(
          key: ValueKey('cover_side_${s.name}'),
          index: index,
          child: child,
        );
      }

      children = [
        ...children,
        side(CoverSide.front, BookPageImpl.frontCoverSideIndex),
        side(CoverSide.back, BookPageImpl.backCoverSideIndex),
      ];
    }

    Widget bookWidget = TurnableBookRenderObjectWidget(
      pageCount: widget.pageCount,
      settings: _settings,
      pageFlip: _pageFlip,
      isZoomed: _isZoomed,
      coverSideCount: sideBuilder != null ? 2 : 0,
      children: children,
    );

    final edgesExtent = PageEdges.extent(
      enabled: _settings.showPageEdges,
      maxWidth: _settings.pageEdgeWidth,
    );

    if (isRtl) {
      bookWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: bookWidget,
      );
    }

    Widget content = SizedBox.fromSize(
      size: Size(widget.bookSize.width + edgesExtent, widget.bookSize.height),
      child: bookWidget,
    );

    if (_settings.enableZoom) {
      content = GestureDetector(
        onDoubleTap: _settings.enableDoubleTapZoom
            ? () {
                if (_isZoomed) {
                  _resetZoom();
                } else {
                  _transformationController.value = Matrix4.diagonal3Values(
                    2.0,
                    2.0,
                    1.0,
                  );
                }
              }
            : null,
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

    content = ValueListenableBuilder<int>(
      valueListenable: _pageNotifier,
      child: content,
      builder: (context, page, child) {
        final value =
            widget.semanticsValueBuilder?.call(page, widget.pageCount) ??
            'Page ${page + 1} of ${widget.pageCount}';
        final hasNext = page < widget.pageCount - 1;
        final hasPrev = page > 0;
        return Semantics(
          container: true,
          value: value,
          increasedValue: hasNext
              ? (widget.semanticsValueBuilder?.call(
                      page + 1,
                      widget.pageCount,
                    ) ??
                    'Page ${page + 2} of ${widget.pageCount}')
              : null,
          decreasedValue: hasPrev
              ? (widget.semanticsValueBuilder?.call(
                      page - 1,
                      widget.pageCount,
                    ) ??
                    'Page $page of ${widget.pageCount}')
              : null,
          onIncrease: hasNext ? _turnNext : null,
          onDecrease: hasPrev ? _turnPrev : null,
          child: child,
        );
      },
    );

    return Focus(
      focusNode: _focusNode,
      canRequestFocus: widget.settings.keyboardNavigation,
      skipTraversal: !widget.settings.keyboardNavigation,
      onKeyEvent: (node, event) => _onKey(node, event, isRtl),
      child: Listener(
        onPointerDown: _requestKeyboardFocus,
        onPointerSignal: _onPointerSignal,
        child: MouseRegion(
          // A corner folded by hovering falls back when the mouse leaves.
          onExit: (_) => _pageFlip.releaseCorner(),
          child: content,
        ),
      ),
    );
  }
}
