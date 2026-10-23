import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class IntakeCard extends StatelessWidget {
  static const double _cardWidth = 162;
  static const double _cardHeight = 176;
  static const double _imageHeight = 72;

  final IntakeEntity intake;
  final Function(BuildContext, IntakeEntity)? onItemLongPressed;
  final Function(BuildContext, IntakeEntity, bool)? onItemTapped;
  final bool firstListElement;
  final bool usesImperialUnits;
  final bool compact;

  const IntakeCard({
    required super.key,
    required this.intake,
    this.onItemLongPressed,
    this.onItemTapped,
    required this.firstListElement,
    required this.usesImperialUnits,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardSurface = Color.alphaBlend(
      colorScheme.onSurface.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.12 : 0.00,
      ),
      colorScheme.surfaceContainerLow,
    );
    final imageSurface = Color.alphaBlend(
      colorScheme.primary.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.18 : 0.08,
      ),
      colorScheme.surfaceContainerLow,
    );
    final metricSurface = Color.alphaBlend(
      colorScheme.primary.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.14 : 0.07,
      ),
      cardSurface,
    );

    return Row(
      children: [
        SizedBox(width: firstListElement ? 16 : 10),
        SizedBox(
          width: _cardWidth,
          height: _cardHeight,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onLongPress: onItemLongPressed != null
                  ? () => onLongPressedItem(context)
                  : null,
              onTap: onItemTapped != null
                  ? () => onTappedItem(context, usesImperialUnits)
                  : null,
              child: Ink(
                decoration: BoxDecoration(
                  color: cardSurface,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        colorScheme.primary.withValues(alpha: 0.04),
                        cardSurface,
                      ),
                      cardSurface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: colorScheme.brightness == Brightness.dark
                            ? 0.20
                            : 0.08,
                      ),
                      blurRadius: 16,
                      spreadRadius: -6,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: _imageHeight,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: imageSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildMealImage(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AutoSizeText(
                        intake.meal.name ?? '?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                        maxLines: 1,
                        minFontSize: 9,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricPill(
                              surface: metricSurface,
                              child: MealValueUnitText(
                                value: intake.amount,
                                meal: intake.meal,
                                displayUnit:
                                    intake.unit.toLowerCase() == 'serving'
                                        ? 'serving'
                                        : null,
                                usesImperialUnits: usesImperialUnits,
                                textStyle: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _MetricPill(
                              surface: metricSurface,
                              child: Text(
                                '${intake.totalKcal.toInt()} ${S.of(context).kcalLabel}',
                                maxLines: 1,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: _MacroValue(
                              visual: MacroVisuals.carbs,
                              value: intake.totalCarbsGram,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _MacroValue(
                              visual: MacroVisuals.fats,
                              value: intake.totalFatsGram,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _MacroValue(
                              visual: MacroVisuals.proteins,
                              value: intake.totalProteinsGram,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onItemTapped == null
            ? null
            : () => onTappedItem(context, usesImperialUnits),
        onLongPress:
            onItemLongPressed == null ? null : () => onLongPressedItem(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                    width: 56, height: 56, child: _buildMealImage(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: Text(intake.meal.name ?? '?',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Text('${intake.totalKcal.toInt()} ${s.kcalLabel}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  MealValueUnitText(
                    value: intake.amount,
                    meal: intake.meal,
                    displayUnit: intake.unit.toLowerCase() == 'serving'
                        ? 'serving'
                        : null,
                    usesImperialUnits: usesImperialUnits,
                    textStyle: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: Tooltip(
                            message: s.carbsLabel,
                            child: _MacroValue(
                                visual: MacroVisuals.carbs,
                                value: intake.totalCarbsGram))),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Tooltip(
                            message: s.fatLabel,
                            child: _MacroValue(
                                visual: MacroVisuals.fats,
                                value: intake.totalFatsGram))),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Tooltip(
                            message: s.proteinLabel,
                            child: _MacroValue(
                                visual: MacroVisuals.proteins,
                                value: intake.totalProteinsGram))),
                  ]),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  void onLongPressedItem(BuildContext context) {
    onItemLongPressed?.call(context, intake);
  }

  void onTappedItem(BuildContext context, bool usesImperialUnits) {
    onItemTapped?.call(context, intake, usesImperialUnits);
  }

  Widget _buildMealImage(BuildContext context) {
    final imageUrl = intake.meal.mainImageUrl;
    if (imageUrl == null || _hasInvalidImageUrl(imageUrl)) {
      return _buildFallbackBackground(context);
    }

    if (intake.meal.mealOrRecipe == MealOrRecipeEntity.recipe) {
      return FutureBuilder<String>(
        future: PathHelper.localImagePath(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingBackground(context);
          }
          if (snapshot.hasError) {
            return _buildFallbackBackground(context);
          }
          final path = snapshot.data;
          if (path == null || path.isEmpty) {
            return _buildFallbackBackground(context);
          }
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackBackground(context),
          );
        },
      );
    }

    return CachedNetworkImage(
      cacheManager: locator<CacheManager>(),
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingBackground(context),
      errorWidget: (context, url, error) => _buildFallbackBackground(context),
    );
  }

  bool _hasInvalidImageUrl(String url) =>
      url.trim().isEmpty || url.contains('/invalid/');

  Widget _buildFallbackBackground(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      );

  Widget _buildLoadingBackground(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
}

class _MetricPill extends StatelessWidget {
  final Color surface;
  final Widget child;

  const _MetricPill({required this.surface, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}

class _MacroValue extends StatelessWidget {
  final MacroVisual visual;
  final double value;

  const _MacroValue({required this.visual, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = Color.alphaBlend(
      visual.color.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.16 : 0.09,
      ),
      colorScheme.surfaceContainerLowest,
    );

    return Container(
      height: 23,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MacroIcon(visual: visual, size: 10),
            const SizedBox(width: 2),
            Text(
              '${value.toInt()}${S.of(context).gramUnit}',
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: visual.color,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
