import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class DiaryTableCalendar extends StatelessWidget {
  final Function(DateTime, Map<String, TrackedDayEntity>) onDateSelected;
  final Duration calendarDurationDays;
  final DateTime focusedDate;
  final DateTime currentDate;
  final DateTime selectedDate;
  final Map<String, TrackedDayEntity> trackedDaysMap;

  const DiaryTableCalendar({
    super.key,
    required this.onDateSelected,
    required this.calendarDurationDays,
    required this.focusedDate,
    required this.currentDate,
    required this.selectedDate,
    required this.trackedDaysMap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final weekStart = _startOfWeek(focusedDate);
    final weekDays = List.generate(
      DateTime.daysPerWeek,
      (index) => DateUtils.dateOnly(weekStart.add(Duration(days: index))),
    );
    final monthLabel = _formatMonth(localeName, focusedDate);
    final previousWeekSelectedDate =
        DateUtils.dateOnly(selectedDate).subtract(const Duration(days: 7));
    final nextWeekSelectedDate =
        DateUtils.dateOnly(selectedDate).add(const Duration(days: 7));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 22.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _CalendarNavButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: _canSelect(previousWeekSelectedDate)
                      ? () => _selectDate(previousWeekSelectedDate)
                      : null,
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _CalendarNavButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: _canSelect(nextWeekSelectedDate)
                      ? () => _selectDate(nextWeekSelectedDate)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            Row(
              children: weekDays
                  .map(
                    (date) => Expanded(
                      child: _CalendarDayCell(
                        date: date,
                        localeName: localeName,
                        trackedDay: trackedDaysMap[date.toParsedDay()],
                        isSelected: DateUtils.isSameDay(date, selectedDate),
                        isEnabled: _canSelect(date),
                        onTap: () => _selectDate(date),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _formatMonth(String localeName, DateTime date) {
    final formatted = DateFormat.yMMMM(localeName).format(date);
    if (formatted.isEmpty) return formatted;
    return formatted.characters.first.toUpperCase() +
        formatted.characters.skip(1).toString();
  }

  bool _canSelect(DateTime date) {
    final firstDay =
        DateUtils.dateOnly(currentDate.subtract(calendarDurationDays));
    final lastDay = DateUtils.dateOnly(currentDate.add(calendarDurationDays));
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(firstDay) && !day.isAfter(lastDay);
  }

  void _selectDate(DateTime date) {
    if (_canSelect(date)) {
      onDateSelected(DateUtils.dateOnly(date), trackedDaysMap);
    }
  }
}

class _CalendarNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CalendarNavButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40.0, height: 40.0),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: onPressed == null
            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
            : colorScheme.onSurface,
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final String localeName;
  final TrackedDayEntity? trackedDay;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.localeName,
    required this.trackedDay,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final contentColor = isSelected
        ? colorScheme.onPrimary
        : isEnabled
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
    final dotColor = trackedDay?.getCalendarDayRatingColor(context);

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(18.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _weekdayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6.0),
              AnimatedContainer(
                duration: kThemeAnimationDuration,
                width: 38.0,
                height: 38.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  DateFormat.d(localeName).format(date),
                  style: textTheme.titleMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 7.0),
              if (dotColor != null)
                AnimatedContainer(
                  duration: kThemeAnimationDuration,
                  width: isSelected ? 6.0 : 5.0,
                  height: isSelected ? 6.0 : 5.0,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : dotColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 6.0),
            ],
          ),
        ),
      ),
    );
  }

  String get _weekdayLabel {
    final rawLabel = DateFormat.E(localeName).format(date);
    final normalizedLabel = rawLabel.replaceAll('.', '');
    if (normalizedLabel.isEmpty) return normalizedLabel;
    return normalizedLabel.characters.first.toUpperCase() +
        normalizedLabel.characters.skip(1).toString();
  }
}
