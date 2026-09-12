import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:turnable_page/src/widgets/paper_widget.dart';

import '../../turnable_page.dart';

/// Enum representing the source of the PDF document
enum PdfSource { asset, network, file }

/// Typedef for loading state builder
typedef LoadingBuilder =
    Widget Function(BuildContext context, String sourceDescription);

/// Typedef for error state builder
typedef ErrorBuilder =
    Widget Function(
      BuildContext context,
      String title,
      String message,
      VoidCallback? onRetry,
    );

/// A widget that loads a PDF (asset, network, or file) using pdfrx,
/// renders each page and displays it with page-turn animation via [TurnablePage].
///
/// Parameters:
/// - [source]: The source type of the PDF (asset, network, or file).
/// - [assetPath]: The asset path for loading the PDF from assets.
/// - [networkUrl]: The URL for loading the PDF from the network.
/// - [filePath]: The file path for loading the PDF from the local file system.
/// - [pageViewMode]: The mode for displaying pages (single or double).
/// - [paperBoundaryDecoration]: The decoration style for the page boundary.
/// - [pagePadding]: The padding around each page.
/// - [boxDecoration]: The decoration for the page container.
/// - [headers]: Optional HTTP headers for network requests.
/// - [settings]: The flip animation settings for [TurnablePage].
/// - [onPageChanged]: Callback when the visible page(s) change.
/// - [loadingBuilder]: Custom builder for loading state. If null, uses default loading UI.
/// - [errorBuilder]: Custom builder for error state. If null, uses default error UI.
/// - [aspectRatio]: The aspect ratio for the PDF pages.
/// - [autoResponseSize]: Whether to automatically adjust the response size.
/// - [controller]: Optional [PageFlipController] to control the page flip behavior.
/// - [pagesBoundaryIsEnabled]: Whether to enable the page boundary effect.
class TurnablePdf extends StatefulWidget {
  final PdfSource _source;
  final String? _assetPath;
  final String? _networkUrl;
  final String? _filePath;
  final PageFlipController? controller;
  final PageViewMode pageViewMode;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final EdgeInsets pagePadding;
  final BoxDecoration? boxDecoration;
  final Map<String, String>? headers; // For network requests
  final FlipSettings? settings;
  final void Function(int leftPageIndex, int rightPageIndex)? onPageChanged;
  final LoadingBuilder? loadingBuilder;
  final ErrorBuilder? errorBuilder;
  final double? aspectRatio;
  final bool pagesBoundaryIsEnabled;

  /// Internal constructor for [TurnablePdf].
  ///
  /// See parameter descriptions in [TurnablePdf].
  const TurnablePdf._internal({
    required PdfSource source,
    String? assetPath,
    String? networkUrl,
    String? filePath,
    this.controller,
    this.pageViewMode = PageViewMode.single,
    this.paperBoundaryDecoration = PaperBoundaryDecoration.modern,
    this.pagePadding = EdgeInsets.zero,
    this.boxDecoration,
    this.headers,
    this.settings,
    this.onPageChanged,
    this.loadingBuilder,
    this.errorBuilder,
    this.aspectRatio,
    this.pagesBoundaryIsEnabled = true,
    super.key,
  }) : _source = source,
       _assetPath = assetPath,
       _networkUrl = networkUrl,
       _filePath = filePath;

