import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/widgets/macro_nutriments_widget.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'set_student_macros_page.dart';

class StudentMacrosPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentMacrosPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentMacrosPage> createState() => _StudentMacrosPageState();
}

enum MacroType { calories, carbs, fat, protein, weight }

enum TimeRange { week, month, threeMonths, sixMonths, year }

class _StudentMacrosPageState extends State<StudentMacrosPage> {
  late Future<Map<String, Map<String, dynamic>>> _macrosFuture;
  Map<String, Map<String, dynamic>> _allMacros = {};
  DateTime _selectedDate = DateTime.now();
  MacroType _selectedMacro = MacroType.calories;
  TimeRange _selectedRange = TimeRange.month;
  double caloriesTracked = 0;
  double caloriesBurned = 0;
  double calorieGoal = 0;
  double carbsGoal = 0;
  double carbsTracked = 0;
  double fatGoal = 0;
  double fatTracked = 0;
  double proteinGoal = 0;
  double proteinTracked = 0;

  @override
  void initState() {
    super.initState();
    _macrosFuture = _fetchMacros();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchMacros() async {
    final supabase = locator<SupabaseClient>();

    final now = DateTime.now();
    final startDate = DateFormat('yyyy-MM-dd')
        .format(now.subtract(const Duration(days: 365)));
    final endDate = DateFormat('yyyy-MM-dd').format(now);

    // 1. Récupère les macros
    final macroResponse = await supabase
        .from('tracked_days')
        .select(
          'day, calorieGoal, caloriesTracked, caloriesBurned, carbsGoal, carbsTracked, fatGoal, fatTracked, proteinGoal, proteinTracked',
        )
        .eq('user_id', widget.studentId)
        .gte('day', startDate)
        .lte('day', endDate)
        .order('day');

    caloriesTracked = macroResponse.isNotEmpty
        ? (macroResponse.last['caloriesTracked'] as num?)?.toDouble() ?? 0
        : 0;
    caloriesBurned = macroResponse.isNotEmpty
        ? (macroResponse.last['caloriesBurned'] as num?)?.toDouble() ?? 0
        : 0;
    calorieGoal = macroResponse.isNotEmpty
        ? (macroResponse.last['calorieGoal'] as num?)?.toDouble() ?? 0
        : 0;
    carbsTracked = macroResponse.isNotEmpty
        ? (macroResponse.last['carbsTracked'] as num?)?.toDouble() ?? 0
        : 0;
    carbsGoal = macroResponse.isNotEmpty
        ? (macroResponse.last['carbsGoal'] as num?)?.toDouble() ?? 0
        : 0;
    fatTracked = macroResponse.isNotEmpty
        ? (macroResponse.last['fatTracked'] as num?)?.toDouble() ?? 0
        : 0;
    fatGoal = macroResponse.isNotEmpty
        ? (macroResponse.last['fatGoal'] as num?)?.toDouble() ?? 0
        : 0;
    proteinTracked = macroResponse.isNotEmpty
        ? (macroResponse.last['proteinTracked'] as num?)?.toDouble() ?? 0
        : 0;
    proteinGoal = macroResponse.isNotEmpty
        ? (macroResponse.last['proteinGoal'] as num?)?.toDouble() ?? 0
        : 0;

    // 2. Récupère les poids
    final weightResponse = await supabase
        .from('user_weight')
        .select('date, weight')
        .eq('user_id', widget.studentId)
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date');

    // 3. Combine les deux
    final Map<String, Map<String, dynamic>> result = {
      for (final Map<String, dynamic> item in macroResponse)
        item['day'] as String: item,
    };

    for (final Map<String, dynamic> item in weightResponse) {
      final dateStr = item['date'] as String;
      result.putIfAbsent(dateStr, () => {});
      result[dateStr]!['weight'] = item['weight'];
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSetMacrosPage,
        icon: const Icon(Icons.edit_outlined),
        label: Text(S.of(context).setMacrosLabel),
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _macrosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${S.of(context).errorPrefix} ${snapshot.error}'),
            );
          }

          if (snapshot.hasData) {
            _allMacros = snapshot.data!;
          }

          final dayKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
          final data = _allMacros[dayKey];

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
                    // Navigation toujours visible
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _goToPreviousDay,
                        ),
                        InkWell(
                          onTap: _selectDate,
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_selectedDate),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _goToNextDay,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Si pas de données pour ce jour
                    if (data == null)
                      Text(S.of(context).noDataToday)
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.keyboard_arrow_up_outlined,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              Text('${caloriesTracked.toInt()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                              Text(S.of(context).suppliedLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                            ],
                          ),
                          CircularPercentIndicator(
                            radius: 90.0,
                            lineWidth: 13.0,
                            animation: true,
                            percent: gaugeValue,
                            arcType: ArcType.FULL,
                            progressColor:
                                Theme.of(context).colorScheme.primary,
                            arcBackgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(50),
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedFlipCounter(
                                  duration: const Duration(milliseconds: 1000),
                                  value: kcalLeft.clamp(0, calorieGoal).toInt(),
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          letterSpacing: -1),
                                ),
                                Text(
                                  S.of(context).kcalLeftLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                )
                              ],
                            ),
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          Column(
                            children: [
                              Icon(Icons.keyboard_arrow_down_outlined,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              Text('${caloriesBurned.toInt()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                              Text(S.of(context).burnedLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                            ],
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
                          value: _selectedMacro,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMacro = value;
                              });
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
                              child: Text(S
                                  .of(context)
                                  .weightLabel), // ou "Poids" si pas encore traduit
                            ),
                          ],
                        ),
                        DropdownButton<TimeRange>(
                          value: _selectedRange,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRange = value;
                              });
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
                    buildChart(),
                  ],
                ),
              ),
            ),
          ));
        },
      ),
    );
  }

  Widget buildChart() {
    final axisConfig = _getAxisIntervalConfig(_selectedRange);

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
            dataSource: _getMacroPoints(_selectedMacro),
            xValueMapper: (p, _) => p.date,
            yValueMapper: (p, _) => p.value,
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
      TimeRange range) {
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

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openSetMacrosPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetStudentMacrosPage(
            studentId: widget.studentId,
            initialCarbs: carbsGoal.toInt(),
            initialFat: fatGoal.toInt(),
            initialProtein: proteinGoal.toInt()),
      ),
    );
  }

  List<_MacroPoint> _getMacroPoints(MacroType type) {
    final now = DateTime.now();
    final start = _rangeStart(now);
    final List<_MacroPoint> points = [];

    for (var day = start;
        !day.isAfter(now);
        day = day.add(const Duration(days: 1))) {
      final normalizedDay =
          DateTime(day.year, day.month, day.day); // 👈 00:00:00
      final key = DateFormat('yyyy-MM-dd').format(normalizedDay);
      final data = _allMacros[key];

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

  DateTime _rangeStart(DateTime now) {
    switch (_selectedRange) {
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
  final double? value; // Nullable pour gérer les jours sans données

  _MacroPoint(this.date, this.value);
}
