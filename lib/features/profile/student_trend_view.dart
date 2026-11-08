part of 'student_macros_page.dart';

/// One day of the trend period. Null fields mean "nothing recorded", never 0.
class TrendDay {
  final DateTime date;
  final double? kcal;
  final double? weight;
  final double? carbs;
  final double? fat;
  final double? protein;

  /// Objectif kcal en vigueur ce jour-là (0 sans objectif).
  final double calorieGoal;

  const TrendDay(this.date,
      {this.kcal,
      this.weight,
      this.carbs,
      this.fat,
      this.protein,
      this.calorieGoal = 0});
}

class TrendData {
  final List<TrendDay> days;

  /// Objectifs moyens des jours saisis : chaque jour est comparé à l'objectif
  /// qui s'appliquait ce jour-là, même si le coach l'a changé en cours de période.
  final double calorieGoal;
  final double carbsGoal;
  final double fatGoal;
  final double proteinGoal;

  const TrendData({
    required this.days,
    required this.calorieGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.proteinGoal,
  });
}

/// Last [length] completed civil days, from the student's Supabase rows.
/// A day counts as logged only with calories > 0, as in the day view.
TrendData trendDataFrom(Map<String, Map<String, dynamic>> macros, int length) {
  final today = _dateOnly(DateTime.now());
  final days = <TrendDay>[];
  final dayGoals = <Map<String, dynamic>?>[];
  for (var i = length - 1; i >= 0; i--) {
    final date = DateTime(today.year, today.month, today.day - i - 1);
    final row = macros[_dayKey(date)];
    // ponytail: _latestGoals parcourt tout l'historique pour chaque jour
    // (90 × ~365 lignes), trier les clés une fois si ça devient lent.
    final goals = _latestGoals(macros, date);
    double goal(String key) => _num(row, key) ?? _num(goals, key) ?? 0;
    final logged = (_num(row, 'caloriesTracked') ?? 0) > 0;
    days.add(TrendDay(
      date,
      kcal: logged ? _num(row, 'caloriesTracked') : null,
      weight: _num(row, 'weight'),
      carbs: logged ? _num(row, 'carbsTracked') : null,
      fat: logged ? _num(row, 'fatTracked') : null,
      protein: logged ? _num(row, 'proteinTracked') : null,
      calorieGoal: goal('calorieGoal'),
    ));
    if (logged) {
      dayGoals.add({
        for (final k in ['calorieGoal', 'carbsGoal', 'fatGoal', 'proteinGoal'])
          k: goal(k),
      });
    }
  }
  // Sans jour saisi, on retombe sur l'objectif actuel.
  if (dayGoals.isEmpty) dayGoals.add(_latestGoals(macros, today));
  double avgGoal(String key) => _avg(dayGoals.map((g) => _num(g, key))) ?? 0;
  return TrendData(
    days: days,
    calorieGoal: avgGoal('calorieGoal'),
    carbsGoal: avgGoal('carbsGoal'),
    fatGoal: avgGoal('fatGoal'),
    proteinGoal: avgGoal('proteinGoal'),
  );
}

double? _avg(Iterable<double?> values) {
  final v = values.whereType<double>().toList();
  return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
}

class _TrendView extends StatefulWidget {
  final StudentMacrosLoaded state;

  const _TrendView({required this.state});

  @override
  State<_TrendView> createState() => _TrendViewState();
}

class _TrendViewState extends State<_TrendView> {
  WeightChartRange _range = WeightChartRange.sevenDays;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = trendDataFrom(widget.state.macros, _range.days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChartSelector(
          labels: [for (final range in WeightChartRange.values) range.label(s)],
          selectedIndex: _range.index,
          onSelected: (i) =>
              setState(() => _range = WeightChartRange.values[i]),
        ),
        const SizedBox(height: 12),
        _TrendStats(
            data: data,
            weightSnapshot: _studentWeightSnapshot(
                widget.state.macros, _dateOnly(DateTime.now()))),
        const SizedBox(height: 12),
        _TrendChartCard(
            range: _range,
            data: TrendData(
              days: [
                ...data.days,
                TrendDay(_dateOnly(DateTime.now()),
                    weight: _num(
                        widget.state.macros[_dayKey(DateTime.now())], 'weight'))
              ],
              calorieGoal: data.calorieGoal,
              carbsGoal: data.carbsGoal,
              fatGoal: data.fatGoal,
              proteinGoal: data.proteinGoal,
            )),
        const SizedBox(height: 12),
        _TrendMacrosCard(data: data),
      ],
    );
  }
}

