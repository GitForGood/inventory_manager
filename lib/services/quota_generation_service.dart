import 'package:inventory_manager/models/consumption_period.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:inventory_manager/models/inventory_batch.dart';

class QuotaGenerationService {
  /// Generates consumption quotas for the current period only
  ///
  /// Groups all batches by food item and creates one aggregated quota per item.
  /// Each batch contributes a proportional amount based on its lifespan.
  static List<ConsumptionQuota> generateQuotasForCurrentPeriod({
    required List<InventoryBatch> batches,
    required ConsumptionPeriod period,
  }) {
    final quotas = <ConsumptionQuota>[];
    final now = DateTime.now();
    final periodEnd = now.add(Duration(days: period.daysInPeriod));

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

        // Calculate total lifespan of this batch (from dateAdded to expiration)
        final totalLifespanDays = batch.expirationDate
            .difference(batch.dateAdded)
            .inDays;

        // If batch expires within this period or already expired, consume all remaining
        if (batch.expirationDate.isBefore(periodEnd) || totalLifespanDays <= 0) {
          totalTargetCount += batch.count;
          continue;
        }

        // Calculate how many periods fit in the total lifespan
        final totalPeriods = totalLifespanDays / period.daysInPeriod;

        // Items per period for this batch (proportional)
        final itemsPerPeriod = (batch.count / totalPeriods).ceil();

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
