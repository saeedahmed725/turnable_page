import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

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
class TurnablePdf extends StatefulWidget {
  final PdfSource _source;
  final String? _assetPath;
  final String? _networkUrl;
  final String? _filePath;
  final PageFlipController? controller;
  final PageViewMode pageViewMode;
  final EdgeInsets pagePadding;
  final BoxDecoration? boxDecoration;
  final Map<String, String>? headers; // For network requests
  final FlipSettings? settings;
  final void Function(int leftPageIndex, int rightPageIndex)? onPageChanged;

  /// Called once for each page turn that is going to complete. See
  /// [TurnablePage.onPageTurn].
  final void Function(FlipDirection direction)? onPageTurn;

  /// Make links in the PDF tappable (default `true`). Links to another page
  /// of the document turn to it. Links to a web address call [onLinkTap];
  /// without it they do nothing (open them with url_launcher, for example).
  final bool enableLinks;

  /// Called when a link is tapped. When set, it replaces the default
  /// behavior for every link, including links to pages.
  final void Function(PdfLink link)? onLinkTap;
  final LoadingBuilder? loadingBuilder;
  final ErrorBuilder? errorBuilder;
  final double? aspectRatio;
  final TextDirection? textDirection;

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
    this.pagePadding = EdgeInsets.zero,
    this.boxDecoration,
    this.headers,
    this.settings,
    this.onPageChanged,
    this.onPageTurn,
    this.enableLinks = true,
    this.onLinkTap,
    this.loadingBuilder,
    this.errorBuilder,
    this.aspectRatio,
    this.textDirection,
    super.key,
  }) : _source = source,
       _assetPath = assetPath,
       _networkUrl = networkUrl,
       _filePath = filePath;

  /// Create a TurnablePdf from an asset.
  ///
  /// [assetPath]: The asset path of the PDF.
  /// [pageViewMode]: The mode for displaying pages (default: single).
  /// [pagePadding]: The padding around each page.
  /// [boxDecoration]: The decoration for the page container.
  /// [settings]: The flip animation settings for [TurnablePage].
  /// [onPageChanged]: Callback when the visible page(s) change.
  /// [loadingBuilder]: Custom builder for loading state.
  /// [errorBuilder]: Custom builder for error state.
  /// [aspectRatio]: The aspect ratio for the PDF pages.
  /// [autoResponseSize]: Whether to automatically adjust the response size.
  /// [textDirection]: Reading direction (LTR/RTL). If null, auto-detects from Directionality.
  /// [key]: Optional widget key.
  factory TurnablePdf.asset(
    String assetPath, {
    PageFlipController? controller,
    PageViewMode pageViewMode = PageViewMode.single,
    EdgeInsets pagePadding = EdgeInsets.zero,
    BoxDecoration? boxDecoration,
    FlipSettings? settings,
    void Function(int leftPageIndex, int rightPageIndex)? onPageChanged,
    void Function(FlipDirection direction)? onPageTurn,
    bool enableLinks = true,
    void Function(PdfLink link)? onLinkTap,
    LoadingBuilder? loadingBuilder,
    ErrorBuilder? errorBuilder,
    double? aspectRatio,
    TextDirection? textDirection,
    Key? key,
  }) => TurnablePdf._internal(
    source: PdfSource.asset,
    assetPath: assetPath,
    controller: controller,
    pageViewMode: pageViewMode,
    pagePadding: pagePadding,
    boxDecoration: boxDecoration,
    settings: settings,
    onPageChanged: onPageChanged,
    onPageTurn: onPageTurn,
    enableLinks: enableLinks,
    onLinkTap: onLinkTap,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    aspectRatio: aspectRatio,
    textDirection: textDirection,
    key: key,
  );

  /// Create a TurnablePdf from a network URL.
  ///
  /// [url]: The network URL of the PDF.
  /// [pageViewMode]: The mode for displaying pages (default: single).
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
    EdgeInsets pagePadding = EdgeInsets.zero,
    BoxDecoration? boxDecoration,
    Map<String, String>? headers,
    FlipSettings? settings,
    void Function(int leftPageIndex, int rightPageIndex)? onPageChanged,
    void Function(FlipDirection direction)? onPageTurn,
    bool enableLinks = true,
    void Function(PdfLink link)? onLinkTap,
    LoadingBuilder? loadingBuilder,
    ErrorBuilder? errorBuilder,
    double? aspectRatio,
    TextDirection? textDirection,
    Key? key,
  }) => TurnablePdf._internal(
    source: PdfSource.network,
    networkUrl: url,
    controller: controller,
    pageViewMode: pageViewMode,
    pagePadding: pagePadding,
    boxDecoration: boxDecoration,
    headers: headers,
    settings: settings,
    onPageChanged: onPageChanged,
    onPageTurn: onPageTurn,
    enableLinks: enableLinks,
    onLinkTap: onLinkTap,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    aspectRatio: aspectRatio,
    textDirection: textDirection,
    key: key,
  );

  /// Create a TurnablePdf from a file path.
  ///
  /// [filePath]: The local file path of the PDF.
  /// [pageViewMode]: The mode for displaying pages (default: single).
  /// [pagePadding]: The padding around each page.
  /// [boxDecoration]: The decoration for the page container.
  /// [settings]: The flip animation settings for [TurnablePage].
  /// [onPageChanged]: Callback when the visible page(s) change.
  /// [loadingBuilder]: Custom builder for loading state.
  /// [errorBuilder]: Custom builder for error state.
  /// [aspectRatio]: The aspect ratio for the PDF pages.
  /// [autoResponseSize]: Whether to automatically adjust the response size.
  /// [textDirection]: Reading direction (LTR/RTL). If null, auto-detects from Directionality.
  /// [key]: Optional widget key.
  factory TurnablePdf.file(
    String filePath, {
    PageFlipController? controller,

    PageViewMode pageViewMode = PageViewMode.single,
    EdgeInsets pagePadding = EdgeInsets.zero,
    int dpi = 144,
    BoxDecoration? boxDecoration,
    FlipSettings? settings,
    void Function(int leftPageIndex, int rightPageIndex)? onPageChanged,
    void Function(FlipDirection direction)? onPageTurn,
    bool enableLinks = true,
    void Function(PdfLink link)? onLinkTap,
    LoadingBuilder? loadingBuilder,
    ErrorBuilder? errorBuilder,
    double? aspectRatio,
    TextDirection? textDirection,
    Key? key,
  }) => TurnablePdf._internal(
    source: PdfSource.file,
    filePath: filePath,
    controller: controller,
    pageViewMode: pageViewMode,
    pagePadding: pagePadding,
    boxDecoration: boxDecoration,
    settings: settings,
    onPageChanged: onPageChanged,
    onPageTurn: onPageTurn,
    enableLinks: enableLinks,
    onLinkTap: onLinkTap,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    aspectRatio: aspectRatio,
    textDirection: textDirection,
    key: key,
  );

  static Future<void> initPDFLoaders() async {
    // Sets the cache directory (skipped on web) and the asset loader.
    await pdfrxFlutterInitialize();
  }

  @override
  State<TurnablePdf> createState() => _TurnablePdfState();
}