class _TrendStats extends StatelessWidget {
  final TrendData data;

  final WeightSnapshot weightSnapshot;

  const _TrendStats({required this.data, required this.weightSnapshot});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final logged = data.days.where((d) => d.kcal != null).length;
    final total = data.days.length;
    final avgKcal = _avg(data.days.map((d) => d.kcal));

    final String weightValue;
    final IconData? weightTrend;
    final delta = weightSnapshot.delta;
    if (delta == null) {
      weightValue = '—';
      weightTrend = null;
    } else {
      weightValue =
          '${formatNumber(delta, decimals: 1, signed: true)} ${s.kgLabel}';
      weightTrend = delta.abs() < 0.05
          ? Icons.trending_flat_rounded
          : delta > 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: atlasCardDecoration(Theme.of(context).colorScheme),
      child: Column(
        children: [
          _TrendStatRow(
            icon: Icons.monitor_weight_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            label: s.weightAverageDeltaLabel,
            value: weightValue,
            trailing: weightTrend,
            detail: weightSnapshot.current == null
                ? s.trendNotEnoughDataLabel
                : '${formatNumber(weightSnapshot.current!.weight, decimals: 1)} ${s.kgLabel}',
          ),
          const Divider(height: 1),
          _TrendStatRow(
            icon: Icons.event_available_outlined,
            color: lunchColor,
            progress: logged / total,
            label: s.studentConsistencyLabel,
            value: s.trendDaysTracked(logged, total),
            detail: '${(logged / total * 100).round()} %',
          ),
          const Divider(height: 1),
          _TrendStatRow(
            icon: Icons.local_fire_department_outlined,
            color: breakfastColor,
            label: s.trendAvgCaloriesLabel,
            value: avgKcal == null
                ? '—'
                : '${formatNumber(avgKcal)} ${s.kcalLabel}',
            detail: avgKcal == null
                ? s.trendNotEnoughDataLabel
                : data.calorieGoal > 0
                    ? s.trendVsGoal(
                        '${formatNumber(-remainingCalories(data.calorieGoal, avgKcal), signed: true)} ${s.kcalLabel}')
                    : null,
          ),
        ],
      ),
    );
  }
}

