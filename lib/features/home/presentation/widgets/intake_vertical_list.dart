import 'dart:async';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_for_recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_all_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/vertical_list_popup_menu_selections.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/create_meal/create_meal_screen.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class IntakeVerticalList extends StatefulWidget {
  final DateTime day;
  final String title;
  final AddMealType addMealType;
  final List<IntakeEntity> intakeList;
  final FutureOr<void> Function(
          IntakeEntity intake, TrackedDayEntity? trackedDayEntity)
      onDeleteIntakeCallback;
  final Future<void> Function(List<IntakeEntity>) onDeleteAllIntakesCallback;
  final Future<void> Function()? onCopyFromYesterday;
  final Function(BuildContext, IntakeEntity)? onItemLongPressedCallback;
  final Function(bool)? onItemDragCallback;
  final Function(BuildContext, IntakeEntity)? onItemTappedCallback;
  final Future<void> Function(
    List<IntakeEntity> intakes,
    DateTime targetDay,
    AddMealType type,
  )? onCopyMealToDateCallback;
  final TrackedDayEntity? trackedDayEntity;
  final bool isDropZone;
  final bool isCollapsible;
  final int? foodPreviewLimit;
  final bool initiallyExpanded;
  final double horizontalMargin;

  const IntakeVerticalList({
    super.key,
    required this.day,
    required this.title,
    required this.addMealType,
    required this.intakeList,
    required this.onDeleteIntakeCallback,
    required this.onDeleteAllIntakesCallback,
    this.onCopyFromYesterday,
    this.onItemLongPressedCallback,
    this.onItemDragCallback,
    this.onItemTappedCallback,
    this.onCopyMealToDateCallback,
    this.trackedDayEntity,
    this.isDropZone = true,
    this.isCollapsible = false,
    this.foodPreviewLimit = 2,
    this.initiallyExpanded = true,
    this.horizontalMargin = 20,
  });

  @override
  State<IntakeVerticalList> createState() => _IntakeVerticalListState();
}

