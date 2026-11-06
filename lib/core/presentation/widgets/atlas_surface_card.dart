import 'package:flutter/material.dart';

class AtlasSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool _calendar;

  const AtlasSurfaceCard(
      {super.key, required this.child, required this.padding, this.radius = 22})
      : _calendar = false;
  const AtlasSurfaceCard.calendar({super.key, required this.child})
      : padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
        radius = 22,
        _calendar = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
        decoration: BoxDecoration(
          color: _calendar ? colors.surfaceContainerLowest : colors.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: _calendar ? 22 : 24,
                offset: Offset(0, _calendar ? 10 : 12))
          ],
        ),
        child: Padding(padding: padding, child: child));
  }
}
