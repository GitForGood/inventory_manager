import '../models/inventory_batch.dart';
import '../models/consumption_period.dart';
import '../models/consumption_quota.dart';
import 'storage_calculator_service.dart';

/// Result of storage deficit calculations
class StorageDeficit {
  final double currentCalories;
  final double targetCalories;
  final double deficitCalories;
  final double? daysUntilEmpty;
  final bool hasTarget;
  final bool isAboveTarget;

  const StorageDeficit({
    required this.currentCalories,
    required this.targetCalories,
    required this.deficitCalories,
    this.daysUntilEmpty,
    required this.hasTarget,
    required this.isAboveTarget,
  });
}

/// Current consumption rate from quotas
class ConsumptionRate {
  final double dailyCalories;
  final double weeklyCalories;
  final double monthlyCalories;
  final double quarterlyCalories;

  const ConsumptionRate({
    required this.dailyCalories,
    required this.weeklyCalories,
    required this.monthlyCalories,
    required this.quarterlyCalories,
  });

  double getCaloriesForPeriod(ConsumptionPeriod period) {
    switch (period) {
      case ConsumptionPeriod.weekly:
        return weeklyCalories;
      case ConsumptionPeriod.monthly:
        return monthlyCalories;
      case ConsumptionPeriod.quarterly:
        return quarterlyCalories;
    }
  }
}

/// Result of purchase impact calculations
class PurchaseImpact {
  final double purchaseCalories;
  final int daysUntilExpiry;
  final double dailyQuotaIncrease;
  final double monthlyQuotaIncrease;
  final double newTotalCalories;
  final double? newDaysUntilEmpty;
  final ConsumptionRate? currentConsumptionRate;
  final ConsumptionRate? newConsumptionRate;

  const PurchaseImpact({
    required this.purchaseCalories,
    required this.daysUntilExpiry,
    required this.dailyQuotaIncrease,
    required this.monthlyQuotaIncrease,
    required this.newTotalCalories,
    this.newDaysUntilEmpty,
    this.currentConsumptionRate,
    this.newConsumptionRate,
  });
}

/// Service for calculating storage upkeep metrics and purchase impacts
class UpkeepCalculatorService {
  /// Calculate current consumption rate from active quotas
  ///
  /// Analyzes all active quotas across different periods to determine
  /// the average consumption rate in calories per period
  static ConsumptionRate calculateConsumptionRateFromQuotas({
    required Map<String, List<ConsumptionQuota>> quotasByFoodItem,
    required List<InventoryBatch> batches,
  }) {
    // Calculate total calories for each period's quotas
    double weeklyCalories = 0;
    double monthlyCalories = 0;
    double quarterlyCalories = 0;

    // Get all quotas (flatten the map)
    final allQuotas = quotasByFoodItem.values.expand((list) => list).toList();

    // Create a map of batch ID to batch for quick lookup
    final batchMap = {for (var batch in batches) batch.id: batch};

    for (final quota in allQuotas) {
      // Skip completed quotas
      if (quota.isCompleted) continue;

      // Find the batch to get calorie information
      final batch = batchMap[quota.batchId];
      if (batch == null) continue;

      // Calculate calories for this quota's remaining target
      final remainingItems = quota.remainingCount;
      final caloriesPerItem = batch.item.getKcalForItems(1);
      final quotaCalories = caloriesPerItem * remainingItems;

      // Determine which period this quota belongs to based on target date
      final now = DateTime.now();
      final daysUntilTarget = quota.targetDate.difference(now).inDays;

      // Approximate period assignment based on days until target
      if (daysUntilTarget <= 7) {
        weeklyCalories += quotaCalories;
      } else if (daysUntilTarget <= 31) {
        monthlyCalories += quotaCalories;
      } else {
        quarterlyCalories += quotaCalories;
      }
    }

    // Calculate daily rate (average across all periods, normalized)
    // Weekly quotas contribute to daily, monthly spread over ~30 days, quarterly over ~90 days
    final dailyFromWeekly = weeklyCalories / 7;
    final dailyFromMonthly = monthlyCalories / 30;
    final dailyFromQuarterly = quarterlyCalories / 90;
    final dailyCalories = dailyFromWeekly + dailyFromMonthly + dailyFromQuarterly;

    return ConsumptionRate(
      dailyCalories: dailyCalories,
      weeklyCalories: weeklyCalories,
      monthlyCalories: monthlyCalories,
      quarterlyCalories: quarterlyCalories,
    );
  }

