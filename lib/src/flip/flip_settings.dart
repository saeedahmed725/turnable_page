import 'package:flutter/widgets.dart';

import '../enums/page_view_mode.dart';
import '../enums/size_type.dart';

/// Configuration object for PageFlip widget behavior and appearance
class FlipSettings {
  /// Initial page to display when the book loads (0-based index).
  ///
  /// Like `PageController.initialPage`, this is read only when the book is
  /// first laid out. Changing it later does not navigate; use
  /// `PageFlipController.jumpToPage` / `animateToPage` instead.
  int startPageIndex;

  /// How the book size is calculated - fixed dimensions or stretch to fit parent
  final SizeType size;

  /// Width of the book in pixels (for single page in portrait, or full spread in landscape)
  final double width;

  /// Height of the book in pixels
  final double height;

  /// Whether to draw realistic shadow effects during page flips
  final bool drawShadow;

  /// Whether to show the spine/crease shadow in the center between pages in two-page spread mode
  final bool showCenterShadow;

  /// Color of the center/spine shadow between pages (defaults to Colors.black)
  final Color centerShadowColor;

  /// Color of the outer shadow cast on the page beneath the turning page (defaults to Colors.black)
  final Color outerShadowColor;

  /// Color of the inner fold shadow on the back/inside of the curling page (defaults to Colors.black)
  final Color innerShadowColor;

  /// Color of the perimeter elevation shadow around the lifting/curling page
  final Color perimeterShadowColor;

  /// Color of the subtle perimeter hairline border along the curling page edge
  final Color perimeterBorderColor;

  /// Whether to hide permanent left shadow
  final bool hideLeftShadow;

  /// Duration of flip animation in milliseconds
  final int flippingTime;

  /// Page view mode: single page, double-page spread, or auto-responsive
  final PageViewMode pageViewMode;

  /// Portrait mode (single page) vs landscape (two-page spread).
  /// Deprecated: use [pageViewMode] instead.
  @Deprecated('Use pageViewMode instead')
  bool get usePortrait => pageViewMode == PageViewMode.single;

  /// Maximum opacity for shadow effects (0.0 to 1.0)
  final double maxShadowOpacity;

  /// Whether the book has a front/back cover
  final bool showCover;

  /// Enable touch scrolling support on mobile devices
  final bool mobileScrollSupport;

  // Removed legacy gesture flags (clickEventForward, enableSmartGestures, disableFlipByClick)
  // to simplify API. Click-to-flip now always requires corner (see FlipProcess.flip).

  /// Minimum distance in pixels for a swipe gesture to register
  final double swipeDistance;

  /// Show interactive corner highlighting when hovering near page corners
  final bool showPageCorners;

  // (Removed) disableFlipByClick, enableSmartGestures

  /// Size of the corner trigger areas as a fraction of the page diagonal (0.1 = 10% of diagonal)
  final double cornerTriggerAreaSize;

  // --- Realism / physics additions ---
  /// Enable easing (cubic) for programmatic flip animations
  final bool enableEasing;

  /// Enable inertia so a fast swipe finishes even before crossing center
  final bool enableInertia;

  /// Enable only vertical Page Flip, no corner turns
  final bool onlyVerticalPageFlip;

  /// Velocity threshold (logical px/second) to treat release as a swipe
  final double inertiaVelocityThreshold;

  /// Extra normalized progress allowance for inertia completion (0-1)
  final double inertiaProgressBoost;

  /// Vertical sag amplitude as fraction of page height (0 = straight line)
  final double sagAmplitude;

  /// Bend strength multiplier (0-1) influencing hardAngle easing
  final double bendStrength;

  /// Whether zooming is enabled (pinch-to-zoom, plus double-tap zoom when
  /// [enableDoubleTapZoom] is true)
  final bool enableZoom;

  /// Whether a double tap toggles zoom. Only applies when [enableZoom] is
  /// true. Set to false to keep pinch-to-zoom while leaving double tap free
  /// for your own gestures.
  final bool enableDoubleTapZoom;

