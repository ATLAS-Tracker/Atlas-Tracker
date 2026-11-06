import 'package:opennutritracker/core/presentation/widgets/weight_chart_card.dart';
import 'package:opennutritracker/core/presentation/widgets/chart_controls.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_surface_card.dart';
import 'package:opennutritracker/core/domain/entity/weight_snapshot.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_tab_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/editable_text_widget.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_actions.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/add_weight/presentation/widgets/weight_trend_color.dart';

String _formatWeight(double weight, {bool signed = false}) =>
    formatNumber(weight, decimals: 1, signed: signed);

enum _WeightScreenTab { overview, history }

class AddWeightScreen extends StatefulWidget {
  const AddWeightScreen({super.key});

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  late HomeBloc _homeBloc;
  late WeightBloc _weightBloc;
  late AddWeightUsecase _addWeightUsecase;
  late GetWeightUsecase _getWeightUsecase;
  late GetUserUsecase _getUserUsecase;
  late CalendarDayBloc _calendarDayBloc;
  late DateTime _day;
  late bool _isEditable;
  Future<WeightSummary>? _summaryFuture;
  WeightSummary? _latestSummary;
  bool _isSaving = false;
  double? _savedWeightKg;
  _WeightScreenTab _selectedTab = _WeightScreenTab.overview;
  static const int _summaryDays = 7;

  @override
  void initState() {
    super.initState();
    _homeBloc = locator<HomeBloc>();
    _weightBloc = locator<WeightBloc>();
    _addWeightUsecase = locator<AddWeightUsecase>();
    _getWeightUsecase = locator<GetWeightUsecase>();
    _getUserUsecase = locator<GetUserUsecase>();
    _calendarDayBloc = locator<CalendarDayBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as AddWeightScreenArguments;
    final selectedDay = DateTime(args.day.year, args.day.month, args.day.day);

    _isEditable = args.isReadOnly;

    if (_summaryFuture == null || selectedDay != _day) {
      _day = selectedDay;
      _savedWeightKg = null;
      _weightBloc.add(WeightLoadInitialRequested(_day));
      _summaryFuture = _getWeightsSummary();
    }
  }

  Future<WeightSummary> _getWeightsSummary() async {
    final lastSavedWeights = await _getWeightUsecase.getWeightsFromPastDays(
      _day,
      _summaryDays,
      includeToday: true,
    );

    final weightsMap = {
      for (var e in lastSavedWeights)
        DateTime(e.date.year, e.date.month, e.date.day): e.weight,
    };

    final List<WeightData> weightDataList = List.generate(_summaryDays, (i) {
      final date = DateTime(
        _day.year,
        _day.month,
        _day.day,
      ).subtract(Duration(days: i));
      final weight = weightsMap[date];
      return WeightData(date, weight);
    }).reversed.toList();

    final snapshot = await _getWeightUsecase.getSnapshot(_day);
    final userData = await _getUserUsecase.getUserData();

    return WeightSummary(
      lastRecordedWeight: snapshot.current?.weight,
      weeklyWeightDelta: snapshot.delta,
      userWeightGoal: userData.goal,
      weightDataList: weightDataList,
    );
  }

  double _roundDecimal(double number) {
    return (number * 10).round() / 10;
  }

