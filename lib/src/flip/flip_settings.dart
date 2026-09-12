import 'package:flutter/material.dart';

import '../enums/size_type.dart';

/// Configuration object for PageFlip widget behavior and appearance
class FlipSettings {
  /// Initial page to display when the book loads (0-based index)
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

  /// Book orientation - true for single page (portrait), false for two-page spread (landscape)
  final bool usePortrait;

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

    /// Portrait mode (single page). Default: true. Set false for landscape (two-page spread)
    this.usePortrait = true,

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
  });

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
    bool? usePortrait,
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
  }) {
    return FlipSettings(
      startPageIndex: startPage ?? startPageIndex,
      size: size ?? this.size,
      width: (width ?? this.width) / (usePortrait ?? this.usePortrait ? 1 : 2),
      height: height ?? this.height,
      drawShadow: drawShadow ?? this.drawShadow,
      showCenterShadow: showCenterShadow ?? this.showCenterShadow,
      centerShadowColor: centerShadowColor ?? this.centerShadowColor,
      outerShadowColor: outerShadowColor ?? this.outerShadowColor,
      innerShadowColor: innerShadowColor ?? this.innerShadowColor,
      perimeterShadowColor: perimeterShadowColor ?? this.perimeterShadowColor,
      perimeterBorderColor: perimeterBorderColor ?? this.perimeterBorderColor,
      flippingTime: flippingTime ?? this.flippingTime,
      usePortrait: usePortrait ?? this.usePortrait,
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
    );
  }
}
