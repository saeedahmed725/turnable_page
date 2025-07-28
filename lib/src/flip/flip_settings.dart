import '../enums/size_type.dart';

/// Configuration object for PageFlip widget behavior and appearance
class FlipSetting {
  /// Initial page to display when the book loads (0-based index)
  final int startPage;

  /// How the book size is calculated - fixed dimensions or stretch to fit parent
  final SizeType size;

  /// Width of the book in pixels (for single page in portrait, or full spread in landscape)
  final double width;

  /// Height of the book in pixels
  final double height;

  /// Whether to draw realistic shadow effects during page flips
  final bool drawShadow;

  /// Duration of flip animation in milliseconds
  final int flippingTime;

  /// Book orientation - true for single page (portrait), false for two-page spread (landscape)
  final bool usePortrait;

  /// Maximum opacity for shadow effects (0.0 to 1.0)
  final double maxShadowOpacity;

  /// Whether the book has a front/back cover
  final bool showCover;

  /// Enable touch scrolling support on mobile devices
  final bool mobileScrollSupport;

  /// Whether click events should propagate to parent widgets
  final bool clickEventForward;

  /// Enable mouse events (hover effects, etc.)
  final bool useMouseEvents;

  /// Minimum distance in pixels for a swipe gesture to register
  final double swipeDistance;

  /// Show interactive corner highlighting when hovering near page corners
  final bool showPageCorners;

  /// Disable page flipping when clicking on the page (only allow drag gestures)
  final bool disableFlipByClick;

  const FlipSetting({
    /// Initial page to display (0-based). Default: 0 (first page)
    this.startPage = 0,

    /// Size calculation method. Default: SizeType.fixed
    this.size = SizeType.fixed,

    /// Book width in pixels.
    this.width = 0,

    /// Book height in pixels.
    this.height = 0,

    /// Enable shadow effects. Default: true
    this.drawShadow = true,

    /// Animation duration in milliseconds. Default: 700ms (0.7 second)
    this.flippingTime = 700,

    /// Portrait mode (single page). Default: true. Set false for landscape (two-page spread)
    this.usePortrait = true,

    /// Shadow opacity (0.0-1.0). Default: 1.0 (fully opaque)
    this.maxShadowOpacity = 1.0,

    /// Show book cover. Default: false
    this.showCover = false,

    /// Enable mobile scroll support. Default: true
    this.mobileScrollSupport = false,

    /// Forward click events to parent. Default: true
    this.clickEventForward = false,

    /// Enable mouse hover effects. Default: true
    this.useMouseEvents = false,

    /// Swipe distance threshold in pixels. Default: 30px
    this.swipeDistance = 0.0,

    /// Show corner highlights on hover. Default: true
    this.showPageCorners = true,

    /// Disable click-to-flip (drag only). Default: false
    this.disableFlipByClick = false,
  });

  FlipSetting copyWith({
    int? startPage,
    SizeType? size,
    double? width,
    double? height,

    bool? drawShadow,
    int? flippingTime,
    bool? usePortrait,
    double? maxShadowOpacity,
    bool? showCover,
    bool? mobileScrollSupport,
    bool? clickEventForward,
    bool? useMouseEvents,
    double? swipeDistance,
    bool? showPageCorners,
    bool? disableFlipByClick,
  }) {
    return FlipSetting(
      startPage: startPage ?? this.startPage,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      drawShadow: drawShadow ?? this.drawShadow,
      flippingTime: flippingTime ?? this.flippingTime,
      usePortrait: usePortrait ?? this.usePortrait,
      maxShadowOpacity: maxShadowOpacity ?? this.maxShadowOpacity,
      showCover: showCover ?? this.showCover,
      mobileScrollSupport: mobileScrollSupport ?? this.mobileScrollSupport,
      clickEventForward: clickEventForward ?? this.clickEventForward,
      useMouseEvents: useMouseEvents ?? this.useMouseEvents,
      swipeDistance: swipeDistance ?? this.swipeDistance,
      showPageCorners: showPageCorners ?? this.showPageCorners,
      disableFlipByClick: disableFlipByClick ?? this.disableFlipByClick,
    );
  }
}
