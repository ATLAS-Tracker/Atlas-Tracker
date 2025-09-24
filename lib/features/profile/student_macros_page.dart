import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/widgets/macro_nutriments_widget.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/student_macros_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'set_student_macros_page.dart';

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

class _StudentMacrosView extends StatelessWidget {
  final String studentId;
  final String studentName;

  const _StudentMacrosView({
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(studentName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSetMacrosPage(context),
        icon: const Icon(Icons.edit_outlined),
        label: Text(S.of(context).setMacrosLabel),
      ),
      body: BlocBuilder<StudentMacrosBloc, StudentMacrosState>(
        builder: (context, state) {
          if (state is StudentMacrosLoading || state is StudentMacrosInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentMacrosError) {
            return Center(
              child: Text('${S.of(context).errorPrefix} ${state.message}'),
            );
          }

          if (state is! StudentMacrosLoaded) {
            return const SizedBox.shrink();
          }

          final dayKey = DateFormat('yyyy-MM-dd').format(state.selectedDate);
          final data = state.macros[dayKey];
          final double calorieGoal =
              (data?['calorieGoal'] as num?)?.toDouble() ?? 0;
          final double caloriesTracked =
              (data?['caloriesTracked'] as num?)?.toDouble() ?? 0;
          final double carbsGoal =
              (data?['carbsGoal'] as num?)?.toDouble() ?? 0;
          final double carbsTracked =
              (data?['carbsTracked'] as num?)?.toDouble() ?? 0;
          final double fatGoal = (data?['fatGoal'] as num?)?.toDouble() ?? 0;
          final double fatTracked =
              (data?['fatTracked'] as num?)?.toDouble() ?? 0;
          final double proteinGoal =
              (data?['proteinGoal'] as num?)?.toDouble() ?? 0;
          final double proteinTracked =
              (data?['proteinTracked'] as num?)?.toDouble() ?? 0;

          final double kcalLeft = calorieGoal - caloriesTracked;
          final double gaugeValue = calorieGoal == 0
              ? 0
              : (caloriesTracked / calorieGoal).clamp(0.0, 1.0);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () =>
                                _goToPreviousDay(context, state.selectedDate),
                          ),
                          InkWell(
                            onTap: () =>
                                _selectDate(context, state.selectedDate),
                            child: Text(
                              DateFormat(
                                'yyyy-MM-dd',
                              ).format(state.selectedDate),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Builder(builder: (context) {
                            final now = DateTime.now();
                            final todayOnly =
                                DateTime(now.year, now.month, now.day);
                            final d = state.selectedDate;
                            final selectedOnly =
                                DateTime(d.year, d.month, d.day);
                            final canGoNext = selectedOnly.isBefore(todayOnly);
                            return IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: canGoNext
                                  ? () => _goToNextDay(
                                        context,
                                        state.selectedDate,
                                      )
                                  : null,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (data == null)
                        Text(S.of(context).noDataToday)
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_up_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                Text(
                                  '${caloriesTracked.toInt()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                Text(
                                  S.of(context).suppliedLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                              ],
                            ),
                            CircularPercentIndicator(
                              radius: 90.0,
                              lineWidth: 13.0,
                              animation: true,
                              percent: gaugeValue,
                              arcType: ArcType.FULL,
                              progressColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              arcBackgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(50),
                              center: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedFlipCounter(
                                    duration: const Duration(
                                      milliseconds: 1000,
                                    ),
                                    value:
                                        kcalLeft.clamp(0, calorieGoal).toInt(),
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          letterSpacing: -1,
                                        ),
                                  ),
                                  Text(
                                    S.of(context).kcalLeftLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                              circularStrokeCap: CircularStrokeCap.round,
                            ),
                          ],
                        ),
                        MacroNutrientsView(
                          totalCarbsIntake: carbsTracked,
                          totalFatsIntake: fatTracked,
                          totalProteinsIntake: proteinTracked,
                          totalCarbsGoal: carbsGoal,
                          totalFatsGoal: fatGoal,
                          totalProteinsGoal: proteinGoal,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<MacroType>(
                            value: state.selectedMacro,
                            onChanged: (value) {
                              if (value != null) {
                                context.read<StudentMacrosBloc>().add(
                                      ChangeMacroTypeEvent(value),
                                    );
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: MacroType.calories,
                                child: Text(S.of(context).caloriesLabel),
                              ),
                              DropdownMenuItem(
                                value: MacroType.carbs,
                                child: Text(S.of(context).carbsLabel),
                              ),
                              DropdownMenuItem(
                                value: MacroType.fat,
                                child: Text(S.of(context).fatLabel),
                              ),
                              DropdownMenuItem(
                                value: MacroType.protein,
                                child: Text(S.of(context).proteinLabel),
                              ),
                              DropdownMenuItem(
                                value: MacroType.weight,
                                child: Text(S.of(context).weightLabel),
                              ),
                            ],
                          ),
                          DropdownButton<TimeRange>(
                            value: state.selectedRange,
                            onChanged: (value) {
                              if (value != null) {
                                context.read<StudentMacrosBloc>().add(
                                      ChangeRangeEvent(value),
                                    );
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: TimeRange.week,
                                child: Text('1W'),
                              ),
                              DropdownMenuItem(
                                value: TimeRange.month,
                                child: Text('1M'),
                              ),
                              DropdownMenuItem(
                                value: TimeRange.threeMonths,
                                child: Text('3M'),
                              ),
                              DropdownMenuItem(
                                value: TimeRange.sixMonths,
                                child: Text('6M'),
                              ),
                              DropdownMenuItem(
                                value: TimeRange.year,
                                child: Text('1Y'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      buildChart(
                        state.macros,
                        state.selectedMacro,
                        state.selectedRange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _goToPreviousDay(BuildContext context, DateTime current) {
    context.read<StudentMacrosBloc>().add(
          ChangeDateEvent(current.subtract(const Duration(days: 1))),
        );
  }

  void _goToNextDay(BuildContext context, DateTime current) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final c = current;
    final currentOnly = DateTime(c.year, c.month, c.day);
    if (currentOnly.isBefore(todayOnly)) {
      context.read<StudentMacrosBloc>().add(
            ChangeDateEvent(current.add(const Duration(days: 1))),
          );
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime initial) async {
    final bloc = context.read<StudentMacrosBloc>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      bloc.add(ChangeDateEvent(picked));
    }
  }

  Future<void> _openSetMacrosPage(BuildContext context) async {
    final bloc = context.read<StudentMacrosBloc>();
    final state = bloc.state;
    if (state is! StudentMacrosLoaded) return;

    Map<String, dynamic>? latestGoals() {
      Map<String, dynamic>? latest;
      DateTime? latestDate;
      for (final entry in state.macros.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date == null) continue;
        final value = entry.value;
        if (latestDate == null || date.isAfter(latestDate)) {
          if (value['carbsGoal'] != null ||
              value['fatGoal'] != null ||
              value['proteinGoal'] != null) {
            latest = value;
            latestDate = date;
          }
        }
      }
      return latest;
    }

    final dayKey = DateFormat('yyyy-MM-dd').format(state.selectedDate);
    Map<String, dynamic>? data = state.macros[dayKey];
    data ??= latestGoals();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetStudentMacrosPage(
          studentId: studentId,
          initialCarbs: (data?['carbsGoal'] as num?)?.toInt() ?? 0,
          initialFat: (data?['fatGoal'] as num?)?.toInt() ?? 0,
          initialProtein: (data?['proteinGoal'] as num?)?.toInt() ?? 0,
        ),
      ),
    );

    if (result != null) {
      final startDate = result['startDate'] as String?;
      final double newCarbs = (result['carbsGoal'] as num).toDouble();
      final double newFat = (result['fatGoal'] as num).toDouble();
      final double newProtein = (result['proteinGoal'] as num).toDouble();
      final double newCalories = (result['calorieGoal'] as num).toDouble();

      if (startDate != null) {
        bloc.add(
          UpdateDayMacrosEvent(startDate, {
            'carbsGoal': newCarbs,
            'fatGoal': newFat,
            'proteinGoal': newProtein,
            'calorieGoal': newCalories,
          }),
        );
      }
    }
  }

  Widget buildChart(
    Map<String, Map<String, dynamic>> macros,
    MacroType selectedMacro,
    TimeRange range,
  ) {
    final axisConfig = _getAxisIntervalConfig(range);

    return SizedBox(
      height: 200,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          intervalType: axisConfig.type,
          interval: axisConfig.interval.toDouble(),
          dateFormat: axisConfig.type == DateTimeIntervalType.months
              ? DateFormat('MMM')
              : DateFormat('dd/MM'),
        ),
        series: <ScatterSeries<_MacroPoint, DateTime>>[
          ScatterSeries<_MacroPoint, DateTime>(
            dataSource: _getMacroPoints(macros, selectedMacro, range),
            xValueMapper: (p, _) => p.date,
            yValueMapper: (p, _) => p.value,
            animationDuration: 0,
            emptyPointSettings: const EmptyPointSettings(
              mode: EmptyPointMode.gap,
            ),
            markerSettings: const MarkerSettings(
              isVisible: true,
              width: 8,
              height: 8,
            ),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
              builder: (dynamic data, _, __, ___, ____) {
                final point = data as _MacroPoint;
                final value = point.value?.toStringAsFixed(1) ?? '';
                return Text(value, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ],
      ),
    );
  }

  ({DateTimeIntervalType type, int interval}) _getAxisIntervalConfig(
    TimeRange range,
  ) {
    switch (range) {
      case TimeRange.week:
        return (type: DateTimeIntervalType.days, interval: 1);
      case TimeRange.month:
        return (type: DateTimeIntervalType.days, interval: 3);
      case TimeRange.threeMonths:
        return (type: DateTimeIntervalType.days, interval: 7);
      case TimeRange.sixMonths:
        return (type: DateTimeIntervalType.days, interval: 14);
      case TimeRange.year:
        return (type: DateTimeIntervalType.months, interval: 1);
    }
  }

  List<_MacroPoint> _getMacroPoints(
    Map<String, Map<String, dynamic>> macros,
    MacroType type,
    TimeRange range,
  ) {
    final now = DateTime.now();
    final start = _rangeStart(range, now);
    final List<_MacroPoint> points = [];

    for (var day = start;
        !day.isAfter(now);
        day = day.add(const Duration(days: 1))) {
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final key = DateFormat('yyyy-MM-dd').format(normalizedDay);
      final data = macros[key];

      double? value;
      if (data != null) {
        switch (type) {
          case MacroType.calories:
            value = (data['caloriesTracked'] as num?)?.toDouble();
            break;
          case MacroType.carbs:
            value = (data['carbsTracked'] as num?)?.toDouble();
            break;
          case MacroType.fat:
            value = (data['fatTracked'] as num?)?.toDouble();
            break;
          case MacroType.protein:
            value = (data['proteinTracked'] as num?)?.toDouble();
            break;
          case MacroType.weight:
            value = (data['weight'] as num?)?.toDouble();
            break;
        }
      }

      points.add(_MacroPoint(normalizedDay, value));
    }

    return points;
  }

  DateTime _rangeStart(TimeRange range, DateTime now) {
    switch (range) {
      case TimeRange.week:
        return now.subtract(const Duration(days: 7));
      case TimeRange.month:
        return now.subtract(const Duration(days: 30));
      case TimeRange.threeMonths:
        return now.subtract(const Duration(days: 90));
      case TimeRange.sixMonths:
        return now.subtract(const Duration(days: 180));
      case TimeRange.year:
        return now.subtract(const Duration(days: 365));
    }
  }
}

class _MacroPoint {
  final DateTime date;
  final double? value;

  _MacroPoint(this.date, this.value);
}
