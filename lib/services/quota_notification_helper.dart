import 'package:inventory_manager/models/consumption_period.dart';

/// Helper for calculating quota regeneration notification times
class QuotaNotificationHelper {
  /// Calculate the next notification time based on the consumption period
  /// Notifications are scheduled for 12:00 PM on the day the period begins
  static DateTime calculateNextNotificationTime(ConsumptionPeriod period) {
    final now = DateTime.now();
    DateTime nextPeriodStart;

    switch (period) {
      case ConsumptionPeriod.weekly:
        // Next Monday at 12:00
        final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        final daysToAdd = daysUntilMonday == 0 ? 7 : daysUntilMonday;
        nextPeriodStart = DateTime(
          now.year,
          now.month,
          now.day + daysToAdd,
          12, // 12:00 PM
          0,
          0,
        );
        break;

      case ConsumptionPeriod.monthly:
        // First day of next month at 12:00
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        nextPeriodStart = DateTime(
          nextYear,
          nextMonth,
          1, // First day of month
          12, // 12:00 PM
          0,
          0,
        );
        break;

      case ConsumptionPeriod.quarterly:
        // First day of next quarter at 12:00
        // Quarters: Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec
        final currentQuarter = ((now.month - 1) ~/ 3);
        final nextQuarterMonth = (currentQuarter + 1) * 3 + 1;

        int nextMonth;
        int nextYear;
        if (nextQuarterMonth > 12) {
          nextMonth = 1;
          nextYear = now.year + 1;
        } else {
          nextMonth = nextQuarterMonth;
          nextYear = now.year;
        }

        nextPeriodStart = DateTime(
          nextYear,
          nextMonth,
          1, // First day of quarter
          12, // 12:00 PM
          0,
          0,
        );
        break;
    }

    return nextPeriodStart;
  }

  /// Get a human-readable period name for notifications
  static String getPeriodName(ConsumptionPeriod period) {
    switch (period) {
      case ConsumptionPeriod.weekly:
        return 'weekly';
      case ConsumptionPeriod.monthly:
        return 'monthly';
      case ConsumptionPeriod.quarterly:
        return 'quarterly';
    }
  }
}
