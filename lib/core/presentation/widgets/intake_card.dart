import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';
import 'dart:io';

class IntakeCard extends StatelessWidget {
  final IntakeEntity intake;
  final Function(BuildContext, IntakeEntity)? onItemLongPressed;
  final Function(BuildContext, IntakeEntity, bool)? onItemTapped;
  final bool firstListElement;
  final bool usesImperialUnits;

  const IntakeCard(
      {required super.key,
      required this.intake,
      this.onItemLongPressed,
      this.onItemTapped,
      required this.firstListElement,
      required this.usesImperialUnits});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: firstListElement ? 16 : 0),
        SizedBox(
          width: 120,
          height: 120,
          child: Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            child: InkWell(
              onLongPress: onItemLongPressed != null
                  ? () => onLongPressedItem(context)
                  : null,
              onTap: onItemTapped != null
                  ? () => onTappedItem(context, usesImperialUnits)
                  : null,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMealImage(context)),
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiaryContainer
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${intake.totalKcal.toInt()} kcal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer),
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            intake.meal.name ?? "?",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          MealValueUnitText(
                            value: intake.amount,
                            meal: intake.meal,
                            // Force display to use the intake's unit (e.g., serving)
                            displayUnit: intake.unit,
                            usesImperialUnits: usesImperialUnits,
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer
                                        .withValues(alpha: 0.7)),
                          ),
                        ],
                      ))
                ],
              ),
            ),
          ),
        ),
      ],
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
        color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_outlined,
          color: Theme.of(context).colorScheme.secondary,
        ),
      );

  Widget _buildLoadingBackground(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      );
}