  /// Minimum zoom scale
  final double minScale;

  /// Maximum zoom scale
  final double maxScale;

  /// Ratio of horizontal to vertical movement required to prioritize page flip over vertical scroll
  final double swipeAngleThreshold;

  /// Decide the turn direction from the drag direction instead of the
  /// position where the finger landed (single-page mode only).
  ///
  /// When `false` (default, legacy behaviour) touching the left 40% of the
  /// page always means "previous page". When `true`, dragging right-to-left
  /// turns forward and left-to-right turns back, wherever the finger
  /// landed; the curl starts from the matching page edge and follows the
  /// finger. Mirrored automatically for right-to-left books.
  final bool directionFromDrag;

  /// Keep the grabbed spot of the page under the finger (default `true`).
  ///
  /// The curl is driven by a page corner. When `true`, the corner keeps the
  /// vertical offset it had from the finger at the first touch, so grabbing
  /// the page edge mid-height and pulling gives a natural curl and the page
  /// follows when steered up or down. When `false` (legacy), the corner
  /// itself jumps to the finger, which makes mid-height grabs start with a
  /// large fold and lag behind the finger.
  final bool keepGrabOffset;

  /// Turn the page when the book is tapped (default `true`).
  ///
  /// When `true`, a tap on an empty part of a page turns it, and the page
  /// corners are reserved for turning (taps there never reach the page's
  /// widgets). Set it to `false` when the pages have their own tappable
  /// content: taps then always go to the page, and pages turn only by
  /// dragging (from anywhere, corners included) or from the controller.
  final bool flipOnTap;

  /// Light haptic feedback (a short vibration) for each page turn, on
  /// devices that support it. Default `false`.
  final bool hapticFeedback;

  /// Turn pages with the keyboard when the book has focus (default `true`).
  /// The book takes focus when it is tapped or clicked. Arrow keys,
  /// Page Up / Page Down and Space turn one page; Home and End go to the
  /// first and last page. Arrows follow the reading direction, so in a
  /// right-to-left book the left arrow turns forward.
  final bool keyboardNavigation;

  /// Turn pages with the mouse wheel or a trackpad scroll (default `false`).
  /// Scroll views inside a page keep their own scrolling.
  final bool mouseWheelNavigation;

  /// Strengthen the turn shadows on dark paper (default `true`). Black
  /// shadows lose most of their contrast on a dark [pageBackgroundColor], so
  /// they are drawn up to 1.8x stronger there. Light paper is unchanged.
  final bool adaptiveShadows;

  /// Shadow strength actually used: [maxShadowOpacity], scaled up on dark
  /// paper when [adaptiveShadows] is on.
  double get effectiveShadowOpacity {
    if (!adaptiveShadows) return maxShadowOpacity;
    final luminance = pageBackgroundColor.computeLuminance();
    // 1.0 at luminance >= 0.4, rising to 1.8 for black paper.
    final boost = 1.0 + 0.8 * ((0.4 - luminance) / 0.4).clamp(0.0, 1.0);
    return maxShadowOpacity * boost;
  }

  /// Paper color painted under pages, on the back side of a turning page and
  /// on blank filler pages. Defaults to white. Set it to your page background
  /// (e.g. a dark color in dark mode) to avoid light flashes at curl edges.
  final Color pageBackgroundColor;

  /// 1px border drawn around the back side of a turning page and around
  /// blank filler pages. When `null` (default) it is derived from
  /// [pageBackgroundColor]: 12% darker for light backgrounds (white gives
  /// the classic `0xFFE0E0E0`), and no border at all for dark backgrounds,
  /// so no light line appears along the curl edge in dark mode.
  final Color? pageBorderColor;

  /// The border color actually painted, or `null` for no border.
  /// See [pageBorderColor].
  Color? get effectivePageBorderColor {
    if (pageBorderColor != null) return pageBorderColor;
    if (pageBackgroundColor.computeLuminance() < 0.5) return null;
    final c = Color.lerp(pageBackgroundColor, const Color(0xFF000000), 0.12)!;
    // Round to 8-bit channels (white -> exactly 0xFFE0E0E0).
    return Color(c.toARGB32());
  }

