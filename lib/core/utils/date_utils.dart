import 'package:intl/intl.dart';

class FitDateUtils {
  static String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  static String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);
  static String formatDayName(DateTime date) => DateFormat('EEE').format(date);
  static String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static List<DateTime> currentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());
}