  /// Calculate storage deficit relative to target
  static StorageDeficit calculateStorageDeficit({
    required List<InventoryBatch> batches,
    required int? dailyCalorieTarget,
    int targetDaysOfStorage = 30,
  }) {
    final currentCalories = StorageCalculatorService.calculateTotalCalories(batches);

    // If no target is set, return without target calculations
    if (dailyCalorieTarget == null) {
      return StorageDeficit(
        currentCalories: currentCalories,
        targetCalories: 0,
        deficitCalories: 0,
        daysUntilEmpty: null,
        hasTarget: false,
        isAboveTarget: false,
      );
    }

    final targetCalories = dailyCalorieTarget * targetDaysOfStorage.toDouble();
    final deficitCalories = targetCalories - currentCalories;
    final daysUntilEmpty = currentCalories / dailyCalorieTarget;
    final isAboveTarget = currentCalories >= targetCalories;

    return StorageDeficit(
      currentCalories: currentCalories,
      targetCalories: targetCalories,
      deficitCalories: deficitCalories,
      daysUntilEmpty: daysUntilEmpty,
      hasTarget: true,
      isAboveTarget: isAboveTarget,
    );
  }

  /// Calculate the impact of a purchase on consumption quotas
  static PurchaseImpact calculatePurchaseImpact({
    required double purchaseCalories,
    required int daysUntilExpiry,
    required List<InventoryBatch> currentBatches,
    required int? dailyCalorieTarget,
    Map<String, List<ConsumptionQuota>>? quotasByFoodItem,
  }) {
    // Calculate daily quota increase if we consume this purchase evenly over its lifetime
    final dailyQuotaIncrease = purchaseCalories / daysUntilExpiry;

    // Calculate monthly quota increase (approximate 30 days per month)
    final monthlyQuotaIncrease = dailyQuotaIncrease * 30;

    // Calculate new total calories after purchase
    final currentCalories = StorageCalculatorService.calculateTotalCalories(currentBatches);
    final newTotalCalories = currentCalories + purchaseCalories;

    // Calculate new days until empty if target is set
    double? newDaysUntilEmpty;
    if (dailyCalorieTarget != null && dailyCalorieTarget > 0) {
      newDaysUntilEmpty = newTotalCalories / dailyCalorieTarget;
    }

    // Calculate current and new consumption rates from quotas
    ConsumptionRate? currentRate;
    ConsumptionRate? newRate;

    if (quotasByFoodItem != null && quotasByFoodItem.isNotEmpty) {
      currentRate = calculateConsumptionRateFromQuotas(
        quotasByFoodItem: quotasByFoodItem,
        batches: currentBatches,
      );

      // Calculate new rate by adding the purchase impact
      newRate = ConsumptionRate(
        dailyCalories: currentRate.dailyCalories + dailyQuotaIncrease,
        weeklyCalories: currentRate.weeklyCalories + (dailyQuotaIncrease * 7),
        monthlyCalories: currentRate.monthlyCalories + monthlyQuotaIncrease,
        quarterlyCalories: currentRate.quarterlyCalories + (monthlyQuotaIncrease * 3),
      );
    }

    return PurchaseImpact(
      purchaseCalories: purchaseCalories,
      daysUntilExpiry: daysUntilExpiry,
      dailyQuotaIncrease: dailyQuotaIncrease,
      monthlyQuotaIncrease: monthlyQuotaIncrease,
      newTotalCalories: newTotalCalories,
      newDaysUntilEmpty: newDaysUntilEmpty,
      currentConsumptionRate: currentRate,
      newConsumptionRate: newRate,
    );
  }

  /// Calculate recommended purchase to reach target storage
  static PurchaseImpact calculateRecommendedPurchase({
    required List<InventoryBatch> batches,
    required int? dailyCalorieTarget,
    required int targetDaysOfStorage,
    required int daysUntilExpiry,
  }) {
    final deficit = calculateStorageDeficit(
      batches: batches,
      dailyCalorieTarget: dailyCalorieTarget,
      targetDaysOfStorage: targetDaysOfStorage,
    );

    // If no deficit or no target, recommend a baseline amount
    final purchaseCalories = deficit.hasTarget && deficit.deficitCalories > 0
        ? deficit.deficitCalories
        : (dailyCalorieTarget ?? 2000) * targetDaysOfStorage.toDouble();

    return calculatePurchaseImpact(
      purchaseCalories: purchaseCalories,
      daysUntilExpiry: daysUntilExpiry,
      currentBatches: batches,
      dailyCalorieTarget: dailyCalorieTarget,
    );
  }

  /// Calculate how many calories per expiry period to maintain target
  static double calculateRequiredCaloriesPerPeriod({
    required int? dailyCalorieTarget,
    required ConsumptionPeriod period,
    int periodCount = 1,
  }) {
    if (dailyCalorieTarget == null) {
      return 0;
    }

    // Calculate days in period
    final now = DateTime.now();
    final periodStart = period.getCurrentPeriodStart(now);
    final periodEnd = period.getCurrentPeriodEnd(now);
    final daysInPeriod = periodEnd.difference(periodStart).inDays;

    return dailyCalorieTarget * daysInPeriod * periodCount.toDouble();
  }
}