  void _changeWeightBy(double delta) {
    final nextWeight = (_weightBloc.state.weight + delta).clamp(
      0.0,
      _weightBloc.maxWeight,
    );
    _weightBloc.add(WeightSet(nextWeight));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(S.of(context).weightLabel),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<WeightSummary>(
          future: _summaryFuture,
          builder: (
            BuildContext context,
            AsyncSnapshot<WeightSummary> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done &&
                _latestSummary == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final weightSummary = snapshot.data ?? _latestSummary;
            if (snapshot.hasData) {
              _latestSummary = snapshot.data;
            }

            if (weightSummary == null) {
              return Center(child: Text(S.of(context).weightLabel));
            }

            return BlocBuilder<WeightBloc, WeightState>(
              bloc: _weightBloc,
              builder: (context, state) {
                final unit = S.of(context).kgLabel;
                final overviewChildren = <Widget>[
                  _WeightHeroCard(
                    currentWeight: weightSummary.lastRecordedWeight,
                    delta: weightSummary.weeklyWeightDelta,
                    unit: unit,
                    goal: weightSummary.userWeightGoal,
                  ),
                  const SizedBox(height: 22),
                  _WeightSelectorCard(
                    weight: state.weight,
                    unit: unit,
                    day: _day,
                    isReadOnly: _isEditable || _isSaving,
                    isSaving: _isSaving,
                    isSaved: _savedWeightKg != null &&
                        _roundDecimal(state.weight) == _savedWeightKg,
                    onStepChanged: _changeWeightBy,
                    onSavePressed: () => _onButtonPressed(context),
                  ),
                  const SizedBox(height: 22),
                  _WeightEvolutionCard(
                    day: _day,
                    initialData: weightSummary.recordedWeights,
                  ),
                  if (weightSummary.weightDataList.last.weight != null) ...[
                    const SizedBox(height: 16),
                    _DeleteWeightCard(
                      onPressed: _isEditable || _isSaving
                          ? null
                          : () => _onDeleteWeightPressed(context),
                    ),
                  ],
                ];
                final historyChildren = <Widget>[
                  _WeightHistoryCard(
                    day: _day,
                    userWeightGoal: weightSummary.userWeightGoal,
                    onEdit: _isEditable ? null : _editHistoryWeight,
                  ),
                ];

                return ListView(
                  key: PageStorageKey<String>(
                    'add_weight_screen_${_selectedTab.name}_list',
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                  children: [
                    AtlasTabBar(
                      labels: [
                        S.of(context).overviewLabel,
                        S.of(context).historyLabel,
                      ],
                      selectedIndex: _selectedTab.index,
                      onSelected: (index) {
                        final tab = _WeightScreenTab.values[index];
                        if (tab == _selectedTab) return;
                        setState(() => _selectedTab = tab);
                      },
                    ),
                    const SizedBox(height: 20),
                    ...(_selectedTab == _WeightScreenTab.overview
                        ? overviewChildren
                        : historyChildren),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _onButtonPressed(BuildContext context) async {
    if (_isSaving || _isEditable) return;
    final roundedWeight = _roundDecimal(_weightBloc.state.weight);
    final savedDay = _day;
    setState(() {
      _isSaving = true;
      _savedWeightKg = null;
    });
    try {
      final existing = await _getWeightUsecase.getUserWeightByDate(savedDay);
      await _addWeightUsecase.addUserWeight(UserWeightEntity(
        id: existing?.id ?? IdGenerator.getUniqueID(),
        weight: roundedWeight,
        date: savedDay,
        updatedAt: DateTime.now().toUtc(),
      ));
      if (!mounted) return;
      _homeBloc.add(const LoadItemsEvent());
      _calendarDayBloc.add(const RefreshCalendarDayEvent());
      if (_day == savedDay) {
        setState(() {
          _savedWeightKg = roundedWeight;
          _summaryFuture = _getWeightsSummary();
        });
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).weightSaveError)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editHistoryWeight(DateTime day) async {
    await Navigator.of(context).pushNamed(NavigationOptions.addWeightRoute,
        arguments: AddWeightScreenArguments(day: day, isReadOnly: false));
    if (!mounted) return;
    _weightBloc.add(WeightLoadInitialRequested(_day));
    setState(() => _summaryFuture = _getWeightsSummary());
  }

  Future<void> _onDeleteWeightPressed(BuildContext context) async {
    final deleteWeight = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );
    if (deleteWeight != true) return;
    final deletedDay = _day;
    final original = await _getWeightUsecase.getUserWeightByDate(deletedDay);
    if (original == null) return;
    await _calendarDayBloc.deleteUserWeightItem(deletedDay);
    _homeBloc.add(const LoadItemsEvent());
    _calendarDayBloc.add(const RefreshCalendarDayEvent());
    _weightBloc.add(WeightLoadInitialRequested(_day));

    if (!context.mounted) return;
    showUndo(context, () async {
      await _addWeightUsecase.addUserWeight(UserWeightEntity(
          id: original.id,
          weight: original.weight,
          date: original.date,
          updatedAt: DateTime.now().toUtc()));
      _homeBloc.add(const LoadItemsEvent());
      _calendarDayBloc.add(const RefreshCalendarDayEvent());
      _weightBloc.add(WeightLoadInitialRequested(_day));
      if (mounted) setState(() => _summaryFuture = _getWeightsSummary());
    });
    setState(() {
      _savedWeightKg = null;
      _summaryFuture = _getWeightsSummary();
    });
  }
}

class _WeightHeroCard extends StatelessWidget {
  final double? currentWeight;
  final double? delta;
  final String unit;
  final UserWeightGoalEntity goal;

  const _WeightHeroCard({
    required this.currentWeight,
    required this.delta,
    required this.unit,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = S.of(context);
    final brandOnSurface = atlasBrandOnSurface(colorScheme);
    final brandTertiary = brandOnSurface.withValues(alpha: 0.58);
    final trendColor = delta == null
        ? colorScheme.onSurfaceVariant
        : weightTrendColor(deltaKg: delta!, goal: goal, colors: colorScheme);
    final trendIcon = delta == null || delta == 0
        ? Icons.trending_flat_rounded
        : delta! > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

    return AtlasBrandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            capitalizeFirst(s.currentWeightLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: brandTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: currentWeight == null
                        ? '—'
                        : _formatWeight(currentWeight!)),
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: brandOnSurface.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ]),
              style: theme.textTheme.displayMedium?.copyWith(
                color: brandOnSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.6,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: s.weightAverageDeltaLabel,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: trendColor.withValues(
                          alpha: colorScheme.brightness == Brightness.dark
                              ? 0.22
                              : 0.14,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(trendIcon, color: trendColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      delta == null
                          ? '—'
                          : '${_formatWeight(delta!, signed: true)} $unit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightSelectorCard extends StatelessWidget {
  final double weight;
  final String unit;
  final DateTime day;
  final bool isSaving;
  final bool isSaved;
  final bool isReadOnly;
  final ValueChanged<double> onStepChanged;
  final VoidCallback onSavePressed;

  const _WeightSelectorCard({
    required this.weight,
    required this.unit,
    required this.day,
    required this.isSaving,
    required this.isSaved,
    required this.isReadOnly,
    required this.onStepChanged,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectorSurface = Color.alphaBlend(
      colorScheme.onSurface.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.08 : 0.00,
      ),
      colorScheme.surfaceContainerLowest,
    );

    return AtlasSurfaceCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.10),
                    colorScheme.surfaceContainerLowest,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.monitor_weight_rounded,
                  color: colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).selectMyWeightLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              S.of(context).weightEntryDate(DateFormat.yMMMMEEEEd(
                      Localizations.localeOf(context).toString())
                  .format(day)),
              key: const ValueKey('weight-entry-date'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: selectorSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.primary.withValues(
                  alpha:
                      colorScheme.brightness == Brightness.dark ? 0.16 : 0.10,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.035),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _WeightAdjustButton(
                  icon: Icons.remove,
                  onPressed: isReadOnly ? null : () => onStepChanged(-0.1),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return EditableTextWidget(
                        initialValue: _formatWeight(weight),
                        disabledEnter: isReadOnly,
                        unit: unit,
                        width: constraints.maxWidth,
                        textStyle: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 35,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.9,
                        ),
                        unitStyle: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                _WeightAdjustButton(
                  icon: Icons.add,
                  onPressed: isReadOnly ? null : () => onStepChanged(0.1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            for (final (index, step) in <(String, double)>[
              ('-1', -1),
              ('-0,5', -0.5),
              ('+0,5', 0.5),
              ('+1', 1),
            ].indexed) ...[
              if (index > 0) const SizedBox(width: 12),
              Expanded(
                  child: _StepButton(
                      label: step.$1,
                      onPressed:
                          isReadOnly ? null : () => onStepChanged(step.$2))),
            ],
          ]),
          const SizedBox(height: 28),
          FilledButton.icon(
            key: const ValueKey('save-weight'),
            onPressed: isReadOnly || isSaving ? null : onSavePressed,
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.event_available_outlined, size: 22),
            label: Text(isSaving
                ? S.of(context).weightSavingLabel
                : S.of(context).saveMyWeightLabel),
            style: FilledButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.primary,
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (isSaved && !isSaving) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_outline,
                  color: lunchColor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(S.of(context).weightSavedLabel,
                      key: const ValueKey('weight-saved'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: lunchColor))),
            ]),
          ],
        ],
      ),
    );
  }
}

class _WeightAdjustButton extends StatelessWidget {
  static const double _size = 56;
  final IconData icon;
  final VoidCallback? onPressed;

  const _WeightAdjustButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = Color.alphaBlend(
      colorScheme.primary.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.18 : 0.10,
      ),
      colorScheme.surfaceContainerLowest,
    );

    return SizedBox.square(
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          tooltip: icon == Icons.add
              ? S.of(context).increaseWeightLabel
              : S.of(context).decreaseWeightLabel,
          onPressed: onPressed,
          icon: Icon(icon, size: 28),
          color: colorScheme.primary,
          disabledColor: colorScheme.onSurfaceVariant,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: colorScheme.primary,
          backgroundColor: Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.04),
            colorScheme.surface,
          ),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.10),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1),
        ),
      ),
    );
  }
}

