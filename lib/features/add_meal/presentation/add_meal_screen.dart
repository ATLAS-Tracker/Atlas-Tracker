import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/recipe_results_list.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<String> _searchStringListener = ValueNotifier('');

  late AddMealType _mealType;
  late DateTime _day;
  late String _mealOrRecipe;

  late ProductsBloc _productsBloc;
  late FoodBloc _foodBloc;
  late RecentMealBloc _recentMealBloc;
  late RecipeSearchBloc _recipeSearchBloc;

  late TabController _tabController;

  @override
  void initState() {
    _productsBloc = locator<ProductsBloc>();
    _foodBloc = locator<FoodBloc>();
    _recentMealBloc = locator<RecentMealBloc>();
    _recipeSearchBloc = locator<RecipeSearchBloc>();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // Update search results when tab changes
      _onSearchSubmit(_searchStringListener.value);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as AddMealScreenArguments;
    _mealType = args.mealType;
    _day = args.day;
    _mealOrRecipe = args.mealOrRecipe;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              _mealOrRecipe == "recipe" ? "" : _mealType.getTypeName(context)),
          actions: [
            BlocBuilder<AddMealBloc, AddMealState>(
              bloc: locator<AddMealBloc>()..add(InitializeAddMealEvent()),
              builder: (BuildContext context, AddMealState state) {
                if (state is AddMealLoadedState) {
                  return IconButton(
                    onPressed: () =>
                        _onCustomAddButtonPressed(state.usesImperialUnits),
                    icon: const Icon(Icons.add_circle_outline),
                  );
                }
                return const SizedBox();
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              MealSearchBar(
                searchStringListener: _searchStringListener,
                onSearchSubmit: _onSearchSubmit,
                onBarcodePressed: _onBarcodeIconPressed,
              ),
              const SizedBox(height: 16.0),
              TabBar(
                  tabs: [
                    Tab(text: S.of(context).searchProductsPage),
                    Tab(text: S.of(context).searchFoodPage),
                    Tab(text: S.of(context).recipeLabel),
                    Tab(text: S.of(context).recentlyAddedLabel)
                  ],
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(controller: _tabController, children: [
                  Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).searchResultsLabel,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      BlocBuilder<ProductsBloc, ProductsState>(
                        bloc: _productsBloc,
                        builder: (context, state) {
                          if (state is ProductsInitial) {
                            return const DefaultsResultsWidget();
                          } else if (state is ProductsLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is ProductsLoadedState) {
                            return state.products.isNotEmpty
                                ? Flexible(
                                    child: ListView.builder(
                                        itemCount: state.products.length,
                                        itemBuilder: (context, index) {
                                          return MealItemCard(
                                            day: _day,
                                            mealEntity: state.products[index],
                                            addMealType: _mealType,
                                            usesImperialUnits:
                                                state.usesImperialUnits,
                                          );
                                        }))
                                : const NoResultsWidget();
                          } else if (state is ProductsFailedState) {
                            return ErrorDialog(
                              errorText: S.of(context).errorFetchingProductData,
                              onRefreshPressed: _onProductsRefreshButtonPressed,
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).searchResultsLabel,
                              style:
                                  Theme.of(context).textTheme.headlineSmall)),
                      BlocBuilder<FoodBloc, FoodState>(
                        bloc: _foodBloc,
                        builder: (context, state) {
                          if (state is FoodInitial) {
                            return const DefaultsResultsWidget();
                          } else if (state is FoodLoadingState) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 32),
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is FoodLoadedState) {
                            return state.food.isNotEmpty
                                ? Flexible(
                                    child: ListView.builder(
                                        itemCount: state.food.length,
                                        itemBuilder: (context, index) {
                                          return MealItemCard(
                                            day: _day,
                                            mealEntity: state.food[index],
                                            addMealType: _mealType,
                                            usesImperialUnits:
                                                state.usesImperialUnits,
                                          );
                                        }))
                                : const NoResultsWidget();
                          } else if (state is FoodFailedState) {
                            return ErrorDialog(
                              errorText: S.of(context).errorFetchingProductData,
                              onRefreshPressed: _onFoodRefreshButtonPressed,
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    ],
                  ),
                  RecipeResultsList(
                    day: _day,
                    mealType: _mealType,
                    bloc: _recipeSearchBloc,
                  ),
                  Column(
                    children: [
                      BlocBuilder<RecentMealBloc, RecentMealState>(
                          bloc: _recentMealBloc,
                          builder: (context, state) {
                            if (state is RecentMealInitial) {
                              _recentMealBloc.add(
                                  const LoadRecentMealEvent(searchString: ""));
                              return const SizedBox();
                            } else if (state is RecentMealLoadingState) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 32),
                                child: CircularProgressIndicator(),
                              );
                            } else if (state is RecentMealLoadedState) {
                              final isOnCreateMealScreen =
                                  locator<CreateMealBloc>()
                                      .state
                                      .isOnCreateMealScreen;

                              final filteredMeals = isOnCreateMealScreen
                                  ? state.recentMeals
                                      .where((meal) =>
                                          meal.mealOrRecipe != 'recipe')
                                      .toList()
                                  : state.recentMeals;

                              return filteredMeals.isNotEmpty
                                  ? Flexible(
                                      child: ListView.builder(
                                        itemCount: filteredMeals.length,
                                        itemBuilder: (context, index) {
                                          return MealItemCard(
                                            day: _day,
                                            mealEntity: filteredMeals[index],
                                            addMealType: _mealType,
                                            usesImperialUnits:
                                                state.usesImperialUnits,
                                          );
                                        },
                                      ),
                                    )
                                  : const NoResultsWidget();
                            } else if (state is RecentMealFailedState) {
                              return ErrorDialog(
                                errorText:
                                    S.of(context).noMealsRecentlyAddedLabel,
                                onRefreshPressed:
                                    _onRecentMealsRefreshButtonPressed,
                              );
                            }
                            return const SizedBox();
                          })
                    ],
                  )
                ]),
              )
            ],
          ),
        ));
  }

  void _onProductsRefreshButtonPressed() {
    _productsBloc.add(const RefreshProductsEvent());
  }

  void _onFoodRefreshButtonPressed() {
    _foodBloc.add(const RefreshFoodEvent());
  }

  void _onRecentMealsRefreshButtonPressed() {
    _recentMealBloc.add(const LoadRecentMealEvent(searchString: ""));
  }

  void _onSearchSubmit(String inputText) {
    switch (_tabController.index) {
      case 0:
        _productsBloc.add(LoadProductsEvent(searchString: inputText));
        break;
      case 1:
        _foodBloc.add(LoadFoodEvent(searchString: inputText));
        break;
      case 2:
        _recipeSearchBloc.add(LoadRecipeSearchEvent(searchString: inputText));
        break;
      case 3:
        _recentMealBloc.add(LoadRecentMealEvent(searchString: inputText));
        break;
    }
  }

  void _onBarcodeIconPressed() {
    Navigator.of(context).pushNamed(NavigationOptions.scannerRoute,
        arguments: ScannerScreenArguments(_day, _mealType.getIntakeType()));
  }

  void _onCustomAddButtonPressed(bool usesImperialUnits) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).createCustomDialogTitle),
            content: Text(S.of(context).createCustomDialogContent),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(), // close dialog
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    _openEditMealScreen(usesImperialUnits);
                  },
                  child: Text(S.of(context).buttonYesLabel)),
            ],
          );
        });
  }

  void _openEditMealScreen(bool usesImperialUnits) {
    // TODO
    Navigator.of(context).pushNamed(NavigationOptions.editMealRoute,
        arguments: EditMealScreenArguments(
          _day,
          MealEntity.empty(),
          _mealType.getIntakeType(),
          usesImperialUnits,
        ));
  }
}

class AddMealScreenArguments {
  final AddMealType mealType;
  final DateTime day;
  final String mealOrRecipe;

  AddMealScreenArguments(this.mealType, this.day, this.mealOrRecipe);
}
