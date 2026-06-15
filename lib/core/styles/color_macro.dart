import 'package:flutter/material.dart';

const Color carbColor = Color(0xfff2a51a);
const Color fatColor = Color(0xff16b892);
const Color proteinColor = Color(0xff1e78ff);
const Color breakfastColor = Color(0xffff9800);
const Color lunchColor = Color(0xff2fbf71);
const Color dinnerColor = Color(0xff5f6bff);
const Color snackColor = Color(0xffff5aa5);

const List<Color> atlasBrandGradientColors = [
  Color(0xff0454f2),
  Color(0xff003fce),
];
const Color atlasBrandShadowColor = Color(0x240045d9);
const Offset atlasBrandShadowOffset = Offset(0, 14);
const double atlasBrandShadowBlurRadius = 28;
const Color atlasBrandBubbleColor = Color(0x1400a8ff);
const double atlasBrandBubbleOuterSize = 260;
const double atlasBrandBubbleInnerSize = 180;
const double atlasBrandBubbleOuterRight = -112;
const double atlasBrandBubbleOuterTop = -18;
const double atlasBrandBubbleInnerRight = -42;
const double atlasBrandBubbleInnerTop = 36;

class MacroVisual {
  final Color color;
  final IconData icon;
  final bool useCornCobIcon;

  const MacroVisual({
    required this.color,
    required this.icon,
    this.useCornCobIcon = false,
  });
}

class MacroVisuals {
  static const MacroVisual carbs = MacroVisual(
    color: carbColor,
    icon: Icons.eco_outlined,
    useCornCobIcon: true,
  );
  static const MacroVisual fats = MacroVisual(
    color: fatColor,
    icon: Icons.water_drop_outlined,
  );
  static const MacroVisual proteins = MacroVisual(
    color: proteinColor,
    icon: Icons.egg_alt_outlined,
  );
}
