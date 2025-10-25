import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/services/recipe_database.dart';

class ConsumptionQuotaRepository {
  final RecipeDatabase _database = RecipeDatabase.instance;
  static const String _periodPreferenceKey = 'consumption_period_preference';

  // ===== SETTINGS MANAGEMENT =====

  /// Get user's preferred consumption period
  Future<ConsumptionPeriod> getPreferredPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final periodString = prefs.getString(_periodPreferenceKey);

    if (periodString != null) {
      return consumptionPeriodFromJson(periodString);
    }

    // Default to weekly
    return ConsumptionPeriod.weekly;
  }

  /// Set user's preferred consumption period
  Future<void> setPreferredPeriod(ConsumptionPeriod period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_periodPreferenceKey, period.toJson());
  }

  // ===== QUOTA CRUD OPERATIONS =====

  /// Create a single consumption quota
  Future<String> createQuota(ConsumptionQuota quota) async {
    return await _database.createConsumptionQuota(quota);
  }

  /// Create multiple consumption quotas
  Future<void> createQuotas(List<ConsumptionQuota> quotas) async {
    if (quotas.isEmpty) return;
    await _database.createConsumptionQuotas(quotas);
  }

  /// Get a single quota by ID
  Future<ConsumptionQuota?> getQuota(String id) async {
    return await _database.getConsumptionQuota(id);
  }

  /// Get all quotas
  Future<List<ConsumptionQuota>> getAllQuotas() async {
    return await _database.getAllConsumptionQuotas();
  }

  /// Get quotas for a specific batch
  Future<List<ConsumptionQuota>> getQuotasForBatch(String batchId) async {
    return await _database.getConsumptionQuotasForBatch(batchId);
  }

  /// Get quotas for a specific food item
  Future<List<ConsumptionQuota>> getQuotasForFoodItem(String foodItemId) async {
    return await _database.getConsumptionQuotasForFoodItem(foodItemId);
  }

  /// Get quotas within a date range
  Future<List<ConsumptionQuota>> getQuotasByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _database.getConsumptionQuotasByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get active (incomplete) quotas
  Future<List<ConsumptionQuota>> getActiveQuotas() async {
    return await _database.getActiveConsumptionQuotas();
  }

  /// Get overdue quotas
  Future<List<ConsumptionQuota>> getOverdueQuotas() async {
    return await _database.getOverdueConsumptionQuotas();
  }

  /// Update a single quota
  Future<void> updateQuota(ConsumptionQuota quota) async {
    await _database.updateConsumptionQuota(quota);
  }

  /// Update multiple quotas
  Future<void> updateQuotas(List<ConsumptionQuota> quotas) async {
    if (quotas.isEmpty) return;
    await _database.updateConsumptionQuotas(quotas);
  }

  /// Delete a quota
  Future<void> deleteQuota(String id) async {
    await _database.deleteConsumptionQuota(id);
  }

  /// Delete all quotas for a batch
  Future<void> deleteQuotasForBatch(String batchId) async {
    await _database.deleteConsumptionQuotasForBatch(batchId);
  }

  /// Delete all quotas for a food item
  Future<void> deleteQuotasForFoodItem(String foodItemId) async {
    await _database.deleteConsumptionQuotasForFoodItem(foodItemId);
  }

  // ===== GROUPED OPERATIONS =====

  /// Get quotas grouped by food item name
  Future<Map<String, List<ConsumptionQuota>>> getQuotasGroupedByFoodItem() async {
    final allQuotas = await getAllQuotas();
    final grouped = <String, List<ConsumptionQuota>>{};

    for (final quota in allQuotas) {
      grouped.putIfAbsent(quota.foodItemName, () => []).add(quota);
    }

    // Sort each group by target date
    for (final quotas in grouped.values) {
      quotas.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    }

    return grouped;
  }

  /// Get quotas for the current period
  Future<Map<String, List<ConsumptionQuota>>> getCurrentPeriodQuotas() async {
    final period = await getPreferredPeriod();
    final now = DateTime.now();

    // Calculate current period boundaries
    final periodStart = _getPeriodStart(now, period);
    final periodEnd = _getPeriodEnd(periodStart, period);

    final quotas = await getQuotasByDateRange(
      startDate: periodStart,
      endDate: periodEnd,
    );

    // Group by food item
    final grouped = <String, List<ConsumptionQuota>>{};
    for (final quota in quotas) {
      grouped.putIfAbsent(quota.foodItemName, () => []).add(quota);
    }

    return grouped;
  }

  /// Get quotas for upcoming periods
  Future<Map<String, List<ConsumptionQuota>>> getUpcomingPeriodsQuotas({
    int numberOfPeriods = 3,
  }) async {
    final period = await getPreferredPeriod();
    final now = DateTime.now();

    // Calculate the range covering the upcoming periods
    final periodStart = _getPeriodStart(now, period);
    final periodEnd = _getPeriodEnd(periodStart, period)
        .add(Duration(days: period.daysInPeriod * (numberOfPeriods - 1)));

    final quotas = await getQuotasByDateRange(
      startDate: periodStart,
      endDate: periodEnd,
    );

    // Group by food item
    final grouped = <String, List<ConsumptionQuota>>{};
    for (final quota in quotas) {
      grouped.putIfAbsent(quota.foodItemName, () => []).add(quota);
    }

    // Sort each group by target date
    for (final quotas in grouped.values) {
      quotas.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    }

    return grouped;
  }

  // ===== HELPER METHODS =====

  DateTime _getPeriodStart(DateTime date, ConsumptionPeriod period) {
    switch (period) {
      case ConsumptionPeriod.weekly:
        // Start of the week (Monday)
        final weekday = date.weekday;
        return DateTime(date.year, date.month, date.day)
            .subtract(Duration(days: weekday - 1));

      case ConsumptionPeriod.monthly:
        // Start of the month
        return DateTime(date.year, date.month, 1);

      case ConsumptionPeriod.quarterly:
        // Start of the quarter
        final quarter = ((date.month - 1) ~/ 3);
        final quarterStartMonth = quarter * 3 + 1;
        return DateTime(date.year, quarterStartMonth, 1);
    }
  }

  DateTime _getPeriodEnd(DateTime periodStart, ConsumptionPeriod period) {
    switch (period) {
      case ConsumptionPeriod.weekly:
        return periodStart.add(const Duration(days: 7));

      case ConsumptionPeriod.monthly:
        // End of the month
        final nextMonth = periodStart.month == 12
            ? DateTime(periodStart.year + 1, 1, 1)
            : DateTime(periodStart.year, periodStart.month + 1, 1);
        return nextMonth.subtract(const Duration(days: 1));

      case ConsumptionPeriod.quarterly:
        // End of the quarter (3 months)
        final endMonth = periodStart.month + 3;
        if (endMonth <= 12) {
          return DateTime(periodStart.year, endMonth, 1)
              .subtract(const Duration(days: 1));
        } else {
          return DateTime(periodStart.year + 1, endMonth - 12, 1)
              .subtract(const Duration(days: 1));
        }
    }
  }
}
