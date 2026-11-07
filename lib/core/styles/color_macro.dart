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

/// Light card shared by Home, the weight screen and the coach pages.
BoxDecoration atlasCardDecoration(ColorScheme colors) => BoxDecoration(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: colors.primary.withValues(
            alpha: colors.brightness == Brightness.dark ? 0.16 : 0.10),
      ),
      boxShadow: [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.035),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
