import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';

enum ChartSelectorStyle { dropdown, pills, compact }

class ChartSelector extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ChartSelectorStyle style;

  const ChartSelector(
      {super.key,
      required this.labels,
      required this.selectedIndex,
      required this.onSelected,
      this.style = ChartSelectorStyle.pills});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (style == ChartSelectorStyle.dropdown) {
      return DecoratedBox(
        decoration: BoxDecoration(
            color: Color.alphaBlend(colors.primary.withValues(alpha: 0.06),
                colors.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(999)),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
          value: selectedIndex,
          isDense: true,
          borderRadius: BorderRadius.circular(18),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: colors.onSurface),
          dropdownColor: colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w800),
          selectedItemBuilder: (_) => [
            for (final label in labels)
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label, maxLines: 1))
          ],
          items: [
            for (var i = 0; i < labels.length; i++)
              DropdownMenuItem(value: i, child: Text(labels[i]))
          ],
          onChanged: (index) {
            if (index != null) onSelected(index);
          },
        )),
      );
    }
    final compact = style == ChartSelectorStyle.compact;
    Widget option(int i) {
      final selected = i == selectedIndex;
      final child = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: compact ? Curves.linear : Curves.easeOutCubic,
        alignment: compact ? null : Alignment.center,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
            : null,
        decoration: BoxDecoration(
            color: selected
                ? (compact
                    ? colors.primary.withValues(alpha: 0.12)
                    : atlasBrandGradientColors.first)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999)),
        child: Text(labels[i],
            maxLines: 1,
            style: (compact
                    ? theme.textTheme.labelMedium
                    : theme.textTheme.labelLarge)
                ?.copyWith(
                    fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
                    color: selected
                        ? (compact ? colors.primary : Colors.white)
                        : colors.onSurfaceVariant)),
      );
      return Semantics(
          button: true,
          selected: selected,
          child: compact
              ? InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.circular(999),
                  child: child)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(i),
                  child: child));
    }

    if (compact) {
      return Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < labels.length; i++) option(i)]);
    }
    return Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++) Expanded(child: option(i))
        ]));
  }
}

class ChartTooltip extends StatelessWidget {
  final DateTime date;
  final List<String> lines;
  final String? unit;
  final bool inverse;

  const ChartTooltip(
      {super.key,
      required this.date,
      required this.lines,
      this.unit,
      this.inverse = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textColor = inverse ? colors.onInverseSurface : colors.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: inverse
              ? colors.inverseSurface
              : Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.08), colors.surface),
          borderRadius: BorderRadius.circular(inverse ? 10 : 14),
          border: inverse
              ? null
              : Border.all(color: colors.primary.withValues(alpha: 0.14)),
          boxShadow: inverse
              ? null
              : [
                  BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8))
                ]),
      child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: inverse ? 10 : 12, vertical: inverse ? 6 : 9),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    (inverse
                            ? DateFormat.MMMd(
                                Localizations.localeOf(context).toString())
                            : DateFormat('dd MMM',
                                Localizations.localeOf(context).toString()))
                        .format(date),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: inverse ? textColor : colors.onSurfaceVariant,
                        fontWeight: inverse ? null : FontWeight.w700)),
                if (!inverse) const SizedBox(height: 3),
                for (final line in lines)
                  Text.rich(
                      TextSpan(children: [
                        TextSpan(text: line),
                        if (unit != null)
                          TextSpan(
                              text: ' $unit',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700))
                      ]),
                      style: (inverse
                              ? theme.textTheme.labelMedium
                              : theme.textTheme.titleSmall)
                          ?.copyWith(
                              color: textColor,
                              fontWeight:
                                  inverse ? FontWeight.w800 : FontWeight.w900)),
              ])),
    );
  }
}
