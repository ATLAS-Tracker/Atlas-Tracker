import 'package:opennutritracker/core/presentation/refresh_journal.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';

class CalendarMealTypeSelector extends StatefulWidget {
  final String mealName;
  final String? imagePath;
  final DateTime? initialDay;
  final IntakeTypeEntity? initialType;

  const CalendarMealTypeSelector({
    super.key,
    required this.mealName,
    required this.imagePath,
    this.initialDay,
    this.initialType,
  });

  @override
  State<CalendarMealTypeSelector> createState() =>
      _CalendarMealTypeSelectorState();
}

class _CalendarMealTypeSelectorState extends State<CalendarMealTypeSelector> {
  late DateTime _selectedDate;
  int _currentMealIndex = 0;
  bool _addToDiary = false;
  bool _saving = false;

  final List<IntakeTypeEntity> _mealTypes = IntakeTypeEntity.values;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDay ?? DateTime.now();
    _currentMealIndex = (widget.initialType ?? IntakeTypeEntity.lunch).index;
  }

  void _handleDateSelected(DateTime day) {
    setState(() {
      _selectedDate = day;
    });
  }

  void _goToPreviousMeal() {
    setState(() {
      _currentMealIndex =
          (_currentMealIndex - 1 + _mealTypes.length) % _mealTypes.length;
    });
  }

  void _goToNextMeal() {
    setState(() {
      _currentMealIndex = (_currentMealIndex + 1) % _mealTypes.length;
    });
  }

  String _getMealLabel(IntakeTypeEntity type) {
    switch (type) {
      case IntakeTypeEntity.breakfast:
        return S.of(context).breakfastLabel;
      case IntakeTypeEntity.lunch:
        return S.of(context).lunchLabel;
      case IntakeTypeEntity.dinner:
        return S.of(context).dinnerLabel;
      case IntakeTypeEntity.snack:
        return S.of(context).snackLabel;
    }
  }

  Future<void> _onSavePressed() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await saveRecipe(
        context,
        mealName: widget.mealName,
        imagePath: widget.imagePath,
        idOfRecipeToModify: null,
        type: _mealTypes[_currentMealIndex],
        day: _selectedDate,
        addToDiary: _addToDiary,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).recipeSaveError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMeal = _mealTypes[_currentMealIndex];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 20),
              Text(widget.mealName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),

              Text(S.of(context).recipeLibraryHelp),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.of(context).addRecipeToDiary),
                  value: _addToDiary,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _addToDiary = value)),

              /// Meal type selector
              if (_addToDiary) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: S.of(context).previousLabel,
                      onPressed: _goToPreviousMeal,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(currentMeal.getIconData()),
                          const SizedBox(width: 8),
                          Flexible(
                              child: Text(
                            _getMealLabel(currentMeal),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          )),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: S.of(context).nextLabel,
                      onPressed: _goToNextMeal,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// Calendar
                DiaryTableCalendar(
                  onDateSelected: _handleDateSelected,
                  calendarDurationDays: const Duration(days: 30),
                  focusedDate: _selectedDate,
                  currentDate: DateTime.now(),
                  selectedDate: _selectedDate,
                  trackedDaysMap: const {},
                ),
              ],
              const SizedBox(height: 16),

              /// Save button
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: _saving ? null : _onSavePressed,
                    child: Text(S.of(context).buttonSaveLabel),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saves the ingredients currently held by [CreateMealBloc] as a recipe whose
/// serving is one of its [CreateMealBloc.portions], and logs one serving of it
/// to [type] on [day].
Future<void> saveRecipe(
  BuildContext context, {
  required String mealName,
  required String? imagePath,
  required String? idOfRecipeToModify,
  required IntakeTypeEntity type,
  required DateTime day,
  bool addToDiary = false,
}) async {
  final bloc = locator<CreateMealBloc>();
  final portions = bloc.portions < 1 ? 1 : bloc.portions;
  final macros =
      bloc.computeMacros().map((key, value) => MapEntry(key, value / portions));

  final nutriment = MealNutrimentsEntity(
    energyKcalPerQuantity: macros['totalKcal']!,
    carbohydratesPerQuantity: macros['totalCarbs']!,
    fatPerQuantity: macros['totalFats']!,
    proteinsPerQuantity: macros['totalProteins']!,
    sugarsPerQuantity: null,
    saturatedFatPerQuantity: null,
    fiberPerQuantity: null,
    mealOrRecipe: MealOrRecipeEntity.recipe,
  );

  final meal = MealEntity(
    code: idOfRecipeToModify ?? IdGenerator.getUniqueID(),
    name: mealName,
    brands: "",
    url: imagePath,
    thumbnailImageUrl: imagePath,
    mainImageUrl: imagePath,
    mealQuantity: '1',
    mealUnit: 'serving',
    servingQuantity: 1,
    servingUnit: 'serving',
    servingSize: S.of(context).servingLabel,
    nutriments: nutriment,
    source: MealSourceEntity.custom,
  );

  // Add the recipe to the DB to keep tracking of the mealEntity composing the recipe
  final recipe = RecipeEntity(
    meal: meal,
    ingredients: bloc.getListOfIntakeForRecipeEntity(),
    portions: portions,
  );
  await locator<AddRecipeUsecase>().addRecipe(recipe);
  if (addToDiary) {
    if (!context.mounted) return;
    await locator<MealDetailBloc>().addIntake(
      context,
      'serving',
      '1',
      type,
      meal,
      day,
    );
  }

  // Clean the list of intake
  locator<CreateMealBloc>().clearIntakeList();

  refreshJournalViews();
}