/// One line of the trend summary: badge + label on the left, value and its
/// detail aligned on the right, so every value has the same size.
class _TrendStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final IconData? trailing;
  final Color color;

  /// Mini-jauge sous la valeur (régularité).
  final double? progress;

  const _TrendStatRow({
    required this.icon,
    required this.color,
    this.progress,
    required this.label,
    required this.value,
    this.detail,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _IconBadge(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (trailing != null) ...[
                    Icon(trailing, size: 18, color: color),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(value,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ]),
                if (detail != null)
                  Text(detail!,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: color, fontWeight: FontWeight.w700)),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 5,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartCard extends StatefulWidget {
  final TrendData data;
  final WeightChartRange range;

  const _TrendChartCard({required this.data, required this.range});

  @override
  State<_TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<_TrendChartCard> {
  int _metric = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final selector = ChartSelector(
        style: ChartSelectorStyle.compact,
        labels: [s.weightLabel, s.caloriesLabel],
        selectedIndex: _metric,
        onSelected: (index) => setState(() => _metric = index));
    if (_metric == 0) {
      final points = [
        for (final day in widget.data.days)
          if (day.weight != null) WeightData(day.date, day.weight!)
      ];
      return Column(children: [
        WeightChartCard(data: points, range: widget.range, selector: selector),
        if (points.length == 1)
          Text(s.trendSingleWeighInLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
      ]);
    }
    final theme = Theme.of(context);
    return AtlasSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(s.evolutionLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900)),
              selector,
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 230, child: _CaloriesChart(data: widget.data)),
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  final String message;

  const _ChartEmpty(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined,
              size: 36, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

DateTimeAxis _dateAxis(BuildContext context, TrendData data) {
  final theme = Theme.of(context);
  return DateTimeAxis(
    dateFormat: DateFormat.MMMd(Localizations.localeOf(context).toString()),
    minimum: data.days.first.date.subtract(const Duration(hours: 12)),
    maximum: data.days.last.date.add(const Duration(hours: 12)),
    intervalType: DateTimeIntervalType.days,
    majorTickLines: const MajorTickLines(size: 0),
    majorGridLines: const MajorGridLines(width: 0),
    axisLine: const AxisLine(width: 0),
    labelIntersectAction: AxisLabelIntersectAction.hide,
    labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
  );
}

NumericAxis _valueAxis(BuildContext context,
    {List<PlotBand> plotBands = const [], double? minimum}) {
  final theme = Theme.of(context);
  return NumericAxis(
    minimum: minimum,
    plotBands: plotBands,
    rangePadding: ChartRangePadding.round,
    numberFormat: numberFormatter(decimals: 1),
    majorTickLines: const MajorTickLines(size: 0),
    majorGridLines: MajorGridLines(
        width: 0.7,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
    axisLine: const AxisLine(width: 0),
    labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
  );
}

class _CaloriesChart extends StatelessWidget {
  final TrendData data;

  const _CaloriesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final logged = data.days.where((d) => d.kcal != null).toList();
    if (logged.isEmpty) return _ChartEmpty(s.trendNoDataLabel);

    final goalDays = data.days.where((d) => d.calorieGoal > 0).toList();
    final top = math.max(
            goalDays.isEmpty
                ? 0.0
                : goalDays.map((d) => d.calorieGoal).reduce(math.max),
            logged.map((d) => d.kcal!).reduce(math.max)) *
        1.08;
    final missing = data.days.where((d) => d.kcal == null).toList();

    Widget tooltip(dynamic d, _, __, ___, ____) {
      final day = d as TrendDay;
      return ChartTooltip(inverse: true, date: day.date, lines: [
        day.kcal == null
            ? s.studentNoEntryLabel
            : '${day.kcal!.round()} ${s.kcalLabel}',
        if (day.calorieGoal > 0)
          '${s.trendGoalLabel} ${day.calorieGoal.round()} ${s.kcalLabel}',
      ]);
    }

    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: _dateAxis(context, data),
      primaryYAxis: _valueAxis(context, minimum: 0),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: Colors.transparent,
        elevation: 0,
        builder: tooltip,
      ),
      series: [
        // Days without entries: faint full-height ghost, not a 0 kcal bar.
        ColumnSeries<TrendDay, DateTime>(
          dataSource: missing,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (_, __) => top,
          color: colors.onSurfaceVariant.withValues(alpha: 0.07),
          width: 0.7,
          animationDuration: 0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        ColumnSeries<TrendDay, DateTime>(
          dataSource: logged,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.kcal,
          color: colors.primary,
          pointColorMapper: (day, _) =>
              isWithinNutritionGoal(day.kcal!, day.calorieGoal)
                  ? colors.primary
                  : colors.error,
          width: 0.7,
          animationDuration: 600,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        // Objectif du jour : une marche à chaque changement d'objectif.
        if (goalDays.isNotEmpty)
          StepLineSeries<TrendDay, DateTime>(
            dataSource: goalDays,
            xValueMapper: (d, _) => d.date,
            yValueMapper: (d, _) => d.calorieGoal,
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
            width: 1.5,
            dashArray: const [5, 4],
            animationDuration: 0,
            enableTooltip: false,
          ),
      ],
    );
  }
}

class _TrendMacrosCard extends StatefulWidget {
  final TrendData data;

  const _TrendMacrosCard({required this.data});

  @override
  State<_TrendMacrosCard> createState() => _TrendMacrosCardState();
}

class _TrendMacrosCardState extends State<_TrendMacrosCard> {
  bool _showPercent = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final data = widget.data;
    // Same order and colours as the day view's macros card.
    final rows = [
      (
        s.carbsLabel,
        MacroVisuals.carbs,
        _avg(data.days.map((d) => d.carbs)),
        data.carbsGoal
      ),
      (
        s.fatLabel,
        MacroVisuals.fats,
        _avg(data.days.map((d) => d.fat)),
        data.fatGoal
      ),
      (
        s.proteinLabel,
        MacroVisuals.proteins,
        _avg(data.days.map((d) => d.protein)),
        data.proteinGoal
      ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showPercent = !_showPercent),
      child: _InfoCard(
        title: s.trendMacrosTitle,
        icon: Icons.pie_chart_outline_rounded,
        fill: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(s.trendMacrosSubtitle,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            if (rows.every((r) => r.$3 == null))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _ChartEmpty(s.trendNoDataLabel),
              )
            else
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                _MacroProgressRow(
                  label: rows[i].$1,
                  visual: rows[i].$2,
                  tracked: rows[i].$3 ?? 0,
                  goal: rows[i].$4,
                  showPercent: _showPercent,
                ),
              ],
          ],
        ),
      ),
    );
  }
}
