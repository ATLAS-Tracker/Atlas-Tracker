import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'dart:io';

class MealItemCard extends StatelessWidget {
  final DateTime day;
  final AddMealType addMealType;
  final MealEntity mealEntity;
  final bool usesImperialUnits;

  const MealItemCard(
      {super.key,
      required this.day,
      required this.mealEntity,
      required this.addMealType,
      required this.usesImperialUnits});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.onSurface.withValues(alpha: 0.06))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onItemPressed(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildThumbnail(context))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mealEntity.name ?? '?',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (mealEntity.brands?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(mealEntity.brands!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                    if (mealEntity.mealQuantity != null) ...[
                      const SizedBox(height: 5),
                      MealValueUnitText(
                          value: double.parse(mealEntity.mealQuantity ?? '0'),
                          meal: mealEntity,
                          usesImperialUnits: usesImperialUnits),
                    ],
                  ],
                )),
                const SizedBox(width: 4),
                IconButton(
                  style: IconButton.styleFrom(
                      foregroundColor: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: 0.08)),
                  onPressed: () => _onItemPressed(context),
                  icon: const Icon(Icons.add_rounded, size: 23),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemPressed(BuildContext context) {
    Navigator.of(context).pushNamed(NavigationOptions.mealDetailRoute,
        arguments: MealDetailScreenArguments(
            mealEntity, addMealType.getIntakeType(), day, usesImperialUnits));
  }

  Widget _buildThumbnail(BuildContext context) {
    final thumbnailUrl = mealEntity.thumbnailImageUrl;
    if (thumbnailUrl == null || _hasInvalidImageUrl(thumbnailUrl)) {
      return _buildFallbackPlaceholder(context);
    }

    if (mealEntity.mealOrRecipe == MealOrRecipeEntity.recipe) {
      return FutureBuilder<String>(
        future: PathHelper.localImagePath(thumbnailUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPlaceholder(context);
          }
          if (snapshot.hasError) {
            return _buildFallbackPlaceholder(context);
          }
          final path = snapshot.data;
          if (path == null || path.isEmpty) {
            return _buildFallbackPlaceholder(context);
          }
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackPlaceholder(context),
          );
        },
      );
    }

    return CachedNetworkImage(
      cacheManager: locator<CacheManager>(),
      fit: BoxFit.cover,
      imageUrl: thumbnailUrl,
      placeholder: (context, url) => _buildLoadingPlaceholder(context),
      errorWidget: (context, url, error) => _buildFallbackPlaceholder(context),
    );
  }

  Widget _buildFallbackPlaceholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        child: Icon(
          Icons.restaurant_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      );

  Widget _buildLoadingPlaceholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      );

  bool _hasInvalidImageUrl(String url) =>
      url.trim().isEmpty || url.contains('/invalid/');
}
