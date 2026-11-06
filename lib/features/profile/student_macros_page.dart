import 'package:opennutritracker/core/presentation/widgets/atlas_surface_card.dart';
import 'package:opennutritracker/core/presentation/widgets/weight_chart_card.dart';
import 'package:opennutritracker/core/presentation/widgets/chart_controls.dart';
import 'package:opennutritracker/core/domain/entity/weight_snapshot.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_tab_bar.dart';
import 'package:opennutritracker/core/presentation/widgets/error_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/student_macros_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'set_student_macros_page.dart';

part 'student_trend_view.dart';

final _dayKeyFormat = DateFormat('yyyy-MM-dd');

String _dayKey(DateTime day) => _dayKeyFormat.format(day);

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

double? _num(Map<String, dynamic>? data, String key) =>
    (data?[key] as num?)?.toDouble();

WeightSnapshot _studentWeightSnapshot(
        Map<String, Map<String, dynamic>> macros, DateTime day) =>
    WeightSnapshot.at(day, [
      for (final entry in macros.entries)
        if (_num(entry.value, 'weight') != null)
          UserWeightEntity(
              id: entry.key,
              date: DateTime.parse(entry.key),
              weight: _num(entry.value, 'weight')!),
    ]);

class StudentMacrosPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentMacrosPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentMacrosBloc(locator<SupabaseClient>())
        ..add(LoadStudentMacrosEvent(studentId)),
      child: _StudentMacrosView(studentId: studentId, studentName: studentName),
    );
  }
}

class _StudentMacrosView extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _StudentMacrosView({
    required this.studentId,
    required this.studentName,
  });

  @override
  State<_StudentMacrosView> createState() => _StudentMacrosViewState();
}

class _StudentMacrosViewState extends State<_StudentMacrosView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: s.setMacrosLabel,
            onPressed: () => _openSetMacrosPage(context),
          ),
        ],
      ),
      body: BlocBuilder<StudentMacrosBloc, StudentMacrosState>(
        builder: (context, state) {
          if (state is StudentMacrosError) {
            return ErrorDialog(
                errorText: s.studentLoadError,
                onRefreshPressed: () => context
                    .read<StudentMacrosBloc>()
                    .add(LoadStudentMacrosEvent(widget.studentId)));
          }
          if (state is! StudentMacrosLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () {
              final done = Completer<void>();
              context
                  .read<StudentMacrosBloc>()
                  .add(LoadStudentMacrosEvent(widget.studentId, done: done));
              return done.future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Largeur max 560 sur tablette, comme « Définir les macros ».
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AtlasTabBar(
                          labels: [s.studentDayTab, s.studentTrendTab],
                          selectedIndex: _tab,
                          onSelected: (i) => setState(() => _tab = i),
                        ),
                        const SizedBox(height: 16),
                        if (_tab == 0)
                          _DayView(state: state)
                        else
                          _TrendView(state: state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSetMacrosPage(BuildContext context) async {
    final bloc = context.read<StudentMacrosBloc>();
    final state = bloc.state;
    if (state is! StudentMacrosLoaded) return;

    final data = _latestGoals(state.macros, state.selectedDate);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetStudentMacrosPage(
          studentId: widget.studentId,
          initialCarbs: (data?['carbsGoal'] as num?)?.round() ?? 0,
          initialFat: (data?['fatGoal'] as num?)?.round() ?? 0,
          initialProtein: (data?['proteinGoal'] as num?)?.round() ?? 0,
        ),
      ),
    );

    if (result != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).macroGoalsSaved)));
      }
      final startDate = result['startDate'] as String?;
      if (startDate != null) {
        bloc.add(
          UpdateDayMacrosEvent(startDate, {
            'carbsGoal': (result['carbsGoal'] as num).toDouble(),
            'fatGoal': (result['fatGoal'] as num).toDouble(),
            'proteinGoal': (result['proteinGoal'] as num).toDouble(),
            'calorieGoal': (result['calorieGoal'] as num).toDouble(),
          }),
        );
      }
    }
  }
}

/// Goals in force on [day]: that day's row, else the latest earlier row with goals.
Map<String, dynamic>? _latestGoals(
    Map<String, Map<String, dynamic>> macros, DateTime day) {
  final dayKey = _dayKey(day);
  String? bestKey;
  for (final entry in macros.entries) {
    if (entry.key.compareTo(dayKey) > 0) continue;
    if (entry.value['calorieGoal'] == null &&
        entry.value['proteinGoal'] == null) {
      continue;
    }
    if (bestKey == null || entry.key.compareTo(bestKey) > 0) {
      bestKey = entry.key;
    }
  }
  return bestKey == null ? null : macros[bestKey];
}

