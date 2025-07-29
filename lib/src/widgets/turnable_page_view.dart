import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../turnable_page.dart';
import '../enums/flip_corner.dart';
import '../flip/flip_settings.dart';
import '../page/page_flip.dart';
import '../render/render.dart';
import 'page_flip_controller.dart';

class TurnablePageView extends StatefulWidget {
  /// Optional controller for programmatic control
  final PageFlipController? controller;

  /// Custom page builder function for widget content
  final TurnableBuilder pageBuilder;

  /// Total number of pages
  final int pageCount;

  /// Callback when page changes
  final TurnablePageCallback? onPageChanged;

  /// Page flip settings configuration
  final FlipSetting settings;

  /// Aspect ratio for individual pages (width/height ratio)
  /// Default: 2/3 ≈ 0.667 for single page (6" × 9") and 3/4 ≈ 0.75 for two-page spread (8.5" × 11")
  /// Adjust based on your design requirements
  final double aspectRatio;

  /// Pixel ratio for high-quality rendering
  final double pixelRatio;
  final Size bookSize;

  /// Create a PageFlipWidget in portrait mode (single page view)
  const TurnablePageView.singlePage({
    super.key,
    this.controller,
    required this.pageBuilder,
    required this.pageCount,
    this.onPageChanged,
    this.aspectRatio = 2 / 3,
    this.pixelRatio = 1.0,
    this.autoResponse = true,
    required this.bookSize,
    FlipSetting? settings,
  }) : settings = const FlipSetting(usePortrait: true);

  /// Create a PageFlipWidget in landscape mode (two-page spread view)
  const TurnablePageView.twoPages({
    super.key,
    this.controller,
    required this.pageBuilder,
    required this.pageCount,
    this.onPageChanged,
    this.aspectRatio = 3 / 4,
    this.pixelRatio = 1.0,
    required this.bookSize,
    FlipSetting? settings,
  }) : autoResponse = false,
       settings = const FlipSetting(usePortrait: false);

  final bool autoResponse;

  @override
  State<TurnablePageView> createState() => _TurnablePageViewState();
}

