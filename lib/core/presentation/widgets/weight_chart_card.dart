import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_surface_card.dart';
import 'package:opennutritracker/core/presentation/widgets/chart_controls.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The one list of periods every weight/trend selector offers.
enum WeightChartRange {
  sevenDays(days: 7),
  fourteenDays(days: 14),
  oneMonth(days: 30),
  threeMonths(days: 90);

  final int days;

  const WeightChartRange({required this.days});

  /// Non-breaking: "7 j" never wraps between number and unit.
  String label(S s) => _label(s).replaceAll(' ', ' ');

  String _label(S s) => switch (this) {
        sevenDays => s.trendPeriod7d,
        fourteenDays => s.trendPeriod14d,
        oneMonth => s.trendPeriod1m,
        threeMonths => s.trendPeriod3m,
      };
}

class WeightChartCard extends StatelessWidget {
  final List<WeightData> data;
  final WeightChartRange range;
  final Widget? selector;

  const WeightChartCard(
      {super.key, required this.data, required this.range, this.selector});

  double _xAxisInterval(WeightChartRange range) => switch (range) {
        WeightChartRange.sevenDays => 2,
        WeightChartRange.fourteenDays => 4,
        WeightChartRange.oneMonth => 10,
        WeightChartRange.threeMonths => 30,
      };

  DateFormat _dateFormat(WeightChartRange range) =>
      DateFormat(range == WeightChartRange.threeMonths ? 'MMM yy' : 'dd/MM');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chartData = data;
    final isDenseRange = chartData.length > 31;
    final yValues = [for (final point in chartData) point.weight!];
    final minWeight =
        yValues.isEmpty ? 0.0 : yValues.reduce((a, b) => a < b ? a : b);
    final maxWeight =
        yValues.isEmpty ? 0.0 : yValues.reduce((a, b) => a > b ? a : b);
    final paddedMin = ((minWeight - 0.8) * 2).floor() / 2;
    final paddedMax = ((maxWeight + 0.8) * 2).ceil() / 2;

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
              Text(
                S.of(context).evolutionLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (selector != null) selector!,
            ],
          ),
          const SizedBox(height: 18),
          if (chartData.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(S.of(context).weightNoMeasurementsLabel,
                    textAlign: TextAlign.center))
          else
            SizedBox(
              height: 230,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                enableAxisAnimation: false,
                plotAreaBorderWidth: 0,
                primaryXAxis: DateTimeAxis(
                  dateFormat: _dateFormat(range),
                  intervalType: DateTimeIntervalType.days,
                  interval: _xAxisInterval(range),
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
                  minimum:
                      chartData.first.date.subtract(const Duration(hours: 12)),
                ),
                primaryYAxis: NumericAxis(
                  desiredIntervals: 4,
                  numberFormat: numberFormatter(decimals: 1),
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
                    final unit = S.of(context).kgLabel;
                    return ChartTooltip(
                        date: weightPoint.date,
                        lines: [
                          formatNumber(weightPoint.weight ?? 0, decimals: 1)
                        ],
                        unit: unit);
                  },
                ),
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
                    final unit = S.of(context).kgLabel;
                    return ChartTooltip(
                        date: date,
                        lines: [formatNumber(weight, decimals: 1)],
                        unit: unit);
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
                    dataSource: chartData,
                    enableTooltip: true,
                    enableTrackball: false,
                    animationDuration: 0,
                    color: colorScheme.primary,
                    markerSettings: MarkerSettings(
                      isVisible: chartData.isNotEmpty && chartData.length <= 31,
                      width: range == WeightChartRange.sevenDays ? 11 : 7,
                      height: range == WeightChartRange.sevenDays ? 11 : 7,
                      color: colorScheme.primary,
                      borderColor: colorScheme.surface,
                      borderWidth: 2,
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

class WeightData {
  final DateTime date;
  final double? weight;

  WeightData(this.date, this.weight);
}