class _DayView extends StatelessWidget {
  final StudentMacrosLoaded state;

  const _DayView({required this.state});

  @override
  Widget build(BuildContext context) {
    final day = _dateOnly(state.selectedDate);
    final data = state.macros[_dayKey(day)];
    final goals = _latestGoals(state.macros, day);
    // Comme la tendance : une journée compte seulement avec des kcal > 0.
    final logged = (_num(data, 'caloriesTracked') ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayNavigator(selectedDate: day),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _DayWeightCard(
                    weight: _num(data, 'weight'),
                    targetWeight: state.targetWeight),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: StudentEnergyCard(
                  consumed: logged ? _num(data, 'caloriesTracked') : null,
                  goal: _num(data, 'calorieGoal') ??
                      _num(goals, 'calorieGoal') ??
                      0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DayMacrosCard(data: logged ? data : null, goals: goals),
      ],
    );
  }
}

class _DayNavigator extends StatelessWidget {
  final DateTime selectedDate;

  const _DayNavigator({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final bloc = context.read<StudentMacrosBloc>();
    final today = _dateOnly(DateTime.now());
    final diff = today.difference(selectedDate).inDays;
    final label = switch (diff) {
      0 => s.todayLabel,
      1 => s.yesterdayLabel,
      _ => toBeginningOfSentenceCase(
          DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString())
              .format(selectedDate)),
    };

    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: MaterialLocalizations.of(context).previousPageTooltip,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => bloc.add(
              ChangeDateEvent(selectedDate.subtract(const Duration(days: 1)))),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) bloc.add(ChangeDateEvent(picked));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: MaterialLocalizations.of(context).nextPageTooltip,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: diff > 0
              ? () => bloc.add(
                  ChangeDateEvent(selectedDate.add(const Duration(days: 1))))
              : null,
        ),
      ],
    );
  }
}

/// Metric card: icon badge + title row, then content. With [fill] (square
/// cards) the content is pinned to the bottom of the available height.
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool fill;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: atlasCardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconBadge(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          SizedBox(height: fill ? 10 : 16),
          if (fill)
            Expanded(
              child: Align(alignment: Alignment.bottomLeft, child: child),
            )
          else
            child,
        ],
      ),
    );
  }
}

/// Card/section icon: small tinted rounded square.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const _IconBadge(this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 16, color: tint),
    );
  }
}

class _DayWeightCard extends StatelessWidget {
  final double? weight;
  final double? targetWeight;

