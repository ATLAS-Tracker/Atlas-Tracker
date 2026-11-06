import 'package:opennutritracker/core/presentation/refresh_journal.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_actions.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:intl/intl.dart';
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
  bool _copyingYesterday = false;
  StepTrackingController? _stepTrackingController;

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

    await controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        } else if (state is HomeErrorState) {
          return ErrorDialog(
              errorText: S.of(context).journalLoadError,
              onRefreshPressed: () => _homeBloc.add(const LoadItemsEvent()));
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
      state.userWeightEntity,
      state.weeklyWeightDelta,
      state.userWeightGoal,
    );
  }

  Widget _getLoadedContent(
    BuildContext context,
    String userName,
    String? coachName,
    double totalKcalDaily,
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
    UserWeightEntity? userWeight,
    double? weeklyWeightDelta,
    UserWeightGoalEntity userWeightGoal,
  ) {
    return RefreshIndicator(
        onRefresh: () async {
          final done = _homeBloc.stream.firstWhere(
              (state) => state is HomeLoadedState || state is HomeErrorState);
          _homeBloc.add(const LoadItemsEvent());
          await done;
        },
        child: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              key: const PageStorageKey<String>('home-page-scroll'),
              controller: _scrollController,
              children: [
                _HomeHeader(userName: userName, coachName: coachName),
                DashboardWidget(
                  totalKcalDaily: totalKcalDaily,
                  totalKcalSupplied: totalKcalSupplied,
                  totalCarbsIntake: totalCarbsIntake,
                  totalFatsIntake: totalFatsIntake,
                  totalProteinsIntake: totalProteinsIntake,
                  totalCarbsGoal: totalCarbsGoal,
                  totalFatsGoal: totalFatsGoal,
                  totalProteinsGoal: totalProteinsGoal,
                  userWeight: userWeight,
                  weeklyWeightDelta: weeklyWeightDelta,
                  userWeightGoal: userWeightGoal,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                  child: Row(
                    children: [
                      Text(
                        S.of(context).mealsOfDayLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
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
                  addMealType: AddMealType.breakfastType,
                  intakeList: breakfastIntakeList,
                  onDeleteIntakeCallback: onDeleteIntake,
                  onDeleteAllIntakesCallback: onDeleteIntakes,
                  onCopyFromYesterday: () =>
                      _copyYesterday(AddMealType.breakfastType),
                  onItemDragCallback: onIntakeItemDrag,
                  onItemTappedCallback: onIntakeItemTapped,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                ),
                IntakeVerticalList(
                  day: DateTime.now(),
                  title: S.of(context).lunchLabel,
                  addMealType: AddMealType.lunchType,
                  intakeList: lunchIntakeList,
                  onDeleteIntakeCallback: onDeleteIntake,
                  onDeleteAllIntakesCallback: onDeleteIntakes,
                  onCopyFromYesterday: () =>
                      _copyYesterday(AddMealType.lunchType),
                  onItemDragCallback: onIntakeItemDrag,
                  onItemTappedCallback: onIntakeItemTapped,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                ),
                IntakeVerticalList(
                  day: DateTime.now(),
                  title: S.of(context).dinnerLabel,
                  addMealType: AddMealType.dinnerType,
                  intakeList: dinnerIntakeList,
                  onDeleteIntakeCallback: onDeleteIntake,
                  onDeleteAllIntakesCallback: onDeleteIntakes,
                  onCopyFromYesterday: () =>
                      _copyYesterday(AddMealType.dinnerType),
                  onItemDragCallback: onIntakeItemDrag,
                  onItemTappedCallback: onIntakeItemTapped,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                ),
                IntakeVerticalList(
                  day: DateTime.now(),
                  title: S.of(context).snackLabel,
                  addMealType: AddMealType.snackType,
                  intakeList: snackIntakeList,
                  onDeleteIntakeCallback: onDeleteIntake,
                  onDeleteAllIntakesCallback: onDeleteIntakes,
                  onCopyFromYesterday: () =>
                      _copyYesterday(AddMealType.snackType),
                  onItemDragCallback: onIntakeItemDrag,
                  onItemTappedCallback: onIntakeItemTapped,
                  onItemLongPressedCallback: onIntakeItemLongPressed,
                ),
                const SizedBox(height: 48.0),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Visibility(
                visible: _isDragging,
                child: Container(
                  height: 70,
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.3),
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
        ));
  }

  void onIntakeItemLongPressed(
    BuildContext context,
    IntakeEntity intakeEntity,
  ) async {
    await showIntakeActions(context, intakeEntity,
        edit: () => onIntakeItemTapped(context, intakeEntity),
        delete: () => onDeleteIntake(intakeEntity, null),
        refresh: _refreshAllViews);
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
        await _homeBloc.updateIntakeItem(intakeEntity.id, {
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

  Future<void> onDeleteIntake(
      IntakeEntity intake, TrackedDayEntity? trackedDayEntity) async {
    await onDeleteIntakes([intake]);
  }

  Future<void> onDeleteIntakes(List<IntakeEntity> intakes) async {
    await deleteIntakesWithUndo(
        context, intakes, _homeBloc.deleteIntakeItem, _refreshAllViews);
  }

  void _refreshAllViews() {
    refreshJournalViews();
  }

  Future<void> _copyYesterday(AddMealType type) async {
    if (_copyingYesterday) return;
    _copyingYesterday = true;
    try {
      final today = DateUtils.dateOnly(DateTime.now());
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      final intakes = await locator<GetIntakeUsecase>()
          .getIntakeByDay(type.getIntakeType(), yesterday);
      await locator<AddIntakeUsecase>().addIntakes([
        for (final intake in intakes)
          intake.copyWith(
              id: IdGenerator.getUniqueID(),
              dateTime: today,
              updatedAt: DateTime.now().toUtc())
      ]);
      _refreshAllViews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(intakes.isEmpty
              ? S.of(context).noFoodYesterdayLabel
              : S.of(context).mealCopiedSnackbar)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).intakeSaveError)));
      }
    } finally {
      _copyingYesterday = false;
    }
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
