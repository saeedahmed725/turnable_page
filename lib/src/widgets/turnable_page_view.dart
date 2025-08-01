import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../turnable_page.dart';
import '../page/page_flip.dart';
import 'page_flip_painter.dart';
import 'paper_widget.dart';

class TurnablePageView extends StatefulWidget {
  final PageFlipController? controller;
  final TurnableBuilder pageBuilder;
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
    required this.pageBuilder,
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

class _TurnablePageViewState extends State<TurnablePageView>
    with SingleTickerProviderStateMixin {
  /// Instance of PageFlip to handle the flipping logic
  late PageFlip _pageFlip;

  /// Animation controller to handle the flipping animation
  late AnimationController _animationController;

  /// Check if we need to add a white page in the end of the book for even total page count
  bool get _needsWhitePage =>
      widget.settings.usePortrait ? false : widget.pageCount % 2 == 1;

  /// Get the adjusted settings for the PageFlip instance
  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: widget.settings.startPageIndex,
  );

  /// Flag to indicate if the widget needs repainting
  bool _needsRepaint = true;

  @override
  void initState() {
    // Initialize the PageFlip instance with the provided settings
    _animationController = AnimationController(
      duration: Duration(milliseconds: widget.settings.flippingTime),
      vsync: this,
    );

    // Create the PageFlip instance with the adjusted settings
    _pageFlip = PageFlip(_settings);
    _setupPageFlipEventsAndController();
    _loadPageContent();
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
        _loadPageContent();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _setupPageFlipEventsAndController() async {
    widget.controller?.initializeController(
      pageFlip: _pageFlip,
      startAnimation: _startAnimation,
      stopAnimation: _stopAnimation,
    );
    // Set up event listeners
    _pageFlip.on('flip', (_) {
      final newIndex = _pageFlip.getCurrentPageIndex();
      final left = newIndex.clamp(0, widget.pageCount - 1);
      final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
      widget.settings.startPageIndex = left;
      _pageFlip.updateSetting(_settings);
      widget.onPageChanged?.call(left, right);
    });

    _pageFlip.on('init', (_) async {
      log('PageFlip initialized with ${widget.pageCount} pages');
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Start animation when needed
  void _startAnimation() {
    _needsRepaint = true;
    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
  }

  /// Stop animation when not needed to save performance
  void _stopAnimation() {
    _resizeTimer?.cancel();
    _resizeTimer = Timer(
      Duration(milliseconds: widget.settings.flippingTime),
      () {
        _needsRepaint = false;
        if (_animationController.isAnimating) {
          _animationController.stop();
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resizeTimer?.cancel();
    super.dispose();
  }

  Future<ui.Image> captureWidgetOffScreen(
    Widget child, {
    double pixelRatio = 3.0,
  }) async {
    // Create render boundary and view configuration
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.expand(
          width: widget.settings.width,
          height: widget.settings.height,
        ),
        devicePixelRatio: pixelRatio,
      ),
      view: ui.PlatformDispatcher.instance.implicitView!,
      child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
    );

    // Set up pipeline and build owners
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    // Attach widget to render tree
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ).attachToRenderTree(buildOwner);

    // Render the widget
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    return boundary.toImage(pixelRatio: pixelRatio);
  }

  Future<void> _loadPageContent() async {
    final images = <ui.Image>[];

    // Generate images for each page
    for (var i = 0; i < widget.pageCount; i++) {
      try {
        final image = await captureWidgetOffScreen(
          widget.pageBuilder(
            i,
            BoxConstraints(
              maxWidth: widget.bookSize.width,
              maxHeight: widget.bookSize.height,
            ),
          ),
          pixelRatio: widget.pixelRatio,
        );
        images.add(image);
      } catch (e) {
        images.add(await _createFallbackImage(i));
      }
    }

    // Add white page for odd page count
    if (_needsWhitePage) {
      images.add(await _createTransparentImage());
    }

    // Load images and show start page
    _pageFlip.loadFromWidgets(images);
    _pageFlip.pages?.show(widget.settings.startPageIndex);
  }

  Future<ui.Image> _createTransparentImage() async {
    final recorder = ui.PictureRecorder();
    final _ = Canvas(recorder);
    return recorder.endRecording().toImage(
      (widget.settings.width).toInt(),
      (widget.settings.height).toInt(),
    );
  }

  Future<ui.Image> _createFallbackImage(int pageIndex) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = widget.bookSize;

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw error text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Failed to render page $pageIndex',
        style: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    return recorder.endRecording().toImage(
      (size.width * widget.pixelRatio).toInt(),
      (size.height * widget.pixelRatio).toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSinglePage = widget.settings.usePortrait;

    return PaperWidget(
      size: widget.bookSize,
      isSinglePage: isSinglePage,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      padding: const EdgeInsetsDirectional.only(
        start: 4.0,
        end: 4.0,
        top: 1.0,
        bottom: 2.0,
      ),
      child: GestureDetector(
        onPanStart: (details) => _pageFlip.canvasInteractionHandler
            .handleOnPanStart(details.localPosition, () => _startAnimation()),
        onPanUpdate: (details) => _pageFlip.canvasInteractionHandler
            .handleOnPanUpdate(details.localPosition),
        onPanEnd: (details) => _pageFlip.canvasInteractionHandler
            .handleOnPanEnd(details.localPosition),
        onTapUp: (details) => _stopAnimation(),
        onTapDown: (details) {
          _startAnimation();
          _pageFlip.canvasInteractionHandler.handleClick(details.localPosition);
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              key: UniqueKey(),
              size: widget.bookSize,
              painter: PageFlipPainter(_pageFlip.render, _needsRepaint),
            );
          },
        ),
      ),
    );
  }
}
