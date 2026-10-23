import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/recipe_results_list.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/default_results_widget.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/no_results_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
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
  late ProductsBloc _productsBloc;
  late RecentMealBloc _recentMealBloc;
  late RecipeSearchBloc _recipeSearchBloc;
  late final ScrollController _productsScrollController;

  late TabController _tabController;

  @override
  void initState() {
    _productsBloc = locator<ProductsBloc>();
    _recentMealBloc = locator<RecentMealBloc>();
    _recipeSearchBloc = locator<RecipeSearchBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _productsScrollController = ScrollController();
    _productsScrollController.addListener(_onProductsScroll);
    _tabController.addListener(() {
      setState(() {});
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
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productsScrollController.removeListener(_onProductsScroll);
    _productsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(children: [
          Icon(Icons.restaurant_rounded, color: colorScheme.primary, size: 23),
          const SizedBox(width: 10),
          Expanded(
              child: Text(S.of(context).searchLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800))),
        ]),
        actions: [
          BlocBuilder<AddMealBloc, AddMealState>(
            bloc: locator<AddMealBloc>()..add(InitializeAddMealEvent()),
            builder: (BuildContext context, AddMealState state) {
              if (state is AddMealLoadedState) {
                return IconButton(
                  onPressed: () =>
                      _onCustomAddButtonPressed(state.usesImperialUnits),
                  icon: const Icon(Icons.edit_outlined),
                  color: colorScheme.primary,
                );
              }
              return const SizedBox();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: SizedBox(
                height: math.max(constraints.maxHeight,
                    320 * MediaQuery.textScalerOf(context).scale(1)),
                child: Column(
                  children: [
                    _SearchHeader(
                      searchStringListener: _searchStringListener,
                      onSearchSubmit: _onSearchSubmit,
                      onBarcodePressed: _onBarcodeIconPressed,
                      tabController: _tabController,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _ProductsResultsPane(
                            bloc: _productsBloc,
                            scrollController: _productsScrollController,
                            day: _day,
                            mealType: _mealType,
                            onRefreshPressed: _onProductsRefreshButtonPressed,
                          ),
                          RecipeResultsList(
                            day: _day,
                            mealType: _mealType,
                            bloc: _recipeSearchBloc,
                          ),
                          _RecentMealsPane(
                            bloc: _recentMealBloc,
                            day: _day,
                            mealType: _mealType,
                            onRefreshPressed:
                                _onRecentMealsRefreshButtonPressed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _onProductsRefreshButtonPressed() {
    _productsBloc.add(const RefreshProductsEvent());
  }

  void _onRecentMealsRefreshButtonPressed() {
    _recentMealBloc.add(const LoadRecentMealEvent(searchString: ""));
  }

  void _onSearchSubmit(String inputText) {
    // The search is case-sensitive, so it is necessary to replace "oe"
    // with "œ" to find the corresponding foods.
    inputText = inputText.replaceAll("oe", "œ");
    switch (_tabController.index) {
      case 0:
        final trimmedInput = inputText.trim();
        _scrollProductsToTop();
        if (trimmedInput.isEmpty) {
          _productsBloc.add(const ClearProductsEvent());
          return;
        }
        _productsBloc.add(LoadProductsEvent(searchString: trimmedInput));
        break;
      case 1:
        _recipeSearchBloc.add(LoadRecipeSearchEvent(searchString: inputText));
        break;
      case 2:
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

  void _onProductsScroll() {
    if (!_productsScrollController.hasClients) {
      return;
    }
    final state = _productsBloc.state;
    if (state is! ProductsLoadedState) {
      return;
    }
    if (!state.hasMore || state.isLoadingMore) {
      return;
    }
    const threshold = 200.0;
    if (_productsScrollController.position.extentAfter < threshold) {
      _productsBloc.add(const LoadMoreProductsEvent());
    }
  }

  void _scrollProductsToTop() {
    if (_productsScrollController.hasClients) {
      _productsScrollController.jumpTo(0);
    }
  }
}

class _SearchHeader extends StatelessWidget {
  final ValueNotifier<String> searchStringListener;
  final ValueChanged<String> onSearchSubmit;
  final VoidCallback onBarcodePressed;
  final TabController tabController;

  const _SearchHeader({
    required this.searchStringListener,
    required this.onSearchSubmit,
    required this.onBarcodePressed,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MealSearchBar(
          searchStringListener: searchStringListener,
          onSearchSubmit: onSearchSubmit,
          onBarcodePressed: onBarcodePressed,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.06)),
          ),
          child: TabBar(
            controller: tabController,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            labelStyle: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              for (final label in [
                S.of(context).searchFoodPage,
                S.of(context).searchRecipesTabLabel,
                S.of(context).searchRecentTabLabel
              ])
                Tab(
                    child:
                        FittedBox(fit: BoxFit.scaleDown, child: Text(label))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductsResultsPane extends StatelessWidget {
  final ProductsBloc bloc;
  final ScrollController scrollController;
  final DateTime day;
  final AddMealType mealType;
  final VoidCallback onRefreshPressed;

  const _ProductsResultsPane({
    required this.bloc,
    required this.scrollController,
    required this.day,
    required this.mealType,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.of(context).searchResultsLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BlocBuilder<ProductsBloc, ProductsState>(
            bloc: bloc,
            builder: (context, state) {
              if (state is ProductsInitial) {
                return const DefaultsResultsWidget();
              } else if (state is ProductsLoadingState) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          S.of(context).productSearchMayTakeLongerMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is ProductsLoadedState) {
                if (state.visibleCount == 0) {
                  return state.isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : const NoResultsWidget();
                }
                final itemCount =
                    state.visibleCount + (state.isLoadingMore ? 1 : 0);
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index >= state.visibleCount) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return MealItemCard(
                      day: day,
                      mealEntity: state.products[index],
                      addMealType: mealType,
                      usesImperialUnits: state.usesImperialUnits,
                    );
                  },
                );
              } else if (state is ProductsFailedState) {
                return ErrorDialog(
                  errorText: S.of(context).errorFetchingProductData,
                  onRefreshPressed: onRefreshPressed,
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}

class _RecentMealsPane extends StatelessWidget {
  final RecentMealBloc bloc;
  final DateTime day;
  final AddMealType mealType;
  final VoidCallback onRefreshPressed;

  const _RecentMealsPane({
    required this.bloc,
    required this.day,
    required this.mealType,
    required this.onRefreshPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentMealBloc, RecentMealState>(
      bloc: bloc,
      builder: (context, state) {
        if (state is RecentMealInitial) {
          bloc.add(const LoadRecentMealEvent(searchString: ""));
          return const SizedBox();
        } else if (state is RecentMealLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecentMealLoadedState) {
          final isOnCreateMealScreen =
              locator<CreateMealBloc>().state.isOnCreateMealScreen;
          final filteredMeals = isOnCreateMealScreen
              ? state.recentMeals
                  .where(
                    (meal) => meal.mealOrRecipe != MealOrRecipeEntity.recipe,
                  )
                  .toList()
              : state.recentMeals;

          if (filteredMeals.isEmpty) {
            return const NoResultsWidget();
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            itemCount: filteredMeals.length,
            itemBuilder: (context, index) {
              return MealItemCard(
                day: day,
                mealEntity: filteredMeals[index],
                addMealType: mealType,
                usesImperialUnits: state.usesImperialUnits,
              );
            },
          );
        } else if (state is RecentMealFailedState) {
          return ErrorDialog(
            errorText: S.of(context).noMealsRecentlyAddedLabel,
            onRefreshPressed: onRefreshPressed,
          );
        }
        return const SizedBox();
      },
    );
  }
}

class AddMealScreenArguments {
  final AddMealType mealType;
  final DateTime day;
  final MealOrRecipeEntity mealOrRecipe;

  AddMealScreenArguments(this.mealType, this.day, this.mealOrRecipe);
}
