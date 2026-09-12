import 'package:flutter/material.dart';

/// Model class to control the colors and shadows of the Paper widget
class PaperBoundaryDecoration {
  final Color baseColor;
  final Color shadowColor;
  final Color borderColor;
  final Color innerBorderColor;
  final Color glowColor;
  final Color gradientStartColor;
  final Color gradientMiddleColor;
  final Color gradientEndColor;
  final Color finalBorderColor;
  final Color finalShadowColor;

  final double outerAlpha;
  final double middleAlpha;
  final double innerAlpha;
  final double gradientStartAlpha;
  final double gradientMiddleAlpha;
  final double gradientEndAlpha;

  final double borderRadius;
  final double outerBorderWidth;
  final double middleBorderWidth;
  final double innerBorderWidth;
  final double finalBorderWidth;

  final double shadowBlurRadius;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final double finalShadowBlurRadius;
  final double finalShadowSpreadRadius;
  final Offset finalShadowOffset;

  const PaperBoundaryDecoration({
    this.baseColor = Colors.yellow,
    this.shadowColor = Colors.black,
    this.borderColor = Colors.brown,
    this.innerBorderColor = Colors.orange,
    this.glowColor = Colors.amber,
    this.gradientStartColor = Colors.yellow,
    this.gradientMiddleColor = Colors.yellow,
    this.gradientEndColor = Colors.amber,
    this.finalBorderColor = Colors.orange,
    this.finalShadowColor = Colors.brown,

    this.outerAlpha = 0.5,
    this.middleAlpha = 0.25,
    this.innerAlpha = 0.1,
    this.gradientStartAlpha = 0.05,
    this.gradientMiddleAlpha = 0.15,
    this.gradientEndAlpha = 0.08,

    this.borderRadius = 4.0,
    this.outerBorderWidth = 0.5,
    this.middleBorderWidth = 0.3,
    this.innerBorderWidth = 0.2,
    this.finalBorderWidth = 0.1,

    this.shadowBlurRadius = 1.0,
    this.glowBlurRadius = 0.5,
    this.glowSpreadRadius = 0.5,
    this.finalShadowBlurRadius = 0.5,
    this.finalShadowSpreadRadius = -0.5,
    this.finalShadowOffset = const Offset(0.5, 0.5),
  });

  /// Factory constructor to easily customize a paper boundary decoration
  /// with common high-level parameters instead of specifying all 26 low-level properties.
  factory PaperBoundaryDecoration.custom({
    Color baseColor = const Color(0xFFF8F8F8),
    Color shadowColor = Colors.black,
    Color? borderColor,
    Color? glowColor,
    double borderRadius = 4.0,
    double borderWidth = 0.5,
    double shadowBlurRadius = 1.0,
    double shadowOpacity = 0.2,
    double baseOpacity = 0.5,
  }) {
    final border = borderColor ?? shadowColor.withValues(alpha: 0.2);
    final glow = glowColor ?? baseColor;
    return PaperBoundaryDecoration(
      baseColor: baseColor,
      shadowColor: shadowColor,
      borderColor: border,
      innerBorderColor: border,
      finalBorderColor: border,
      glowColor: glow,
      gradientStartColor: baseColor,
      gradientMiddleColor: baseColor,
      gradientEndColor: glow,
      finalShadowColor: shadowColor,
      borderRadius: borderRadius,
      outerBorderWidth: borderWidth,
      middleBorderWidth: borderWidth * 0.6,
      innerBorderWidth: borderWidth * 0.4,
      finalBorderWidth: borderWidth * 0.2,
      shadowBlurRadius: shadowBlurRadius,
      outerAlpha: baseOpacity,
      middleAlpha: baseOpacity * 0.6,
      innerAlpha: baseOpacity * 0.3,
    );
  }

