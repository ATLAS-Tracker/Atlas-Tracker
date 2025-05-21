import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_for_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'recipe_dbo.g.dart';

@HiveType(typeId: 17)
@JsonSerializable()
class RecipesDBO extends HiveObject {
  @HiveField(0)
  MealDBO recipe;

  @HiveField(1)
  List<IntakeForRecipeDBO> ingredients;

  RecipesDBO({
    required this.recipe,
    required this.ingredients,
  });

  factory RecipesDBO.fromRecipeEntity(RecipeEntity entity) {
    return RecipesDBO(
      recipe: MealDBO.fromMealEntity(entity.meal),
      ingredients: entity.ingredients.map((ingredient) {
        return IntakeForRecipeDBO(
          code: ingredient.code,
          name: ingredient.name,
          unit: ingredient.unit,
          amount: ingredient.amount,
          meal: ingredient.meal != null
              ? MealDBO.fromMealEntity(ingredient.meal!)
              : null,
        );
      }).toList(),
    );
  }

  RecipeEntity toEntity() {
    return RecipeEntity(
      meal: MealEntity.fromMealDBO(recipe),
      ingredients: ingredients.map((i) {
        return IntakeForRecipeEntity(
          code: i.code,
          name: i.name,
          unit: i.unit,
          amount: i.amount,
          meal: i.meal != null ? MealEntity.fromMealDBO(i.meal!) : null,
        );
      }).toList(),
    );
  }

  factory RecipesDBO.fromJson(Map<String, dynamic> json) =>
      _$RecipesDBOFromJson(json);

  Map<String, dynamic> toJson() => _$RecipesDBOToJson(this);
}
