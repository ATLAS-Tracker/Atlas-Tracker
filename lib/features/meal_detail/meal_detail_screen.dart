import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:opennutritracker/core/presentation/widgets/image_full_screen.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/create_meal/create_meal_screen.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_macro_nutrients.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_info_button.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_placeholder.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_title_expanded.dart';
import 'package:opennutritracker/core/domain/usecase/get_recipe_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'dart:io';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({super.key});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final _energyKey = GlobalKey();
  final _bottomKey = GlobalKey();

  static const String _initialQuantityMetric = '100';

  final log = Logger('ItemDetailScreen');

  late MealDetailBloc _mealDetailBloc;
  final _scrollController = ScrollController();

  late MealEntity meal;
  late DateTime _day;
  late IntakeTypeEntity intakeTypeEntity;
  IntakeEntity? _intakeToEdit;
  IntakeEntity? _initialIntake;

  final quantityTextController = TextEditingController();

  String _initialUnit = "";
  String _initialQuantity = "";
  bool _userChangedQuantityOrUnit = false;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    // Runs again on every keyboard/menu open: read the arguments only once, or
    // the full product loaded below gets replaced by the search result again.
    if (_initialUnit == "") {
      final args = ModalRoute.of(context)?.settings.arguments
          as MealDetailScreenArguments;
      meal = args.mealEntity;
      _day = args.day;
      intakeTypeEntity = args.intakeTypeEntity;
      _intakeToEdit = args.intakeToEdit;
      _initialIntake = args.initialIntake;

      if (args.postNavigationAction != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            args.postNavigationAction!(context);
          }
        });
      }

      _applyInitialUnitAndQuantity();
      _loadFullOffProduct();
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealDetailBloc, MealDetailState>(
      bloc: _mealDetailBloc,
      builder: (context, state) {
        if (state is MealDetailInitial) {
          return Scaffold(
            body: _getLoadedContent(
              context,
              state.totalQuantityConverted,
              state.totalKcal,
              state.totalCarbs,
              state.totalFat,
              state.totalProtein,
              state.selectedUnit,
            ),
            bottomNavigationBar: SafeArea(
                key: _bottomKey,
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: (MediaQuery.sizeOf(context).height -
                                MediaQuery.viewInsetsOf(context).bottom) *
                            0.5),
                    child: SingleChildScrollView(
                        child: MealDetailBottomSheet(
                      product: meal,
                      intakeToEdit: _intakeToEdit,
                      day: _day,
                      intakeTypeEntity: intakeTypeEntity,
                      selectedUnit: state.selectedUnit,
                      mealDetailBloc: _mealDetailBloc,
                      quantityTextController: quantityTextController,
                      onQuantityOrUnitChanged: onQuantityOrUnitChanged,
                    )),
                  ),
                )),
          );
        } else {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _getLoadedContent(
      BuildContext context,
      String totalQuantity,
      double totalKcal,
      double totalCarbs,
      double totalFat,
      double totalProtein,
      String selectedUnit) {
    final colors = Theme.of(context).colorScheme;
    final hasPhoto = meal.mainImageUrl?.trim().isNotEmpty == true;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
            pinned: true,
            backgroundColor: colors.surface,
            surfaceTintColor: colors.surface,
            title: Text(meal.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            actions: [
              if (meal.mealOrRecipe == MealOrRecipeEntity.recipe)
                IconButton(
                  tooltip: S.of(context).editRecipeLabel,
                  onPressed: () async {
                    final recipe = await locator<GetRecipeUsecase>()
                        .getRecipeById(meal.code!);
                    if (recipe == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).errorRecipeLabel)),
                      );
                      return;
                    }

                    if (!context.mounted) return;
                    await Navigator.of(context).pushNamed(
                      NavigationOptions.createMealRoute,
                      arguments: CreateMealScreenArguments(
                        meal.code!,
                        meal.name!,
                        recipe,
                        meal.url,
                      ),
                    );
                    if (!mounted) return;
                    final updated = await locator<GetRecipeUsecase>()
                        .getRecipeById(meal.code!);
                    if (mounted && updated != null) {
                      setState(() => meal = updated.meal);
                      _mealDetailBloc.add(UpdateKcalEvent(
                          meal: meal,
                          totalQuantity: quantityTextController.text,
                          selectedUnit: _mealDetailBloc.state.selectedUnit));
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                )
              else
                IconButton(
                  tooltip: S.of(context).editLabel,
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      NavigationOptions.editMealRoute,
                      arguments: EditMealScreenArguments(
                        _day,
                        meal,
                        intakeTypeEntity,
                        intakeToEdit: _intakeToEdit,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ]),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverToBoxAdapter(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: colors.onSurface.withValues(alpha: 0.05))),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 120,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primary.withValues(alpha: 0.10),
                              colors.primary.withValues(alpha: 0.025)
                            ],
                          )),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: GestureDetector(
                                  onTap: hasPhoto
                                      ? () {
                                          Navigator.of(context).pushNamed(
                                            NavigationOptions
                                                .imageFullScreenRoute,
                                            arguments: ImageFullScreenArguments(
                                                meal.mainImageUrl ?? ""),
                                          );
                                        }
                                      : null,
                                  child: hasPhoto
                                      ? !meal.mainImageUrl!.startsWith('http')
                                          ? Hero(
                                              tag: ImageFullScreen
                                                  .fullScreenHeroTag,
                                              child: FutureBuilder<String>(
                                                future:
                                                    PathHelper.localImagePath(
                                                        meal.mainImageUrl!),
                                                builder: (context, snapshot) {
                                                  final path = snapshot.data;
                                                  if (path == null) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                  return Image.file(
                                                    File(path),
                                                    width: 80,
                                                    height: 96,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __,
                                                            ___) =>
                                                        const MealPlaceholder(),
                                                  );
                                                },
                                              ),
                                            )
                                          : Hero(
                                              tag: ImageFullScreen
                                                  .fullScreenHeroTag,
                                              child: CachedNetworkImage(
                                                width: 80,
                                                height: 96,
                                                cacheManager:
                                                    locator<CacheManager>(),
                                                imageUrl: meal.mainImageUrl!,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, string) =>
                                                        const MealPlaceholder(),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const MealPlaceholder(),
                                              ),
                                            )
                                      : Container(
                                          width: 64,
                                          height: 64,
                                          color: colors.primary
                                              .withValues(alpha: 0.08),
                                          child: Icon(Icons.fastfood_outlined,
                                              color: colors.primary, size: 30),
                                        )),
                            ),
                          ),
                        ),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: MealTitleExpanded(meal: meal),
                        )),
                      ]),
                ),
                const SizedBox(height: 18),
                AtlasBrandPanel(
                  key: _energyKey,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(S.of(context).energyLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.74),
                                          fontWeight: FontWeight.w700))),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(
                                Icons.local_fire_department_outlined,
                                color: Colors.white,
                                size: 22),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            '${formatNumber(totalKcal)} ${S.of(context).kcalLabel}',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        MealValueUnitText(
                            value: double.parse(totalQuantity),
                            meal: meal,
                            displayUnit: selectedUnit ==
                                    UnitDropdownItem.serving.toString()
                                ? meal.servingUnit
                                : selectedUnit,
                            portionCount: selectedUnit ==
                                    UnitDropdownItem.serving.toString()
                                ? double.tryParse(quantityTextController.text
                                    .replaceAll(',', '.'))
                                : null,
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.80)),
                            prefix: ''),
                        const SizedBox(height: 18),
                        Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.16)),
                        const SizedBox(height: 18),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: MealDetailMacroNutrients(
                                      typeString: S.of(context).carbsLabel,
                                      value: totalCarbs,
                                      visual: MacroVisuals.carbs)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: MealDetailMacroNutrients(
                                      typeString: S.of(context).fatLabel,
                                      value: totalFat,
                                      visual: MacroVisuals.fats)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: MealDetailMacroNutrients(
                                      typeString: S.of(context).proteinLabel,
                                      value: totalProtein,
                                      visual: MacroVisuals.proteins)),
                            ]),
                      ]),
                ),
                const SizedBox(height: 18),
                ExpansionTile(
                  key: PageStorageKey('meal-nutrition-${meal.code}'),
                  initiallyExpanded: false,
                  maintainState: true,
                  backgroundColor: colors.surfaceContainerLowest,
                  collapsedBackgroundColor: colors.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                          color: colors.onSurface.withValues(alpha: 0.06))),
                  collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                          color: colors.onSurface.withValues(alpha: 0.06))),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.fact_check_outlined,
                        color: colors.primary, size: 22),
                  ),
                  title: Text(S.of(context).nutritionInfoLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      MealDetailNutrimentsTable.headerFor(context, meal),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: MealDetailNutrimentsTable(
                          product: meal, embedded: true),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                MealInfoButton(url: meal.url, source: meal.source),
              ])),
        ),
      ],
    );
  }

  /// Last intake first, then serving, else 100 g/ml (OFF package sizes are not
  /// a portion), else the quantity of custom foods. Only metric
  /// units are offered (the app targets France).
  void _applyInitialUnitAndQuantity() {
    final initialIntake = _intakeToEdit ?? _initialIntake;
    if (initialIntake != null) {
      _initialUnit = MealEntity.metricUnit(initialIntake.unit);
      _initialQuantity =
          formatQuantity(initialIntake.amount).replaceAll('\u202f', '');
    } else if (meal.hasServingValues) {
      _initialUnit = UnitDropdownItem.serving.toString();
      _initialQuantity = "1";
    } else {
      _initialUnit =
          UnitDropdownItem.g.fromString(meal.mealUnit ?? '').toString();
      _initialQuantity = meal.source == MealSourceEntity.off
          ? _initialQuantityMetric
          : meal.mealQuantity ?? _initialQuantityMetric;
    }
    quantityTextController.text = _initialQuantity;
    _mealDetailBloc.add(UpdateKcalEvent(
        meal: meal,
        totalQuantity: _initialQuantity,
        selectedUnit: _initialUnit));
  }

  /// Search results lack the serving size (1 Prince = 20 g): fetch the full
  /// product in the background. The screen is usable meanwhile.
  Future<void> _loadFullOffProduct() async {
    final code = meal.code;
    if (_intakeToEdit != null ||
        meal.source != MealSourceEntity.off ||
        meal.hasServingValues ||
        code == null) {
      return;
    }
    try {
      final fullProduct = await locator<SearchProductByBarcodeUseCase>()
          .searchProductByBarcode(code);
      if (!mounted || !fullProduct.hasNutriments) return;
      setState(() => meal = fullProduct);
      if (!_userChangedQuantityOrUnit) _applyInitialUnitAndQuantity();
    } catch (e) {
      log.fine('Full OFF product not loaded, keeping search data: $e');
    }
  }

  void onQuantityOrUnitChanged(String? quantityString, String? unit) {
    if (quantityString == null || unit == null) {
      return;
    }
    _userChangedQuantityOrUnit = true;
    final oldUnit = _mealDetailBloc.state.selectedUnit;
    final enteredQuantity = parsePositiveQuantity(quantityString);
    if (unit != oldUnit && enteredQuantity != null) {
      double factor(String value) =>
          value == 'serving' ? meal.servingQuantity ?? 1 : 1;
      final converted = enteredQuantity * factor(oldUnit) / factor(unit);
      quantityString = formatQuantity(converted).replaceAll('\u202f', '');
      quantityTextController.text = quantityString;
    }
    _mealDetailBloc.add(UpdateKcalEvent(
        meal: meal, totalQuantity: quantityString, selectedUnit: unit));
    _scrollToCalorieText();
  }

  void _scrollToCalorieText() {
    final target = _energyKey.currentContext;
    if (target != null) {
      final box = target.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottomBox =
          _bottomKey.currentContext?.findRenderObject() as RenderBox?;
      final visibleBottom = bottomBox?.localToGlobal(Offset.zero).dy ??
          MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom;
      if (top >= MediaQuery.paddingOf(context).top &&
          top + box.size.height <= visibleBottom) {
        return;
      }
      Scrollable.ensureVisible(target,
          alignment: 0.1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _mealDetailBloc.close();
    _scrollController.dispose();
    quantityTextController.dispose();
    super.dispose();
  }
}

class MealDetailScreenArguments {
  final MealEntity mealEntity;
  final IntakeTypeEntity intakeTypeEntity;
  final DateTime day;
  final void Function(BuildContext)? postNavigationAction;
  final IntakeEntity? intakeToEdit;
  final IntakeEntity? initialIntake;

  MealDetailScreenArguments(this.mealEntity, this.intakeTypeEntity, this.day,
      {this.postNavigationAction, this.intakeToEdit, this.initialIntake});
}