class _TurnablePageViewState extends State<TurnablePageView>
    with TickerProviderStateMixin {
  late PageFlip _pageFlip;
  late AnimationController _animationController;
  int _currentPageIndex = 0;
  bool _needsRepaint = true;
  late final List<GlobalKey> globalKeys;

  /// Check if we need to add a white page in the end of the book for even total page count
  bool get _needsWhitePage => widget.pageCount % 2 == 1;

  /// Get the actual page count including white page if needed
  int get totalpageCount =>
      _needsWhitePage ? widget.pageCount + 1 : widget.pageCount;

  late Size bookSize;

  @override
  void initState() {
    bookSize =widget.bookSize;
    globalKeys = List.generate(
      totalpageCount,
      (index) => GlobalKey(debugLabel: "PageFlipWidgetPageKey-$index"),
    );
    _currentPageIndex = widget.settings.startPage;
    // Use 60 FPS for smooth animation but with optimization
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    );
    // Only animate when needed - not continuously
    _animationController.addListener(() {
      if (_needsRepaint && mounted) {
        setState(() {});
      }
    });
    _pageFlip = PageFlip(widget.settings);
    _updateSize();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPageFlip();

    });
  }
  void _updateSize(){
    bookSize = widget.bookSize;
    final isPortrait = bookSize.width < bookSize.height;

    _pageFlip.updateSetting(
      widget.settings.copyWith(
        usePortrait: isPortrait,
        height: bookSize.height,
        width: bookSize.width / (isPortrait ? 1 : 2),
        minHeight: bookSize.height,
        minWidth: bookSize.width / (isPortrait ? 1 : 2),
        maxHeight: bookSize.height,
        maxWidth: bookSize.width / (isPortrait ? 1 : 2),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant TurnablePageView oldWidget) {
    if (
        widget.bookSize.width != oldWidget.bookSize.width &&
        widget.bookSize.height != oldWidget.bookSize.height) {
      _updateSize();
      _setupPageFlip(); // تحميل الصفحات بالحجم الجديد
        setState(() {});
    }

    super.didUpdateWidget(oldWidget);
  }

  /// Flip to the next page
  void flipNext([FlipCorner corner = FlipCorner.top]) {
    _startAnimation();
    _pageFlip.flipNext(corner);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _stopAnimation();
    });
  }

  /// Flip to the previous page
  void flipPrevious([FlipCorner corner = FlipCorner.top]) {
    _startAnimation();
    _pageFlip.flipPrev(corner);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _stopAnimation();
    });
  }

  /// Turn to a specific page
  void turnToPage(int pageIndex) {
    _startAnimation();
    _pageFlip.flip(pageIndex, FlipCorner.top);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _stopAnimation();
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
    _needsRepaint = false;
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _setupPageFlip() async {
    await _loadPageContent();
    // Initialize the controller if provided
    widget.controller?.initializeController(
      pageFlip: _pageFlip,
      onNextPage: flipNext,
      onPreviousPage: flipPrevious,
      onGoToPage: turnToPage,
    );

    // Set up event listeners
    _pageFlip.on('flip', (data) {
      if (mounted) {
        final newPageIndex = _pageFlip.getCurrentPageIndex();
        if (newPageIndex != _currentPageIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentPageIndex = newPageIndex;
              });

              // Calculate correct indexes for the callback
              int leftPageIndex = newPageIndex;
              int rightPageIndex = newPageIndex + 1;

              // Ensure we don't exceed the original page count
              if (leftPageIndex >= widget.pageCount) {
                leftPageIndex = widget.pageCount - 1;
              }
              if (rightPageIndex >= widget.pageCount) {
                rightPageIndex = -1; // No right page if it's the white page
              }

              widget.onPageChanged?.call(leftPageIndex, rightPageIndex);
            }
          });
        }
      }
    });

    _pageFlip.on('init', (data) {
      log('PageFlip init complete, showing page: ${widget.settings.startPage}');
      setState(() {});
    });

    _pageFlip.on('animationComplete', (data) {
      log('PageFlip animation complete');
      if (mounted) {
        _stopAnimation();
      }
    });
  }

  Future<void> _loadPageContent() async {
    List<ui.Image> images = [];

    for (int i = 0; i < widget.pageCount; i++) {
      try {
        // globalKeys[index].currentState.
        RenderRepaintBoundary boundary =
            globalKeys[i].currentContext?.findRenderObject()
                as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(
          pixelRatio: widget.pixelRatio,
        ); // High quality

        images.add(image);
      } catch (e) {
        ui.Image fallbackImage = await _createFallbackImage(i);
        images.add(fallbackImage);
      }
    }

    // Add white page if needed for odd page count
    if (_needsWhitePage) {
      final whitePage = await _createWhitePage();
      images.add(whitePage);
    }

    // Load images into the PageFlip instance
    _pageFlip.loadFromWidgets(images);

    // Ensure the start page is shown
    _pageFlip.pages?.show(widget.settings.startPage);
  }

  Future<ui.Image> _createWhitePage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Calculate individual page dimensions
    final pageWidth = bookSize.width;
    final pageHeight = bookSize.height;

    // Create a pure white background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, pageWidth, pageHeight), paint);

    final picture = recorder.endRecording();
    return await picture.toImage(
      (pageWidth * widget.pixelRatio).toInt(),
      (pageHeight * widget.pixelRatio).toInt(),
    );
  }

  Future<ui.Image> _createFallbackImage(int pageIndex) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Calculate individual page dimensions
    final pageWidth = bookSize.width;
    final pageHeight = bookSize.height;

    // Create a white background with error message
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, pageWidth, pageHeight), paint);

    // Add error text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Failed to render page $pageIndex',
        style: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (pageWidth - textPainter.width) / 2,
        (pageHeight - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    return await picture.toImage(
      (pageWidth * widget.pixelRatio).toInt(),
      (pageHeight * widget.pixelRatio).toInt(),
    );
  }


  @override
  Widget build(BuildContext context) {

    return Center(
      child: SizedBox(
        width: bookSize.width,
        height: bookSize.height,
        child: GestureDetector(
          onPanStart: (details) {
            final position = details.localPosition;
            _startAnimation();
            (_pageFlip.canvasInteractionHandler).handleMouseDown(position);
          },
          onPanUpdate: (details) {
            final position = details.localPosition;
            _pageFlip.canvasInteractionHandler.handleMouseMove(position);
          },
          onPanEnd: (details) {
            final position = details.localPosition;
            _pageFlip.canvasInteractionHandler.handleMouseUp(position);
          },
          onTapUp: (details) {
            final position = details.localPosition;
            _startAnimation();
            _pageFlip.canvasInteractionHandler.handleClick(position);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _stopAnimation();
            });
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {

              return CustomPaint(
                key: ValueKey(bookSize.width.toString() + bookSize.height.toString()),
                willChange: true,
                painter: _PageFlipPainter(

                    _pageFlip.render, _needsRepaint),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageFlipPainter extends CustomPainter {
  final Render? render;
  final bool needsRepaint;

  _PageFlipPainter(this.render, this.needsRepaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (render != null) {
      // Use the provided size which should match the widget's canvas size
      render!.setCanvas(canvas, size);
      // Call render with current time to process animations
      final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
      render!.render(currentTime);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _PageFlipPainter) {
      return needsRepaint || oldDelegate.needsRepaint;
    }
    return true;
  }
}
