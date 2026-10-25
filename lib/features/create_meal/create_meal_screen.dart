import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_macro_nutrients.dart';
import 'package:opennutritracker/core/domain/entity/intake_for_recipe_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/meal_value_unit_text.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/features/create_meal/create_meal_modal.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/create_meal/pick_image_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';

class MealCreationScreen extends StatefulWidget {
  const MealCreationScreen({super.key});

  @override
  State<MealCreationScreen> createState() => _MealCreationScreenState();
}

class _MealCreationScreenState extends State<MealCreationScreen> {
  final log = Logger('MealCreationScreen');
  late final CreateMealBloc _createMealBloc;
  final _nameTextController = TextEditingController();
  String? _imagePath;
  late String _id = "";
  late String _name = "";
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _createMealBloc = locator<CreateMealBloc>();
    _createMealBloc.add(InitializeCreateMealEvent());
    log.info(
      "InitializeCreateMealEvent added: isOnCreateMealScreen set to true",
    );
  }

  @override
  void dispose() {
    _createMealBloc.add(ExitCreateMealScreenEvent());
    log.info(
      "ExitCreateMealScreenEvent added: isOnCreateMealScreen set to false",
    );
    _nameTextController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;
    _isInitialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is CreateMealScreenArguments) {
      _id = args.id;
      _name = args.name;
      _nameTextController.text = _name;
      _imagePath = args.imagePath;

      // Envoie les ingrédients au bloc de façon réactive (déclenche UI update)
      _createMealBloc.add(
        SetIntakeListFromRecipeEvent(args.recipe.ingredients),
      );
    } else {
      _id = UniqueKey().toString();
      _name = "";
      _nameTextController.text = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final editing =
        ModalRoute.of(context)?.settings.arguments is CreateMealScreenArguments;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: colors.surface,
          title: Text(editing ? s.editRecipeLabel : s.createRecipeLabel,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                    top: BorderSide(
                        color: colors.onSurface.withValues(alpha: 0.06)))),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameTextController,
              builder: (context, value, _) =>
                  BlocBuilder<CreateMealBloc, CreateMealState>(
                bloc: _createMealBloc,
                builder: (context, state) => FilledButton.icon(
                  key: const ValueKey('save-recipe'),
                  onPressed: value.text.trim().isNotEmpty &&
                          state.intakeList.isNotEmpty
                      ? _onSavePressed
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(s.buttonSaveLabel),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhotoPickerButton(
                      initialImagePath: _imagePath,
                      onImagePicked: (path) =>
                          setState(() => _imagePath = path)),
                  const SizedBox(height: 26),
                  Text(s.recipeNameLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _nameTextController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 3,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.7),
                    decoration: InputDecoration(
                        hintText: s.recipeNameHint,
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.28),
                            fontWeight: FontWeight.w700),
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none),
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<CreateMealBloc, CreateMealState>(
                    bloc: _createMealBloc,
                    builder: (context, state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (editing && state.intakeList.isNotEmpty) ...[
                          _nutritionSummary(state),
                          const SizedBox(height: 28),
                        ],
                        Row(children: [
                          Expanded(
                              child: Text(s.recipeIngredientsLabel,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800))),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('${state.intakeList.length}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700))),
                        ]),
                        const SizedBox(height: 16),
                        if (state.intakeList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                color: colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: colors.onSurface
                                        .withValues(alpha: 0.06))),
                            child: Column(children: [
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: colors.primary
                                          .withValues(alpha: 0.07),
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.restaurant_outlined,
                                      color: colors.primary, size: 28)),
                              const SizedBox(height: 14),
                              Text(s.noFoodAddedLabel,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(s.recipeEmptyHelp,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant)),
                            ]),
                          )
                        else
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                                color: colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: colors.onSurface
                                        .withValues(alpha: 0.06))),
                            child: Column(children: [
                              for (var i = 0;
                                  i < state.intakeList.length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: colors.onSurface
                                          .withValues(alpha: 0.06)),
                                _ingredientRow(state.intakeList[i]),
                              ],
                            ]),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                            key: const ValueKey('add-recipe-ingredient'),
                            onPressed: () => _showAddItemScreen(
                                context, AddMealType.snackType, DateTime.now()),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(s.addIngredientLabel),
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color:
                                        colors.primary.withValues(alpha: 0.25)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)))),
                        if (!editing && state.intakeList.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _nutritionSummary(state),
                        ],
                      ],
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _ingredientRow(IntakeForRecipeEntity ingredient) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final meal = ingredient.meal!;
    final intake = IntakeEntity(
        id: ingredient.code ?? ingredient.name ?? '',
        unit: ingredient.unit ?? 'g',
        amount: ingredient.amount ?? 0,
        type: IntakeTypeEntity.breakfast,
        meal: meal,
        dateTime: DateTime.now());
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('recipe-ingredient-${intake.id}'),
        onTap: () => onIntakeItemTapped(context, intake, false),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(children: [
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.restaurant_outlined,
                    size: 21, color: colors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(meal.name ?? '',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  MealValueUnitText(
                      value: intake.amount,
                      meal: meal,
                      displayUnit: intake.unit,
                      usesImperialUnits: false,
                      textStyle: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                ])),
            IconButton(
                tooltip: S.of(context).editItemDialogTitle,
                onPressed: () => onIntakeItemTapped(context, intake, false),
                icon: Icon(Icons.tune_rounded,
                    color: colors.onSurfaceVariant, size: 20)),
          ]),
        ),
      ),
    );
  }

  Widget _nutritionSummary(CreateMealState state) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final macros = _createMealBloc.computeMacros();
    return AtlasBrandPanel(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(s.recipeTotalsLabel,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 8),
        Row(children: [
          Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: breakfastColor, size: 26)),
          const SizedBox(width: 12),
          Expanded(
              child: Text('${macros['totalKcal']!.toInt()} ${s.kcalLabel}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: MealDetailMacroNutrients(
                  typeString: s.carbsLabel,
                  value: state.totalCarbs,
                  visual: MacroVisuals.carbs)),
          const SizedBox(width: 8),
          Expanded(
              child: MealDetailMacroNutrients(
                  typeString: s.fatLabel,
                  value: state.totalFats,
                  visual: MacroVisuals.fats)),
          const SizedBox(width: 8),
          Expanded(
              child: MealDetailMacroNutrients(
                  typeString: s.proteinLabel,
                  value: state.totalProteins,
                  visual: MacroVisuals.proteins)),
        ]),
        const SizedBox(height: 16),
        Text(s.recipePortionsHelp,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.76))),
      ]),
    );
  }

  void onIntakeItemTapped(
    BuildContext context,
    IntakeEntity intakeEntity,
    bool usesImperialUnits,
  ) async {
    final dialogResult = await showDialog<EditDialogResult>(
      context: context,
      builder: (context) => EditDialog(
        intakeEntity: intakeEntity,
        usesImperialUnits: usesImperialUnits,
      ),
    );

    if (dialogResult == null) {
      return;
    }

    switch (dialogResult.action) {
      case EditDialogAction.updateAmount:
        final updatedAmount = dialogResult.amount;
        if (updatedAmount == null) {
          return;
        }
        locator<CreateMealBloc>().updateIntakeAmount(
          intakeEntity.id,
          updatedAmount,
        );
        break;
      case EditDialogAction.deleteItem:
        locator<CreateMealBloc>().removeIntake(intakeEntity.id);
        break;
      case EditDialogAction.viewProduct:
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pushNamed(
          NavigationOptions.mealDetailRoute,
          arguments: MealDetailScreenArguments(
            intakeEntity.meal,
            intakeEntity.type,
            intakeEntity.dateTime,
            usesImperialUnits,
          ),
        );
        break;
    }
  }

  void _showAddItemScreen(
    BuildContext context,
    AddMealType itemType,
    DateTime day,
  ) {
    Navigator.of(context).pushNamed(
      NavigationOptions.addMealRoute,
      arguments: AddMealScreenArguments(
        itemType,
        day,
        MealOrRecipeEntity.recipe,
      ),
    );
  }

  void _onSavePressed() {
    final recipeName = _nameTextController.text;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return CalendarMealTypeSelector(
          onDateSelected: (date) {},
          mealName: recipeName,
          idOfRecipeToModify: _id,
          imagePath: _imagePath,
        );
      },
    );
  }
}

class CreateMealScreenArguments {
  final String id;
  final String name;
  final RecipeEntity recipe;
  final String? imagePath;
  CreateMealScreenArguments(this.id, this.name, this.recipe, this.imagePath);
}
