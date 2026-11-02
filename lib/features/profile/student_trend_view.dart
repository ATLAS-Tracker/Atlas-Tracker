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

/// Last [length] days ending today, from the student's Supabase rows.
/// A day counts as logged only with calories > 0, as in the day view.
TrendData trendDataFrom(Map<String, Map<String, dynamic>> macros, int length) {
  final today = _dateOnly(DateTime.now());
  final days = <TrendDay>[];
  final dayGoals = <Map<String, dynamic>?>[];
  for (var i = length - 1; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
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

String _signedNum(double value, int decimals, String locale) {
  final text =
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals)
          .format(value.abs());
  if (value.abs() < 0.5 * math.pow(10, -decimals)) return text;
  return value > 0 ? '+$text' : '−$text';
}

class _TrendView extends StatefulWidget {
  final StudentMacrosLoaded state;

  const _TrendView({required this.state});

  @override
  State<_TrendView> createState() => _TrendViewState();
}

class _TrendViewState extends State<_TrendView> {
  static const _periods = [7, 14, 30, 90];
  int _period = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = trendDataFrom(widget.state.macros, _periods[_period]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrendPillSelector(
          labels: [
            s.trendPeriod7d,
            s.trendPeriod14d,
            s.trendPeriod1m,
            s.trendPeriod3m
          ],
          selectedIndex: _period,
          onSelected: (i) => setState(() => _period = i),
        ),
        const SizedBox(height: 12),
        _TrendStats(data: data),
        const SizedBox(height: 12),
        _TrendChartCard(data: data),
        const SizedBox(height: 12),
        _TrendMacrosCard(data: data),
      ],
    );
  }
}

/// Compact pill selector (period filter, chart metric).
class TrendPillSelector extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TrendPillSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selectedIndex,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? atlasBrandGradientColors.first
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(labels[i],
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: i == selectedIndex
                                ? Colors.white
                                : colors.onSurfaceVariant)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendStats extends StatelessWidget {
  final TrendData data;

  const _TrendStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final weighIns = data.days.where((d) => d.weight != null).toList();
    final logged = data.days.where((d) => d.kcal != null).length;
    final total = data.days.length;
    final avgKcal = _avg(data.days.map((d) => d.kcal));
    final kcalFormat = NumberFormat.decimalPattern(locale);

    final String weightValue;
    final IconData? weightTrend;
    if (weighIns.length < 2) {
      weightValue = '—';
      weightTrend = null;
    } else {
      final delta = weighIns.last.weight! - weighIns.first.weight!;
      weightValue = '${_signedNum(delta, 1, locale)} ${s.kgLabel}';
      // Direction only, no good/bad colour: goals differ between students.
      weightTrend = delta.abs() < 0.05
          ? Icons.trending_flat_rounded
          : delta > 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TrendStatCard(
              icon: Icons.monitor_weight_outlined,
              label: s.weightLabel,
              value: weightValue,
              trailing: weightTrend,
              detail: weighIns.isEmpty
                  ? s.trendNotEnoughDataLabel
                  : weighIns.length == 1
                      ? '${s.trendNotEnoughDataLabel} · ${weighIns.last.weight!.toStringAsFixed(1)} ${s.kgLabel}'
                      : '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1).format(weighIns.last.weight)} ${s.kgLabel}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TrendStatCard(
              icon: Icons.event_available_outlined,
              label: s.studentConsistencyLabel,
              value: s.trendDaysTracked(logged, total),
              detail: '${(logged / total * 100).round()} %',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TrendStatCard(
              icon: Icons.local_fire_department_outlined,
              label: s.trendAvgCaloriesLabel,
              value: avgKcal == null
                  ? '—'
                  : '${kcalFormat.format(avgKcal.round())} ${s.kcalLabel}',
              detail: avgKcal == null
                  ? s.trendNotEnoughDataLabel
                  : data.calorieGoal > 0
                      ? s.trendVsGoal(
                          '${_signedNum(avgKcal - data.calorieGoal, 0, locale)} ${s.kcalLabel}')
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final IconData? trailing;

  const _TrendStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final valueStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    final detailStyle = theme.textTheme.labelSmall
        ?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: colors.primary),
              ),
              const Spacer(),
              if (trailing != null)
                Icon(trailing, size: 18, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          // Invisible line keeps full height when a long value (e.g.
          // "21/30 jours") gets scaled down by the FittedBox.
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Text(' ', style: valueStyle),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: valueStyle),
              ),
            ],
          ),
          const Spacer(),
          // Always reserve two lines so card height doesn't change with the
          // period (a detail wrapping on 3 mois used to grow every card).
          Stack(
            children: [
              Text('\n', maxLines: 2, style: detailStyle),
              if (detail != null)
                Text(detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: detailStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendChartCard extends StatefulWidget {
  final TrendData data;

  const _TrendChartCard({required this.data});

  @override
  State<_TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<_TrendChartCard> {
  int _metric = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget metric(int i, String label) {
      final selected = i == _metric;
      return Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: () => setState(() => _metric = i),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? colors.primary : colors.onSurfaceVariant)),
          ),
        ),
      );
    }

    return _InfoCard(
      title: s.trendEvolutionTitle,
      icon: Icons.show_chart_rounded,
      fill: false,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        metric(0, s.weightLabel),
        metric(1, s.caloriesLabel),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _metric == 0
                  ? _WeightChart(key: const ValueKey('w'), data: widget.data)
                  : _CaloriesChart(key: const ValueKey('c'), data: widget.data),
            ),
          ),
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

