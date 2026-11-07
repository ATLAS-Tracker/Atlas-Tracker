import 'package:flutter/material.dart';

class DynamicOntLogo extends StatelessWidget {
  const DynamicOntLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/atlas_tracker_logo.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
