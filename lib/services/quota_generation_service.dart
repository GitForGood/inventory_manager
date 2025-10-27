import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
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
  /// **Algorithm**:
  /// 1. For batches expiring within this period: consume all remaining items
  /// 2. For other batches: divide remaining items by remaining complete periods until expiration
  /// 3. Periods are counted respecting calendar boundaries (e.g., monthly counts actual months)
  /// 4. This ensures even distribution based on current inventory and time remaining
  ///
  /// **Example** (Monthly period, today is Oct 15):
  /// - Period: Oct 1 - Oct 31
  /// - Batch with 100 items expires Dec 20
  /// - Remaining months: Oct, Nov, Dec = 3 months
  /// - Quota for October: 100 / 3 = 34 items
  static List<ConsumptionQuota> generateQuotasForCurrentPeriod({
    required List<InventoryBatch> batches,
    required ConsumptionPeriod period,
  }) {
    final quotas = <ConsumptionQuota>[];
    final now = DateTime.now();
    final periodEnd = period.getCurrentPeriodEnd();

    // Group batches by food item name
    final batchesByFoodItem = <String, List<InventoryBatch>>{};
    for (final batch in batches) {
      // Skip empty batches
      if (batch.count <= 0) continue;

      batchesByFoodItem
          .putIfAbsent(batch.item.name, () => [])
          .add(batch);
    }

    // Generate one quota per food item
    for (final entry in batchesByFoodItem.entries) {
      final foodItemName = entry.key;
      final foodBatches = entry.value;

      int totalTargetCount = 0;
      String? foodItemId;

      // Calculate proportional consumption for each batch
      for (final batch in foodBatches) {
        foodItemId ??= batch.item.id;

        // If batch expires within this period or is already expired, consume all remaining
        if (batch.expirationDate.isBefore(periodEnd) ||
            batch.expirationDate.difference(now).inDays <= 0) {
          totalTargetCount += batch.count;
          continue;
        }

        // Calculate how many complete periods fit from now until expiration
        // using the period-aware method that respects calendar boundaries
        final remainingPeriods = period.getPeriodsCount(now, batch.expirationDate);

        // If less than 1 period remaining, consume all
        if (remainingPeriods < 1) {
          totalTargetCount += batch.count;
          continue;
        }

        // Items per period for this batch (proportional to remaining periods)
        final itemsPerPeriod = (batch.count / remainingPeriods).ceil();

        totalTargetCount += itemsPerPeriod;
      }

      // Create aggregated quota for this food item
      if (totalTargetCount > 0 && foodItemId != null) {
        quotas.add(ConsumptionQuota(
          id: '${foodItemName.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}',
          batchId: '', // Not tied to specific batch - aggregated quota
          foodItemId: foodItemId,
          foodItemName: foodItemName,
          targetDate: periodEnd,
          targetCount: totalTargetCount,
        ));
      }
    }

    return quotas;
  }

  /// Legacy method for batch-specific generation - now deprecated
  /// Use generateQuotasForCurrentPeriod instead
  @Deprecated('Use generateQuotasForCurrentPeriod for aggregated quotas')
  static List<ConsumptionQuota> generateQuotasForBatch({
    required InventoryBatch batch,
    required ConsumptionPeriod period,
  }) {
    // Delegate to the new method
    return generateQuotasForCurrentPeriod(
      batches: [batch],
      period: period,
    );
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
