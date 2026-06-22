import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/copy_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_all_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/presentation/widgets/placeholder_card.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/vertical_list_popup_menu_selections.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class IntakeVerticalList extends StatefulWidget {
  final DateTime day;
  final String title;
  final IconData listIcon;
  final AddMealType addMealType;
  final List<IntakeEntity> intakeList;
  final bool usesImperialUnits;
  final Function(IntakeEntity intake, TrackedDayEntity? trackedDayEntity)
      onDeleteIntakeCallback;
  final Function(BuildContext, IntakeEntity)? onItemLongPressedCallback;
  final Function(bool)? onItemDragCallback;
  final Function(BuildContext, IntakeEntity, bool)? onItemTappedCallback;
  final Function(IntakeEntity intake, TrackedDayEntity? trackedDayEntity,
      AddMealType? type)? onCopyIntakeCallback;
  final Future<void> Function(
    List<IntakeEntity> intakes,
    DateTime targetDay,
    AddMealType type,
  )? onCopyMealToDateCallback;
  final TrackedDayEntity? trackedDayEntity;
  final bool isDropZone;
  final bool isCollapsible;
  final bool initiallyExpanded;
  final double horizontalMargin;

  const IntakeVerticalList({
    super.key,
    required this.day,
    required this.title,
    required this.listIcon,
    required this.addMealType,
    required this.intakeList,
    required this.usesImperialUnits,
    required this.onDeleteIntakeCallback,
    this.onItemLongPressedCallback,
    this.onItemDragCallback,
    this.onItemTappedCallback,
    this.onCopyIntakeCallback,
    this.onCopyMealToDateCallback,
    this.trackedDayEntity,
    this.isDropZone = true,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
    this.horizontalMargin = 20,
  });

  @override
  State<IntakeVerticalList> createState() => _IntakeVerticalListState();
}

