import 'package:flutter/material.dart';

import '../model/paper_boundary_decoration.dart';

/// A customizable paper widget with layered shadows and borders
class PaperWidget extends StatelessWidget {
  final Widget child;
  final Size size;
  final EdgeInsetsGeometry padding;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final bool isSinglePage;

  const PaperWidget({
    super.key,
    required this.child,
    required this.size,
    this.padding = const EdgeInsetsDirectional.only(
      start: 4.0,
      end: 4.0,
      top: 1.0,
      bottom: 2.0,
    ),
    this.paperBoundaryDecoration = const PaperBoundaryDecoration(),
    this.isSinglePage = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = EdgeInsetsDirectional.only(
      start: isSinglePage
          ? 0.0
          : padding.resolve(Directionality.of(context)).left,
      end: padding.resolve(Directionality.of(context)).right,
      top: padding.resolve(Directionality.of(context)).top,
      bottom: padding.resolve(Directionality.of(context)).bottom,
    );

    return Container(
      width: size.width,
      height: size.height,
      padding: effectivePadding,
      decoration: _buildOuterDecoration(),
      child: Container(
        padding: effectivePadding,
        decoration: _buildMiddleDecoration(),
        child: Container(
          padding: effectivePadding,
          decoration: _buildInnerDecoration(),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: _buildFinalDecoration(),
            child: child,
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildOuterDecoration() {
    return BoxDecoration(
      color: paperBoundaryDecoration.baseColor.withValues(
        alpha: paperBoundaryDecoration.outerAlpha,
      ),
      borderRadius: BorderRadius.circular(paperBoundaryDecoration.borderRadius),
      boxShadow: [
        BoxShadow(
          color: paperBoundaryDecoration.shadowColor.withValues(alpha: 0.2),
          blurRadius: paperBoundaryDecoration.shadowBlurRadius,
        ),
      ],
      border: Border.all(
        color: paperBoundaryDecoration.borderColor.withValues(alpha: 0.3),
        width: paperBoundaryDecoration.outerBorderWidth,
      ),
    );
  }

  BoxDecoration _buildMiddleDecoration() {
    return BoxDecoration(
      color: paperBoundaryDecoration.baseColor.withValues(
        alpha: paperBoundaryDecoration.middleAlpha,
      ),
      borderRadius: isSinglePage
          ? BorderRadiusDirectional.only(
              topEnd: Radius.circular(paperBoundaryDecoration.borderRadius),
              bottomEnd: Radius.circular(paperBoundaryDecoration.borderRadius),
            )
          : BorderRadius.circular(paperBoundaryDecoration.borderRadius),
      boxShadow: [
        BoxShadow(
          color: paperBoundaryDecoration.shadowColor.withValues(alpha: 0.2),
          blurRadius: paperBoundaryDecoration.shadowBlurRadius,
        ),
        BoxShadow(
          color: paperBoundaryDecoration.glowColor.withValues(alpha: 0.1),
          blurRadius: paperBoundaryDecoration.glowBlurRadius,
          spreadRadius: paperBoundaryDecoration.glowSpreadRadius,
        ),
      ],
      border: Border.all(
        color: paperBoundaryDecoration.innerBorderColor.withValues(alpha: 0.2),
        width: paperBoundaryDecoration.middleBorderWidth,
      ),
    );
  }

  BoxDecoration _buildInnerDecoration() {
    return BoxDecoration(
      color: paperBoundaryDecoration.baseColor.withValues(
        alpha: paperBoundaryDecoration.innerAlpha,
      ),

      borderRadius: isSinglePage
          ? BorderRadiusDirectional.only(
              topEnd: Radius.circular(paperBoundaryDecoration.borderRadius),
              bottomEnd: Radius.circular(paperBoundaryDecoration.borderRadius),
            )
          : BorderRadius.circular(paperBoundaryDecoration.borderRadius),
      boxShadow: [
        BoxShadow(
          color: paperBoundaryDecoration.shadowColor.withValues(alpha: 0.2),
          blurRadius: paperBoundaryDecoration.shadowBlurRadius,
        ),
        // Inner paper glow
        BoxShadow(
          color: paperBoundaryDecoration.baseColor.withValues(alpha: 0.15),
          blurRadius: 2.0,
          spreadRadius: -1.0,
        ),
      ],
      border: Border.all(
        color: paperBoundaryDecoration.borderColor.withValues(alpha: 0.15),
        width: paperBoundaryDecoration.innerBorderWidth,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          paperBoundaryDecoration.gradientStartColor.withValues(
            alpha: paperBoundaryDecoration.gradientStartAlpha,
          ),
          paperBoundaryDecoration.gradientMiddleColor.withValues(
            alpha: paperBoundaryDecoration.gradientMiddleAlpha,
          ),
          paperBoundaryDecoration.gradientEndColor.withValues(
            alpha: paperBoundaryDecoration.gradientEndAlpha,
          ),
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    );
  }

  BoxDecoration _buildFinalDecoration() {
    return BoxDecoration(
      borderRadius: isSinglePage
          ? BorderRadiusDirectional.only(
              topEnd: Radius.circular(paperBoundaryDecoration.borderRadius),
              bottomEnd: Radius.circular(paperBoundaryDecoration.borderRadius),
            )
          : BorderRadius.circular(paperBoundaryDecoration.borderRadius),
      border: Border.all(
        color: paperBoundaryDecoration.finalBorderColor.withValues(alpha: 0.1),
        width: paperBoundaryDecoration.finalBorderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: paperBoundaryDecoration.finalShadowColor.withValues(
            alpha: 0.05,
          ),
          blurRadius: paperBoundaryDecoration.finalShadowBlurRadius,
          spreadRadius: paperBoundaryDecoration.finalShadowSpreadRadius,
          offset: paperBoundaryDecoration.finalShadowOffset,
        ),
      ],
    );
  }
}

/// Extension methods for PaperModel to create variations
extension PaperModelExtensions on PaperBoundaryDecoration {
  /// Create a copy of this PaperModel with modified properties
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
}