  /// Create a TurnablePdf from an asset.
  ///
  /// [assetPath]: The asset path of the PDF.
  /// [pageViewMode]: The mode for displaying pages (default: single).
  /// [paperBoundaryDecoration]: The decoration style for the page boundary.
  /// [pagePadding]: The padding around each page.
  /// [boxDecoration]: The decoration for the page container.
  /// [settings]: The flip animation settings for [TurnablePage].
  /// [onPageChanged]: Callback when the visible page(s) change.
  /// [loadingBuilder]: Custom builder for loading state.
  /// [errorBuilder]: Custom builder for error state.
  /// [aspectRatio]: The aspect ratio for the PDF pages.
  /// [autoResponseSize]: Whether to automatically adjust the response size.
  /// [key]: Optional widget key.
  factory TurnablePdf.asset(
    String assetPath, {
    PageFlipController? controller,
    PageViewMode pageViewMode = PageViewMode.single,
    PaperBoundaryDecoration paperBoundaryDecoration =
        PaperBoundaryDecoration.modern,
    EdgeInsets pagePadding = EdgeInsets.zero,
    BoxDecoration? boxDecoration,
    FlipSettings? settings,
    void Function(int leftPageIndex, int rightPageIndex)? onPageChanged,
    LoadingBuilder? loadingBuilder,
    ErrorBuilder? errorBuilder,
    double? aspectRatio,
    bool pagesBoundaryIsEnabled = true,
    Key? key,
  }) => TurnablePdf._internal(
    source: PdfSource.asset,
    assetPath: assetPath,
    controller: controller,
    pageViewMode: pageViewMode,
    paperBoundaryDecoration: paperBoundaryDecoration,
    pagePadding: pagePadding,
    boxDecoration: boxDecoration,
    settings: settings,
    onPageChanged: onPageChanged,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    aspectRatio: aspectRatio,
    pagesBoundaryIsEnabled: pagesBoundaryIsEnabled,
    key: key,
  );

  /// Create a TurnablePdf from a network URL.
  ///
  /// [url]: The network URL of the PDF.
  /// [pageViewMode]: The mode for displaying pages (default: single).
  /// [paperBoundaryDecoration]: The decoration style for the page boundary.
  /// [pagePadding]: The padding around each page.
  /// [boxDecoration]: The decoration for the page container.
  /// [headers]: Optional HTTP headers for the network request.
  /// [settings]: The flip animation settings for [TurnablePage].
  /// [onPageChanged]: Callback when the visible page(s) change.
  /// [loadingBuilder]: Custom builder for loading state.
  /// [errorBuilder]: Custom builder for error state.
  /// [aspectRatio]: The aspect ratio for the PDF pages.
  /// [autoResponseSize]: Whether to automatically adjust the response size.
  /// [key]: Optional widget key.
  factory TurnablePdf.network(
    String url, {
    PageFlipController? controller,
    PageViewMode pageViewMode = PageViewMode.single,
    PaperBoundaryDecoration paperBoundaryDecoration =
        PaperBoundaryDecoration.modern,
    EdgeInsets pagePadding = EdgeInsets.zero,
    BoxDecoration? boxDecoration,
    Map<String, String>? headers,
    FlipSettings? settings,
    void Function(int leftPageIndex, int rightPageIndex)? onPageChanged,
    LoadingBuilder? loadingBuilder,
    ErrorBuilder? errorBuilder,
    double? aspectRatio,
    bool pagesBoundaryIsEnabled = true,
    Key? key,
  }) => TurnablePdf._internal(
    source: PdfSource.network,
    networkUrl: url,
    controller: controller,
    pageViewMode: pageViewMode,
    paperBoundaryDecoration: paperBoundaryDecoration,
    pagePadding: pagePadding,
    boxDecoration: boxDecoration,
    headers: headers,
    settings: settings,
    onPageChanged: onPageChanged,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    aspectRatio: aspectRatio,
    pagesBoundaryIsEnabled: pagesBoundaryIsEnabled,
    key: key,
  );

