import 'package:flutter/material.dart';

import '../model/paper_boundary_decoration.dart';

/// A customizable paper widget with layered shadows and borders
class PaperWidget extends StatelessWidget {
  final Widget child;
  final Size size;
  final EdgeInsetsGeometry padding;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final bool isSinglePage;
  final bool isEnabled;

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
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEnabled || paperBoundaryDecoration == PaperBoundaryDecoration.none) {
      return child;
    }

    final effectivePadding = EdgeInsetsDirectional.only(
      start: isSinglePage
          ? 0.0
          : padding.resolve(Directionality.of(context)).left,
      end: padding.resolve(Directionality.of(context)).right,
      top: padding.resolve(Directionality.of(context)).top,
      bottom: padding.resolve(Directionality.of(context)).bottom,
    );

    return Container(
      width: size.width + effectivePadding.horizontal * 3,
      height: size.height + effectivePadding.vertical * 3,
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

