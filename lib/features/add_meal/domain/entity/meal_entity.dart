import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_fdc_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';

class MealEntity extends Equatable {
  static const liquidUnits = {'ml', 'l', 'dl', 'cl'};
  static const solidUnits = {
    'kg',
    'g',
    'mg',
    'µg',
  };

  final String? code;
  final String? name;

  final String? brands;

  final String? thumbnailImageUrl;
  final String? mainImageUrl;

  final String? url;

  final String? mealQuantity;
  final String? mealUnit;
  final double? servingQuantity;
  final String? servingUnit;
  final String? servingSize;

  bool get hasServingValues =>
      servingQuantity != null &&
      servingQuantity!.isFinite &&
      servingQuantity! > 0 &&
      const {'g', 'ml', 'serving'}.contains(servingUnit);

  static String metricUnit(String? unit) {
    final normalized = unit?.trim().toLowerCase();
    if (normalized == 'serving') return 'serving';
    // Legacy intake amounts already use base units; only their labels change.
    return liquidUnits.contains(normalized) ||
            normalized == 'fl oz' ||
            normalized == 'fl.oz'
        ? 'ml'
        : 'g';
  }

  final MealSourceEntity source;

  final MealNutrimentsEntity nutriments;

  bool get isPortionBased =>
      mealUnit == 'serving' && servingUnit == 'serving' && servingQuantity == 1;

  bool get isLiquid => metricUnit(mealUnit) == 'ml';

  bool get isSolid => solidUnits.contains(mealUnit);

  bool get hasNutriments =>
      nutriments.energyKcalPerQuantity != null &&
      nutriments.carbohydratesPerQuantity != null &&
      nutriments.fatPerQuantity != null &&
      nutriments.proteinsPerQuantity != null;

  const MealEntity(
      {required this.code,
      required this.name,
      this.brands,
      this.thumbnailImageUrl,
      this.mainImageUrl,
      required this.url,
      required this.mealQuantity,
      required this.mealUnit,
      required this.servingQuantity,
      required this.servingUnit,
      required this.servingSize,
      required this.nutriments,
      required this.source});

  factory MealEntity.empty() => MealEntity(
      code: IdGenerator.getUniqueID(),
      name: null,
      url: null,
      mealQuantity: null,
      mealUnit: 'gml',
      servingQuantity: null,
      servingUnit: 'gml',
      servingSize: '',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom);

  factory MealEntity.fromMealDBO(MealDBO mealDBO) => MealEntity(
      code: mealDBO.code,
      name: mealDBO.name,
      brands: mealDBO.brands,
      thumbnailImageUrl: mealDBO.thumbnailImageUrl,
      mainImageUrl: mealDBO.mainImageUrl,
      url: mealDBO.url,
      mealQuantity: mealDBO.mealQuantity,
      mealUnit: mealDBO.mealUnit,
      servingQuantity: mealDBO.servingQuantity,
      servingUnit: mealDBO.servingUnit,
      servingSize: mealDBO.servingSize,
      nutriments:
          MealNutrimentsEntity.fromMealNutrimentsDBO(mealDBO.nutriments),
      source: MealSourceEntity.fromMealSourceDBO(mealDBO.source));

  factory MealEntity.fromOFFProduct(OFFProductDTO offProduct) {
    final serving = _offServing(offProduct);
    return MealEntity(
        code: offProduct.code,
        name: offProduct
            .getLocaleName(SupportedLanguage.fromCode(Platform.localeName)),
        brands: offProduct.brands,
        thumbnailImageUrl: offProduct.image_front_thumb_url,
        mainImageUrl: offProduct.image_front_url,
        // Search results carry no url, the product page is derived from the code.
        url: offProduct.url ??
            (offProduct.code == null
                ? null
                : '${OFFConst.offWebsiteUrl}product/${offProduct.code}'),
        mealQuantity: offProduct.product_quantity?.toString(),
        mealUnit: _tryGetUnit(offProduct.quantity),
        servingQuantity: serving.quantity,
        servingUnit: serving.unit,
        servingSize: offProduct.serving_size,
        nutriments:
            MealNutrimentsEntity.fromOffNutriments(offProduct.nutriments),
        source: MealSourceEntity.off);
  }