class _TurnablePdfState extends State<TurnablePdf> {
  Color get _paperColor =>
      widget.settings?.pageBackgroundColor ?? const Color(0xFFFFFFFF);

  late final PageFlipController _controller;
  Future<PdfDocument?>? _pdfFuture;

  /// Pages are rendered sharper when zoom is on, up to the maximum zoom
  /// (capped at 3x to bound memory).
  double get _renderScale {
    final s = widget.settings;
    if (s == null || !s.enableZoom) return 1.0;
    return s.maxScale.clamp(1.0, 3.0).toDouble();
  }

  /// Default link action: links to a page of the document turn to it.
  void _openLink(PdfLink link) {
    final dest = link.dest;
    if (dest == null) return;
    final page = dest.pageNumber - 1;
    if (page >= 0 && page < _controller.pageCount) {
      _controller.animateToPage(page);
    }
  }

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
            color: const Color(0xFF000000).withValues(alpha: 0.3),
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
                    Stack(
                      alignment:
                          widget.pageViewMode == PageViewMode.single && isMobile
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.center,
                      children: [
                        if (widget.pageViewMode == PageViewMode.single &&
                            isMobile) ...[
                          AspectRatio(
                            aspectRatio: widget.aspectRatio != null
                                ? (widget.aspectRatio!)
                                : 2 / 3,
                            child: _ShimmerEffect(background: _paperColor),
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
                                child: _ShimmerEffect(background: _paperColor),
                              ),
                              AspectRatio(
                                aspectRatio: widget.aspectRatio != null
                                    ? (widget.aspectRatio! / 2)
                                    : 2 / 3,
                                child: _ShimmerEffect(background: _paperColor),
                              ),
                            ],
                          ),
                        ],
                        _buildBookSpine(),
                      ],
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
            settings: widget.settings,
            onPageChanged: widget.onPageChanged,
            onPageTurn: widget.onPageTurn,
            aspectRatio: widget.aspectRatio,
            autoResponseSize: false,
            textDirection: widget.textDirection,
            builder: (context, index, constraints) {
              return Container(
                margin: widget.pagePadding,
                decoration:
                    widget.boxDecoration ??
                    BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.horizontal(
                        left: index % 2 == 0 ? Radius.circular(8) : Radius.zero,
                        right: index % 2 == 1
                            ? Radius.circular(8)
                            : Radius.zero,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 6,
                          color: Color(0x42000000),
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                child: _PdfPage(
                  document: document,
                  pageNumber: index + 1,
                  renderScale: _renderScale,
                  links: widget.enableLinks,
                  onLinkTap: widget.onLinkTap ?? _openLink,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PDF',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF757575), fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD32F2F)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Color(0xFFD32F2F), fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A PDF page, rendered sharp enough for zooming, with tappable links.
class _PdfPage extends StatelessWidget {
  const _PdfPage({
    required this.document,
    required this.pageNumber,
    required this.renderScale,
    required this.links,
    required this.onLinkTap,
  });

  final PdfDocument document;
  final int pageNumber;

  /// Extra resolution for zoomed-in pages (1 = screen resolution).
  final double renderScale;
  final bool links;
  final void Function(PdfLink link) onLinkTap;

  @override
  Widget build(BuildContext context) {
    Widget view = PdfPageView(
      document: document,
      pageNumber: pageNumber,
      alignment: Alignment.center,
    );
    // PdfPageView renders at its size times the device pixel ratio, so a
    // higher ratio keeps text sharp when the page is zoomed in.
    final mq = MediaQuery.maybeOf(context);
    if (renderScale > 1 && mq != null) {
      view = MediaQuery(
        data: mq.copyWith(devicePixelRatio: mq.devicePixelRatio * renderScale),
        child: view,
      );
    }
    if (!links) return view;
    final page = document.pages[pageNumber - 1];
    return Stack(
      fit: StackFit.expand,
      children: [
        view,
        FutureBuilder<List<PdfLink>>(
          future: page.loadLinks(compact: true),
          builder: (context, snapshot) {
            final list = snapshot.data;
            if (list == null || list.isEmpty) return const SizedBox.shrink();
            return LayoutBuilder(
              builder: (context, constraints) {
                // The page is fitted and centered in the box (BoxFit.contain).
                final scale = math.min(
                  constraints.maxWidth / page.width,
                  constraints.maxHeight / page.height,
                );
                final ox = (constraints.maxWidth - page.width * scale) / 2;
                final oy = (constraints.maxHeight - page.height * scale) / 2;
                return Stack(
                  children: [
                    for (final link in list)
                      for (final r in link.rects)
                        Positioned(
                          left: ox + r.left * scale,
                          // PDF y grows upwards from the bottom of the page.
                          top: oy + (page.height - r.top) * scale,
                          width: r.width * scale,
                          height: r.height * scale,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onLinkTap(link),
                          ),
                        ),
                  ],
                );
              },
            );
          },
        ),
      ],
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
    final baseColor = widget.background ?? const Color(0xFFE0E0E0);
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