  /// Create a copy of this decoration with modified properties
  PaperBoundaryDecoration copyWith({
    Color? baseColor,
    Color? shadowColor,
    Color? borderColor,
    Color? innerBorderColor,
    Color? glowColor,
    Color? gradientStartColor,
    Color? gradientMiddleColor,
    Color? gradientEndColor,
    Color? finalBorderColor,
    Color? finalShadowColor,
    double? outerAlpha,
    double? middleAlpha,
    double? innerAlpha,
    double? gradientStartAlpha,
    double? gradientMiddleAlpha,
    double? gradientEndAlpha,
    double? borderRadius,
    double? outerBorderWidth,
    double? middleBorderWidth,
    double? innerBorderWidth,
    double? finalBorderWidth,
    double? shadowBlurRadius,
    double? glowBlurRadius,
    double? glowSpreadRadius,
    double? finalShadowBlurRadius,
    double? finalShadowSpreadRadius,
    Offset? finalShadowOffset,
  }) {
    return PaperBoundaryDecoration(
      baseColor: baseColor ?? this.baseColor,
      shadowColor: shadowColor ?? this.shadowColor,
      borderColor: borderColor ?? this.borderColor,
      innerBorderColor: innerBorderColor ?? this.innerBorderColor,
      glowColor: glowColor ?? this.glowColor,
      gradientStartColor: gradientStartColor ?? this.gradientStartColor,
      gradientMiddleColor: gradientMiddleColor ?? this.gradientMiddleColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      finalBorderColor: finalBorderColor ?? this.finalBorderColor,
      finalShadowColor: finalShadowColor ?? this.finalShadowColor,
      outerAlpha: outerAlpha ?? this.outerAlpha,
      middleAlpha: middleAlpha ?? this.middleAlpha,
      innerAlpha: innerAlpha ?? this.innerAlpha,
      gradientStartAlpha: gradientStartAlpha ?? this.gradientStartAlpha,
      gradientMiddleAlpha: gradientMiddleAlpha ?? this.gradientMiddleAlpha,
      gradientEndAlpha: gradientEndAlpha ?? this.gradientEndAlpha,
      borderRadius: borderRadius ?? this.borderRadius,
      outerBorderWidth: outerBorderWidth ?? this.outerBorderWidth,
      middleBorderWidth: middleBorderWidth ?? this.middleBorderWidth,
      innerBorderWidth: innerBorderWidth ?? this.innerBorderWidth,
      finalBorderWidth: finalBorderWidth ?? this.finalBorderWidth,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      glowBlurRadius: glowBlurRadius ?? this.glowBlurRadius,
      glowSpreadRadius: glowSpreadRadius ?? this.glowSpreadRadius,
      finalShadowBlurRadius:
          finalShadowBlurRadius ?? this.finalShadowBlurRadius,
      finalShadowSpreadRadius:
          finalShadowSpreadRadius ?? this.finalShadowSpreadRadius,
      finalShadowOffset: finalShadowOffset ?? this.finalShadowOffset,
    );
  }

  /// Create a vintage paper theme
  static const PaperBoundaryDecoration vintage = PaperBoundaryDecoration(
    baseColor: Color(0xFFF5E6D3),
    shadowColor: Color(0xFF8B4513),
    borderColor: Color(0xFFD2B48C),
    innerBorderColor: Color(0xFFCD853F),
    glowColor: Color(0xFFDEB887),
    gradientStartColor: Color(0xFFF5E6D3),
    gradientMiddleColor: Color(0xFFF5E6D3),
    gradientEndColor: Color(0xFFDEB887),
    finalBorderColor: Color(0xFFCD853F),
    finalShadowColor: Color(0xFF8B4513),
    outerAlpha: 0.6,
    middleAlpha: 0.4,
    innerAlpha: 0.2,
  );

  /// Create a modern clean paper theme
  static const PaperBoundaryDecoration modern = PaperBoundaryDecoration(
    baseColor: Color(0xFFF8F8F8),
    shadowColor: Colors.grey,
    borderColor: Color(0xFFE0E0E0),
    innerBorderColor: Color(0xFFBDBDBD),
    glowColor: Colors.white,
    gradientStartColor: Colors.white,
    gradientMiddleColor: Color(0xFFF8F8F8),
    gradientEndColor: Color(0xFFF0F0F0),
    finalBorderColor: Color(0xFFBDBDBD),
    finalShadowColor: Colors.grey,
    outerAlpha: 0.3,
    middleAlpha: 0.2,
    innerAlpha: 0.1,
  );

