import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/presentation/recipe_results_list.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipeState();
}

class _RecipeState extends State<RecipePage> {
  final log = Logger('RecipePage');
  late RecipeSearchBloc _recipeSearchBloc;

  @override
  void initState() {
    _recipeSearchBloc = locator<RecipeSearchBloc>();
    _recipeSearchBloc.add(const LoadRecipeSearchEvent(searchString: ""));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).recipeLabel),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: RecipeResultsList(
          day: DateTime.now(),
          mealType: AddMealType.snackType,
          bloc: _recipeSearchBloc,
        ),
      ),
    );
  }
}