  const _DayWeightCard({required this.weight, required this.targetWeight});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final oneDecimal =
        NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1);
    final target = targetWeight ?? 0;

    return _InfoCard(
      title: s.weightLabel,
      icon: Icons.monitor_weight_outlined,
      // Tout le bloc rétrécit d'un coup sur petit écran / grand texte.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                  text: weight == null ? '—' : oneDecimal.format(weight),
                  style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: weight == null
                          ? colors.onSurfaceVariant.withValues(alpha: 0.5)
                          : colors.onSurface)),
              if (weight != null)
                TextSpan(
                    text: ' ${s.kgLabel}',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
            ])),
            if (weight != null && target > 0) ...[
              const SizedBox(height: 4),
              Text(
                  s.trendVsGoal(
                      '${formatNumber(weight! - target, decimals: 1, signed: true)} ${s.kgLabel}'),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cross-fades between [first] and [second] without changing layout size.
class _FadeToggle extends StatelessWidget {
  final bool showSecond;
  final Widget first;
  final Widget second;
  final AlignmentGeometry alignment;

  const _FadeToggle({
    required this.showSecond,
    required this.first,
    required this.second,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 250);
    return Stack(
      alignment: alignment,
      children: [
        AnimatedOpacity(
            opacity: showSecond ? 0 : 1,
            duration: duration,
            curve: Curves.easeInOut,
            child: first),
        AnimatedOpacity(
            opacity: showSecond ? 1 : 0,
            duration: duration,
            curve: Curves.easeInOut,
            child: second),
      ],
    );
  }
}

String _percent(double value, double goal) =>
    '${goal > 0 ? (value / goal * 100).round() : 0} %';

/// Energy ring of the coach's day view; tap toggles kcal and %.
class StudentEnergyCard extends StatefulWidget {
  /// Null quand l'élève n'a rien saisi ce jour-là.
  final double? consumed;
  final double goal;

  const StudentEnergyCard(
      {super.key, required this.consumed, required this.goal});

  @override
  State<StudentEnergyCard> createState() => StudentEnergyCardState();
}

class StudentEnergyCardState extends State<StudentEnergyCard> {
  bool _showPercent = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final consumed = widget.consumed ?? 0;
    final logged = widget.consumed != null;
    final goal = widget.goal;
    final progress = goal > 0 ? consumed / goal : 0.0;
    final numberStyle = theme.textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1);

    // Tap toggles the ring's centre between kcal and % of the goal.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: logged ? () => setState(() => _showPercent = !_showPercent) : null,
      child: _InfoCard(
        title: toBeginningOfSentenceCase(s.energyLabel),
        icon: Icons.local_fire_department_outlined,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => CustomPaint(
                painter: _RingPainter(
                  progress: value,
                  color: exceedsNutritionGoal(consumed, goal)
                      ? colors.error
                      : colors.primary,
                  track: colors.primary.withValues(alpha: 0.12),
                ),
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: !logged
                      ? Text('—',
                          style: numberStyle?.copyWith(
                              color: colors.onSurfaceVariant
                                  .withValues(alpha: 0.5)))
                      : _FadeToggle(
                          showSecond: _showPercent,
                          first: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(formatNumber(consumed), style: numberStyle),
                              if (consumed.round() > goal.round())
                                Text(calorieBalanceLabel(s, goal, consumed),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(color: colors.error)),
                              Text(s.kcalLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      height: 1)),
                            ],
                          ),
                          second: Text(_percent(consumed, goal),
                              style: numberStyle),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final arcRect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, paint..color = track);
    if (progress <= 0) return;
    canvas.drawArc(arcRect, -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0), false, paint..color = color);
    if (progress > 1) {
      canvas.drawArc(
          arcRect.deflate(stroke + 3),
          -math.pi / 2,
          2 * math.pi * (progress - 1).clamp(0.0, 1.0),
          false,
          paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class _DayMacrosCard extends StatefulWidget {
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? goals;

  const _DayMacrosCard({required this.data, required this.goals});

  @override
  State<_DayMacrosCard> createState() => _DayMacrosCardState();
}

class _DayMacrosCardState extends State<_DayMacrosCard> {
  bool _showPercent = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = widget.data;
    double goal(String key) => _num(data, key) ?? _num(widget.goals, key) ?? 0;
    final rows = [
      (s.carbsLabel, MacroVisuals.carbs, 'carbsTracked', 'carbsGoal'),
      (s.fatLabel, MacroVisuals.fats, 'fatTracked', 'fatGoal'),
      (s.proteinLabel, MacroVisuals.proteins, 'proteinTracked', 'proteinGoal'),
    ];

    // Tap toggles every row between grams and % of the goal.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showPercent = !_showPercent),
      child: _InfoCard(
        title: s.dayMacrosTitle,
        icon: Icons.pie_chart_outline_rounded,
        fill: false,
        child: data == null
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _ChartEmpty(s.studentNoEntryLabel),
              )
            : Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _MacroProgressRow(
                      label: rows[i].$1,
                      visual: rows[i].$2,
                      tracked: _num(data, rows[i].$3) ?? 0,
                      goal: goal(rows[i].$4),
                      showPercent: _showPercent,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _MacroProgressRow extends StatelessWidget {
  final String label;
  final MacroVisual visual;
  final double tracked;
  final double goal;
  final bool showPercent;

  const _MacroProgressRow({
    required this.label,
    required this.visual,
    required this.tracked,
    required this.goal,
    required this.showPercent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final gram = S.of(context).gramUnit;
    final valueStyle =
        theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: visual.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: MacroIcon(visual: visual, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  _FadeToggle(
                    showSecond: showPercent,
                    alignment: Alignment.centerRight,
                    first: Text.rich(TextSpan(children: [
                      TextSpan(text: formatNumber(tracked), style: valueStyle),
                      TextSpan(
                          text: ' / ${formatNumber(goal)} $gram',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ])),
                    second: Text(_percent(tracked, goal), style: valueStyle),
                  ),
                ],
              ),
              if (!showPercent && goal > 0 && tracked > goal)
                Text(_percent(tracked, goal),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: exceedsNutritionGoal(tracked, goal)
                            ? colors.error
                            : colors.onSurfaceVariant)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: 0,
                      end: goal > 0 ? (tracked / goal).clamp(0.0, 1.0) : 0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    color: goal > 0 && exceedsNutritionGoal(tracked, goal)
                        ? colors.error
                        : visual.color,
                    backgroundColor: visual.color.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
