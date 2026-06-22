import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
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

  static const _calendarDurationDays = Duration(days: 356);
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
          return _getLoadingContent();
        } else if (state is DiaryLoadedState) {
          return _getLoadedContent(context, state.trackedDayMap);
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
    final selectedTrackedDay = trackedDaysMap[_selectedDate.toParsedDay()];

    return ListView(
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
        const SizedBox(height: 14.0),
        BlocBuilder<CalendarDayBloc, CalendarDayState>(
          bloc: _calendarDayBloc,
          builder: (context, calendarDayState) {
            if (calendarDayState is CalendarDayInitial) {
              _calendarDayBloc.add(LoadCalendarDayEvent(_selectedDate));
            }

            return BlocBuilder<HomeBloc, HomeState>(
              bloc: _homeBloc,
              builder: (context, homeState) {
                if (homeState is HomeInitial) {
                  _homeBloc.add(const LoadItemsEvent());
                }

                final loadedDay = calendarDayState is CalendarDayLoaded
                    ? calendarDayState
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DiarySummaryCard(
                      trackedDay: selectedTrackedDay,
                      selectedDayWeight: loadedDay?.userWeightEntity,
                      homeState:
                          homeState is HomeLoadedState ? homeState : null,
                      onEditWeight: _openSelectedDayWeightScreen,
                    ),
                    if (loadedDay != null) ...[
                      const SizedBox(height: 14),
                      IntakeVerticalList(
                        day: _selectedDate,
                        title: S.of(context).breakfastLabel,
                        listIcon: IntakeTypeEntity.breakfast.getIconData(),
                        addMealType: AddMealType.breakfastType,
                        intakeList: loadedDay.breakfastIntakeList,
                        onDeleteIntakeCallback: onDeleteIntake,
                        onItemLongPressedCallback: onIntakeItemLongPressed,
                        onItemTappedCallback: onIntakeItemTapped,
                        onCopyIntakeCallback: onCopyIntake,
                        onCopyMealToDateCallback: onCopyMealToDate,
                        usesImperialUnits: homeState is HomeLoadedState
                            ? homeState.usesImperialUnits
                            : false,
                        trackedDayEntity: loadedDay.trackedDayEntity,
                        isDropZone: false,
                        isCollapsible: true,
                        initiallyExpanded: false,
                        horizontalMargin: 0,
                      ),
                      IntakeVerticalList(
                        day: _selectedDate,
                        title: S.of(context).lunchLabel,
                        listIcon: IntakeTypeEntity.lunch.getIconData(),
                        addMealType: AddMealType.lunchType,
                        intakeList: loadedDay.lunchIntakeList,
                        onDeleteIntakeCallback: onDeleteIntake,
                        onItemLongPressedCallback: onIntakeItemLongPressed,
                        onItemTappedCallback: onIntakeItemTapped,
                        onCopyIntakeCallback: onCopyIntake,
                        onCopyMealToDateCallback: onCopyMealToDate,
                        usesImperialUnits: homeState is HomeLoadedState
                            ? homeState.usesImperialUnits
                            : false,
                        trackedDayEntity: loadedDay.trackedDayEntity,
                        isDropZone: false,
                        isCollapsible: true,
                        initiallyExpanded: false,
                        horizontalMargin: 0,
                      ),
                      IntakeVerticalList(
                        day: _selectedDate,
                        title: S.of(context).dinnerLabel,
                        listIcon: IntakeTypeEntity.dinner.getIconData(),
                        addMealType: AddMealType.dinnerType,
                        intakeList: loadedDay.dinnerIntakeList,
                        onDeleteIntakeCallback: onDeleteIntake,
                        onItemLongPressedCallback: onIntakeItemLongPressed,
                        onItemTappedCallback: onIntakeItemTapped,
                        onCopyIntakeCallback: onCopyIntake,
                        onCopyMealToDateCallback: onCopyMealToDate,
                        usesImperialUnits: homeState is HomeLoadedState
                            ? homeState.usesImperialUnits
                            : false,
                        trackedDayEntity: loadedDay.trackedDayEntity,
                        isDropZone: false,
                        isCollapsible: true,
                        initiallyExpanded: false,
                        horizontalMargin: 0,
                      ),
                      IntakeVerticalList(
                        day: _selectedDate,
                        title: S.of(context).snackLabel,
                        listIcon: IntakeTypeEntity.snack.getIconData(),
                        addMealType: AddMealType.snackType,
                        intakeList: loadedDay.snackIntakeList,
                        onDeleteIntakeCallback: onDeleteIntake,
                        onItemLongPressedCallback: onIntakeItemLongPressed,
                        onItemTappedCallback: onIntakeItemTapped,
                        onCopyIntakeCallback: onCopyIntake,
                        onCopyMealToDateCallback: onCopyMealToDate,
                        usesImperialUnits: homeState is HomeLoadedState
                            ? homeState.usesImperialUnits
                            : false,
                        trackedDayEntity: loadedDay.trackedDayEntity,
                        isDropZone: false,
                        isCollapsible: true,
                        initiallyExpanded: false,
                        horizontalMargin: 0,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ],
    );
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
        await _calendarDayBloc.deleteIntakeItem(
          context,
          intakeEntity,
          _selectedDate,
        );
        _refreshSelectedDay();
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)),
        );
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

  void onIntakeItemLongPressed(
      BuildContext context, IntakeEntity intakeEntity) async {
    await _calendarDayBloc.deleteIntakeItem(
      context,
      intakeEntity,
      _selectedDate,
    );
    _refreshSelectedDay();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).itemDeletedSnackbar)),
    );
  }

  void onCopyIntake(
    IntakeEntity intake,
    TrackedDayEntity? trackedDayEntity,
    AddMealType? type,
  ) {
    final targetMealType = type ?? _addMealTypeFromIntake(intake.type);
    _mealDetailBloc.addIntake(
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

  void onDeleteIntake(IntakeEntity intake, TrackedDayEntity? trackedDayEntity) {
    _calendarDayBloc.deleteIntakeItem(context, intake, _selectedDate);
    _refreshSelectedDay();
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