  /// Create a TurnablePdf from a file path.
  ///
  /// [filePath]: The local file path of the PDF.
  /// [pageViewMode]: The mode for displaying pages (default: single).
  /// [paperBoundaryDecoration]: The decoration style for the page boundary.
  /// [pagePadding]: The padding around each page.
  /// [boxDecoration]: The decoration for the page container.
  /// [settings]: The flip animation settings for [TurnablePage].
  /// [onPageChanged]: Callback when the visible page(s) change.
  /// [loadingBuilder]: Custom builder for loading state.
  /// [errorBuilder]: Custom builder for error state.
  /// [aspectRatio]: The aspect ratio for the PDF pages.
  /// [autoResponseSize]: Whether to automatically adjust the response size.
  /// [key]: Optional widget key.
  factory TurnablePdf.file(
    String filePath, {
    PageFlipController? controller,

    PageViewMode pageViewMode = PageViewMode.single,
    PaperBoundaryDecoration paperBoundaryDecoration =
        PaperBoundaryDecoration.modern,
    EdgeInsets pagePadding = EdgeInsets.zero,
    int dpi = 144,
    BoxDecoration? boxDecoration,
    FlipSettings? settings,
    void Function(int leftPageIndex, int rightPageIndex)? onPageChanged,
    LoadingBuilder? loadingBuilder,
    ErrorBuilder? errorBuilder,
    double? aspectRatio,
    bool pagesBoundaryIsEnabled = true,
    Key? key,
  }) => TurnablePdf._internal(
    source: PdfSource.file,
    filePath: filePath,
    controller: controller,
    pageViewMode: pageViewMode,
    paperBoundaryDecoration: paperBoundaryDecoration,
    pagePadding: pagePadding,
    boxDecoration: boxDecoration,
    settings: settings,
    onPageChanged: onPageChanged,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    aspectRatio: aspectRatio,
    pagesBoundaryIsEnabled: pagesBoundaryIsEnabled,
    key: key,
  );

  static Future<void> initPDFLoaders() async {
    final cacheDir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}pdfrx_cache',
    );
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    Pdfrx.cacheDirectoryPath ??= cacheDir.path;

    Pdfrx.loadAsset ??= (String name) async {
      final data = await rootBundle.load(name);
      return data.buffer.asUint8List();
    };
  }

  @override
  State<TurnablePdf> createState() => _TurnablePdfState();
}

