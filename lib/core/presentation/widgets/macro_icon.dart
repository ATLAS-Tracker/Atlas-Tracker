import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';

class MacroIcon extends StatelessWidget {
  static const _carbsAssetPath = 'assets/icon/macro_carbs_corn.png';

  final MacroVisual visual;
  final double size;

  const MacroIcon({super.key, required this.visual, required this.size});

  @override
  Widget build(BuildContext context) {
    if (visual.useCornCobIcon) {
      return Image.asset(
        _carbsAssetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: visual.color,
        colorBlendMode: BlendMode.srcIn,
        filterQuality: FilterQuality.high,
      );
    }
    return Icon(visual.icon, size: size, color: visual.color);
  }
}
