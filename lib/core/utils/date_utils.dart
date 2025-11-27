import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppDateUtils {
  static DateTime getThailandTime() {
    return DateTime.now().toUtc().add(
      Duration(hours: AppConstants.thailandTimezoneOffset),
    );
  }

  static String formatTimeOnly(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  static String formatDateOnly(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat(AppConstants.dateFormat).format(dateTime);
  }

  static String formatFullDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat(AppConstants.fullDateTimeFormat).format(dateTime);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static DateTime getToday() {
    final thailandTime = getThailandTime();
    return DateTime(thailandTime.year, thailandTime.month, thailandTime.day);
  }

  static DateTime parseTimeWithDate(String timeString, String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final timeParts = timeString.split(':');

      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

        return DateTime(date.year, date.month, date.day, hour, minute, second);
      }
      return date;
    } catch (e) {
      return getThailandTime();
    }
  }
}