class _WeightEvolutionCard extends StatefulWidget {
  final DateTime day;
  final List<WeightData> initialData;

  const _WeightEvolutionCard({
    required this.day,
    required this.initialData,
  });

  @override
  State<_WeightEvolutionCard> createState() => _WeightEvolutionCardState();
}

class _WeightEvolutionCardState extends State<_WeightEvolutionCard> {
  final GetWeightUsecase _getWeightUsecase = locator<GetWeightUsecase>();
  WeightChartRange _selectedRange = WeightChartRange.sevenDays;
  Future<List<WeightData>>? _chartDataFuture;

  @override
  void initState() {
    super.initState();
    _chartDataFuture = Future.value(widget.initialData);
  }

  @override
  void didUpdateWidget(covariant _WeightEvolutionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day ||
        oldWidget.initialData != widget.initialData) {
      _chartDataFuture = _selectedRange == WeightChartRange.sevenDays
          ? Future.value(widget.initialData)
          : _loadChartData(_selectedRange);
    }
  }

  Future<List<WeightData>> _loadChartData(WeightChartRange range) async {
    if (range == WeightChartRange.sevenDays) {
      return widget.initialData;
    }

    final days = range.days;
    final weights = days == null
        ? await _getWeightUsecase.getAllUserWeights()
        : await _getWeightUsecase.getWeightsFromPastDays(widget.day, days,
            includeToday: true);
    final firstDay = days == null
        ? null
        : DateTime(
            widget.day.year, widget.day.month, widget.day.day - days + 1);
    final byDate = <DateTime, double>{};
    for (final entry in weights) {
      final date = DateUtils.dateOnly(entry.date);
      if (date.isAfter(widget.day) ||
          (firstDay != null && date.isBefore(firstDay))) {
        continue;
      }
      byDate[date] = entry.weight;
    }
    if (days == null && byDate.isEmpty) return widget.initialData;
    return [
      for (final entry in byDate.entries) WeightData(entry.key, entry.value)
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  String _rangeLabel(BuildContext context, WeightChartRange range) {
    final s = S.of(context);
    switch (range) {
      case WeightChartRange.sevenDays:
        return s.lastSevenDaysLabel;
      case WeightChartRange.fourteenDays:
        return s.lastFourteenDaysLabel;
      case WeightChartRange.oneMonth:
        return s.lastMonthLabel;
      case WeightChartRange.threeMonths:
        return s.lastThreeMonthsLabel;
      case WeightChartRange.sixMonths:
        return s.lastSixMonthsLabel;
      case WeightChartRange.oneYear:
        return s.lastYearLabel;
      case WeightChartRange.all:
        return s.allTimeLabel;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<WeightData>>(
        future: _chartDataFuture,
        initialData: _selectedRange == WeightChartRange.sevenDays
            ? widget.initialData
            : null,
        builder: (context, snapshot) => WeightChartCard(
          data: snapshot.data ?? widget.initialData,
          range: _selectedRange,
          selector: ChartSelector(
              style: ChartSelectorStyle.dropdown,
              selectedIndex: _selectedRange.index,
              labels: [
                for (final range in WeightChartRange.values)
                  _rangeLabel(context, range)
              ],
              onSelected: (index) {
                final range = WeightChartRange.values[index];
                if (range == _selectedRange) return;
                setState(() {
                  _selectedRange = range;
                  _chartDataFuture = _loadChartData(range);
                });
              }),
        ),
      );
}

class _DeleteWeightCard extends StatelessWidget {
  final VoidCallback? onPressed;

  const _DeleteWeightCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: TextButton.icon(
      key: const ValueKey('delete-weight'),
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded, size: 20),
      label: Text(S.of(context).deleteWeightCardTitle),
      style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error),
    ));
  }
}