  FlipSettings({
    /// Initial page to display (0-based). Default: 0 (first page)
    this.startPageIndex = 0,

    /// Size calculation method. Default: SizeType.fixed
    this.size = SizeType.fixed,

    /// Book width in pixels.
    this.width = 0,

    /// Book height in pixels.
    this.height = 0,

    /// Enable shadow effects. Default: true
    this.drawShadow = true,

    /// Show center/spine shadow between pages in two-page spread mode. Default: true
    this.showCenterShadow = true,

    /// Center/spine shadow color. Default: Colors.black
    this.centerShadowColor = const Color(0xFF000000),

    /// Outer page flip shadow color. Default: Colors.black
    this.outerShadowColor = const Color(0xFF000000),

    /// Inner curled fold shadow color. Default: Colors.black
    this.innerShadowColor = const Color(0xFF000000),

    /// Perimeter elevation shadow color. Default: Color(0x3D000000)
    this.perimeterShadowColor = const Color(0x3D000000),

    /// Perimeter boundary stroke color. Default: Color(0x1F000000)
    this.perimeterBorderColor = const Color(0x1F000000),

    /// Animation duration in milliseconds. Default: 700ms (0.7 second)
    this.flippingTime = 700,

    /// Controls how pages are displayed: single, double, or auto. Default: PageViewMode.single
    PageViewMode? pageViewMode,

    /// Deprecated: use [pageViewMode] instead.
    @Deprecated('Use pageViewMode instead') bool? usePortrait,

    /// Shadow opacity (0.0-1.0). Default: 1.0 (fully opaque)
    this.maxShadowOpacity = 1.0,

    /// Show book cover. Default: false
    this.showCover = false,

    /// Enable mobile scroll support. Default: true
    this.mobileScrollSupport = true,

    // Legacy flags removed

    /// Swipe distance threshold in pixels. Default: 100px
    this.swipeDistance = 100.0,

    /// Show corner highlights on hover. Default: true
    this.showPageCorners = true,

    // Legacy flags removed

    /// Corner trigger area size as fraction of diagonal. Default: 0.2 (20%)
    this.cornerTriggerAreaSize = 0.2,

    this.enableEasing = true,
    this.enableInertia = true,
    this.inertiaVelocityThreshold = 900.0,
    this.inertiaProgressBoost = 0.15,
    this.sagAmplitude = 0.08,
    this.bendStrength = 0.6,
    this.onlyVerticalPageFlip = false,
    this.hideLeftShadow = false,
    this.enableZoom = false,
    this.enableDoubleTapZoom = true,
    this.minScale = 1.0,
    this.maxScale = 3.0,
    this.swipeAngleThreshold = 1.25,
    this.directionFromDrag = false,
    this.keepGrabOffset = true,
    this.flipOnTap = true,
    this.hapticFeedback = false,
    this.keyboardNavigation = true,
    this.mouseWheelNavigation = false,
    this.adaptiveShadows = true,
    this.pageBackgroundColor = const Color(0xFFFFFFFF),
    this.pageBorderColor,
  }) : pageViewMode =
           pageViewMode ??
           (usePortrait != null
               ? (usePortrait ? PageViewMode.single : PageViewMode.double)
               : PageViewMode.single);

