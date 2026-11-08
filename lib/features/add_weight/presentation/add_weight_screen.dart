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
import 'package:opennutritracker/core/domain/entity/weight_period_stats.dart';
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
  WeightChartRange _range = WeightChartRange.sevenDays;
  final _heroKey = GlobalKey();
  final _showStickyBar = ValueNotifier(false);

  @override
  void dispose() {
    _showStickyBar.dispose();
    super.dispose();
  }

  bool _stickyCheckScheduled = false;

  /// Shows the compact recap once the dashboard has scrolled out of view.
  /// Measured after the frame: sizes cannot be read mid-layout.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || _stickyCheckScheduled) return false;
    final viewportContext = notification.context;
    final pixels = notification.metrics.pixels;
    _stickyCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stickyCheckScheduled = false;
      if (!mounted) return;
      final hero = _heroKey.currentContext?.findRenderObject() as RenderBox?;
      final viewport = viewportContext != null && viewportContext.mounted
          ? viewportContext.findRenderObject() as RenderBox?
          : null;
      final hidden = hero == null ||
              !hero.attached ||
              viewport == null ||
              !viewport.attached
          ? pixels > 0
          : hero.localToGlobal(Offset(0, hero.size.height)).dy <=
              viewport.localToGlobal(Offset.zero).dy;
      _showStickyBar.value =
          _selectedTab == _WeightScreenTab.overview && hidden;
    });
    return false;
  }

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
    final range = _range;
    final weights = await _getWeightUsecase.getWeightsFromPastDays(
      _day,
      range.days,
      includeToday: true,
    );
    final userData = await _getUserUsecase.getUserData();
    return WeightSummary(
      stats: WeightPeriodStats.of(_day, weights, range.days),
      range: range,
      userWeightGoal: userData.goal,
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
                    key: _heroKey,
                    stats: weightSummary.stats,
                    range: weightSummary.range,
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
                  ChartSelector(
                    labels: [
                      for (final range in WeightChartRange.values)
                        range.label(S.of(context))
                    ],
                    selectedIndex: _range.index,
                    onSelected: (index) {
                      final range = WeightChartRange.values[index];
                      if (range == _range) return;
                      setState(() {
                        _range = range;
                        _summaryFuture = _getWeightsSummary();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  WeightChartCard(
                    data: weightSummary.recordedWeights,
                    range: weightSummary.range,
                  ),
                  if (weightSummary.stats.today != null) ...[
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

                final list = ListView(
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
                        _showStickyBar.value = false;
                        setState(() => _selectedTab = tab);
                      },
                    ),
                    const SizedBox(height: 20),
                    ...(_selectedTab == _WeightScreenTab.overview
                        ? overviewChildren
                        : historyChildren),
                  ],
                );
                return Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: list,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _showStickyBar,
                        builder: (context, show, child) => IgnorePointer(
                          ignoring: !show,
                          child: AnimatedSlide(
                            offset: show ? Offset.zero : const Offset(0, -1.2),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: AnimatedOpacity(
                              opacity: show ? 1 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: child,
                            ),
                          ),
                        ),
                        child: _WeightStickyBar(
                          key: const ValueKey('weight-sticky-bar'),
                          stats: weightSummary.stats,
                          range: weightSummary.range,
                          unit: unit,
                          goal: weightSummary.userWeightGoal,
                        ),
                      ),
                    ),
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

String _signedWeight(double kg) =>
    _formatWeight(kg, signed: true).replaceFirst('-', '−');

/// Text, goal colour and arrow for a weight difference; null when unknown.
({String text, Color color, IconData icon})? _deltaView(
    double? delta, String unit, UserWeightGoalEntity goal, ColorScheme colors) {
  if (delta == null) return null;
  final rounded = (delta * 10).round() / 10;
  return (
    text: '${_signedWeight(rounded)} $unit',
    color: weightTrendColor(deltaKg: rounded, goal: goal, colors: colors),
    icon: rounded == 0
        ? Icons.trending_flat_rounded
        : rounded > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
  );
}

String _goalLabel(S s, UserWeightGoalEntity goal) => switch (goal) {
      UserWeightGoalEntity.loseWeight => s.goalLoseWeight,
      UserWeightGoalEntity.maintainWeight => s.goalMaintainWeight,
      UserWeightGoalEntity.gainWeight => s.goalGainWeight,
    };

class _WeightHeroCard extends StatelessWidget {
  final WeightPeriodStats stats;
  final WeightChartRange range;
  final String unit;
  final UserWeightGoalEntity goal;

  const _WeightHeroCard({
    super.key,
    required this.stats,
    required this.range,
    required this.unit,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = S.of(context);
    final onBrand = atlasBrandOnSurface(colorScheme);
    final today = stats.today;
    final period = range.label(s);

    return AtlasBrandPanel(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                capitalizeFirst(s.weightTodayLabel),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onBrand.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                key: const ValueKey('weight-goal'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: onBrand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, size: 14, color: onBrand),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s.weightGoalReminder(_goalLabel(s, goal)),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: onBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            key: const ValueKey('weight-today'),
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: today == null ? '—' : _formatWeight(today)),
                if (today != null)
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onBrand.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
              ]),
              style: theme.textTheme.displayMedium?.copyWith(
                color: onBrand,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final tiles = <Widget>[
              _WeightStatTile(
                key: const ValueKey('weight-average'),
                large: true,
                label: s.weightPeriodAverageLabel(period),
                details: stats.weighIns.isEmpty
                    ? null
                    : _WeightAverageDetails(stats: stats, unit: unit),
                value: stats.average == null
                    ? '—'
                    : '${_formatWeight(stats.average!)} $unit',
              ),
              _WeightStatTile(
                key: const ValueKey('weight-average-gap'),
                label: s.weightAverageGapLabel,
                delta:
                    _deltaView(stats.deltaToAverage, unit, goal, colorScheme),
              ),
              _WeightStatTile(
                key: const ValueKey('weight-change'),
                label: s.weightPeriodChangeLabel(period),
                delta: _deltaView(stats.change, unit, goal, colorScheme),
                hint: stats.weighIns.length < 2
                    ? s.weightTrendNotEnoughLabel
                    : null,
              ),
            ];
            // Square average on the left, gap and change stacked on the right;
            // a plain column when large text leaves no room for squares.
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final half = (constraints.maxWidth - 10) / 2;
            if (half < 128 * scale) {
              return Column(children: [
                for (final tile in tiles) ...[
                  tile,
                  if (tile != tiles.last) const SizedBox(height: 8),
                ],
              ]);
            }
            final minHeight = 156 * scale;
            return SizedBox(
              height: half > minHeight ? half : minHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[1]),
                        const SizedBox(height: 10),
                        Expanded(child: tiles[2]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Glass tile on the brand panel: label, optional hint, then the value.
/// [large] is the square average tile; the others are its half-height pair.
class _WeightStatTile extends StatelessWidget {
  final String label;
  final String? value;
  final ({String text, Color color, IconData icon})? delta;
  final String? hint;
  final bool large;
  final Widget? details;

  const _WeightStatTile({
    super.key,
    required this.label,
    this.value,
    this.delta,
    this.hint,
    this.large = false,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = atlasBrandOnSurface(theme.colorScheme);
    final d = delta;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: onBrand.withValues(alpha: 0.74),
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: 1.2,
    );
    return Container(
      padding: EdgeInsets.all(large ? 16 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            onBrand.withValues(alpha: large ? 0.20 : 0.14),
            onBrand.withValues(alpha: large ? 0.08 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(large ? 24 : 20),
        border: Border.all(color: onBrand.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              if (large)
                Icon(Icons.insights_rounded,
                    size: 18, color: onBrand.withValues(alpha: 0.6)),
            ],
          ),
          if (details != null) details!,
          const SizedBox(height: 6),
          Row(
            children: [
              if (d != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: d.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: d.color.withValues(alpha: 0.45),
                          blurRadius: 8),
                    ],
                  ),
                  child: Icon(d.icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value ?? d?.text ?? '—',
                    style: (large
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                      color: onBrand,
                      fontWeight: FontWeight.w800,
                      letterSpacing: large ? -0.8 : -0.3,
                    ),
                  ),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  flex: 3,
                  child: Text(
                    hint!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle?.copyWith(
                        color: onBrand.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Fills the square average tile: lowest and highest weigh-in, and how
/// many weigh-ins the average is built from.
class _WeightAverageDetails extends StatelessWidget {
  final WeightPeriodStats stats;
  final String unit;

  const _WeightAverageDetails({required this.stats, required this.unit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = atlasBrandOnSurface(theme.colorScheme);
    final s = S.of(context);
    final weights = [for (final e in stats.weighIns) e.weight];
    final low = weights.reduce((a, b) => a < b ? a : b);
    final high = weights.reduce((a, b) => a > b ? a : b);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: onBrand,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );

    final dim = style?.copyWith(
      color: onBrand.withValues(alpha: 0.65),
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '${s.weightMinLabel} ', style: dim),
              TextSpan(text: _formatWeight(low)),
              TextSpan(text: '  ·  ', style: dim),
              TextSpan(text: '${s.weightMaxLabel} ', style: dim),
              TextSpan(text: '${_formatWeight(high)} $unit'),
            ]),
            key: const ValueKey('weight-min-max'),
            style: style,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          s.weightWeighInCount(stats.weighIns.length),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: onBrand.withValues(alpha: 0.65),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Floating recap pinned under the app bar once the dashboard scrolls away.
class _WeightStickyBar extends StatelessWidget {
  final WeightPeriodStats stats;
  final WeightChartRange range;
  final String unit;
  final UserWeightGoalEntity goal;

  const _WeightStickyBar({
    super.key,
    required this.stats,
    required this.range,
    required this.unit,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = S.of(context);
    final period = range.label(s);

    Widget item(String label, String text,
        ({String text, Color color, IconData icon})? delta) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (delta != null) ...[
                Icon(delta.icon, size: 16, color: delta.color),
                const SizedBox(width: 3),
              ],
              Text(
                delta?.text ?? text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: delta?.color ?? colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget divider() => Container(
          width: 1,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        );

    final today = stats.today;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        elevation: 6,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(6, 6, 20, 6),
          child: Row(
            children: [
              DecoratedBox(
                decoration: const ShapeDecoration(
                  shape: StadiumBorder(),
                  gradient: LinearGradient(colors: atlasBrandGradientColors),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    today == null ? '—' : '${_formatWeight(today)} $unit',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              item(
                  s.weightAverageShort(period),
                  stats.average == null
                      ? '—'
                      : '${_formatWeight(stats.average!)} $unit',
                  null),
              divider(),
              item(s.weightGapShort, '—',
                  _deltaView(stats.deltaToAverage, unit, goal, colorScheme)),
              divider(),
              item(s.weightChangeShort(period), '—',
                  _deltaView(stats.change, unit, goal, colorScheme)),
            ],
          ),
        ),
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
  final WeightPeriodStats stats;
  final WeightChartRange range;
  final UserWeightGoalEntity userWeightGoal;
  // Stable input prevents a weight adjustment from reloading the chart's period.
  late final List<WeightData> recordedWeights = [
    for (final entry in stats.weighIns)
      WeightData(DateUtils.dateOnly(entry.date), entry.weight),
  ];

  WeightSummary({
    required this.stats,
    required this.range,
    required this.userWeightGoal,
  });
}