class _TurnablePdfState extends State<TurnablePdf> {
  late final PageFlipController _controller;
  Future<PdfDocument?>? _pdfFuture;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PageFlipController();
    _initializePdf();
  }

  void _initializePdf() {
    _pdfFuture = _loadPdfDocument();
  }

  /// Load PDF document based on the source type
  Future<PdfDocument?> _loadPdfDocument() async {
    try {
      switch (widget._source) {
        case PdfSource.asset:
          if (widget._assetPath == null) {
            throw Exception('Asset path is required for asset source');
          }
          log('Loading PDF from asset: ${widget._assetPath}');
          return await PdfDocument.openAsset(widget._assetPath!);

        case PdfSource.network:
          if (widget._networkUrl == null) {
            throw Exception('Network URL is required for network source');
          }
          log('Loading PDF from network: ${widget._networkUrl}');
          WidgetsFlutterBinding.ensureInitialized();

          return await PdfDocument.openUri(
            Uri.parse(widget._networkUrl!),
            headers: widget.headers,
          );

        case PdfSource.file:
          if (widget._filePath == null) {
            throw Exception('File path is required for file source');
          }
          log('Loading PDF from file: ${widget._filePath}');
          final file = File(widget._filePath!);
          if (!await file.exists()) {
            throw Exception('File does not exist: ${widget._filePath}');
          }
          return await PdfDocument.openFile(widget._filePath!);
      }
    } catch (e) {
      log('Error loading PDF: $e');
      rethrow;
    }
  }

  /// Retry loading the PDF
  void _retryLoading() {
    setState(() {
      _initializePdf();
    });
  }

  Widget _buildBookSpine() {
    return Container(
      width: 8,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfDocument?>(
      future: _pdfFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth <= 912.8;
              log('isMobile: ${constraints.maxWidth}');
              return Center(
                child:
                    widget.loadingBuilder?.call(
                      context,
                      _getSourceDescription(),
                    ) ??
                    PaperWidget(
                      isEnabled: widget.pagesBoundaryIsEnabled,
                      isSinglePage: widget.pageViewMode == PageViewMode.single,
                      size: const Size(double.maxFinite, double.maxFinite),
                      paperBoundaryDecoration: widget.paperBoundaryDecoration,
                      child: Stack(
                        alignment:
                            widget.pageViewMode == PageViewMode.single &&
                                isMobile
                            ? AlignmentDirectional.centerStart
                            : AlignmentDirectional.center,
                        children: [
                          if (widget.pageViewMode == PageViewMode.single &&
                              isMobile) ...[
                            AspectRatio(
                              aspectRatio: widget.aspectRatio != null
                                  ? (widget.aspectRatio!)
                                  : 2 / 3,
                              child: _ShimmerEffect(
                                background:
                                    widget.paperBoundaryDecoration.baseColor,
                              ),
                            ),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: widget.aspectRatio != null
                                      ? (widget.aspectRatio! / 2)
                                      : 2 / 3,
                                  child: _ShimmerEffect(
                                    background: widget
                                        .paperBoundaryDecoration
                                        .baseColor,
                                  ),
                                ),
                                AspectRatio(
                                  aspectRatio: widget.aspectRatio != null
                                      ? (widget.aspectRatio! / 2)
                                      : 2 / 3,
                                  child: _ShimmerEffect(
                                    background: widget
                                        .paperBoundaryDecoration
                                        .baseColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          _buildBookSpine(),
                        ],
                      ),
                    ),
              );
            },
          );
        }

        if (snapshot.hasError) {
          // Use custom error builder if provided, otherwise use default
          return widget.errorBuilder?.call(
                context,
                'Error loading PDF',
                snapshot.error.toString(),
                _retryLoading,
              ) ??
              _PDFErrorPlaceholder(
                title: 'Error loading PDF',
                message: snapshot.error.toString(),
                onRetry: _retryLoading,
              );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // Use custom error builder if provided, otherwise use default
          return widget.errorBuilder?.call(
                context,
                'No PDF data',
                'The PDF document could not be loaded.',
                _retryLoading,
              ) ??
              _PDFErrorPlaceholder(
                title: 'No PDF data',
                message: 'The PDF document could not be loaded.',
                onRetry: _retryLoading,
              );
        }

        final document = snapshot.data!;

        if (document.pages.isEmpty) {
          return widget.errorBuilder?.call(
                context,
                'Empty PDF',
                'The PDF document has no pages.',
                _retryLoading,
              ) ??
              _PDFErrorPlaceholder(
                title: 'Empty PDF',
                message: 'The PDF document has no pages.',
                onRetry: _retryLoading,
              );
        }

        return Center(
          child: TurnablePage(
            controller: _controller,
            pageCount: document.pages.length,
            pageViewMode: widget.pageViewMode,
            paperBoundaryDecoration: widget.paperBoundaryDecoration,
            settings: widget.settings,
            onPageChanged: widget.onPageChanged,
            aspectRatio: widget.aspectRatio,
            pagesBoundaryIsEnabled: widget.pagesBoundaryIsEnabled,
            autoResponseSize: false,
            builder: (context, index, constraints) {
              return Container(
                margin: widget.pagePadding,
                decoration:
                    widget.boxDecoration ??
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(
                        left: index % 2 == 0 ? Radius.circular(8) : Radius.zero,
                        right: index % 2 == 1
                            ? Radius.circular(8)
                            : Radius.zero,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 6,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                child: PdfPageView(
                  document: document,
                  pageNumber: index + 1,
                  alignment: Alignment.center,
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getSourceDescription() {
    switch (widget._source) {
      case PdfSource.asset:
        return 'Asset: ${widget._assetPath ?? 'Unknown'}';
      case PdfSource.network:
        return 'Network: ${widget._networkUrl ?? 'Unknown'}';
      case PdfSource.file:
        return 'File: ${widget._filePath ?? 'Unknown'}';
    }
  }
}

// Default error placeholder (kept for backward compatibility)
class _PDFErrorPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _PDFErrorPlaceholder({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, size: 45, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Color? background;

  const _ShimmerEffect({this.background});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.background ?? Colors.grey.shade300;
    final highlight = HSLColor.fromColor(baseColor)
        .withLightness(
          (HSLColor.fromColor(baseColor).lightness + 0.1).clamp(0.0, 1.0),
        )
        .toColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final dx = -1.0 + 3.0 * t;

        final gradient = LinearGradient(
          begin: Alignment(-1.0 + dx, 0.0),
          end: Alignment(1.0 + dx, 0.0),
          colors: [baseColor, highlight, baseColor],
          stops: const [0.25, 0.5, 0.75],
        );

        return ShaderMask(
          shaderCallback: (rect) => gradient.createShader(rect),
          blendMode: BlendMode.srcATop,
          child: Container(color: baseColor),
        );
      },
    );
  }
}
