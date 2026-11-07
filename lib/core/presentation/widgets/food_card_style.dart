import 'package:flutter/material.dart';

const foodCardWidth = 162.0;
const foodCardHeight = 176.0;
const foodCardLeadingInset = 16.0;
const foodCardSpacing = 10.0;

Color foodCardSurface(ColorScheme colors) => Color.alphaBlend(
      colors.onSurface
          .withValues(alpha: colors.brightness == Brightness.dark ? 0.12 : 0.0),
      colors.surfaceContainerLow,
    );
