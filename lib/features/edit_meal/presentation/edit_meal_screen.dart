import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:flutter/material.dart';
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
  String? _pickedImagePath;
  bool _pickingPhoto = false;
  bool _saving = false;

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

  Future<void> _pickPhoto() async {
    if (_pickingPhoto || _saving) return;
    setState(() => _pickingPhoto = true);
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);
      if (mounted && image != null) {
        setState(() => _pickedImagePath = image.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).customFoodPhotoError)));
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Widget _photoField() {
    final colors = Theme.of(context).colorScheme;
    final imagePath = _pickedImagePath ?? _args!.mealEntity.mainImageUrl;
    final hasPhoto = imagePath?.isNotEmpty == true;
    final placeholder = Icon(Icons.add_photo_alternate_outlined,
        size: 42, color: colors.primary);
    Widget preview = placeholder;
    if (hasPhoto) {
      if (imagePath!.startsWith('http')) {
        preview = CachedNetworkImage(
            imageUrl: imagePath,
            cacheManager: locator<CacheManager>(),
            fit: BoxFit.cover,
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder);
      } else {
        preview = FutureBuilder<String>(
          future: p.isAbsolute(imagePath)
              ? Future.value(imagePath)
              : PathHelper.localImagePath(imagePath),
          builder: (context, snapshot) => snapshot.hasData
              ? Image.file(File(snapshot.data!),
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
              : placeholder,
        );
      }
    }
    return Material(
      color: colors.primary.withValues(alpha: 0.06),
      child: InkWell(
        key: const ValueKey('custom-food-photo'),
        onTap: _pickingPhoto || _saving ? null : _pickPhoto,
        child: SizedBox(
          height: 176,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 42),
                    child: Center(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                                width: 112, height: 112, child: preview))))),
            Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_pickingPhoto)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(Icons.photo_library_outlined,
                        size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(
                          hasPhoto
                              ? S.of(context).customFoodChangePhoto
                              : S.of(context).customFoodAddPhoto,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700))),
                ])),
          ]),
        ),
      ),
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
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        decoration: _decoration(label,
            icon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10)),
                child: icon),
            suffix: unit),
        validator: (text) {
          final value = double.tryParse((text ?? '').replaceAll(',', '.'));
          return value == null || !value.isFinite || value < 0
              ? S.of(context).customFoodNumberError
              : null;
        },
      ),
    );
  }

  Widget _referenceOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    bool compact = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.10)
            : compact
                ? Colors.transparent
                : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          side: BorderSide(
            color: selected
                ? colors.primary.withValues(alpha: 0.40)
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 8, vertical: compact ? 13 : 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 26),
                const SizedBox(height: 8),
              ],
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton.icon(
            key: const ValueKey('save-custom-food'),
            onPressed: _saving || _pickingPhoto ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: Text(s.buttonSaveLabel),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18))),
          ),
        ),
      ),
      appBar: AppBar(
          title: Text(s.customFoodTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800))),
      body: SafeArea(
          child: AbsorbPointer(
              absorbing: _saving,
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                                color:
                                    colors.onSurface.withValues(alpha: 0.06))),
                        child: Column(children: [
                          _photoField(),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextFormField(
                                controller: _name,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _decoration(s.customFoodNameLabel,
                                    icon: Icon(Icons.restaurant_outlined,
                                        color: colors.primary)),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? s.customFoodNameError
                                        : null),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      _section([
                        Row(children: [
                          Expanded(
                            child: _referenceOption(
                              label: s.customFoodPortionMode,
                              icon: Icons.restaurant_outlined,
                              selected: _perPortion,
                              onTap: () => setState(() => _perPortion = true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _referenceOption(
                              label: s.customFoodQuantityMode,
                              icon: Icons.scale_outlined,
                              selected: !_perPortion,
                              onTap: () => setState(() => _perPortion = false),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        if (_perPortion)
                          TextFormField(
                              controller: _portionName,
                              decoration: _decoration(s.customFoodPortionName,
                                  hint: s.customFoodPortionHint))
                        else
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(children: [
                              for (final unit in ['g', 'ml'])
                                Expanded(
                                  child: _referenceOption(
                                    label: '100 $unit',
                                    selected: _unit == unit,
                                    compact: true,
                                    onTap: () => setState(() => _unit = unit),
                                  ),
                                ),
                            ]),
                          ),
                      ]),
                      const SizedBox(height: 18),
                      _section([
                        Text(
                            _perPortion
                                ? s.customFoodPerPortion
                                : s.customFoodPer100(_unit),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(s.customFoodReferenceHelp,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant)),
                        const SizedBox(height: 20),
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
                                child: MacroIcon(
                                    visual: MacroVisuals.carbs, size: 22)),
                            s.gramUnit),
                        _numeric(
                            _fat,
                            s.fatLabel,
                            const Padding(
                                padding: EdgeInsets.all(12),
                                child: MacroIcon(
                                    visual: MacroVisuals.fats, size: 22)),
                            s.gramUnit),
                        _numeric(
                            _protein,
                            s.proteinLabel,
                            const Padding(
                                padding: EdgeInsets.all(12),
                                child: MacroIcon(
                                    visual: MacroVisuals.proteins, size: 22)),
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
                    ],
                  ),
                ),
              ))),
    );
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      String? photoName;
      if (_pickedImagePath != null) {
        photoName =
            'food_photo_${IdGenerator.getUniqueID()}${p.extension(_pickedImagePath!)}';
        final target = await PathHelper.localImagePath(photoName);
        await File(_pickedImagePath!).copy(target);
      }
      if (!mounted) return;
      double value(TextEditingController controller) =>
          double.parse(controller.text.replaceAll(',', '.'));
      final meal = locator<EditMealBloc>().createCustomFood(
          original: _args!.mealEntity,
          photoPath: photoName,
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
        arguments: MealDetailScreenArguments(meal, _args!.intakeTypeEntity,
            _args!.day, _args!.usesImperialUnits),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).customFoodPhotoError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
