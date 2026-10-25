import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/usecase/delete_recipe_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/core/domain/usecase/add_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';

class CalendarMealTypeSelector extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final String mealName;
  final String? idOfRecipeToModify;
  final String? imagePath;

  const CalendarMealTypeSelector({
    super.key,
    required this.onDateSelected,
    required this.mealName,
    required this.idOfRecipeToModify,
    required this.imagePath,
  });

  @override
  State<CalendarMealTypeSelector> createState() =>
      _CalendarMealTypeSelectorState();
}

class _CalendarMealTypeSelectorState extends State<CalendarMealTypeSelector> {
  late DateTime _selectedDate;
  int _currentMealIndex = 0;

  final List<IntakeTypeEntity> _mealTypes = IntakeTypeEntity.values;

  late final TextEditingController mealPortionCountController;
  late final TextEditingController portionsEatenController;

  bool isSaveEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    mealPortionCountController = TextEditingController();
    portionsEatenController = TextEditingController();

    mealPortionCountController.addListener(_validateInputs);
    portionsEatenController.addListener(_onPortionsEatenChanged);
  }

  @override
  void dispose() {
    mealPortionCountController.dispose();
    portionsEatenController.dispose();
    super.dispose();
  }

  void _validatePortions() {
    final total = int.tryParse(mealPortionCountController.text) ?? 0;
    final eaten = int.tryParse(portionsEatenController.text) ?? 0;

    if (eaten > total && total > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        portionsEatenController.text = total.toString();
        portionsEatenController.selection = TextSelection.fromPosition(
          TextPosition(offset: portionsEatenController.text.length),
        );
      });
    }
  }

  void _onPortionsEatenChanged() {
    _validatePortions();
    _validateInputs();
  }

  bool _areInputsValid() {
    final mealPortion = int.tryParse(mealPortionCountController.text) ?? 0;
    final eaten = int.tryParse(portionsEatenController.text) ?? 0;
    return mealPortion > 0 && eaten > 0;
  }

  void _validateInputs() {
    final isValid = _areInputsValid();
    if (isSaveEnabled != isValid) {
      setState(() {
        isSaveEnabled = isValid;
      });
    }
  }

  void _handleDateSelected(DateTime day, Map<String, TrackedDayEntity> _) {
    setState(() {
      _selectedDate = day;
    });
    widget.onDateSelected(day);
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

  void _onSavePressed() {
    final mealPortionCount = mealPortionCountController.text;
    final portionsEaten = portionsEatenController.text;
    final int mealPortionCountInt = int.tryParse(mealPortionCount) ?? 1;

    final macros = locator<CreateMealBloc>().computeMacros();

    final nutriment = MealNutrimentsEntity(
      energyKcalPerQuantity: macros['totalKcal']! / mealPortionCountInt,
      carbohydratesPerQuantity: macros['totalCarbs']! / mealPortionCountInt,
      fatPerQuantity: macros['totalFats']! / mealPortionCountInt,
      proteinsPerQuantity: macros['totalProteins']! / mealPortionCountInt,
      sugarsPerQuantity: null,
      saturatedFatPerQuantity: null,
      fiberPerQuantity: null,
      mealOrRecipe: MealOrRecipeEntity.recipe,
    );

    final meal = MealEntity(
      code: IdGenerator.getUniqueID(),
      name: widget.mealName,
      brands: "",
      url: widget.imagePath,
      thumbnailImageUrl: widget.imagePath,
      mainImageUrl: widget.imagePath,
      mealQuantity: mealPortionCount,
      mealUnit: S.of(context).servingLabel,
      servingQuantity: 1,
      servingUnit: S.of(context).servingLabel,
      servingSize: S.of(context).servingLabel,
      nutriments: nutriment,
      source: MealSourceEntity.custom,
    );

    // In case we want to modify recipe we need to delete the previous version before adding the new one
    if (widget.idOfRecipeToModify != null) {
      locator<DeleteRecipeUsecase>().deleteRecipe(widget.idOfRecipeToModify!);
    }

    locator<MealDetailBloc>().addIntake(
      context,
      'serving',
      portionsEaten,
      _mealTypes[_currentMealIndex],
      meal,
      _selectedDate,
    );

    // Add the recipe to the DB to keep tracking of the mealEntity composing the recipe
    final recipe = RecipeEntity(
      meal: meal,
      ingredients: locator<CreateMealBloc>().getListOfIntakeForRecipeEntity(),
    );
    locator<AddRecipeUsecase>().addRecipe(recipe);

    // Clean the list of intake
    locator<CreateMealBloc>().clearIntakeList();

    locator<HomeBloc>().add(const LoadItemsEvent());
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
    locator<RecipeSearchBloc>().add(
      const LoadRecipeSearchEvent(searchString: ""),
    );

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(NavigationOptions.mainRoute, (route) => false);
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

              /// Meal type selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
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
                    onPressed: _goToNextMeal,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// Portion inputs
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: mealPortionCountController,
                      decoration: InputDecoration(
                        labelText: S.of(context).mealPortionLabel,
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: portionsEatenController,
                      decoration: InputDecoration(
                        labelText: S.of(context).portionEatLabel,
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),

              /// Calendar
              DiaryTableCalendar(
                onDateSelected: _handleDateSelected,
                calendarDurationDays: const Duration(days: 30),
                focusedDate: _selectedDate,
                currentDate: DateTime.now(),
                selectedDate: _selectedDate,
                trackedDaysMap: const {},
              ),
              const SizedBox(height: 16),

              /// Save button
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: isSaveEnabled ? _onSavePressed : null,
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
