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

  int get daysInPeriod {
    switch (this) {
      case ConsumptionPeriod.weekly:
        return 7;
      case ConsumptionPeriod.monthly:
        return 30;
      case ConsumptionPeriod.quarterly:
        return 90;
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