  FlipSettings copyWith({
    int? startPage,
    SizeType? size,
    double? width,
    double? height,
    bool? drawShadow,
    bool? showCenterShadow,
    Color? centerShadowColor,
    Color? outerShadowColor,
    Color? innerShadowColor,
    Color? perimeterShadowColor,
    Color? perimeterBorderColor,
    int? flippingTime,
    PageViewMode? pageViewMode,
    @Deprecated('Use pageViewMode instead') bool? usePortrait,
    double? maxShadowOpacity,
    bool? showCover,
    bool? mobileScrollSupport,
    // Legacy parameters removed
    double? swipeDistance,
    bool? showPageCorners,
    // Legacy parameters removed
    double? cornerTriggerAreaSize,
    bool? enableEasing,
    bool? enableInertia,
    double? inertiaVelocityThreshold,
    double? inertiaProgressBoost,
    double? sagAmplitude,
    double? bendStrength,
    bool? onlyVerticalPageFlip,
    bool? hideLeftShadow,
    bool? enableZoom,
    bool? enableDoubleTapZoom,
    double? minScale,
    double? maxScale,
    double? swipeAngleThreshold,
    bool? directionFromDrag,
    bool? keepGrabOffset,
    bool? flipOnTap,
    bool? hapticFeedback,
    bool? keyboardNavigation,
    bool? mouseWheelNavigation,
    bool? adaptiveShadows,
    Color? pageBackgroundColor,
    Color? pageBorderColor,
  }) {
    final resolvedMode =
        pageViewMode ??
        (usePortrait != null
            ? (usePortrait ? PageViewMode.single : PageViewMode.double)
            : this.pageViewMode);

    return FlipSettings(
      startPageIndex: startPage ?? startPageIndex,
      size: size ?? this.size,
      width: width != null
          ? (resolvedMode == PageViewMode.double ? width / 2 : width)
          : this.width,
      height: height ?? this.height,
      drawShadow: drawShadow ?? this.drawShadow,
      showCenterShadow: showCenterShadow ?? this.showCenterShadow,
      centerShadowColor: centerShadowColor ?? this.centerShadowColor,
      outerShadowColor: outerShadowColor ?? this.outerShadowColor,
      innerShadowColor: innerShadowColor ?? this.innerShadowColor,
      perimeterShadowColor: perimeterShadowColor ?? this.perimeterShadowColor,
      perimeterBorderColor: perimeterBorderColor ?? this.perimeterBorderColor,
      flippingTime: flippingTime ?? this.flippingTime,
      pageViewMode: resolvedMode,
      maxShadowOpacity: maxShadowOpacity ?? this.maxShadowOpacity,
      showCover: showCover ?? this.showCover,
      mobileScrollSupport: mobileScrollSupport ?? this.mobileScrollSupport,
      // Legacy fields omitted
      swipeDistance: swipeDistance ?? this.swipeDistance,
      showPageCorners: showPageCorners ?? this.showPageCorners,
      // Legacy fields omitted
      cornerTriggerAreaSize:
          cornerTriggerAreaSize ?? this.cornerTriggerAreaSize,
      enableEasing: enableEasing ?? this.enableEasing,
      enableInertia: enableInertia ?? this.enableInertia,
      inertiaVelocityThreshold:
          inertiaVelocityThreshold ?? this.inertiaVelocityThreshold,
      inertiaProgressBoost: inertiaProgressBoost ?? this.inertiaProgressBoost,
      sagAmplitude: sagAmplitude ?? this.sagAmplitude,
      bendStrength: bendStrength ?? this.bendStrength,
      hideLeftShadow: hideLeftShadow ?? this.hideLeftShadow,
      onlyVerticalPageFlip: onlyVerticalPageFlip ?? this.onlyVerticalPageFlip,
      enableZoom: enableZoom ?? this.enableZoom,
      enableDoubleTapZoom: enableDoubleTapZoom ?? this.enableDoubleTapZoom,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      swipeAngleThreshold: swipeAngleThreshold ?? this.swipeAngleThreshold,
      directionFromDrag: directionFromDrag ?? this.directionFromDrag,
      keepGrabOffset: keepGrabOffset ?? this.keepGrabOffset,
      flipOnTap: flipOnTap ?? this.flipOnTap,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      keyboardNavigation: keyboardNavigation ?? this.keyboardNavigation,
      mouseWheelNavigation: mouseWheelNavigation ?? this.mouseWheelNavigation,
      adaptiveShadows: adaptiveShadows ?? this.adaptiveShadows,
      pageBackgroundColor: pageBackgroundColor ?? this.pageBackgroundColor,
      pageBorderColor: pageBorderColor ?? this.pageBorderColor,
    );
  }
}
