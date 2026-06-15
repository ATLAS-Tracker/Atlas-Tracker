import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';

class AtlasBrandPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const AtlasBrandPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: atlasBrandGradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: atlasBrandShadowColor,
            blurRadius: atlasBrandShadowBlurRadius,
            offset: atlasBrandShadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned(
              right: atlasBrandBubbleOuterRight,
              top: atlasBrandBubbleOuterTop,
              child: Container(
                width: atlasBrandBubbleOuterSize,
                height: atlasBrandBubbleOuterSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: atlasBrandBubbleColor,
                ),
              ),
            ),
            Positioned(
              right: atlasBrandBubbleInnerRight,
              top: atlasBrandBubbleInnerTop,
              child: Container(
                width: atlasBrandBubbleInnerSize,
                height: atlasBrandBubbleInnerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: atlasBrandBubbleColor,
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
