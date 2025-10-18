import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/editable_text_widget.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:opennutritracker/core/presentation/constants/app_icons.dart';
import 'package:opennutritracker/core/presentation/widgets/weight_info.dart';

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
  late CalendarDayBloc _calendarDayBloc;
  late DateTime _day;
  late bool _isEditable;
  final nbDays = 7;

  @override
  void initState() {
    super.initState();
    _homeBloc = locator<HomeBloc>();
    _weightBloc = locator<WeightBloc>();
    _addWeightUsecase = locator<AddWeightUsecase>();
    _getWeightUsecase = locator<GetWeightUsecase>();
    _calendarDayBloc = locator<CalendarDayBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as AddWeightScreenArguments;
    _day = DateTime(args.day.year, args.day.month, args.day.day);
    _isEditable = args.isReadOnly;

    _weightBloc.add(WeightLoadInitialRequested(_day));
  }

  Future<WeightSummary> _getWeightsSummary() async {
    final lastSavedWeights = await _getWeightUsecase.getWeightsFromPastDays(
      _day,
      nbDays,
      includeToday: true,
    );

    // Create a map for quick lookup of weights by date.
    final weightsMap = {
      for (var e in lastSavedWeights)
        DateTime(e.date.year, e.date.month, e.date.day): e.weight,
    };

    // Generate a complete list of data for the last nbDays, filling missing days with null.
    // This ensures the chart always has a consistent number of data points,
    // which helps in maintaining a constant column width.
    final List<WeightData> weightDataList = List.generate(nbDays, (i) {
      final date = DateTime(
        _day.year,
        _day.month,
        _day.day,
      ).subtract(Duration(days: i));
      final weight = weightsMap[date];
      return WeightData(date, weight);
    }).reversed.toList(); // Reverse to have dates in chronological order.

    final averageWeight = await _getWeightUsecase.getAverageWeight(
      _day,
      nbDays,
    );

    return WeightSummary(
      averageWeight: averageWeight,
      weightDataList: weightDataList,
    );
  }

  double roundDecimal(double number, {int nbDecimal = 1}) {
    return (number * 10 * nbDecimal).round() / (10 * nbDecimal);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerLow;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).weightLabel)),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: FutureBuilder<WeightSummary>(
              future: _getWeightsSummary(),
              builder: (
                BuildContext context,
                AsyncSnapshot<WeightSummary> snapshot,
              ) {
                if (snapshot.hasData) {
                  final WeightSummary weightSummary = snapshot.data!;
                  final List<WeightData> weightDataList =
                      weightSummary.weightDataList;
                  final double averageWeight = roundDecimal(
                    weightSummary.averageWeight,
                  );

                  return Column(
                    children: [
                      /* WEIGHT SELECTION*/
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: ShapeDecoration(
                          color: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          shadows: const [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: _isEditable
                                      ? null
                                      : () => _weightBloc.add(
                                            WeightDecrement(),
                                          ),
                                ),
                                BlocBuilder<WeightBloc, WeightState>(
                                  bloc: _weightBloc,
                                  builder: (context, state) {
                                    return Center(
                                      child: EditableTextWidget(
                                        initialValue:
                                            state.weight.toStringAsFixed(1),
                                        disabledEnter: _isEditable,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _isEditable
                                      ? null
                                      : () => _weightBloc.add(
                                            WeightIncrement(),
                                          ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isEditable
                                    ? null
                                    : () => _onButtonPressed(context),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                ).copyWith(
                                  elevation: ButtonStyleButton.allOrNull(0.0),
                                ),
                                icon: const Icon(Icons.add_outlined),
                                label: Text(S.of(context).buttonSaveLabel),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /* INFO BOXES */
                      SizedBox(height: 25),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            WeightInfo(
                                widget: Text(
                                  averageWeight.toString(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                title: S.of(context).averageWeightLabel,
                                body: S.of(context).averageWeightBody,
                                color: backgroundColor),
                            SizedBox(width: 20),
                            Builder(
                              builder: (context) {
                                final delta = roundDecimal(
                                    _weightBloc.state.weight - averageWeight);
                                return WeightInfo(
                                  widget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          AppIcons.getIconForDifference(
                                              _weightBloc.state.weight,
                                              averageWeight),
                                          size: 26),
                                      Container(
                                        width: 50,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          delta.abs().toStringAsFixed(1),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: S.of(context).deltaWeightLabel,
                                  body: S.of(context).deltaWeightBody,
                                  color: backgroundColor,
                                );
                              },
                            ),
                          ]),

                      /* GRAPHIC */
                      SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: ShapeDecoration(
                          color: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          shadows: const [],
                        ),
                        child: SfCartesianChart(
                          primaryXAxis: DateTimeAxis(
                            dateFormat: DateFormat('dd/MM/yyyy'),
                            intervalType: DateTimeIntervalType.days,
                            interval: 1,
                            labelRotation: -90,
                            maximum: _day.add(Duration(hours: 12)),
                            minimum: _day.subtract(Duration(days: nbDays)),
                          ),
                          primaryYAxis: NumericAxis(
                            interval: 0.5,
                            maximum: (averageWeight * 2).round() / 2 + 1.5,
                            minimum: (averageWeight * 2).round() / 2 - 1.5,
                          ),
                          series: <CartesianSeries<WeightData, DateTime>>[
                            ColumnSeries(
                              xValueMapper: (WeightData data, _) => data.date,
                              yValueMapper: (WeightData data, _) => data.weight,
                              dataSource: weightDataList,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              width:
                                  0.8, // Vous pouvez ajuster cette valeur (entre 0.0 et 1.0)
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: Text('No weight data available.'),
                  );
                }
              },
            ),
          ),
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

    /* Reload widget */
    if (mounted) {
      setState(() {});
    }
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
  final List<WeightData> weightDataList;

  WeightSummary({required this.averageWeight, required this.weightDataList});
}
