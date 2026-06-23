import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
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
        centerTitle: true,
        title: Text(
          S.of(context).searchFoodTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
          children: [
            const _SearchHeroCard(),
            const SizedBox(height: 22),
            _SearchControlCard(
              searchStringListener: _searchStringListener,
              onSearchSubmit: _onSearchSubmit,
              onBarcodePressed: _onBarcodeIconPressed,
              tabController: _tabController,
            ),
          ],
        ),
      ),
    );
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

class _SearchHeroCard extends StatelessWidget {
  const _SearchHeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brandOnSurface = colorScheme.brightness == Brightness.dark
        ? lightColorScheme.onPrimary
        : colorScheme.onPrimary;
    final brandSecondary = brandOnSurface.withValues(alpha: 0.78);

    return AtlasBrandPanel(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      borderRadius: BorderRadius.circular(22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).searchFoodTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: brandOnSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  S.of(context).searchFoodRecipeHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: brandSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _SearchHeroIcon(color: colorScheme.primary),
        ],
      ),
    );
  }
}

class _SearchHeroIcon extends StatelessWidget {
  final Color color;

  const _SearchHeroIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.search_rounded,
            color: colorScheme.onPrimary,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _SearchControlCard extends StatelessWidget {
  final ValueNotifier<String> searchStringListener;
  final ValueChanged<String> onSearchSubmit;
  final VoidCallback onBarcodePressed;
  final TabController tabController;

  const _SearchControlCard({
    required this.searchStringListener,
    required this.onSearchSubmit,
    required this.onBarcodePressed,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SearchSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.10),
                    colorScheme.surfaceContainerLowest,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).searchLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          MealSearchBar(
            searchStringListener: searchStringListener,
            onSearchSubmit: onSearchSubmit,
            onBarcodePressed: onBarcodePressed,
          ),
          const SizedBox(height: 18),
          _SearchCategorySelector(controller: tabController),
        ],
      ),
    );
  }
}

class _SearchSurfaceCard extends StatelessWidget {
  final Widget child;

  const _SearchSurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        child: child,
      ),
    );
  }
}

class _SearchCategorySelector extends StatelessWidget {
  final TabController controller;

  const _SearchCategorySelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final labels = [
      S.of(context).searchFoodPage,
      S.of(context).searchRecipesTabLabel,
      S.of(context).recentlyAddedLabel,
    ];
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor = Color.alphaBlend(
      colorScheme.onSurface.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.08 : 0.00,
      ),
      colorScheme.surfaceContainerLowest,
    );
    final dividerColor = colorScheme.primary.withValues(alpha: 0.10);
    final selectedIndex = controller.index;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: colorScheme.brightness == Brightness.dark ? 0.14 : 0.08,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: _SearchCategoryChip(
                label: labels[index],
                isSelected: selectedIndex == index,
                onTap: () => controller.animateTo(index),
              ),
            ),
            if (index != labels.length - 1)
              SizedBox(
                height: 34,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: dividerColor,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SearchCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SearchCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Material(
      color: isSelected
          ? Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.12),
              colorScheme.surfaceContainerLowest,
            )
          : colorScheme.surfaceContainerLowest.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddMealScreenArguments {
  final AddMealType mealType;
  final DateTime day;
  final MealOrRecipeEntity mealOrRecipe;

  AddMealScreenArguments(this.mealType, this.day, this.mealOrRecipe);
}
