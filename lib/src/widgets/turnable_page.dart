import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../enums/flip_corner.dart';
import '../flip/flip_settings.dart';
import '../page/page_flip.dart';
import '../render/render.dart';
import 'page_flip_controller.dart';

typedef TurnableBuilder =
    Widget Function(int pageIndex, BoxConstraints constraints);
typedef TurnablePageCallback =
    void Function(int leftPageIndex, int rightPageIndex);

class TurnablePage extends StatefulWidget {
  /// Optional controller to enable programmatic page turning and control.
  ///
  /// If provided, this controller allows you to flip pages, jump to a specific page,
  /// or listen to page flip events from outside the widget.
  final PageFlipController? controller;

  /// Builder function to generate the content of each page.
  ///
  /// This function is called for every page and provides the current `pageIndex`
  /// and the `BoxConstraints` for sizing. Return the widget you want to display
  /// for the given page index.
  ///
  /// Example:
  ///   (index, constraints) => MyPageWidget(index: index, constraints: constraints)
  final TurnableBuilder pageBuilder;

  /// Total number of pages
  final int pageCount;

  /// Callback triggered when the visible page changes.
  ///
  /// The callback provides the indexes of the left and right pages currently displayed:
  /// - In single page mode, `leftPageIndex` will be `-1` and `rightPageIndex` will be the current page.
  /// - In two-page mode, both indexes are provided. If the last page is a white filler (due to an odd page count),
  ///   `rightPageIndex` will be `-1`.
  ///
  /// Example:
  ///   onPageChanged: (left, right) {
  ///     // left: index of the left page, or -1 if not present
  ///     // right: index of the right page, or -1 if not present
  ///   }
  final TurnablePageCallback? onPageChanged;

  /// Page flip settings configuration
  final FlipSetting settings;

  /// Aspect ratio for individual pages (width/height ratio)
  /// Default: 2/3 ≈ 0.667 for single page (6" × 9") and 3/4 ≈ 0.75 for two-page spread (8.5" × 11")
  /// Adjust based on your design requirements
  final double aspectRatio;

  /// Pixel ratio for high-quality rendering
  final double pixelRatio;

  /// Create a PageFlipWidget in portrait mode (single page view)
  const TurnablePage.singlePage({
    super.key,
    this.controller,
    required this.pageBuilder,
    required this.pageCount,
    this.onPageChanged,
    this.aspectRatio = 2 / 3,
    this.pixelRatio = 1.0,
    FlipSetting? settings,
  }) : settings = const FlipSetting(usePortrait: true);

  /// Create a PageFlipWidget in landscape mode (two-page spread view)
  const TurnablePage.twoPages({
    super.key,
    this.controller,
    required this.pageBuilder,
    required this.pageCount,
    this.onPageChanged,
    this.aspectRatio = (2 / 3) * 2,
    this.pixelRatio = 1.0,
    FlipSetting? settings,
  }) : settings = const FlipSetting(usePortrait: false);

  @override
  State<TurnablePage> createState() => _TurnablePageState();
}

class _TurnablePageState extends State<TurnablePage>
    with TickerProviderStateMixin {
  late PageFlip _pageFlip;
  late AnimationController _animationController;
  late FlipSetting settings;
  int _currentPageIndex = 0;
  bool _needsRepaint = true;
  late final List<GlobalKey> globalKeys;

  /// Check if we need to add a white page in the end of the book for even total page count
  bool get _needsWhitePage => (widget.pageCount % 2 == 1) &&
      !widget.settings.usePortrait;

  /// Get the actual page count including white page if needed
  int get totalpageCount =>
      _needsWhitePage ? widget.pageCount + 1 : widget.pageCount;

  Size bookSize = const Size(0, 0);

  Size calculateBookSize({
    required double maxWidth,
    required double maxHeight,
  }) {
    double width = maxWidth;
    double height = width / widget.aspectRatio;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * widget.aspectRatio;
    }

    return Size(width, height);
  }

  @override
  void initState() {
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
    
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPageFlip();
    });
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
              if (widget.settings.usePortrait) {
                leftPageIndex = -1;
              }
              widget.onPageChanged?.call(leftPageIndex, rightPageIndex);
            }
          });
        }
      }
    });

    _pageFlip.on('init', (data) {
      setState(() {});
    });

    _pageFlip.on('animationComplete', (data) {
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
        style: const TextStyle(color: Colors.black, fontSize: 16),
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

  Size? _oldBookSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bookSize = calculateBookSize(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );
        if (_oldBookSize == null ||
            bookSize.hasSignificantChange(_oldBookSize!)) {
          _oldBookSize = bookSize;
          if (mounted) {
            _pageFlip.updateSetting(
              widget.settings.copyWith(
                height: bookSize.height,
                width: bookSize.width / (widget.settings.usePortrait ? 1 : 2),
              ),
            );
            _setupPageFlip();
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: bookSize.width,
              height: bookSize.height,
              child: GestureDetector(
                onPanStart: (details) {
                  final position = details.localPosition;
                  _startAnimation();
                  (_pageFlip.canvasInteractionHandler).handleMouseDown(
                    position,
                  );
                },
                onPanUpdate: (details) {
                  final position = details.localPosition;
                  _pageFlip.canvasInteractionHandler.handleMouseMove(
                    position,
                  );
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
                      size: Size(bookSize.width, bookSize.height),
                      painter: _PageFlipPainter(
                        _pageFlip.render,
                        _needsRepaint,
                      ),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              left: -bookSize.height * 3,
              top: 0,
              child: SizedBox(
                width: bookSize.width / (widget.settings.usePortrait ? 1 : 2),
                height: bookSize.height,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Render actual content pages
                      ...List.generate(widget.pageCount, (index) {
                        return SizedBox(
                          width: bookSize.width,
                          height: bookSize.height,
                          child: RepaintBoundary(
                            key: globalKeys[index],
                            child: Container(
                              clipBehavior: Clip.hardEdge,
                              decoration: const BoxDecoration(),
                              child: widget.pageBuilder(
                                index,
                                BoxConstraints(
                                  maxWidth:
                                      bookSize.width /
                                      (widget.settings.usePortrait ? 1 : 2),
                                  minWidth:
                                      bookSize.width /
                                      (widget.settings.usePortrait ? 1 : 2),
                                  minHeight: bookSize.height,
                                  maxHeight: bookSize.height,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_needsWhitePage)
                        SizedBox(
                          width:
                              bookSize.width /
                              (widget.settings.usePortrait ? 1 : 2),
                          height: bookSize.height,
                          child: RepaintBoundary(
                            key: globalKeys[widget.pageCount],
                            child: Container(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

extension SizeDiffExtension on Size {
  bool hasSignificantChange(Size other, [double threshold = 20.0]) {
    return (width - other.width).abs() > threshold ||
        (height - other.height).abs() > threshold;
  }
}
