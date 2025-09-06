class DateUtilsHelper {
  static DateTime roundToSeconds(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }
}