  factory MealEntity.fromSpFDCFood(SpFdcFoodDTO foodItem) {
    final fdcId = foodItem.fdcId?.toInt().toString();

    final String unit; // Define the base unit
    switch (foodItem.portions[0].measureUnitId) {
      case 1003:
        unit = "l";
        break;
      case 1001:
      case 1002:
      case 1004:
        unit = "ml";
        break;
      default:
        unit = "g";
    }

    final servingUnit =
        FDCConst.measureUnits[foodItem.portions[0].measureUnitId] ??
            FDCConst.fdcDefaultUnit;

    return MealEntity(
        code: fdcId,
        name: foodItem.descriptionFr,
        brands: null,
        thumbnailImageUrl: foodItem.pictureUrl,
        mainImageUrl: foodItem.pictureUrl,
        url: FDCConst.getFoodDetailUrlString(fdcId),
        mealQuantity: null,
        mealUnit: unit,
        servingQuantity: foodItem.servingSize,
        servingUnit: servingUnit,
        servingSize:
            "${(foodItem.servingAmount ?? 1).toInt()} ${foodItem.servingSizeUnit}",
        nutriments: MealNutrimentsEntity.fromFDCNutriments(foodItem.nutrients),
        source: MealSourceEntity.fdc);
  }

  MealOrRecipeEntity get mealOrRecipe {
    return nutriments.mealOrRecipe;
  }

  static ({double? quantity, String? unit}) _offServing(OFFProductDTO product) {
    final matches = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(kg|mg|g|ml|cl|l)\b',
      caseSensitive: false,
    ).allMatches(product.serving_size ?? '').toList();
    // Mixed ice cream portions give both weight and volume; prefer the weight.
    final match = matches.firstWhereOrNull(
          (match) => const {'kg', 'mg', 'g'}.contains(match[2]!.toLowerCase()),
        ) ??
        matches.firstOrNull;
    if (match != null) {
      final unit = match[2]!.toLowerCase();
      final factor = const {'kg': 1000.0, 'mg': 0.001, 'cl': 10.0, 'l': 1000.0};
      final quantity =
          double.parse(match[1]!.replaceAll(',', '.')) * (factor[unit] ?? 1);
      if (quantity.isFinite && quantity > 0) {
        return (
          quantity: quantity,
          unit: const {'kg', 'mg', 'g'}.contains(unit) ? 'g' : 'ml',
        );
      }
    }
    return (
      quantity: _tryQuantityCast(product.serving_quantity),
      unit: _tryGetUnit(product.quantity),
    );
  }

  /// Value returned from OFF can either be String, int or double.
  /// Try casting it to a double value for calculation
  static double? _tryQuantityCast(dynamic value) {
    double? parsedValue;

    if (value == null) {
      parsedValue = null;
    } else if (value is double) {
      parsedValue = value;
    } else if (value is int) {
      parsedValue = value.toDouble();
    } else if (value is String) {
      value.replaceAll(RegExp("mg|g|kg|ml|cl|l| "), ""); // TODO extract
      final doubleParsed =
          double.tryParse(value) ?? int.tryParse(value)?.toDouble();
      parsedValue = doubleParsed;
    }
    return parsedValue;
  }

  /// TODO extract correct unit
  /// Unit can either be 100g or 100ml
  static String? _tryGetUnit(String? quantityString) {
    if (quantityString == null) return null;

    final isLiter = quantityString.toUpperCase().contains("L");

    if (isLiter) {
      return "ml";
    } else {
      return "g";
    }
  }

  @override
  List<Object?> get props => [code, name];
}

enum MealSourceEntity {
  unknown,
  custom,
  off,
  fdc;

  factory MealSourceEntity.fromMealSourceDBO(MealSourceDBO mealSourceDBO) {
    MealSourceEntity mealSourceEntity;
    switch (mealSourceDBO) {
      case MealSourceDBO.unknown:
        mealSourceEntity = MealSourceEntity.unknown;
        break;
      case MealSourceDBO.custom:
        mealSourceEntity = MealSourceEntity.custom;
        break;
      case MealSourceDBO.off:
        mealSourceEntity = MealSourceEntity.off;
        break;
      case MealSourceDBO.fdc:
        mealSourceEntity = MealSourceEntity.fdc;
        break;
    }
    return mealSourceEntity;
  }
}

extension MealEntityCopyWith on MealEntity {
  MealEntity copyWith({
    String? code,
    String? name,
    String? brands,
    String? thumbnailImageUrl,
    String? mainImageUrl,
    String? url,
    String? mealQuantity,
    String? mealUnit,
    double? servingQuantity,
    String? servingUnit,
    String? servingSize,
    MealNutrimentsEntity? nutriments,
    MealSourceEntity? source,
  }) {
    return MealEntity(
      code: code ?? this.code,
      name: name ?? this.name,
      brands: brands ?? this.brands,
      thumbnailImageUrl: thumbnailImageUrl ?? this.thumbnailImageUrl,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      url: url ?? this.url,
      mealQuantity: mealQuantity ?? this.mealQuantity,
      mealUnit: mealUnit ?? this.mealUnit,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      servingUnit: servingUnit ?? this.servingUnit,
      servingSize: servingSize ?? this.servingSize,
      nutriments: nutriments ?? this.nutriments,
      source: source ?? this.source,
    );
  }
}