  /// Create a parchment paper theme
  static const PaperBoundaryDecoration parchment = PaperBoundaryDecoration(
    baseColor: Color(0xFFF4E4BC),
    shadowColor: Color(0xFF8B7355),
    borderColor: Color(0xFFD4AF37),
    innerBorderColor: Color(0xFFDAA520),
    glowColor: Color(0xFFF0E68C),
    gradientStartColor: Color(0xFFF4E4BC),
    gradientMiddleColor: Color(0xFFF0E68C),
    gradientEndColor: Color(0xFFDAA520),
    finalBorderColor: Color(0xFFDAA520),
    finalShadowColor: Color(0xFF8B7355),
    outerAlpha: 0.7,
    middleAlpha: 0.5,
    innerAlpha: 0.3,
  );

  /// Disables all paper boundary decorations, borders, and shadows (pages-only mode)
  static const PaperBoundaryDecoration none = PaperBoundaryDecoration(
    baseColor: Colors.transparent,
    shadowColor: Colors.transparent,
    borderColor: Colors.transparent,
    innerBorderColor: Colors.transparent,
    glowColor: Colors.transparent,
    gradientStartColor: Colors.transparent,
    gradientMiddleColor: Colors.transparent,
    gradientEndColor: Colors.transparent,
    finalBorderColor: Colors.transparent,
    finalShadowColor: Colors.transparent,
    outerAlpha: 0.0,
    middleAlpha: 0.0,
    innerAlpha: 0.0,
    gradientStartAlpha: 0.0,
    gradientMiddleAlpha: 0.0,
    gradientEndAlpha: 0.0,
    borderRadius: 0.0,
    outerBorderWidth: 0.0,
    middleBorderWidth: 0.0,
    innerBorderWidth: 0.0,
    finalBorderWidth: 0.0,
    shadowBlurRadius: 0.0,
    glowBlurRadius: 0.0,
    glowSpreadRadius: 0.0,
    finalShadowBlurRadius: 0.0,
    finalShadowSpreadRadius: 0.0,
    finalShadowOffset: Offset.zero,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperBoundaryDecoration &&
          runtimeType == other.runtimeType &&
          baseColor == other.baseColor &&
          shadowColor == other.shadowColor &&
          borderColor == other.borderColor &&
          innerBorderColor == other.innerBorderColor &&
          glowColor == other.glowColor &&
          gradientStartColor == other.gradientStartColor &&
          gradientMiddleColor == other.gradientMiddleColor &&
          gradientEndColor == other.gradientEndColor &&
          finalBorderColor == other.finalBorderColor &&
          finalShadowColor == other.finalShadowColor &&
          outerAlpha == other.outerAlpha &&
          middleAlpha == other.middleAlpha &&
          innerAlpha == other.innerAlpha &&
          gradientStartAlpha == other.gradientStartAlpha &&
          gradientMiddleAlpha == other.gradientMiddleAlpha &&
          gradientEndAlpha == other.gradientEndAlpha &&
          borderRadius == other.borderRadius &&
          outerBorderWidth == other.outerBorderWidth &&
          middleBorderWidth == other.middleBorderWidth &&
          innerBorderWidth == other.innerBorderWidth &&
          finalBorderWidth == other.finalBorderWidth &&
          shadowBlurRadius == other.shadowBlurRadius &&
          glowBlurRadius == other.glowBlurRadius &&
          glowSpreadRadius == other.glowSpreadRadius &&
          finalShadowBlurRadius == other.finalShadowBlurRadius &&
          finalShadowSpreadRadius == other.finalShadowSpreadRadius &&
          finalShadowOffset == other.finalShadowOffset;

  @override
  int get hashCode => Object.hashAll([
        baseColor,
        shadowColor,
        borderColor,
        innerBorderColor,
        glowColor,
        gradientStartColor,
        gradientMiddleColor,
        gradientEndColor,
        finalBorderColor,
        finalShadowColor,
        outerAlpha,
        middleAlpha,
        innerAlpha,
        gradientStartAlpha,
        gradientMiddleAlpha,
        gradientEndAlpha,
        borderRadius,
        outerBorderWidth,
        middleBorderWidth,
        innerBorderWidth,
        finalBorderWidth,
        shadowBlurRadius,
        glowBlurRadius,
        glowSpreadRadius,
        finalShadowBlurRadius,
        finalShadowSpreadRadius,
        finalShadowOffset,
      ]);
}
