import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipeResultsList extends StatefulWidget {
  final DateTime day;
  final AddMealType mealType;
  final RecipeSearchBloc bloc;

  const RecipeResultsList({
    super.key,
    required this.day,
    required this.mealType,
    required this.bloc,
  });

  @override
  State<RecipeResultsList> createState() => _RecipeResultsListState();
}

class _RecipeResultsListState extends State<RecipeResultsList> {
  final _log = Logger('Recipe Result List');
  bool _isDragging = false;

  void _onRecipeRefreshButtonPressed() {
    widget.bloc.add(const LoadRecipeSearchEvent(searchString: ""));
  }

  // 👇 Fonction pour supprimer un fichier local si le chemin n’est pas une URL distante
  void _deleteImageIfLocal(String? path) async {
    if (path != null) {
      final imageFile = File(path);
      if (await imageFile.exists()) {
        try {
          await imageFile.delete();
          _log.fine('🗑️ Image deleted : $path');
        } catch (e) {
          _log.fine('⚠️ Error with image suppression : $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _log.fine("Recipe result list build method");

    return BlocBuilder<RecipeSearchBloc, RecipeSearchState>(
      bloc: widget.bloc,
      builder: (context, state) {
        if (state is RecipeInitial) {
          return const DefaultsResultsWidget();
        } else if (state is RecipeLoadingState) {
          return const Padding(
            padding: EdgeInsets.only(top: 32),
            child: CircularProgressIndicator(),
          );
        } else if (state is RecipeLoadedState) {
          return state.recipes.isNotEmpty
              ? Stack(
                  children: [
                    ListView.builder(
                      itemCount: state.recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = state.recipes[index];
                        return LongPressDraggable(
                          data: recipe,
                          onDragStarted: () {
                            setState(() {
                              _isDragging = true;
                            });
                          },
                          onDraggableCanceled: (_, __) {
                            setState(() {
                              _isDragging = false;
                            });
                          },
                          onDragEnd: (_) {
                            setState(() {
                              _isDragging = false;
                            });
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Opacity(
                                opacity: 0.85,
                                child: MealItemCard(
                                  day: widget.day,
                                  mealEntity: recipe,
                                  addMealType: widget.mealType,
                                  usesImperialUnits: state.usesImperialUnits,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: MealItemCard(
                              day: widget.day,
                              mealEntity: recipe,
                              addMealType: widget.mealType,
                              usesImperialUnits: state.usesImperialUnits,
                            ),
                          ),
                          child: MealItemCard(
                            day: widget.day,
                            mealEntity: recipe,
                            addMealType: widget.mealType,
                            usesImperialUnits: state.usesImperialUnits,
                          ),
                        );
                      },
                    ),
                    if (_isDragging)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 70,
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.3),
                          child: DragTarget(
                            onWillAcceptWithDetails: (data) => true,
                            onAcceptWithDetails: (details) {
                              setState(() {
                                _isDragging = false;
                              });

                              final draggedData = details.data;

                              if (draggedData is MealEntity) {
                                _deleteImageIfLocal(draggedData.url);

                                if (draggedData.code != null) {
                                  widget.bloc.add(DeleteRecipeEvent(
                                      recipeId: draggedData.code!));
                                }
                              }
                            },
                            onLeave: (data) {
                              setState(() {
                                _isDragging = false;
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              return const Center(
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                )
              : const Center(child: NoResultsWidget());
        } else if (state is RecipeFailedState) {
          return ErrorDialog(
            errorText: S.of(context).errorRecipeLabel,
            onRefreshPressed: _onRecipeRefreshButtonPressed,
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
