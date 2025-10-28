enum ConsumptionPeriod {
  weekly,
  monthly,
  quarterly,
}

extension ConsumptionPeriodExtension on ConsumptionPeriod {
  String get displayName {
    switch (this) {
      case ConsumptionPeriod.weekly:
        return 'Weekly';
      case ConsumptionPeriod.monthly:
        return 'Monthly';
      case ConsumptionPeriod.quarterly:
        return 'Quarterly';
    }
  }
  /// Gets the start date of the current period aligned to calendar boundaries
  ///
  /// **Weekly**: Most recent Monday (start of ISO week)
  /// - Example: If today is Wednesday, Oct 30, 2024 → returns Monday, Oct 28, 2024
  ///
  /// **Monthly**: First day of current month
  /// - Example: If today is Oct 15, 2024 → returns Oct 1, 2024
  ///
  /// **Quarterly**: First day of current quarter (Jan 1, Apr 1, Jul 1, Oct 1)
  /// - Example: If today is Nov 15, 2024 → returns Oct 1, 2024
  /// - Example: If today is Feb 20, 2024 → returns Jan 1, 2024
  DateTime getCurrentPeriodStart([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();

    switch (this) {
      case ConsumptionPeriod.weekly:
        // Get the most recent Monday (weekday 1)
        final daysSinceMonday = (now.weekday - DateTime.monday) % 7;
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceMonday));

      case ConsumptionPeriod.monthly:
        // First day of current month
        return DateTime(now.year, now.month, 1);

      case ConsumptionPeriod.quarterly:
        // First day of current quarter (Jan=1, Apr=4, Jul=7, Oct=10)
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarterStartMonth, 1);
    }
  }

  /// Gets the end date of the current period aligned to calendar boundaries
  /// - Weekly: Next Sunday (end of week)
  /// - Monthly: Last day of current month
  /// - Quarterly: Last day of current quarter
  DateTime getCurrentPeriodEnd([DateTime? referenceDate]) {
    final start = getCurrentPeriodStart(referenceDate);

    switch (this) {
      case ConsumptionPeriod.weekly:
        // Add 7 days to get to next Monday, then subtract 1 day to get Sunday
        return start.add(const Duration(days: 7));

      case ConsumptionPeriod.monthly:
        // First day of next month
        final nextMonth = start.month == 12
            ? DateTime(start.year + 1, 1, 1)
            : DateTime(start.year, start.month + 1, 1);
        return nextMonth;

      case ConsumptionPeriod.quarterly:
        // First day of next quarter
        final nextQuarterMonth = start.month + 3;
        final nextQuarter = nextQuarterMonth > 12
            ? DateTime(start.year + 1, nextQuarterMonth - 12, 1)
            : DateTime(start.year, nextQuarterMonth, 1);
        return nextQuarter;
    }
  }

  /// Gets the number of days remaining in the current period
  int getDaysRemainingInCurrentPeriod([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final periodEnd = getCurrentPeriodEnd(referenceDate);
    return periodEnd.difference(now).inDays;
  }

  /// Calculates how many complete periods fit between two dates
  int getPeriodsCount(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;

    switch (this) {
      case ConsumptionPeriod.weekly:
        return days ~/ 7;

      case ConsumptionPeriod.monthly:
        int months = (end.year - start.year) * 12 + (end.month - start.month);
        return months;

      case ConsumptionPeriod.quarterly:
        int months = (end.year - start.year) * 12 + (end.month - start.month);
        return months ~/ 3;
    }
  }

  String toJson() => name;
}

// Helper function for fromJson
ConsumptionPeriod consumptionPeriodFromJson(String json) {
  return ConsumptionPeriod.values.firstWhere(
    (period) => period.name == json,
    orElse: () => ConsumptionPeriod.weekly,
  );
}