class _WeightHistoryCard extends StatefulWidget {
  final DateTime day;
  final UserWeightGoalEntity userWeightGoal;
  final ValueChanged<DateTime>? onEdit;

  const _WeightHistoryCard({
    required this.day,
    required this.userWeightGoal,
    this.onEdit,
  });

  @override
  State<_WeightHistoryCard> createState() => _WeightHistoryCardState();
}

class _WeightHistoryCardState extends State<_WeightHistoryCard> {
  final GetWeightUsecase _getWeightUsecase = locator<GetWeightUsecase>();
  late Future<List<_WeightHistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  @override
  void didUpdateWidget(covariant _WeightHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day ||
        oldWidget.userWeightGoal != widget.userWeightGoal) {
      _historyFuture = _loadHistory();
    }
  }

  Future<List<_WeightHistoryEntry>> _loadHistory() async {
    final weights = await _getWeightUsecase.getAllUserWeights();
    final filteredWeights = weights
        .where((entry) => !DateTime(
              entry.date.year,
              entry.date.month,
              entry.date.day,
            ).isAfter(widget.day))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final entries = <_WeightHistoryEntry>[];
    for (final weight in filteredWeights) {
      final delta = WeightSnapshot.at(weight.date, weights).delta;
      entries.add((weight: weight, delta: delta));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unit = S.of(context).kgLabel;

    return FutureBuilder<List<_WeightHistoryEntry>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <_WeightHistoryEntry>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.of(context).weightHistoryLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState != ConnectionState.done &&
                entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 26),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              AtlasSurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Text(
                  S.of(context).noDataToday,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else ...[
              for (var index = 0; index < entries.length; index++) ...[
                _WeightHistoryTile(
                    entry: entries[index],
                    unit: unit,
                    userWeightGoal: widget.userWeightGoal,
                    onEdit: widget.onEdit == null
                        ? null
                        : () => widget.onEdit!(entries[index].weight.date)),
                if (index != entries.length - 1) const SizedBox(height: 12),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _WeightHistoryTile extends StatelessWidget {
  final _WeightHistoryEntry entry;
  final String unit;
  final UserWeightGoalEntity userWeightGoal;
  final VoidCallback? onEdit;

  const _WeightHistoryTile({
    required this.entry,
    required this.unit,
    required this.userWeightGoal,
    this.onEdit,
  });

  IconData _variationIcon(double deltaKg) {
    return deltaKg >= 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = capitalizeFirst(
      DateFormat('EEEE d MMMM', locale).format(entry.weight.date),
    );
    final deltaKg = entry.delta;
    final displayedDelta = deltaKg;
    final variationColor = deltaKg == null
        ? colorScheme.onSurfaceVariant
        : weightTrendColor(
            deltaKg: deltaKg, goal: userWeightGoal, colors: colorScheme);

    return Semantics(
      button: onEdit != null,
      label: onEdit == null ? null : S.of(context).editWeightLabel,
      child: InkWell(
        key: ValueKey('edit-weight-${entry.weight.id}'),
        onTap: onEdit,
        borderRadius: BorderRadius.circular(22),
        child: AtlasSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            radius: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 138,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 60,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_formatWeight(entry.weight.weight)} $unit',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 72,
                        child: _WeightHistoryDeltaBadge(
                          delta: displayedDelta,
                          unit: unit,
                          color: variationColor,
                          icon:
                              deltaKg == null ? null : _variationIcon(deltaKg),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class _WeightHistoryDeltaBadge extends StatelessWidget {
  final double? delta;
  final String unit;
  final Color color;
  final IconData? icon;

  const _WeightHistoryDeltaBadge({
    required this.delta,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        delta == null ? '—' : '${_formatWeight(delta!, signed: true)} $unit';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).colorScheme.brightness == Brightness.dark
              ? 0.18
              : 0.10,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                fontSize: 10.5,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 2),
            Icon(icon, size: 12, color: color),
          ],
        ],
      ),
    );
  }
}

typedef _WeightHistoryEntry = ({UserWeightEntity weight, double? delta});

class AddWeightScreenArguments {
  final DateTime day;
  final bool isReadOnly;

  AddWeightScreenArguments({required this.day, required this.isReadOnly});
}

class WeightSummary {
  final double? lastRecordedWeight;
  final double? weeklyWeightDelta;
  final UserWeightGoalEntity userWeightGoal;
  final List<WeightData> weightDataList;
  // Stable input prevents a weight adjustment from reloading the chart's period.
  late final List<WeightData> recordedWeights = [
    for (final point in weightDataList)
      if (point.weight != null) point,
  ];

  WeightSummary({
    required this.lastRecordedWeight,
    required this.weeklyWeightDelta,
    required this.userWeightGoal,
    required this.weightDataList,
  });
}
