import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_for_recipe_entity.dart';

class RecipeEntity extends Equatable {
  final MealEntity meal; // Le plat principal (la recette elle-même)
  final List<IntakeForRecipeEntity> ingredients; // Les composants (ingrédients)
  final DateTime? updatedAt;

  const RecipeEntity({
    required this.meal,
    required this.ingredients,
    this.updatedAt,
  });

  /// Convertir depuis un RecipesDBO Hive
  factory RecipeEntity.fromRecipesDBO(RecipesDBO dbo) {
    return RecipeEntity(
      updatedAt: dbo.updatedAt,
      meal: MealEntity.fromMealDBO(dbo.recipe),
      ingredients: dbo.ingredients
          .map((ingredient) => IntakeForRecipeEntity(
                code: ingredient.code,
                name: ingredient.name,
                unit: ingredient.unit,
                amount: ingredient.amount,
                meal: ingredient.meal != null
                    ? MealEntity.fromMealDBO(ingredient.meal!)
                    : null,
              ))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [meal, ingredients, updatedAt];
}
