import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_actions.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_weight/presentation/add_weight_screen.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_summary_card.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_table_calendar.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with WidgetsBindingObserver {
  final log = Logger('DiaryPage');

  late DiaryBloc _diaryBloc;
  late CalendarDayBloc _calendarDayBloc;
  late HomeBloc _homeBloc;
  late MealDetailBloc _mealDetailBloc;
  DiaryLoadedState? _lastDiaryState;

  static const _calendarDurationDays = Duration(days: 365);
  final _currentDate = DateTime.now();
  var _selectedDate = DateTime.now();
  var _focusedDate = DateTime.now();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _diaryBloc = locator<DiaryBloc>();
    _calendarDayBloc = locator<CalendarDayBloc>();
    _homeBloc = locator<HomeBloc>();
    _mealDetailBloc = locator<MealDetailBloc>();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      bloc: _diaryBloc,
      builder: (context, state) {
        if (state is DiaryInitial) {
          _diaryBloc.add(const LoadDiaryYearEvent());
        } else if (state is DiaryLoadingState) {
          if (_lastDiaryState != null) {
            return _getLoadedContent(context, _lastDiaryState!.trackedDayMap);
          }
          return _getLoadingContent();
        } else if (state is DiaryLoadedState) {
          _lastDiaryState = state;
          return _getLoadedContent(context, state.trackedDayMap);
        } else if (state is DiaryErrorState) {
          return ErrorDialog(
              errorText: S.of(context).journalLoadError,
              onRefreshPressed: _refreshSelectedDay);
        }
        return const SizedBox();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log.info('App resumed');
      _refreshPageOnDayChange();
    }
    super.didChangeAppLifecycleState(state);
  }

  Widget _getLoadingContent() =>
      const Center(child: CircularProgressIndicator());

  Widget _getLoadedContent(
    BuildContext context,
    Map<String, TrackedDayEntity> trackedDaysMap,
  ) {
    return RefreshIndicator(
        onRefresh: () async {
          final done = _diaryBloc.stream.firstWhere(
              (state) => state is DiaryLoadedState || state is DiaryErrorState);
          _refreshSelectedDay();
          await done;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
          children: [
            DiaryTableCalendar(
              trackedDaysMap: trackedDaysMap,
              onDateSelected: _onDateSelected,
              calendarDurationDays: _calendarDurationDays,
              currentDate: _currentDate,
              selectedDate: _selectedDate,
              focusedDate: _focusedDate,
            ),
            const SizedBox(height: 18.0),
            BlocBuilder<CalendarDayBloc, CalendarDayState>(
              bloc: _calendarDayBloc,
              builder: (context, calendarDayState) {
                if (calendarDayState is CalendarDayError) {
                  return ErrorDialog(
                      errorText: S.of(context).journalLoadError,
                      onRefreshPressed: _refreshSelectedDay);
                }
                if (calendarDayState is CalendarDayInitial) {
                  _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
                }

                if (calendarDayState is! CalendarDayLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                return BlocBuilder<HomeBloc, HomeState>(
                  bloc: _homeBloc,
                  builder: (context, homeState) {
                    if (homeState is HomeInitial) {
                      _homeBloc.add(const LoadItemsEvent());
                    }

                    final loadedDay = calendarDayState;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DiarySummaryCard(
                          intakes: [
                            ...loadedDay.breakfastIntakeList,
                            ...loadedDay.lunchIntakeList,
                            ...loadedDay.dinnerIntakeList,
                            ...loadedDay.snackIntakeList,
                          ],
                          // Same load as the meal lists below, so the bar and the
                          // meals refresh together after adding a food.
                          trackedDay: loadedDay.trackedDayEntity,
                          selectedDayWeight: loadedDay.userWeightEntity,
                          weeklyWeightDelta: loadedDay.weeklyWeightDelta,
                          homeState:
                              homeState is HomeLoadedState ? homeState : null,
                          onEditWeight: _openSelectedDayWeightScreen,
                        ),
                        ...[
                          const SizedBox(height: 14),
                          ExpansionTile(
                            key: ValueKey(
                                'diary-meals-${DateUtils.dateOnly(_selectedDate)}'),
                            initiallyExpanded: true,
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            childrenPadding: const EdgeInsets.only(top: 8),
                            shape: const Border(),
                            collapsedShape: const Border(),
                            leading: Icon(Icons.restaurant_menu_rounded,
                                color: Theme.of(context).colorScheme.primary),
                            title: Text(S.of(context).mealsOfDayLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            children: [
                              IntakeVerticalList(
                                day: _selectedDate,
                                title: S.of(context).breakfastLabel,
                                listIcon:
                                    IntakeTypeEntity.breakfast.getIconData(),
                                addMealType: AddMealType.breakfastType,
                                intakeList: loadedDay.breakfastIntakeList,
                                onDeleteIntakeCallback: onDeleteIntake,
                                onDeleteAllIntakesCallback: onDeleteIntakes,
                                onItemLongPressedCallback:
                                    onIntakeItemLongPressed,
                                onItemTappedCallback: onIntakeItemTapped,
                                onCopyIntakeCallback: onCopyIntake,
                                onCopyMealToDateCallback: onCopyMealToDate,
                                trackedDayEntity: loadedDay.trackedDayEntity,
                                isDropZone: false,
                                isCollapsible: true,
                                initiallyExpanded: true,
                                compact: true,
                                foodPreviewLimit: null,
                                horizontalMargin: 0,
                              ),
                              IntakeVerticalList(
                                day: _selectedDate,
                                title: S.of(context).lunchLabel,
                                listIcon: IntakeTypeEntity.lunch.getIconData(),
                                addMealType: AddMealType.lunchType,
                                intakeList: loadedDay.lunchIntakeList,
                                onDeleteIntakeCallback: onDeleteIntake,
                                onDeleteAllIntakesCallback: onDeleteIntakes,
                                onItemLongPressedCallback:
                                    onIntakeItemLongPressed,
                                onItemTappedCallback: onIntakeItemTapped,
                                onCopyIntakeCallback: onCopyIntake,
                                onCopyMealToDateCallback: onCopyMealToDate,
                                trackedDayEntity: loadedDay.trackedDayEntity,
                                isDropZone: false,
                                isCollapsible: true,
                                initiallyExpanded: true,
                                compact: true,
                                foodPreviewLimit: null,
                                horizontalMargin: 0,
                              ),
                              IntakeVerticalList(
                                day: _selectedDate,
                                title: S.of(context).dinnerLabel,
                                listIcon: IntakeTypeEntity.dinner.getIconData(),
                                addMealType: AddMealType.dinnerType,
                                intakeList: loadedDay.dinnerIntakeList,
                                onDeleteIntakeCallback: onDeleteIntake,
                                onDeleteAllIntakesCallback: onDeleteIntakes,
                                onItemLongPressedCallback:
                                    onIntakeItemLongPressed,
                                onItemTappedCallback: onIntakeItemTapped,
                                onCopyIntakeCallback: onCopyIntake,
                                onCopyMealToDateCallback: onCopyMealToDate,
                                trackedDayEntity: loadedDay.trackedDayEntity,
                                isDropZone: false,
                                isCollapsible: true,
                                initiallyExpanded: true,
                                compact: true,
                                foodPreviewLimit: null,
                                horizontalMargin: 0,
                              ),
                              IntakeVerticalList(
                                day: _selectedDate,
                                title: S.of(context).snackLabel,
                                listIcon: IntakeTypeEntity.snack.getIconData(),
                                addMealType: AddMealType.snackType,
                                intakeList: loadedDay.snackIntakeList,
                                onDeleteIntakeCallback: onDeleteIntake,
                                onDeleteAllIntakesCallback: onDeleteIntakes,
                                onItemLongPressedCallback:
                                    onIntakeItemLongPressed,
                                onItemTappedCallback: onIntakeItemTapped,
                                onCopyIntakeCallback: onCopyIntake,
                                onCopyMealToDateCallback: onCopyMealToDate,
                                trackedDayEntity: loadedDay.trackedDayEntity,
                                isDropZone: false,
                                isCollapsible: true,
                                initiallyExpanded: true,
                                compact: true,
                                foodPreviewLimit: null,
                                horizontalMargin: 0,
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ));
  }

  void _onDateSelected(
    DateTime newDate,
    Map<String, TrackedDayEntity> trackedDaysMap,
  ) {
    setState(() {
      _selectedDate = newDate;
      _focusedDate = newDate;
      _calendarDayBloc.add(LoadCalendarDayEvent(newDate));
    });
  }

  void onIntakeItemTapped(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    final dialogResult = await showDialog<EditDialogResult>(
      context: context,
      builder: (context) => EditDialog(
        intakeEntity: intakeEntity,
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
        await _calendarDayBloc.updateIntakeItem(
          intakeEntity.id,
          {'amount': updatedAmount},
          _selectedDate,
        );
        _refreshSelectedDay();
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemUpdatedSnackbar)),
        );
        break;
      case EditDialogAction.deleteItem:
        if (!context.mounted) {
          return;
        }
        await onDeleteIntake(intakeEntity, null);
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
            intakeToEdit: intakeEntity,
          ),
        );
        break;
    }
  }

  void onIntakeItemLongPressed(
      BuildContext context, IntakeEntity intakeEntity) async {
    await showIntakeActions(context, intakeEntity,
        edit: () => onIntakeItemTapped(context, intakeEntity),
        delete: () => onDeleteIntake(intakeEntity, null),
        refresh: _refreshSelectedDay);
  }

  Future<void> onCopyIntake(
    IntakeEntity intake,
    TrackedDayEntity? trackedDayEntity,
    AddMealType? type,
  ) async {
    final targetMealType = type ?? _addMealTypeFromIntake(intake.type);
    await _mealDetailBloc.addIntake(
      context,
      intake.unit,
      intake.amount.toString(),
      targetMealType.getIntakeType(),
      intake.meal,
      DateTime.now(),
    );
    _refreshSelectedDay();
  }

  Future<void> onCopyMealToDate(
    List<IntakeEntity> intakes,
    DateTime targetDay,
    AddMealType type,
  ) async {
    for (final intake in intakes) {
      await _mealDetailBloc.addIntake(
        context,
        intake.unit,
        intake.amount.toString(),
        type.getIntakeType(),
        intake.meal,
        targetDay,
      );
    }
    _refreshSelectedDay();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).mealCopiedSnackbar)),
    );
  }

  AddMealType _addMealTypeFromIntake(IntakeTypeEntity type) {
    switch (type) {
      case IntakeTypeEntity.breakfast:
        return AddMealType.breakfastType;
      case IntakeTypeEntity.lunch:
        return AddMealType.lunchType;
      case IntakeTypeEntity.dinner:
        return AddMealType.dinnerType;
      case IntakeTypeEntity.snack:
        return AddMealType.snackType;
    }
  }

  Future<void> onDeleteIntake(
      IntakeEntity intake, TrackedDayEntity? trackedDayEntity) async {
    await onDeleteIntakes([intake]);
  }

  Future<void> onDeleteIntakes(List<IntakeEntity> intakes) async {
    final selectedDay = _selectedDate;
    await deleteIntakesWithUndo(
        context,
        intakes,
        (item) => _calendarDayBloc.deleteIntakeItem(context, item, selectedDay),
        _refreshSelectedDay);
  }

  void _refreshSelectedDay() {
    _diaryBloc.add(const LoadDiaryYearEvent());
    _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    _homeBloc.add(const LoadItemsEvent());
  }

  Future<void> _openSelectedDayWeightScreen() async {
    await Navigator.of(context).pushNamed(
      NavigationOptions.addWeightRoute,
      arguments: AddWeightScreenArguments(
        day: _selectedDate,
        isReadOnly: false,
      ),
    );
    if (!mounted) {
      return;
    }
    _refreshSelectedDay();
  }

  void _refreshPageOnDayChange() {
    if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      _diaryBloc.add(const LoadDiaryYearEvent());
      _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
    }
  }
}