class _IntakeVerticalListState extends State<IntakeVerticalList> {
  late MealDetailBloc _mealDetailBloc;
  late HomeBloc _homeBloc;
  late final ScrollController _horizontalScrollController;
  late bool _isExpanded;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();
    _homeBloc = locator<HomeBloc>();
    _horizontalScrollController = ScrollController();
    _isExpanded = widget.initiallyExpanded;
    super.initState();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant IntakeVerticalList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.day, widget.day) ||
        oldWidget.addMealType != widget.addMealType) {
      _isExpanded = widget.initiallyExpanded;
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
    final colorScheme = theme.colorScheme;
    final accentColor = _mealAccentColor();
    final mealSurface = Color.alphaBlend(
      colorScheme.onSurface.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.09 : 0.00,
      ),
      colorScheme.surfaceContainerLowest,
    );
    final accentSurface = Color.alphaBlend(
      accentColor.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.12 : 0.06,
      ),
      mealSurface,
    );
    return Container(
      margin: EdgeInsets.fromLTRB(
        widget.horizontalMargin,
        14,
        widget.horizontalMargin,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 0, 14),
      decoration: BoxDecoration(
        color: mealSurface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentSurface, mealSurface],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.24 : 0.06,
            ),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: widget.isCollapsible
                              ? () => setState(() {
                                    _isExpanded = !_isExpanded;
                                  })
                              : null,
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          accentColor.withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      spreadRadius: -6,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: _MealTypeIcon(
                                  mealType: widget.addMealType,
                                  color: accentColor,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (totalKcal > 0 && !widget.isCollapsible) ...[
                                const SizedBox(width: 10),
                                _MealEnergyBadge(
                                  totalKcal: totalKcal,
                                  accentColor: accentColor,
                                ),
                              ],
                              const SizedBox(width: 10),
                              if (_canCopyMeal) ...[
                                _CopyMealButton(
                                  accentColor: accentColor,
                                  onPressed: _showCopyMealDialog,
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (widget.isCollapsible)
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: colorScheme.onSurface,
                                  size: 24,
                                )
                              else
                                const SizedBox(width: 14),
                            ],
                          ),
                        ),
                        if (totalKcal > 0 &&
                            (!widget.isCollapsible || !_isExpanded)) ...[
                          const SizedBox(height: 9),
                          Padding(
                            padding: const EdgeInsets.only(left: 50, right: 28),
                            child: widget.isCollapsible
                                ? _MealCollapsedEnergy(
                                    totalKcal: totalKcal,
                                    accentColor: accentColor,
                                  )
                                : _MealMacroTotals(
                                    totalCarbs: totalCarbs,
                                    totalFats: totalFats,
                                    totalProteins: totalProteins,
                                  ),
                          ),
                        ],
                      ],
                    ),
                    if (totalKcal > 0 && !widget.isCollapsible)
                      Positioned(
                        top: -8,
                        right: -10,
                        child: _buildPopupMenu(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isExpanded
                ? Padding(
                    key: const ValueKey('expanded-intake-list'),
                    padding: const EdgeInsets.only(top: 12),
                    child: DragTarget<IntakeEntity>(
                      onAcceptWithDetails: (intake) {
                        _onItemDropped(intake.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return SizedBox(
                          height: 182,
                          child: ListView.builder(
                            key: PageStorageKey<String>(
                              'home-intake-${widget.addMealType.name}-${widget.day.year}-${widget.day.month}-${widget.day.day}',
                            ),
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            primary: false,
                            itemCount: widget.intakeList.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              final firstListElement = index == 0;
                              if (index == widget.intakeList.length) {
                                return PlaceholderCard(
                                  day: widget.day,
                                  onTap: () =>
                                      _onPlaceholderCardTapped(context),
                                  firstListElement: firstListElement,
                                );
                              }
                              final intakeEntity = widget.intakeList[index];
                              return LongPressDraggable<IntakeEntity>(
                                onDragStarted: () {
                                  widget.onItemDragCallback?.call(true);
                                },
                                onDragEnd: (details) {
                                  widget.onItemDragCallback?.call(false);
                                },
                                data: intakeEntity,
                                feedback: Material(
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Opacity(
                                    opacity: 0.7,
                                    child: IntakeCard(
                                      key: ValueKey(intakeEntity.meal.code),
                                      intake: intakeEntity,
                                      firstListElement: false,
                                      usesImperialUnits:
                                          widget.usesImperialUnits,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Row(
                                  children: [
                                    SizedBox(width: firstListElement ? 16 : 10),
                                    SizedBox(
                                      width: 162,
                                      height: 176,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Color.alphaBlend(
                                            colorScheme.onSurface.withValues(
                                              alpha: colorScheme.brightness ==
                                                      Brightness.dark
                                                  ? 0.11
                                                  : 0.00,
                                            ),
                                            colorScheme.surfaceContainerLow,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                child: IntakeCard(
                                  key: ValueKey(intakeEntity.meal.code),
                                  intake: intakeEntity,
                                  onItemLongPressed:
                                      widget.onItemLongPressedCallback,
                                  onItemTapped: widget.onItemTappedCallback,
                                  firstListElement: firstListElement,
                                  usesImperialUnits: widget.usesImperialUnits,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed-intake-list')),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu({Widget? child}) {
    return PopupMenuButton<VerticalListPopupMenuSelections>(
      padding: EdgeInsets.zero,
      iconSize: 20,
      child: child,
      onSelected: (VerticalListPopupMenuSelections selection) async {
        switch (selection) {
          case VerticalListPopupMenuSelections.onCopy:
            const copyDialog = CopyDialog();
            final selectedMealType = await showDialog<AddMealType>(
              context: context,
              builder: (context) => copyDialog,
            );
            if (selectedMealType != null) {
              for (IntakeEntity intake in widget.intakeList) {
                widget.onCopyIntakeCallback!(intake, null, selectedMealType);
              }
            }
            break;
          case VerticalListPopupMenuSelections.onDelete:
            final shouldDeleteIntakes = await showDialog<bool>(
              context: context,
              builder: (context) => const DeleteAllDialog(),
            );
            if (shouldDeleteIntakes != null) {
              for (IntakeEntity intake in widget.intakeList) {
                widget.onDeleteIntakeCallback(intake, widget.trackedDayEntity);
              }
              break;
            }
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<VerticalListPopupMenuSelections>>[
        if (widget.onCopyIntakeCallback != null)
          PopupMenuItem<VerticalListPopupMenuSelections>(
            value: VerticalListPopupMenuSelections.onCopy,
            child: Text(S.of(context).dialogCopyLabel),
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

  void _onItemDropped(IntakeEntity entity) {
    if (!widget.isDropZone) {
      return;
    }
    _mealDetailBloc.addIntake(
      context,
      entity.unit,
      entity.amount.toString(),
      widget.addMealType.getIntakeType(),
      entity.meal,
      entity.dateTime,
    );
    _homeBloc.deleteIntakeItem(entity);

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
    final formattedDate = MaterialLocalizations.of(context).formatFullDate(
      _targetDate,
    );

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
      firstDate: DateTime.now().subtract(const Duration(days: 356)),
      lastDate: DateTime.now().add(const Duration(days: 356)),
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

  const _CopyDialogField({
    this.label,
    required this.child,
  });

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

class _CopyMealButton extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onPressed;

  const _CopyMealButton({
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = Color.alphaBlend(
      accentColor.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.20 : 0.12,
      ),
      colorScheme.surfaceContainerLowest,
    );

    return Tooltip(
      message: S.of(context).copyMealLabel,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.file_copy_rounded,
              color: accentColor,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _MealCollapsedEnergy extends StatelessWidget {
  final double totalKcal;
  final Color accentColor;

  const _MealCollapsedEnergy({
    required this.totalKcal,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: 15,
          color: accentColor,
        ),
        const SizedBox(width: 5),
        Text(
          '${totalKcal.toInt()} ${S.of(context).kcalLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _MealMacroTotals extends StatelessWidget {
  final double totalCarbs;
  final double totalFats;
  final double totalProteins;

  const _MealMacroTotals({
    required this.totalCarbs,
    required this.totalFats,
    required this.totalProteins,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _MealTotalChip(
              value: '${totalCarbs.toInt()} ${S.of(context).gramUnit}',
              visual: MacroVisuals.carbs,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _MealTotalChip(
              value: '${totalFats.toInt()} ${S.of(context).gramUnit}',
              visual: MacroVisuals.fats,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _MealTotalChip(
              value: '${totalProteins.toInt()} ${S.of(context).gramUnit}',
              visual: MacroVisuals.proteins,
            ),
          ),
        ),
      ],
    );
  }
}

class _MealEnergyBadge extends StatelessWidget {
  final double totalKcal;
  final Color accentColor;

  const _MealEnergyBadge({
    required this.totalKcal,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return _MealTotalChip(
      value: '${totalKcal.toInt()} ${S.of(context).kcalLabel}',
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

    return SizedBox(
      height: 24,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: chipContent,
        ),
      ),
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
