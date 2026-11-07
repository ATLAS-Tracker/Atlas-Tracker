import 'package:opennutritracker/core/styles/color_schemes.dart';
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
            color: _atlasBrandShadowColor,
            blurRadius: _atlasBrandShadowBlurRadius,
            offset: _atlasBrandShadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned(
              right: _atlasBrandBubbleOuterRight,
              top: _atlasBrandBubbleOuterTop,
              child: Container(
                width: _atlasBrandBubbleOuterSize,
                height: _atlasBrandBubbleOuterSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _atlasBrandBubbleColor,
                ),
              ),
            ),
            Positioned(
              right: _atlasBrandBubbleInnerRight,
              top: _atlasBrandBubbleInnerTop,
              child: Container(
                width: _atlasBrandBubbleInnerSize,
                height: _atlasBrandBubbleInnerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _atlasBrandBubbleColor,
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

Color atlasBrandOnSurface(ColorScheme colors) =>
    colors.brightness == Brightness.dark
        ? lightColorScheme.onPrimary
        : colors.onPrimary;

const Color _atlasBrandShadowColor = Color(0x240045d9);
const Offset _atlasBrandShadowOffset = Offset(0, 14);
const double _atlasBrandShadowBlurRadius = 28;
const Color _atlasBrandBubbleColor = Color(0x1400a8ff);
const double _atlasBrandBubbleOuterSize = 260;
const double _atlasBrandBubbleInnerSize = 180;
const double _atlasBrandBubbleOuterRight = -112;
const double _atlasBrandBubbleOuterTop = -18;
const double _atlasBrandBubbleInnerRight = -42;
const double _atlasBrandBubbleInnerTop = 36;