class _IntakeVerticalListState extends State<IntakeVerticalList> {
  late MealDetailBloc _mealDetailBloc;
  late HomeBloc _homeBloc;
  late bool _isExpanded;
  bool _showAllFoods = false;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();
    _homeBloc = locator<HomeBloc>();
    _isExpanded = widget.initiallyExpanded;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant IntakeVerticalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.day, widget.day) ||
        oldWidget.addMealType != widget.addMealType) {
      _isExpanded = widget.initiallyExpanded;
      _showAllFoods = false;
    }
    if (widget.foodPreviewLimit == null ||
        widget.intakeList.length <= widget.foodPreviewLimit!) {
      _showAllFoods = false;
    }
  }

  double get totalKcal => widget.intakeList.fold(
        0,
        (previousValue, element) => previousValue + element.totalKcal,
      );

  double get totalCarbs => widget.intakeList.fold(
        0,
        (previousValue, element) => previousValue + element.totalCarbsGram,
      );

  double get totalFats => widget.intakeList.fold(
        0,
        (previousValue, element) => previousValue + element.totalFatsGram,
      );

  double get totalProteins => widget.intakeList.fold(
        0,
        (previousValue, element) => previousValue + element.totalProteinsGram,
      );

  bool get _canCopyMeal =>
      widget.isCollapsible &&
      widget.onCopyMealToDateCallback != null &&
      widget.intakeList.isNotEmpty;

  Color _mealAccentColor() {
    switch (widget.addMealType) {
      case AddMealType.breakfastType:
        return breakfastColor;
      case AddMealType.lunchType:
        return lunchColor;
      case AddMealType.dinnerType:
        return dinnerColor;
      case AddMealType.snackType:
        return snackColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final separatorColor = colors.onSurface.withValues(
      alpha: colors.brightness == Brightness.dark ? 0.10 : 0.06,
    );
    return Container(
      margin: EdgeInsets.fromLTRB(
        widget.horizontalMargin,
        12,
        widget.horizontalMargin,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isCollapsible)
            _buildJournalMealHeader(context)
          else ...[
            Row(
              children: [
                _MealTypeIcon(
                    mealType: widget.addMealType,
                    color: _mealAccentColor(),
                    size: 23),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                          '${formatNumber(totalKcal)} ${S.of(context).kcalLabel}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '${S.of(context).addLabel} · ${widget.title}',
                  onPressed: () => _onPlaceholderCardTapped(context),
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: colors.primary,
                  ),
                ),
                if (widget.intakeList.isNotEmpty) _buildPopupMenu(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _MealMacroTotals(
                  totalCarbs: totalCarbs,
                  totalFats: totalFats,
                  totalProteins: totalProteins),
            ),
          ],
          if (!widget.isCollapsible || _isExpanded) ...[
            if (widget.intakeList.isNotEmpty)
              Divider(height: 1, thickness: 0.5, color: separatorColor),
            DragTarget<IntakeEntity>(
              onWillAcceptWithDetails: (_) => widget.isDropZone,
              onAcceptWithDetails: (details) => _onItemDropped(details.data),
              builder: (context, candidates, rejected) => Container(
                decoration: BoxDecoration(
                  color: candidates.isEmpty
                      ? null
                      : colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.intakeList.isEmpty
                    ? Column(children: [
                        TextButton.icon(
                          onPressed: () => _onPlaceholderCardTapped(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(S.of(context).addLabel),
                        ),
                        if (widget.onCopyFromYesterday != null)
                          TextButton.icon(
                              onPressed: widget.onCopyFromYesterday,
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label:
                                  Text(S.of(context).copyFromYesterdayLabel)),
                      ])
                    : Column(
                        children: [
                          for (final intake in (_showAllFoods ||
                                  widget.foodPreviewLimit == null
                              ? widget.intakeList
                              : widget.intakeList
                                  .take(widget.foodPreviewLimit!))) ...[
                            if (intake != widget.intakeList.first)
                              Divider(
                                height: 8,
                                thickness: 0.5,
                                indent: 68,
                                endIndent: 4,
                                color: separatorColor,
                              ),
                            LongPressDraggable<IntakeEntity>(
                              maxSimultaneousDrags:
                                  widget.onItemLongPressedCallback == null
                                      ? 1
                                      : 0,
                              key: ValueKey(intake.id),
                              data: intake,
                              onDragStarted: () =>
                                  widget.onItemDragCallback?.call(true),
                              onDragEnd: (_) =>
                                  widget.onItemDragCallback?.call(false),
                              feedback: Material(
                                color: colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 280,
                                  child: IntakeCard(
                                    key: ValueKey('drag-${intake.id}'),
                                    intake: intake,
                                    firstListElement: false,
                                    compact: true,
                                  ),
                                ),
                              ),
                              child: IntakeCard(
                                key: ValueKey('home-${intake.id}'),
                                intake: intake,
                                firstListElement: false,
                                onItemTapped: widget.onItemTappedCallback,
                                onItemLongPressed:
                                    widget.onItemLongPressedCallback,
                                compact: true,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            if (widget.foodPreviewLimit != null &&
                widget.intakeList.length > widget.foodPreviewLimit!)
              TextButton.icon(
                key: const ValueKey('toggle-meal-foods'),
                onPressed: () => setState(() => _showAllFoods = !_showAllFoods),
                icon:
                    Icon(_showAllFoods ? Icons.expand_less : Icons.expand_more),
                label: Text(_showAllFoods
                    ? S.of(context).showFewerFoods
                    : S.of(context).showMoreFoods(
                        widget.intakeList.length - widget.foodPreviewLimit!)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildJournalMealHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _mealAccentColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _MealTypeIcon(
                mealType: widget.addMealType, color: accent, size: 23),
            const SizedBox(width: 10),
            Expanded(
                child: Text(widget.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800))),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 48),
              padding: EdgeInsets.zero,
              tooltip: '${S.of(context).addLabel} · ${widget.title}',
              onPressed: () => _onPlaceholderCardTapped(context),
              icon:
                  Icon(Icons.add_circle_outline_rounded, color: colors.primary),
            ),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 48),
              padding: EdgeInsets.zero,
              tooltip: S.of(context).copyMealLabel,
              onPressed: _canCopyMeal ? _showCopyMealDialog : null,
              icon: const Icon(Icons.content_copy_rounded, size: 20),
            ),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 48),
              padding: EdgeInsets.zero,
              tooltip: S.of(context).deleteAllLabel,
              onPressed: widget.intakeList.isEmpty ? null : _deleteAllIntakes,
              icon: Icon(Icons.delete_outline_rounded,
                  color: widget.intakeList.isEmpty ? null : colors.error),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _MealEnergyBadge(totalKcal: totalKcal, accentColor: accent),
        ),
        Row(
          children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _MealMacroTotals(
                  totalCarbs: totalCarbs,
                  totalFats: totalFats,
                  totalProteins: totalProteins),
            )),
            IconButton(
              tooltip: widget.title,
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _deleteAllIntakes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteAllDialog(),
    );
    if (confirmed != true || !mounted) return;
    await widget.onDeleteAllIntakesCallback(List.of(widget.intakeList));
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<VerticalListPopupMenuSelections>(
      padding: EdgeInsets.zero,
      iconSize: 20,
      onSelected: (VerticalListPopupMenuSelections selection) async {
        switch (selection) {
          case VerticalListPopupMenuSelections.onDelete:
            await _deleteAllIntakes();
            break;
          case VerticalListPopupMenuSelections.onCreateRecipe:
            locator<CreateMealBloc>()
                .add(SetIntakeListFromRecipeEvent(widget.intakeList
                    .map((intake) => IntakeForRecipeEntity(
                          code: intake.id,
                          // Recipe macros are per 100 base units, so
                          // servings are converted to grams first.
                          unit: 'g',
                          amount: intake.effectiveAmountInBaseUnits,
                          meal: intake.meal,
                        ))
                    .toList()));
            final sourceIntakes = List<IntakeEntity>.of(widget.intakeList);
            final onDelete = widget.onDeleteIntakeCallback;
            final trackedDay = widget.trackedDayEntity;
            Navigator.of(context).pushNamed(
              NavigationOptions.createMealRoute,
              arguments: CreateRecipeFromMealArguments(
                widget.addMealType.getIntakeType(),
                widget.day,
                () {
                  for (final intake in sourceIntakes) {
                    onDelete(intake, trackedDay);
                  }
                },
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<VerticalListPopupMenuSelections>>[
        PopupMenuItem<VerticalListPopupMenuSelections>(
          value: VerticalListPopupMenuSelections.onCreateRecipe,
          child: Text(S.of(context).createRecipeLabel),
        ),
        PopupMenuItem<VerticalListPopupMenuSelections>(
          value: VerticalListPopupMenuSelections.onDelete,
          child: Text(S.of(context).deleteAllLabel),
        ),
      ],
    );
  }

  void _onPlaceholderCardTapped(BuildContext context) {
    Navigator.pushNamed(
      context,
      NavigationOptions.addMealRoute,
      arguments: AddMealScreenArguments(
        widget.addMealType,
        widget.day,
        MealOrRecipeEntity.meal,
      ),
    );
  }

  Future<void> _showCopyMealDialog() async {
    final copyCallback = widget.onCopyMealToDateCallback;
    if (copyCallback == null) {
      return;
    }

    final result = await showDialog<_CopyMealToDateResult>(
      context: context,
      builder: (context) => _CopyMealToDateDialog(
        initialMealType: widget.addMealType,
        initialDate: DateTime.now(),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    await copyCallback(widget.intakeList, result.targetDate, result.mealType);
  }

  Future<void> _onItemDropped(IntakeEntity entity) async {
    if (!widget.isDropZone) {
      return;
    }
    await _mealDetailBloc.addIntake(
      context,
      entity.unit,
      entity.amount.toString(),
      widget.addMealType.getIntakeType(),
      entity.meal,
      widget.day,
    );
    await _homeBloc.deleteIntakeItem(entity);

    locator<HomeBloc>().add(const LoadItemsEvent());

    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }
}

class _CopyMealToDateResult {
  final DateTime targetDate;
  final AddMealType mealType;

  const _CopyMealToDateResult({
    required this.targetDate,
    required this.mealType,
  });
}

class _CopyMealToDateDialog extends StatefulWidget {
  final DateTime initialDate;
  final AddMealType initialMealType;

  const _CopyMealToDateDialog({
    required this.initialDate,
    required this.initialMealType,
  });

  @override
  State<_CopyMealToDateDialog> createState() => _CopyMealToDateDialogState();
}

class _CopyMealToDateDialogState extends State<_CopyMealToDateDialog> {
  late DateTime _targetDate;
  late AddMealType _mealType;

  @override
  void initState() {
    super.initState();
    _targetDate = widget.initialDate;
    _mealType = widget.initialMealType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate =
        MaterialLocalizations.of(context).formatFullDate(_targetDate);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colorScheme.primary.withValues(
                  alpha:
                      colorScheme.brightness == Brightness.dark ? 0.24 : 0.12,
                ),
                colorScheme.surfaceContainerHighest,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.content_copy_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).copyMealDialogTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CopyDialogField(
            label: S.of(context).copyMealTargetDateLabel,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _selectDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formattedDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CopyDialogField(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AddMealType>(
                value: _mealType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                dropdownColor: colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(18),
                onChanged: (AddMealType? addMealType) {
                  if (addMealType == null) {
                    return;
                  }
                  setState(() {
                    _mealType = addMealType;
                  });
                },
                items: AddMealType.values.map((addMealType) {
                  return DropdownMenuItem(
                    value: addMealType,
                    child: Text(addMealType.getTypeName(context)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(
              _CopyMealToDateResult(
                targetDate: _targetDate,
                mealType: _mealType,
              ),
            );
          },
          icon: const Icon(Icons.content_copy_rounded, size: 18),
          label: Text(S.of(context).copyMealLabel),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: S.of(context).copyMealSelectDateLabel,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _targetDate = selectedDate;
    });
  }
}

class _CopyDialogField extends StatelessWidget {
  final String? label;
  final Widget child;

  const _CopyDialogField({this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = Color.alphaBlend(
      colorScheme.primary.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.12 : 0.06,
      ),
      colorScheme.surfaceContainerHighest,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _MealMacroTotals extends StatelessWidget {
  final double totalCarbs;
  final double totalFats;
  final double totalProteins;

  const _MealMacroTotals(
      {required this.totalCarbs,
      required this.totalFats,
      required this.totalProteins});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _MealTotalChip(
                    value:
                        '${formatNumber(totalCarbs)} ${S.of(context).gramUnit}',
                    visual: MacroVisuals.carbs))),
        const SizedBox(width: 6),
        Flexible(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _MealTotalChip(
                    value:
                        '${formatNumber(totalFats)} ${S.of(context).gramUnit}',
                    visual: MacroVisuals.fats))),
        const SizedBox(width: 6),
        Flexible(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _MealTotalChip(
                    value:
                        '${formatNumber(totalProteins)} ${S.of(context).gramUnit}',
                    visual: MacroVisuals.proteins))),
      ],
    );
  }
}

class _MealEnergyBadge extends StatelessWidget {
  final double totalKcal;
  final Color accentColor;

  const _MealEnergyBadge({required this.totalKcal, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return _MealTotalChip(
      value: '${formatNumber(totalKcal)} ${S.of(context).kcalLabel}',
      icon: Icons.local_fire_department_rounded,
      color: accentColor,
      emphasized: true,
    );
  }
}

class _MealTotalChip extends StatelessWidget {
  final String value;
  final MacroVisual? visual;
  final IconData? icon;
  final Color? color;
  final bool emphasized;

  const _MealTotalChip({
    required this.value,
    this.visual,
    this.icon,
    this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? visual?.color ?? colorScheme.primary;
    final background = Color.alphaBlend(
      effectiveColor.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.18 : 0.10,
      ),
      colorScheme.surfaceContainerLowest,
    );

    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
      style: theme.textTheme.labelMedium?.copyWith(
        color: emphasized ? colorScheme.onSurface : effectiveColor,
        fontWeight: FontWeight.w800,
        fontSize: 11.5,
        height: 1,
      ),
    );

    final chipContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (visual != null) ...[
          MacroIcon(visual: visual!, size: 14),
          const SizedBox(width: 4),
        ] else if (icon != null) ...[
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 4),
        ],
        valueText,
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: chipContent,
    );
  }
}

class _MealTypeIcon extends StatelessWidget {
  final AddMealType mealType;
  final Color color;
  final double size;

  const _MealTypeIcon({
    required this.mealType,
    required this.color,
    required this.size,
  });

  IconData get _icon {
    switch (mealType) {
      case AddMealType.breakfastType:
        return Icons.free_breakfast_rounded;
      case AddMealType.lunchType:
        return Icons.lunch_dining_rounded;
      case AddMealType.dinnerType:
        return Icons.dinner_dining_rounded;
      case AddMealType.snackType:
        return Icons.cookie_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, color: color, size: size);
  }
}
