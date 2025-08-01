// import 'dart:async';
// import 'dart:developer';
// import 'dart:ui' as ui;
//
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
//
// import 'src/flip/flip_settings.dart';
// import 'src/model/paper_boundary_decoration.dart';
// import 'src/page/page_flip.dart';
// import 'src/widgets/page_flip_controller.dart';
// import 'src/widgets/page_flip_painter.dart';
// import 'src/widgets/paper_widget.dart';
// import 'src/widgets/turnable_page.dart';
//
// class TurnablePageView extends StatefulWidget {
//   final PageFlipController? controller;
//   final TurnableBuilder pageBuilder;
//   final int pageCount;
//   final TurnablePageCallback? onPageChanged;
//   final FlipSettings settings;
//   final double aspectRatio;
//   final double pixelRatio;
//   final Size bookSize;
//   final PaperBoundaryDecoration paperBoundaryDecoration;
//
//   const TurnablePageView({
//     super.key,
//     this.controller,
//     this.onPageChanged,
//     required this.pageBuilder,
//     required this.pageCount,
//     required this.aspectRatio,
//     required this.pixelRatio,
//     required this.bookSize,
//     required this.settings,
//     required this.paperBoundaryDecoration,
//   });
//
//   @override
//   State<TurnablePageView> createState() => _TurnablePageViewState();
// }
//
// class _TurnablePageViewState extends State<TurnablePageView>
//     with SingleTickerProviderStateMixin {
//   /// Instance of PageFlip to handle the flipping logic
//   late PageFlip _pageFlip;
//
//   /// Animation controller to handle the flipping animation
//   late AnimationController _animationController;
//
//   /// Check if we need to add a white page in the end of the book for even total page count
//   bool get _needsWhitePage =>
//       widget.settings.usePortrait ? false : widget.pageCount % 2 == 1;
//
//   /// Get the adjusted settings for the PageFlip instance
//   FlipSettings get _settings => widget.settings.copyWith(
//     width: widget.bookSize.width,
//     height: widget.bookSize.height,
//     startPage: widget.settings.startPageIndex,
//   );
//
//   /// Flag to indicate if the widget needs repainting
//   bool _needsRepaint = true;
//
//   /// Cached images for the pages
//   Map<int, ui.Image> _cachedImages = {};
//
//   @override
//   void initState() {
//     // Initialize the PageFlip instance with the provided settings
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 16),
//       vsync: this,
//     );
//
//     // Create the PageFlip instance with the adjusted settings
//     _pageFlip = PageFlip(_settings);
//     _setupPageFlipEventsAndController();
//     _loadPageContent();
//     super.initState();
//   }
//
//   void _updateSize() {
//     _pageFlip.updateSetting(_settings);
//   }
//
//   Timer? _resizeTimer;
//
//   @override
//   void didUpdateWidget(covariant TurnablePageView oldWidget) {
//     final hasWidthChanged = widget.bookSize.width != oldWidget.bookSize.width;
//     final hasHeightChanged =
//         widget.bookSize.height != oldWidget.bookSize.height;
//     if (hasWidthChanged || hasHeightChanged) {
//       _resizeTimer?.cancel();
//       _resizeTimer = Timer(const Duration(milliseconds: 100), () {
//         _updateSize();
//         _loadPageContent();
//       });
//     }
//     super.didUpdateWidget(oldWidget);
//   }
//
//   Future<void> _setupPageFlipEventsAndController() async {
//     widget.controller?.initializeController(
//       pageFlip: _pageFlip,
//       startAnimation: _startAnimation,
//       stopAnimation: _stopAnimation,
//     );
//     // Set up event listeners
//     _pageFlip.on('flip', (_) {
//       final newIndex = _pageFlip.getCurrentPageIndex();
//       final left = newIndex.clamp(0, widget.pageCount - 1);
//       final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
//       widget.settings.startPageIndex = left;
//       _pageFlip.updateSetting(_settings);
//       widget.onPageChanged?.call(left, right);
//     });
//
//     _pageFlip.on('init', (data) async {
//       log('PageFlip initialized with ${data.data} pages');
//       if (mounted) {
//         setState(() {});
//       }
//     });
//   }
//
//   /// Start animation when needed
//   void _startAnimation() {
//     _needsRepaint = true;
//     if (!_animationController.isAnimating) {
//       _animationController.repeat();
//     }
//   }
//
//   /// Stop animation when not needed to save performance
//   void _stopAnimation() {
//     _needsRepaint = false;
//     if (_animationController.isAnimating) {
//       _animationController.stop();
//     }
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _resizeTimer?.cancel();
//     super.dispose();
//   }
//
//   Future<ui.Image> captureWidgetOffScreen(
//     Widget child, {
//     double pixelRatio = 3.0,
//   }) async {
//     // Create render boundary and view configuration
//     final boundary = RenderRepaintBoundary();
//     final renderView = RenderView(
//       configuration: ViewConfiguration(
//         logicalConstraints: BoxConstraints.expand(
//           width: widget.settings.width,
//           height: widget.settings.height,
//         ),
//         devicePixelRatio: pixelRatio,
//       ),
//       view: ui.PlatformDispatcher.instance.implicitView!,
//       child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
//     );
//
//     // Set up pipeline and build owners
//     final pipelineOwner = PipelineOwner();
//     final buildOwner = BuildOwner(focusManager: FocusManager());
//
//     // Attach widget to render tree
//     final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
//       container: boundary,
//       child: Directionality(textDirection: TextDirection.ltr, child: child),
//     ).attachToRenderTree(buildOwner);
//
//     // Render the widget
//     pipelineOwner.rootNode = renderView;
//     renderView.prepareInitialFrame();
//     buildOwner.buildScope(rootElement);
//     buildOwner.finalizeTree();
//     pipelineOwner
//       ..flushLayout()
//       ..flushCompositingBits()
//       ..flushPaint();
//
//     return boundary.toImage(pixelRatio: pixelRatio);
//   }
//
//   final int _batchSize = 4;
//
//   Future<void> _loadPageContent() async {
//     final images = <ui.Image>[];
//     final endIndex = (widget.settings.startPageIndex + _batchSize).clamp(
//       0,
//       widget.pageCount,
//     );
//
//     // Generate images for each page
//     for (int i = widget.settings.startPageIndex; i < endIndex; i++) {
//       if (_cachedImages.containsKey(i)) continue;
//
//       try {
//         final image = await captureWidgetOffScreen(
//           widget.pageBuilder(
//             i,
//             BoxConstraints(
//               maxWidth: widget.bookSize.width,
//               maxHeight: widget.bookSize.height,
//             ),
//           ),
//           pixelRatio: widget.pixelRatio,
//         );
//         images.add(image);
//       } catch (e) {
//         images.add(await _createFallbackImage(i));
//       }
//     }
//
//     // Add white page for odd page count
//     if (_needsWhitePage) {
//       images.add(await _createWhitePage());
//     }
//
//     // Load images and show start page
//     _pageFlip.loadFromWidgets(images);
//     _pageFlip.pages?.show(widget.settings.startPageIndex);
//   }
//
//   Future<ui.Image> _createWhitePage() async {
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder);
//     final size = widget.bookSize;
//
//     // Draw white background
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Paint()..color = Colors.white,
//     );
//
//     return recorder.endRecording().toImage(
//       (size.width * widget.pixelRatio).toInt(),
//       (size.height * widget.pixelRatio).toInt(),
//     );
//   }
//
//   Future<ui.Image> _createFallbackImage(int pageIndex) async {
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder);
//     final size = widget.bookSize;
//
//     // Draw white background
//     canvas.drawRect(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Paint()..color = Colors.white,
//     );
//
//     // Draw error text
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: 'Failed to render page $pageIndex',
//         style: const TextStyle(color: Colors.black, fontSize: 20),
//       ),
//       textDirection: TextDirection.ltr,
//     )..layout();
//     textPainter.paint(
//       canvas,
//       Offset(
//         (size.width - textPainter.width) / 2,
//         (size.height - textPainter.height) / 2,
//       ),
//     );
//
//     return recorder.endRecording().toImage(
//       (size.width * widget.pixelRatio).toInt(),
//       (size.height * widget.pixelRatio).toInt(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isSinglePage = widget.settings.usePortrait;
//
//     return PaperWidget(
//       size: widget.bookSize,
//       isSinglePage: isSinglePage,
//       paperBoundaryDecoration: widget.paperBoundaryDecoration,
//       padding: const EdgeInsetsDirectional.only(
//         start: 4.0,
//         end: 4.0,
//         top: 1.0,
//         bottom: 2.0,
//       ),
//       child: GestureDetector(
//         onPanStart: (details) {
//           final position = details.localPosition;
//           _startAnimation();
//           (_pageFlip.canvasInteractionHandler).handleMouseDown(position);
//         },
//         onPanUpdate: (details) {
//           final position = details.localPosition;
//           _pageFlip.canvasInteractionHandler.handleMouseMove(position);
//         },
//         onPanEnd: (details) {
//           final position = details.localPosition;
//           _pageFlip.canvasInteractionHandler.handleMouseUp(position);
//         },
//         onTapUp: (details) {
//           final position = details.localPosition;
//           _startAnimation();
//           _pageFlip.canvasInteractionHandler.handleClick(position);
//           Future.delayed(const Duration(milliseconds: 500), () {
//             _stopAnimation();
//           });
//         },
//         child: AnimatedBuilder(
//           animation: _animationController,
//           builder: (context, child) {
//             return CustomPaint(
//               size: widget.bookSize,
//               painter: PageFlipPainter(_pageFlip.render, _needsRepaint),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
