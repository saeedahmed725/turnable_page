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
}
