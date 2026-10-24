import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditMealScreen extends StatefulWidget {
  const EditMealScreen({super.key});
  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brands = TextEditingController();
  final _portionName = TextEditingController();
  final _kcal = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _protein = TextEditingController();
  EditMealScreenArguments? _args;
  bool _perPortion = true;
  String _unit = 'g';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args != null) return;
    _args =
        ModalRoute.of(context)!.settings.arguments as EditMealScreenArguments;
    final meal = _args!.mealEntity;
    _perPortion = meal.isPortionBased || meal.name == null;
    _unit = meal.isLiquid ? 'ml' : 'g';
    _name.text = meal.name ?? '';
    _brands.text = meal.brands ?? '';
    _portionName.text = meal.isPortionBased ? meal.servingSize ?? '' : '';
    String number(double? value) => value == null
        ? ''
        : (meal.isPortionBased ? value / 100 : value).toString();
    _kcal.text = number(meal.nutriments.energyKcalPerQuantity);
    _carbs.text = number(meal.nutriments.carbohydratesPerQuantity);
    _fat.text = number(meal.nutriments.fatPerQuantity);
    _protein.text = number(meal.nutriments.proteinsPerQuantity);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _brands,
      _portionName,
      _kcal,
      _carbs,
      _fat,
      _protein
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _decoration(String label,
      {String? hint, Widget? icon, String? suffix}) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      errorMaxLines: 2,
      hintText: hint,
      prefixIcon: icon,
      suffixText: suffix,
      filled: true,
      fillColor: colors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: colors.onSurface.withValues(alpha: 0.04))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5)),
    );
  }

  Widget _section(List<Widget> children) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _numeric(TextEditingController controller, String label, Widget icon,
      String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: CustomTextInputFormatter.doubleOnly(),
        decoration: _decoration(label, icon: icon, suffix: unit),
        validator: (text) {
          final value = double.tryParse((text ?? '').replaceAll(',', '.'));
          return value == null || !value.isFinite || value < 0
              ? S.of(context).customFoodNumberError
              : null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(s.customFoodTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800))),
      body: SafeArea(
          child: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section([
                TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoration(s.customFoodNameLabel,
                        icon: Icon(Icons.restaurant_outlined,
                            color: colors.primary)),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? s.customFoodNameError
                        : null),
              ]),
              const SizedBox(height: 16),
              _section([
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: true, label: Text(s.customFoodPortionMode)),
                    ButtonSegment(
                        value: false, label: Text(s.customFoodQuantityMode)),
                  ],
                  selected: {_perPortion},
                  onSelectionChanged: (selection) =>
                      setState(() => _perPortion = selection.first),
                ),
                const SizedBox(height: 16),
                if (_perPortion)
                  TextFormField(
                      controller: _portionName,
                      decoration: _decoration(s.customFoodPortionName,
                          hint: s.customFoodPortionHint))
                else
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'g', label: Text('100 g')),
                      ButtonSegment(value: 'ml', label: Text('100 ml'))
                    ],
                    selected: {_unit},
                    onSelectionChanged: (selection) =>
                        setState(() => _unit = selection.first),
                  ),
              ]),
              const SizedBox(height: 18),
              AtlasBrandPanel(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _perPortion
                              ? s.customFoodPerPortion
                              : s.customFoodPer100(_unit),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(s.customFoodReferenceHelp,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.76))),
                    ]),
              ),
              const SizedBox(height: 20),
              _section([
                _numeric(
                    _kcal,
                    s.energyLabel,
                    Icon(Icons.local_fire_department_outlined,
                        color: breakfastColor),
                    s.kcalLabel),
                _numeric(
                    _carbs,
                    s.carbsLabel,
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child: MacroIcon(visual: MacroVisuals.carbs, size: 22)),
                    s.gramUnit),
                _numeric(
                    _fat,
                    s.fatLabel,
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child: MacroIcon(visual: MacroVisuals.fats, size: 22)),
                    s.gramUnit),
                _numeric(
                    _protein,
                    s.proteinLabel,
                    const Padding(
                        padding: EdgeInsets.all(12),
                        child:
                            MacroIcon(visual: MacroVisuals.proteins, size: 22)),
                    s.gramUnit),
              ]),
              const SizedBox(height: 16),
              _section([
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Icon(Icons.info_outline_rounded,
                      color: colors.primary, size: 21),
                  title: Text(s.customFoodOptionalDetails,
                      style: Theme.of(context).textTheme.bodyMedium),
                  children: [
                    TextFormField(
                        controller: _brands,
                        decoration: _decoration(s.mealBrandsLabel)),
                    const SizedBox(height: 16)
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('save-custom-food'),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(s.buttonSaveLabel),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
            ],
          ),
        ),
      )),
    );
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    double value(TextEditingController controller) =>
        double.parse(controller.text.replaceAll(',', '.'));
    final meal = locator<EditMealBloc>().createCustomFood(
        original: _args!.mealEntity,
        name: _name.text,
        brands: _brands.text,
        perPortion: _perPortion,
        unit: _unit,
        portionName: _portionName.text,
        kcal: value(_kcal),
        carbs: value(_carbs),
        fat: value(_fat),
        protein: value(_protein));
    Navigator.of(context).pushNamedAndRemoveUntil(
      NavigationOptions.mealDetailRoute,
      ModalRoute.withName(NavigationOptions.addMealRoute),
      arguments: MealDetailScreenArguments(
          meal, _args!.intakeTypeEntity, _args!.day, _args!.usesImperialUnits),
    );
  }
}

class EditMealScreenArguments {
  final DateTime day;
  final MealEntity mealEntity;
  final IntakeTypeEntity intakeTypeEntity;
  final bool usesImperialUnits;
  EditMealScreenArguments(
      this.day, this.mealEntity, this.intakeTypeEntity, this.usesImperialUnits);
}
