import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller.dart';
import 'package:opennutritracker/services/step_tracking/step_tracking_controller_factory.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final log = Logger('HomePage');
  late HomeBloc _homeBloc;
  HomeLoadedState? _lastLoadedState;
  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  int _steps = 0;
  StepTrackingController? _stepTrackingController;
  StreamSubscription<int>? _stepSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeBloc = locator<HomeBloc>();
    _initializeStepTracking();
  }

  Future<void> _initializeStepTracking() async {
    final factory = locator<StepTrackingControllerFactory>();
    _stepTrackingController = factory.create();
    final controller = _stepTrackingController;
    if (controller == null) {
      log.info('No step tracking controller available for this platform.');
      return;
    }

    final initialSteps = await controller.initialize();
    if (!mounted) return;
    setState(() {
      _steps = initialSteps;
    });

    _stepSubscription = controller.stepsStream.listen((steps) {
      if (!mounted) return;
      setState(() {
        _steps = steps;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stepSubscription?.cancel());
    unawaited(_stepTrackingController?.dispose());
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: _homeBloc,
      builder: (context, state) {
        if (state is HomeInitial) {
          _homeBloc.add(const LoadItemsEvent());
          return _getLoadingContent();
        } else if (state is HomeLoadingState) {
          final lastLoadedState = _lastLoadedState;
          if (lastLoadedState != null) {
            return _getLoadedContentFromState(context, lastLoadedState);
          }
          return _getLoadingContent();
        } else if (state is HomeLoadedState) {
          _lastLoadedState = state;
          return _getLoadedContentFromState(context, state);
        } else {
          return _getLoadingContent();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      log.info('App resumed');
      _refreshPageOnDayChange();
      final controller = _stepTrackingController;
      if (controller != null) {
        unawaited(controller.handleAppResumed());
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  Widget _getLoadingContent() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _getLoadedContentFromState(
    BuildContext context,
    HomeLoadedState state,
  ) {
    return _getLoadedContent(
      context,
      state.userName,
      state.coachName,
      state.totalKcalDaily,
      state.totalKcalLeft,
      state.totalKcalSupplied,
      state.totalCarbsIntake,
      state.totalFatsIntake,
      state.totalProteinsIntake,
      state.totalCarbsGoal,
      state.totalFatsGoal,
      state.totalProteinsGoal,
      state.breakfastIntakeList,
      state.lunchIntakeList,
      state.dinnerIntakeList,
      state.snackIntakeList,
      state.userActivityList,
      state.userWeightEntity,
      state.weeklyWeightDelta,
      state.targetWeight,
      state.userWeightGoal,
      state.usesImperialUnits,
    );
  }

  Widget _getLoadedContent(
    BuildContext context,
    String userName,
    String? coachName,
    double totalKcalDaily,
    double totalKcalLeft,
    double totalKcalSupplied,
    double totalCarbsIntake,
    double totalFatsIntake,
    double totalProteinsIntake,
    double totalCarbsGoal,
    double totalFatsGoal,
    double totalProteinsGoal,
    List<IntakeEntity> breakfastIntakeList,
    List<IntakeEntity> lunchIntakeList,
    List<IntakeEntity> dinnerIntakeList,
    List<IntakeEntity> snackIntakeList,
    List<UserActivityEntity> userActivities,
    UserWeightEntity? userWeight,
    double? weeklyWeightDelta,
    double targetWeight,
    UserWeightGoalEntity userWeightGoal,
    bool usesImperialUnits,
  ) {
    return Stack(
      children: [
        ListView(
          key: const PageStorageKey<String>('home-page-scroll'),
          controller: _scrollController,
          children: [
            _HomeHeader(userName: userName, coachName: coachName),
            DashboardWidget(
              totalKcalDaily: totalKcalDaily,
              totalKcalLeft: totalKcalLeft,
              totalKcalSupplied: totalKcalSupplied,
              dailyStepCount: _steps,
              totalCarbsIntake: totalCarbsIntake,
              totalFatsIntake: totalFatsIntake,
              totalProteinsIntake: totalProteinsIntake,
              totalCarbsGoal: totalCarbsGoal,
              totalFatsGoal: totalFatsGoal,
              totalProteinsGoal: totalProteinsGoal,
              userWeight: userWeight,
              weeklyWeightDelta: weeklyWeightDelta,
              targetWeight: targetWeight,
              userWeightGoal: userWeightGoal,
              usesImperialUnits: usesImperialUnits,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                children: [
                  Text(
                    S.of(context).mealsOfDayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    S.of(context).kcalMacrosLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            IntakeVerticalList(
              day: DateTime.now(),
              title: S.of(context).breakfastLabel,
              listIcon: IntakeTypeEntity.breakfast.getIconData(),
              addMealType: AddMealType.breakfastType,
              intakeList: breakfastIntakeList,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemDragCallback: onIntakeItemDrag,
              onItemTappedCallback: onIntakeItemTapped,
              usesImperialUnits: usesImperialUnits,
            ),
            IntakeVerticalList(
              day: DateTime.now(),
              title: S.of(context).lunchLabel,
              listIcon: IntakeTypeEntity.lunch.getIconData(),
              addMealType: AddMealType.lunchType,
              intakeList: lunchIntakeList,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemDragCallback: onIntakeItemDrag,
              onItemTappedCallback: onIntakeItemTapped,
              usesImperialUnits: usesImperialUnits,
            ),
            IntakeVerticalList(
              day: DateTime.now(),
              title: S.of(context).dinnerLabel,
              addMealType: AddMealType.dinnerType,
              listIcon: IntakeTypeEntity.dinner.getIconData(),
              intakeList: dinnerIntakeList,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemDragCallback: onIntakeItemDrag,
              onItemTappedCallback: onIntakeItemTapped,
              usesImperialUnits: usesImperialUnits,
            ),
            IntakeVerticalList(
              day: DateTime.now(),
              title: S.of(context).snackLabel,
              listIcon: IntakeTypeEntity.snack.getIconData(),
              addMealType: AddMealType.snackType,
              intakeList: snackIntakeList,
              onDeleteIntakeCallback: onDeleteIntake,
              onItemDragCallback: onIntakeItemDrag,
              onItemTappedCallback: onIntakeItemTapped,
              usesImperialUnits: usesImperialUnits,
            ),
            const SizedBox(height: 48.0),
            // TEMP: activities temporarily hidden by request
            // ActivityVerticalList(
            //   day: DateTime.now(),
            //   title: S.of(context).activityLabel,
            //   userActivityList: userActivities,
            //   onItemLongPressedCallback: onActivityItemLongPressed,
            // ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Visibility(
            visible: _isDragging,
            child: Container(
              height: 70,
              color: Theme.of(context).colorScheme.error
                ..withValues(alpha: 0.3),
              child: DragTarget<IntakeEntity>(
                onAcceptWithDetails: (data) {
                  _confirmDelete(context, data.data);
                },
                onLeave: (data) {
                  setState(() {
                    _isDragging = false;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return const Center(
                    child: Icon(
                      Icons.delete_outline,
                      size: 36,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void onActivityItemLongPressed(
    BuildContext context,
    UserActivityEntity activityEntity,
  ) async {
    final deleteIntake = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    if (deleteIntake != null) {
      _homeBloc.deleteUserActivityItem(activityEntity);
      _homeBloc.add(const LoadItemsEvent());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)),
        );
      }
    }
  }

  void onWeightItemLongPressed(BuildContext context) async {
    final deleteWeight = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    final info = await PackageInfo.fromPlatform();
    debugPrint('Bundle ID: ${info.packageName}');
    if (deleteWeight != null) {
      _homeBloc.deleteUserWeightItem();
      _homeBloc.add(const LoadItemsEvent());
    }
  }

  void onIntakeItemLongPressed(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    final deleteIntake = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    if (deleteIntake != null) {
      _homeBloc.deleteIntakeItem(intakeEntity);
      _homeBloc.add(const LoadItemsEvent());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemDeletedSnackbar)),
        );
      }
    }
  }

  void onIntakeItemDrag(bool isDragging) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isDragging = isDragging;
      });
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
        _homeBloc.updateIntakeItem(intakeEntity.id, {
          'amount': updatedAmount,
        });
        _homeBloc.add(const LoadItemsEvent());
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).itemUpdatedSnackbar)),
        );
        break;
      case EditDialogAction.deleteItem:
        _homeBloc.deleteIntakeItem(intakeEntity);
        _homeBloc.add(const LoadItemsEvent());
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

  void onDeleteIntake(IntakeEntity intake, TrackedDayEntity? trackedDayEntity) {
    _homeBloc.deleteIntakeItem(intake);
    _homeBloc.add(const LoadItemsEvent());
  }

  void _confirmDelete(BuildContext context, IntakeEntity intake) async {
    bool? delete = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );

    if (delete == true) {
      onDeleteIntake(intake, null);
    }
    setState(() {
      _isDragging = false;
    });
  }

  /// Refresh page when day changes
  void _refreshPageOnDayChange() {
    if (!DateUtils.isSameDay(_homeBloc.currentDay, DateTime.now())) {
      _homeBloc.add(const LoadItemsEvent());
    }
  }
}

class _HomeHeader extends StatelessWidget {
  final String userName;
  final String? coachName;

  const _HomeHeader({required this.userName, required this.coachName});

  String _firstName() {
    final trimmedName = userName.trim();
    if (trimmedName.isEmpty) {
      return '';
    }
    return trimmedName.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final formattedDate =
        DateFormat.yMMMMEEEEd(localeName).format(DateTime.now());
    final firstName = _firstName();
    final greeting = firstName.isEmpty
        ? '${s.helloLabel} 👋'
        : '${s.helloLabel} $firstName 👋';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (coachName?.trim().isNotEmpty == true) ...[
            const SizedBox(width: 12),
            _CoachChip(coachName: coachName!.trim()),
          ],
        ],
      ),
    );
  }
}

class _CoachChip extends StatelessWidget {
  final String? coachName;

  const _CoachChip({required this.coachName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedCoachName = coachName!.trim();

    return Container(
      constraints: const BoxConstraints(maxWidth: 154),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              resolvedCoachName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
