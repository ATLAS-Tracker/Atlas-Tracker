import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/editable_text_widget.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

String _formatWeight(double weight, {bool signed = false}) {
  final sign = signed && weight > 0 ? '+' : '';
  return '$sign${weight.toStringAsFixed(1)}';
}

String _capitalizeFirst(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

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
  late GetConfigUsecase _getConfigUsecase;
  late CalendarDayBloc _calendarDayBloc;
  late DateTime _day;
  late bool _isEditable;
  Future<WeightSummary>? _summaryFuture;
  WeightSummary? _latestSummary;
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
    _getConfigUsecase = locator<GetConfigUsecase>();
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

    final averageWeight = await _getWeightUsecase.getAverageWeight(
      _day,
      _summaryDays,
    );
    final lastRecordedWeight = await _getWeightUsecase.getLastUserWeight(_day);
    final userData = await _getUserUsecase.getUserData();
    final config = await _getConfigUsecase.getConfig();

    return WeightSummary(
      averageWeight: averageWeight,
      lastRecordedWeight: lastRecordedWeight,
      targetWeight: userData.weightKG,
      userWeightGoal: userData.goal,
      usesImperialUnits: config.usesImperialUnits,
      weightDataList: weightDataList,
    );
  }

  double roundDecimal(double number, {int nbDecimal = 1}) {
    return (number * 10 * nbDecimal).round() / (10 * nbDecimal);
  }

  double _displayWeight(double weightKg, bool usesImperialUnits) {
    return usesImperialUnits ? UnitCalc.kgToLbs(weightKg) : weightKg;
  }

  bool _hasSavedWeightForDay(WeightSummary summary) {
    return summary.weightDataList.any((point) {
      final pointDate = DateTime(
        point.date.year,
        point.date.month,
        point.date.day,
      );
      return pointDate == _day && point.weight != null;
    });
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
                final unit = weightSummary.usesImperialUnits
                    ? S.of(context).lbsLabel
                    : S.of(context).kgLabel;
                final overviewChildren = <Widget>[
                  _WeightHeroCard(
                    currentWeight: _displayWeight(
                      weightSummary.lastRecordedWeight,
                      weightSummary.usesImperialUnits,
                    ),
                    averageWeight: _displayWeight(
                      weightSummary.averageWeight,
                      weightSummary.usesImperialUnits,
                    ),
                    targetWeight: _displayWeight(
                      weightSummary.targetWeight,
                      weightSummary.usesImperialUnits,
                    ),
                    unit: unit,
                  ),
                  const SizedBox(height: 22),
                  _WeightSelectorCard(
                    weight: _displayWeight(
                      state.weight,
                      weightSummary.usesImperialUnits,
                    ),
                    unit: unit,
                    isReadOnly: _isEditable,
                    onStepChanged: _changeWeightBy,
                    onSavePressed: () => _onButtonPressed(context),
                  ),
                  const SizedBox(height: 22),
                  _WeightEvolutionCard(
                    day: _day,
                    initialData: weightSummary.weightDataList,
                    averageWeight: weightSummary.averageWeight,
                    usesImperialUnits: weightSummary.usesImperialUnits,
                  ),
                  if (_hasSavedWeightForDay(weightSummary)) ...[
                    const SizedBox(height: 16),
                    _DeleteWeightCard(
                      onPressed: () => _onDeleteWeightPressed(context),
                    ),
                  ],
                ];
                final historyChildren = <Widget>[
                  _WeightHistoryCard(
                    day: _day,
                    usesImperialUnits: weightSummary.usesImperialUnits,
                    userWeightGoal: weightSummary.userWeightGoal,
                  ),
                ];

                return ListView(
                  key: PageStorageKey<String>(
                    'add_weight_screen_${_selectedTab.name}_list',
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                  children: [
                    _WeightTabBar(
                      selectedTab: _selectedTab,
                      onTabSelected: (tab) {
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

  void _onButtonPressed(BuildContext context) {
    double roundedWeight = roundDecimal(_weightBloc.state.weight);

    _addWeightUsecase.addUserWeight(
      UserWeightEntity(
        id: IdGenerator.getUniqueID(),
        weight: roundedWeight,
        date: _day,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    _homeBloc.add(const LoadItemsEvent());
    _calendarDayBloc.add(const RefreshCalendarDayEvent());

    if (mounted) {
      setState(() {
        _summaryFuture = _getWeightsSummary();
      });
    }
  }

  Future<void> _onDeleteWeightPressed(BuildContext context) async {
    final deleteWeight = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteDialog(),
    );
    if (deleteWeight != true) return;

    await _calendarDayBloc.deleteUserWeightItem(_day);
    _homeBloc.add(const LoadItemsEvent());
    _calendarDayBloc.add(const RefreshCalendarDayEvent());
    _weightBloc.add(WeightLoadInitialRequested(_day));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).weightDeletedSnackbar)),
    );
    setState(() {
      _summaryFuture = _getWeightsSummary();
    });
  }
}

class _WeightTabBar extends StatelessWidget {
  final _WeightScreenTab selectedTab;
  final ValueChanged<_WeightScreenTab> onTabSelected;

  const _WeightTabBar({
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabLabel(
              label: S.of(context).overviewLabel,
              selected: selectedTab == _WeightScreenTab.overview,
              onTap: () => onTabSelected(_WeightScreenTab.overview),
            ),
          ),
          Expanded(
            child: _TabLabel(
              label: S.of(context).historyLabel,
              selected: selectedTab == _WeightScreenTab.history,
              onTap: () => onTabSelected(_WeightScreenTab.history),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 86 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightHeroCard extends StatelessWidget {
  final double currentWeight;
  final double averageWeight;
  final double targetWeight;
  final String unit;

  const _WeightHeroCard({
    required this.currentWeight,
    required this.averageWeight,
    required this.targetWeight,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brandOnSurface = colorScheme.brightness == Brightness.dark
        ? lightColorScheme.onPrimary
        : colorScheme.onPrimary;
    final brandSecondary = brandOnSurface.withValues(alpha: 0.78);
    final brandDivider = brandOnSurface.withValues(alpha: 0.16);
    final delta = currentWeight - averageWeight;
    final remaining = (targetWeight - currentWeight).abs();
    final trendColor = delta <= 0 ? lunchColor : colorScheme.error;

    return AtlasBrandPanel(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizeFirst(S.of(context).currentWeightLabel),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: brandSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: _formatWeight(currentWeight)),
                          TextSpan(
                            text: ' $unit',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: brandOnSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: brandOnSurface,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_formatWeight(delta, signed: true)} $unit / ${S.of(context).weekLabel}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              _ScaleIconCard(color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 26),
          Divider(height: 1, thickness: 1, color: brandDivider),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: S.of(context).weightGoalShortLabel,
                  value: '${_formatWeight(targetWeight)} $unit',
                ),
              ),
              Container(width: 1, height: 56, color: brandDivider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: _HeroMetric(
                    label: S.of(context).remainingToLoseLabel,
                    value: '${_formatWeight(remaining)} $unit',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScaleIconCard extends StatelessWidget {
  final Color color;

  const _ScaleIconCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: CustomPaint(
            painter: _ScaleGlyphPainter(
              dialColor: Theme.of(context).colorScheme.onPrimary,
              needleColor: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleGlyphPainter extends CustomPainter {
  final Color dialColor;
  final Color needleColor;

  const _ScaleGlyphPainter({
    required this.dialColor,
    required this.needleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dialColor;
    final dialRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.35),
      width: size.width * 0.58,
      height: size.height * 0.28,
    );
    canvas.drawOval(dialRect, paint);

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.35),
      Offset(size.width / 2, size.height * 0.27),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScaleGlyphPainter oldDelegate) {
    return oldDelegate.dialColor != dialColor ||
        oldDelegate.needleColor != needleColor;
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brandOnSurface = colorScheme.brightness == Brightness.dark
        ? lightColorScheme.onPrimary
        : colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: brandOnSurface.withValues(alpha: 0.76),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: brandOnSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _WeightSelectorCard extends StatelessWidget {
  final double weight;
  final String unit;
  final bool isReadOnly;
  final ValueChanged<double> onStepChanged;
  final VoidCallback onSavePressed;

  const _WeightSelectorCard({
    required this.weight,
    required this.unit,
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

    return _SurfaceCard(
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
                  Icons.monitor_weight_outlined,
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
          LayoutBuilder(
            builder: (context, constraints) {
              const desiredButtonWidth = 76.0;
              const desiredGap = 22.0;
              const minGap = 12.0;
              const minButtonWidth = 52.0;
              final widthAtMinimumGaps =
                  (constraints.maxWidth - (minGap * 3)) / 4;
              final buttonWidth = widthAtMinimumGaps < minButtonWidth
                  ? widthAtMinimumGaps.clamp(40.0, minButtonWidth)
                  : widthAtMinimumGaps.clamp(
                      minButtonWidth,
                      desiredButtonWidth,
                    );
              final remainingSpace = constraints.maxWidth - (buttonWidth * 4);
              final gap = remainingSpace <= minGap * 3
                  ? (remainingSpace / 3).clamp(0.0, minGap)
                  : (remainingSpace / 3).clamp(minGap, desiredGap);

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepButton(
                    width: buttonWidth,
                    label: '-1',
                    onPressed: isReadOnly ? null : () => onStepChanged(-1),
                  ),
                  SizedBox(width: gap),
                  _StepButton(
                    width: buttonWidth,
                    label: '-0,5',
                    onPressed: isReadOnly ? null : () => onStepChanged(-0.5),
                  ),
                  SizedBox(width: gap),
                  _StepButton(
                    width: buttonWidth,
                    label: '+0,5',
                    onPressed: isReadOnly ? null : () => onStepChanged(0.5),
                  ),
                  SizedBox(width: gap),
                  _StepButton(
                    width: buttonWidth,
                    label: '+1',
                    onPressed: isReadOnly ? null : () => onStepChanged(1),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: isReadOnly ? null : onSavePressed,
            icon: const Icon(Icons.event_available_outlined, size: 22),
            label: Text(S.of(context).saveMyWeightLabel),
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
  final double width;
  final String label;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.width,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: colorScheme.primary,
          backgroundColor: Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.095),
            colorScheme.surface,
          ),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.18),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
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

enum _WeightChartRange {
  sevenDays(days: 7),
  fourteenDays(days: 14),
  oneMonth(days: 31),
  threeMonths(days: 92),
  sixMonths(days: 183),
  oneYear(days: 365),
  all(days: null);

  final int? days;

  const _WeightChartRange({required this.days});
}

class _WeightEvolutionCard extends StatefulWidget {
  final DateTime day;
  final List<WeightData> initialData;
  final double averageWeight;
  final bool usesImperialUnits;

  const _WeightEvolutionCard({
    required this.day,
    required this.initialData,
    required this.averageWeight,
    required this.usesImperialUnits,
  });

  @override
  State<_WeightEvolutionCard> createState() => _WeightEvolutionCardState();
}

class _WeightEvolutionCardState extends State<_WeightEvolutionCard> {
  final GetWeightUsecase _getWeightUsecase = locator<GetWeightUsecase>();
  _WeightChartRange _selectedRange = _WeightChartRange.sevenDays;
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
        oldWidget.initialData != widget.initialData ||
        oldWidget.usesImperialUnits != widget.usesImperialUnits) {
      _chartDataFuture = _selectedRange == _WeightChartRange.sevenDays
          ? Future.value(widget.initialData)
          : _loadChartData(_selectedRange);
    }
  }

  double _displayWeight(double weightKg) {
    return widget.usesImperialUnits ? UnitCalc.kgToLbs(weightKg) : weightKg;
  }

  Future<List<WeightData>> _loadChartData(_WeightChartRange range) async {
    if (range == _WeightChartRange.sevenDays) {
      return widget.initialData;
    }

    final int? days = range.days;
    if (days == null) {
      final weights = await _getWeightUsecase.getAllUserWeights();
      final eligibleDates = weights
          .map((entry) =>
              DateTime(entry.date.year, entry.date.month, entry.date.day))
          .where((date) => !date.isAfter(widget.day))
          .toList();
      if (eligibleDates.isEmpty) {
        return widget.initialData;
      }
      eligibleDates.sort();
      final firstDate = eligibleDates.first;
      final totalDays = widget.day.difference(firstDate).inDays + 1;
      return _buildDenseSeries(totalDays);
    }

    return _buildDenseSeries(days);
  }

  Future<List<WeightData>> _buildDenseSeries(int days) async {
    final savedWeights = await _getWeightUsecase.getWeightsFromPastDays(
      widget.day,
      days,
      includeToday: true,
    );
    final weightsMap = {
      for (final entry in savedWeights)
        DateTime(entry.date.year, entry.date.month, entry.date.day):
            entry.weight,
    };

    final rawData = List.generate(days, (i) {
      final date = DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
      ).subtract(Duration(days: i));
      return WeightData(date, weightsMap[date]);
    }).reversed.toList();

    return rawData;
  }

  List<WeightData> _interpolateMissingWeights(List<WeightData> rawData) {
    if (rawData.isEmpty) return rawData;

    final knownIndexes = <int>[
      for (var i = 0; i < rawData.length; i++)
        if (rawData[i].weight != null) i,
    ];

    if (knownIndexes.isEmpty) return rawData;

    return List.generate(rawData.length, (index) {
      final point = rawData[index];
      if (point.weight != null) return point;

      final previousIndex = knownIndexes.lastWhere(
        (knownIndex) => knownIndex < index,
        orElse: () => -1,
      );
      final nextIndex = knownIndexes.firstWhere(
        (knownIndex) => knownIndex > index,
        orElse: () => -1,
      );

      if (previousIndex == -1 && nextIndex == -1) return point;
      if (previousIndex == -1) {
        return WeightData(point.date, rawData[nextIndex].weight);
      }
      if (nextIndex == -1) {
        return WeightData(point.date, rawData[previousIndex].weight);
      }

      final previous = rawData[previousIndex];
      final next = rawData[nextIndex];
      final totalGap = nextIndex - previousIndex;
      final progress = (index - previousIndex) / totalGap;
      final interpolated =
          previous.weight! + (next.weight! - previous.weight!) * progress;
      return WeightData(point.date, interpolated);
    });
  }

  String _rangeLabel(BuildContext context, _WeightChartRange range) {
    final s = S.of(context);
    switch (range) {
      case _WeightChartRange.sevenDays:
        return s.lastSevenDaysLabel;
      case _WeightChartRange.fourteenDays:
        return s.lastFourteenDaysLabel;
      case _WeightChartRange.oneMonth:
        return s.lastMonthLabel;
      case _WeightChartRange.threeMonths:
        return s.lastThreeMonthsLabel;
      case _WeightChartRange.sixMonths:
        return s.lastSixMonthsLabel;
      case _WeightChartRange.oneYear:
        return s.lastYearLabel;
      case _WeightChartRange.all:
        return s.allTimeLabel;
    }
  }

  DateTimeIntervalType _xAxisIntervalType(_WeightChartRange range) {
    switch (range) {
      case _WeightChartRange.sevenDays:
      case _WeightChartRange.fourteenDays:
      case _WeightChartRange.oneMonth:
      case _WeightChartRange.threeMonths:
        return DateTimeIntervalType.days;
      case _WeightChartRange.sixMonths:
      case _WeightChartRange.oneYear:
      case _WeightChartRange.all:
        return DateTimeIntervalType.months;
    }
  }

  double _xAxisInterval(_WeightChartRange range, int pointCount) {
    switch (range) {
      case _WeightChartRange.sevenDays:
        return 2;
      case _WeightChartRange.fourteenDays:
        return 4;
      case _WeightChartRange.oneMonth:
        return 10;
      case _WeightChartRange.threeMonths:
        return 30;
      case _WeightChartRange.sixMonths:
        return 2;
      case _WeightChartRange.oneYear:
        return 3;
      case _WeightChartRange.all:
        return pointCount > 730 ? 6 : 3;
    }
  }

  DateFormat _dateFormat(_WeightChartRange range) {
    switch (range) {
      case _WeightChartRange.sevenDays:
      case _WeightChartRange.fourteenDays:
      case _WeightChartRange.oneMonth:
        return DateFormat('dd/MM');
      case _WeightChartRange.threeMonths:
      case _WeightChartRange.sixMonths:
      case _WeightChartRange.oneYear:
      case _WeightChartRange.all:
        return DateFormat('MMM yy');
    }
  }

  List<WeightData> _displayData(List<WeightData> rawData) {
    return rawData
        .map(
          (point) => WeightData(
            point.date,
            point.weight == null ? null : _displayWeight(point.weight!),
          ),
        )
        .toList();
  }

  List<WeightData> _recordedDisplayData(List<WeightData> rawData) {
    return rawData
        .where((point) => point.weight != null)
        .map(
          (point) => WeightData(
            point.date,
            _displayWeight(point.weight!),
          ),
        )
        .toList();
  }

  double _safeAverage(List<WeightData> chartData) {
    final weights = chartData
        .where((point) => point.weight != null)
        .map((point) => point.weight!)
        .toList();
    if (weights.isEmpty) return _displayWeight(widget.averageWeight);
    return weights.reduce((a, b) => a + b) / weights.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: FutureBuilder<List<WeightData>>(
        future: _chartDataFuture,
        initialData: _selectedRange == _WeightChartRange.sevenDays
            ? widget.initialData
            : null,
        builder: (context, snapshot) {
          final rawData = snapshot.data ?? widget.initialData;
          final chartData = _displayData(_interpolateMissingWeights(rawData));
          final recordedData = _recordedDisplayData(rawData);
          final isDenseRange = chartData.length > 31;
          final displayedAverage = _safeAverage(chartData);
          final yValues = chartData
              .where((point) => point.weight != null)
              .map((point) => point.weight!)
              .toList();
          final minWeight = yValues.isEmpty
              ? displayedAverage - 2
              : yValues.reduce((a, b) => a < b ? a : b);
          final maxWeight = yValues.isEmpty
              ? displayedAverage + 2
              : yValues.reduce((a, b) => a > b ? a : b);
          final paddedMin = ((minWeight - 0.8) * 2).floor() / 2;
          final paddedMax = ((maxWeight + 0.8) * 2).ceil() / 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    S.of(context).evolutionLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  _RangeDropdown(
                    selectedRange: _selectedRange,
                    labelBuilder: (range) => _rangeLabel(context, range),
                    onChanged: (range) {
                      if (range == null || range == _selectedRange) return;
                      setState(() {
                        _selectedRange = range;
                        _chartDataFuture = _loadChartData(range);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 230,
                child: SfCartesianChart(
                  margin: EdgeInsets.zero,
                  enableAxisAnimation: false,
                  plotAreaBorderWidth: 0,
                  primaryXAxis: DateTimeAxis(
                    dateFormat: _dateFormat(_selectedRange),
                    intervalType: _xAxisIntervalType(_selectedRange),
                    interval: _xAxisInterval(_selectedRange, chartData.length),
                    majorTickLines: const MajorTickLines(size: 0),
                    majorGridLines: MajorGridLines(
                      width: 0.7,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.14),
                    ),
                    axisLine: const AxisLine(width: 0),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    labelIntersectAction: AxisLabelIntersectAction.hide,
                    maximum: chartData.last.date.add(const Duration(hours: 12)),
                    minimum: chartData.first.date
                        .subtract(const Duration(hours: 12)),
                  ),
                  primaryYAxis: NumericAxis(
                    interval: 0.5,
                    numberFormat: NumberFormat('0.#'),
                    maximum: paddedMax == paddedMin ? paddedMax + 1 : paddedMax,
                    minimum: paddedMax == paddedMin ? paddedMin - 1 : paddedMin,
                    majorTickLines: const MajorTickLines(size: 0),
                    majorGridLines: MajorGridLines(
                      width: 0,
                      color: colorScheme.outlineVariant.withValues(alpha: 0),
                    ),
                    axisLine: const AxisLine(width: 0),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: !isDenseRange,
                    canShowMarker: false,
                    color: colorScheme.surface.withValues(alpha: 0),
                    elevation: 0,
                    builder: (data, point, series, pointIndex, seriesIndex) {
                      final weightPoint = data as WeightData;
                      final unit = widget.usesImperialUnits
                          ? S.of(context).lbsLabel
                          : S.of(context).kgLabel;
                      return _WeightChartTooltip(
                        date: weightPoint.date,
                        weight: weightPoint.weight ?? 0,
                        unit: unit,
                      );
                    },
                  ),
                  onTooltipRender: (args) {
                    if (args.seriesIndex != 1) {
                      args.header = '';
                      args.text = '';
                    }
                  },
                  trackballBehavior: TrackballBehavior(
                    enable: isDenseRange,
                    activationMode: ActivationMode.singleTap,
                    tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
                    lineType: TrackballLineType.vertical,
                    lineWidth: 0.8,
                    lineColor: colorScheme.primary.withValues(alpha: 0.20),
                    lineDashArray: const [4, 4],
                    markerSettings: TrackballMarkerSettings(
                      markerVisibility: TrackballVisibilityMode.visible,
                      color: colorScheme.primary,
                      borderColor: colorScheme.surface,
                      borderWidth: 2,
                      height: 9,
                      width: 9,
                    ),
                    tooltipSettings: InteractiveTooltip(
                      color: colorScheme.surface.withValues(alpha: 0),
                      borderWidth: 0,
                    ),
                    builder: (context, details) {
                      final point = details.point;
                      final date = point?.x;
                      final weight = point?.y;
                      if (date is! DateTime || weight is! num) {
                        return const SizedBox.shrink();
                      }
                      final unit = widget.usesImperialUnits
                          ? S.of(context).lbsLabel
                          : S.of(context).kgLabel;
                      return _WeightChartTooltip(
                        date: date,
                        weight: weight.toDouble(),
                        unit: unit,
                      );
                    },
                  ),
                  series: <CartesianSeries<WeightData, DateTime>>[
                    SplineAreaSeries<WeightData, DateTime>(
                      xValueMapper: (WeightData point, _) => point.date,
                      yValueMapper: (WeightData point, _) => point.weight,
                      dataSource: chartData,
                      enableTooltip: false,
                      splineType: SplineType.monotonic,
                      animationDuration: 0,
                      borderColor: colorScheme.primary,
                      borderWidth: isDenseRange ? 2.4 : 2.8,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withValues(
                            alpha: isDenseRange ? 0.20 : 0.24,
                          ),
                          colorScheme.primary.withValues(
                            alpha: isDenseRange ? 0.075 : 0.09,
                          ),
                          colorScheme.primary.withValues(alpha: 0.015),
                        ],
                        stops: const [0, 0.58, 1],
                      ),
                      markerSettings: const MarkerSettings(isVisible: false),
                    ),
                    ScatterSeries<WeightData, DateTime>(
                      xValueMapper: (WeightData point, _) => point.date,
                      yValueMapper: (WeightData point, _) => point.weight,
                      dataSource: recordedData,
                      enableTooltip: true,
                      enableTrackball: false,
                      animationDuration: 0,
                      color: colorScheme.primary,
                      markerSettings: MarkerSettings(
                        isVisible:
                            recordedData.isNotEmpty && chartData.length <= 31,
                        width: _selectedRange == _WeightChartRange.sevenDays
                            ? 11
                            : 7,
                        height: _selectedRange == _WeightChartRange.sevenDays
                            ? 11
                            : 7,
                        color: colorScheme.primary,
                        borderColor: colorScheme.surface,
                        borderWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeleteWeightCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteWeightCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorColor = colorScheme.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              errorColor.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.18 : 0.10,
              ),
              colorScheme.surface,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: errorColor.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: errorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).deleteWeightCardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: errorColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        S.of(context).deleteWeightCardSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: errorColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightHistoryCard extends StatefulWidget {
  final DateTime day;
  final bool usesImperialUnits;
  final UserWeightGoalEntity userWeightGoal;

  const _WeightHistoryCard({
    required this.day,
    required this.usesImperialUnits,
    required this.userWeightGoal,
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
        oldWidget.usesImperialUnits != widget.usesImperialUnits ||
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
      final pastWeights = await _getWeightUsecase.getWeightsFromPastDays(
        weight.date,
        7,
      );
      final delta = pastWeights.isEmpty
          ? null
          : weight.weight -
              (pastWeights.map((entry) => entry.weight).reduce(
                        (value, element) => value + element,
                      ) /
                  pastWeights.length);
      entries.add(_WeightHistoryEntry(weight: weight, delta: delta));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unit = widget.usesImperialUnits
        ? S.of(context).lbsLabel
        : S.of(context).kgLabel;

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
              _SurfaceCard(
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
            else
              _WeightHistoryListCard(
                entries: entries,
                unit: unit,
                usesImperialUnits: widget.usesImperialUnits,
                userWeightGoal: widget.userWeightGoal,
              ),
          ],
        );
      },
    );
  }
}

class _WeightHistoryListCard extends StatelessWidget {
  final List<_WeightHistoryEntry> entries;
  final String unit;
  final bool usesImperialUnits;
  final UserWeightGoalEntity userWeightGoal;

  const _WeightHistoryListCard({
    required this.entries,
    required this.unit,
    required this.usesImperialUnits,
    required this.userWeightGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _WeightHistoryTile(
            entry: entries[index],
            unit: unit,
            usesImperialUnits: usesImperialUnits,
            userWeightGoal: userWeightGoal,
          ),
          if (index != entries.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _WeightHistoryTile extends StatelessWidget {
  final _WeightHistoryEntry entry;
  final String unit;
  final bool usesImperialUnits;
  final UserWeightGoalEntity userWeightGoal;

  const _WeightHistoryTile({
    required this.entry,
    required this.unit,
    required this.usesImperialUnits,
    required this.userWeightGoal,
  });

  double _displayWeight(double weightKg) {
    return usesImperialUnits ? UnitCalc.kgToLbs(weightKg) : weightKg;
  }

  Color _variationColor(BuildContext context, double deltaKg) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGood = switch (userWeightGoal) {
      UserWeightGoalEntity.loseWeight => deltaKg < 0,
      UserWeightGoalEntity.gainWeight => deltaKg > 0,
      UserWeightGoalEntity.maintainWeight => deltaKg.abs() <= 0.2,
    };
    return isGood ? lunchColor : colorScheme.error;
  }

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
    final dateLabel = _capitalizeFirst(
      DateFormat('EEEE d MMMM', locale).format(entry.weight.date),
    );
    final deltaKg = entry.delta;
    final displayedDelta = deltaKg == null ? null : _displayWeight(deltaKg);
    final variationColor = deltaKg == null
        ? colorScheme.onSurfaceVariant
        : _variationColor(context, deltaKg);

    return _SurfaceCard(
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
                      '${_formatWeight(_displayWeight(entry.weight.weight))} $unit',
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
                    icon: deltaKg == null ? null : _variationIcon(deltaKg),
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _WeightHistoryEntry {
  final UserWeightEntity weight;
  final double? delta;

  const _WeightHistoryEntry({
    required this.weight,
    required this.delta,
  });
}

class _WeightChartTooltip extends StatelessWidget {
  final DateTime date;
  final double weight;
  final String unit;

  const _WeightChartTooltip({
    required this.date,
    required this.weight,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = DateFormat(
      'dd MMM',
      Localizations.localeOf(context).toString(),
    ).format(date);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.08),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            RichText(
              text: TextSpan(
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  TextSpan(text: _formatWeight(weight)),
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeDropdown extends StatelessWidget {
  final _WeightChartRange selectedRange;
  final ValueChanged<_WeightChartRange?> onChanged;
  final String Function(_WeightChartRange range) labelBuilder;

  const _RangeDropdown({
    required this.selectedRange,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.06),
          colorScheme.surfaceContainerHighest,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_WeightChartRange>(
          value: selectedRange,
          isDense: true,
          borderRadius: BorderRadius.circular(18),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
          selectedItemBuilder: (context) => _WeightChartRange.values
              .map(
                (range) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(labelBuilder(range), maxLines: 1),
                ),
              )
              .toList(),
          items: _WeightChartRange.values
              .map(
                (range) => DropdownMenuItem<_WeightChartRange>(
                  value: range,
                  child: Text(labelBuilder(range)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _SurfaceCard({
    required this.child,
    required this.padding,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class AddWeightScreenArguments {
  final DateTime day;
  final bool isReadOnly;

  AddWeightScreenArguments({required this.day, required this.isReadOnly});
}

class WeightData {
  final DateTime date;
  final double? weight;

  WeightData(this.date, this.weight);
}

class WeightSummary {
  final double averageWeight;
  final double lastRecordedWeight;
  final double targetWeight;
  final UserWeightGoalEntity userWeightGoal;
  final bool usesImperialUnits;
  final List<WeightData> weightDataList;

  WeightSummary({
    required this.averageWeight,
    required this.lastRecordedWeight,
    required this.targetWeight,
    required this.userWeightGoal,
    required this.usesImperialUnits,
    required this.weightDataList,
  });
}
