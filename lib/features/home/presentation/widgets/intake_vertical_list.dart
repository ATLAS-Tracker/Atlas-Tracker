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
  final TrackedDayEntity? trackedDayEntity;
  final bool isDropZone;

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
    this.trackedDayEntity,
    this.isDropZone = true,
  });

  @override
  State<IntakeVerticalList> createState() => _IntakeVerticalListState();
}

class _IntakeVerticalListState extends State<IntakeVerticalList> {
  late MealDetailBloc _mealDetailBloc;
  late HomeBloc _homeBloc;
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    _mealDetailBloc = locator<MealDetailBloc>();
    _homeBloc = locator<HomeBloc>();
    _horizontalScrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
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
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                        Row(
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
                                    color: accentColor.withValues(alpha: 0.18),
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
                            if (totalKcal > 0) ...[
                              const SizedBox(width: 10),
                              _MealEnergyBadge(
                                totalKcal: totalKcal,
                                accentColor: accentColor,
                              ),
                            ],
                            const SizedBox(width: 24),
                          ],
                        ),
                        if (totalKcal > 0) ...[
                          const SizedBox(height: 9),
                          Padding(
                            padding: const EdgeInsets.only(left: 50, right: 28),
                            child: _MealMacroTotals(
                              totalCarbs: totalCarbs,
                              totalFats: totalFats,
                              totalProteins: totalProteins,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (totalKcal > 0)
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
          const SizedBox(height: 12),
          DragTarget<IntakeEntity>(
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
                        onTap: () => _onPlaceholderCardTapped(context),
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
                            usesImperialUnits: widget.usesImperialUnits,
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
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: IntakeCard(
                        key: ValueKey(intakeEntity.meal.code),
                        intake: intakeEntity,
                        onItemLongPressed: widget.onItemLongPressedCallback,
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
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MealTotalChip(
          value: '${totalCarbs.toInt()} ${S.of(context).gramUnit}',
          visual: MacroVisuals.carbs,
        ),
        _MealTotalChip(
          value: '${totalFats.toInt()} ${S.of(context).gramUnit}',
          visual: MacroVisuals.fats,
        ),
        _MealTotalChip(
          value: '${totalProteins.toInt()} ${S.of(context).gramUnit}',
          visual: MacroVisuals.proteins,
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: emphasized ? 9 : 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (visual != null) ...[
            MacroIcon(visual: visual!, size: 14),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              color: emphasized ? colorScheme.onSurface : effectiveColor,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              height: 1,
            ),
          ),
        ],
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
