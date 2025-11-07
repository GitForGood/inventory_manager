import 'dart:math';

import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:inventory_manager/models/food_item.dart';
import 'package:inventory_manager/models/inventory_batch.dart';

class QuotaGenerationService {
  /// Generates consumption quotas for the current period only
  ///
  /// Groups all batches by food item and creates one aggregated quota per item.
  /// Each batch contributes a proportional amount based on its REMAINING lifespan
  /// from now until expiration, ensuring quotas don't empty inventory too quickly.
  ///
  /// **Period Alignment**: Periods are aligned to calendar boundaries:
  /// - Weekly: Monday to Sunday
  /// - Monthly: 1st to last day of month
  /// - Quarterly: Jan/Apr/Jul/Oct 1st to last day of quarter
  ///
  /// **Algorith**
  /// 1. Each batch provides a saturation for its remaining time until expiration
  /// (days til period end * items left / (current day - expiration date)) + rounding offset
  /// 
  /// 2. If any batch produces a value large enough proportinally to the sum
  /// for that item (a provided value between 0-1 default 0.5)
  /// only take that batch into account and portion out that value rounded up to
  /// the user for the set period.
  /// 3. If no batch is disproportionally large. Sum up the values for the batches
  /// and generate a quota that is the rounded up for the period.
  /// 
  /// So 2 additional values, one proportion (0-1) and one rounding offset (0-1)
  /// needs to be provided for the generation to work.
  static List<ConsumptionQuota> generateQuotasForCurrentPeriod({
    required List<InventoryBatch> batches,
    required ConsumptionPeriod period,
    double roundingOffsetGracePeriod = 0.1,
    double proportionLimitForBatch = 0.5,
  }) {
    final now = DateTime.now();
    final periodEnd = period.getCurrentPeriodEnd();
    final daysUntilPeriodEnd = periodEnd.difference(now).inDays;

    // Calculation helpers
    final decider = (
      ((double,double) highestTotal) => 
      (highestTotal.$1/highestTotal.$2 >= proportionLimitForBatch 
        ? highestTotal.$1 
        : highestTotal.$2)
    );
    final evaluator = (
      (InventoryBatch batch) => 
      min (
        (batch.count * daysUntilPeriodEnd).toDouble() / 
        (batch.expirationDate.difference(now).inDays).toDouble(),
        batch.count.toDouble()
      )
    );

    return batches
      .where((batch) => batch.count > 0)
      .fold(<FoodItem,(double,double)>{}, 
        (acc, batch){
          final item = batch.item;
          final evaluation = evaluator(batch);
          final (highest, total) = acc.putIfAbsent(item, () => (0.0,0.0));
          acc[item] = (highest < evaluation ? evaluation : highest, evaluation + total);
          return acc;
      }).entries
      .map((entry) => ConsumptionQuota(
        id: '${entry.key.name.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}', 
        foodItemId: entry.key.id, 
        foodItemName: entry.key.name, 
        targetDate: periodEnd, 
        targetCount: (decider(entry.value) + roundingOffsetGracePeriod).round()
      )).toList();
  }

  /// Checks if quotas need to be regenerated
  static bool needsRegeneration({
    required List<ConsumptionQuota> existingQuotas,
    required ConsumptionPeriod period,
  }) {
    if (existingQuotas.isEmpty) return true;

    final now = DateTime.now();

    // Check if any quota's target date has passed (new period has started)
    return existingQuotas.every((q) => q.targetDate.isBefore(now));
  }
}
