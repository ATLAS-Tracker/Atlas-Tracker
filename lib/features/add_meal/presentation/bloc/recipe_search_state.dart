part of 'recipe_search_bloc.dart';

abstract class RecipeSearchState extends Equatable {
  const RecipeSearchState();
}

class RecipeInitial extends RecipeSearchState {
  @override
  List<Object> get props => [];
}

class RecipeLoadingState extends RecipeSearchState {
  @override
  List<Object?> get props => [];
}

class RecipeLoadedState extends RecipeSearchState {
  final List<MealEntity> recipes;

  const RecipeLoadedState({required this.recipes});

  @override
  List<Object?> get props => [recipes];
}

class RecipeFailedState extends RecipeSearchState {
  @override
  List<Object?> get props => [];
}