class _ChartTooltip extends StatelessWidget {
  final DateTime date;
  final List<String> lines;

  const _ChartTooltip({required this.date, required this.lines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              DateFormat.MMMd(Localizations.localeOf(context).toString())
                  .format(date),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: colors.onInverseSurface)),
          for (final line in lines)
            Text(line,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onInverseSurface,
                    fontWeight: FontWeight.w800)),
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
    numberFormat: NumberFormat('0.#'),
    majorTickLines: const MajorTickLines(size: 0),
    majorGridLines: MajorGridLines(
        width: 0.7,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
    axisLine: const AxisLine(width: 0),
    labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
  );
}

class _WeightChart extends StatelessWidget {
  final TrendData data;

  const _WeightChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    // Only real weigh-ins: no interpolated points.
    final points = data.days.where((d) => d.weight != null).toList();
    if (points.isEmpty) return _ChartEmpty(s.noWeighInLabel);

    return Column(
      children: [
        Expanded(
          child: SfCartesianChart(
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            primaryXAxis: _dateAxis(context, data),
            primaryYAxis: _valueAxis(context),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: Colors.transparent,
              elevation: 0,
              builder: (d, _, __, ___, ____) => _ChartTooltip(
                date: (d as TrendDay).date,
                lines: ['${d.weight!.toStringAsFixed(1)} ${s.kgLabel}'],
              ),
            ),
            series: [
              LineSeries<TrendDay, DateTime>(
                dataSource: points,
                xValueMapper: (d, _) => d.date,
                yValueMapper: (d, _) => d.weight,
                color: colors.primary,
                width: 2.5,
                animationDuration: 600,
                markerSettings: MarkerSettings(
                  isVisible: points.length <= 31,
                  height: 6,
                  width: 6,
                  color: colors.primary,
                  borderColor: colors.surface,
                  borderWidth: 1.5,
                ),
                trendlines: [
                  if (points.length >= 5)
                    Trendline(
                      type: TrendlineType.linear,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      width: 1.2,
                      dashArray: const [4, 4],
                      enableTooltip: false,
                    ),
                ],
              ),
            ],
          ),
        ),
        if (points.length == 1)
          Text(s.trendSingleWeighInLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CaloriesChart extends StatelessWidget {
  final TrendData data;

  const _CaloriesChart({super.key, required this.data});

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
      return _ChartTooltip(date: day.date, lines: [
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
            Transform.translate(
              offset: const Offset(0, -10),
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
