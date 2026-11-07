import 'package:flutter/material.dart';

DialogThemeData atlasDialogTheme(ColorScheme colors) => DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: colors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
    );
