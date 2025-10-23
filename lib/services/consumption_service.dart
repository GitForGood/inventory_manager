import 'package:inventory_manager/models/inventory_batch.dart';

class ConsumptionService {
  // Consume items from inventory batches using FIFO (First In, First Out)
  // Returns updated batches and the number of items actually consumed
  static ConsumptionResult consumeFromBatches({
    required List<InventoryBatch> batches,
    required String foodItemName,
    required int itemCount,
  }) {
    // Filter batches for the specific food item
    final relevantBatches = batches
        .where((batch) => batch.item.name.toLowerCase() == foodItemName.toLowerCase())
        .toList();

    if (relevantBatches.isEmpty) {
      return ConsumptionResult(
        updatedBatches: batches,
        itemsConsumed: 0,
        success: false,
        message: 'No batches found for $foodItemName',
      );
    }

    // Sort by expiration date (oldest first - FIFO)
    relevantBatches.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

    int remainingToConsume = itemCount;
    final updatedBatches = List<InventoryBatch>.from(batches);
    final consumedBatches = <InventoryBatch>[];

    // Consume from batches starting with the oldest
    for (final batch in relevantBatches) {
      if (remainingToConsume <= 0) break;

      if (batch.count <= remainingToConsume) {
        // Consume entire batch
        remainingToConsume -= batch.count;
        consumedBatches.add(batch);

        // Remove batch from updated list
        updatedBatches.removeWhere((b) => b.id == batch.id);
      } else {
        // Partially consume batch
        final newCount = batch.count - remainingToConsume;
        remainingToConsume = 0;

        // Update batch count
        final batchIndex = updatedBatches.indexWhere((b) => b.id == batch.id);
        if (batchIndex != -1) {
          updatedBatches[batchIndex] = batch.copyWith(count: newCount);
        }
      }
    }

    final totalConsumed = itemCount - remainingToConsume;

    return ConsumptionResult(
      updatedBatches: updatedBatches,
      itemsConsumed: totalConsumed,
      success: remainingToConsume <= 0,
      message: remainingToConsume > 0
          ? 'Only $totalConsumed items available ($remainingToConsume short)'
          : 'Successfully consumed $totalConsumed items',
      consumedBatchIds: consumedBatches.map((b) => b.id).toList(),
    );
  }

  // Calculate suggested consumption based on expiration dates
  static Map<String, SuggestedConsumption> getSuggestedConsumptions({
    required List<InventoryBatch> batches,
    required int daysAhead,
  }) {
    final suggestions = <String, SuggestedConsumption>{};
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: daysAhead));

    // Group batches by food item name
    final batchesByFood = <String, List<InventoryBatch>>{};
    for (final batch in batches) {
      final name = batch.item.name;
      batchesByFood.putIfAbsent(name, () => []).add(batch);
    }

    // Calculate suggestions for each food item
    for (final entry in batchesByFood.entries) {
      final foodName = entry.key;
      final foodBatches = entry.value;

      // Find batches expiring within the target period
      final expiringBatches = foodBatches
          .where((batch) =>
              batch.expirationDate.isBefore(targetDate) &&
              batch.expirationDate.isAfter(now))
          .toList();

      if (expiringBatches.isNotEmpty) {
        // Sort by expiration date
        expiringBatches.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

        final totalItems = expiringBatches.fold<int>(
          0,
          (sum, batch) => sum + batch.count,
        );

        final daysUntilExpiration = expiringBatches.first.daysUntilExpiration();
        final itemsPerDay = daysUntilExpiration > 0
            ? totalItems / daysUntilExpiration
            : totalItems.toDouble();

        suggestions[foodName] = SuggestedConsumption(
          foodName: foodName,
          totalItems: totalItems,
          itemsPerDay: itemsPerDay,
          daysUntilExpiration: daysUntilExpiration,
          batchCount: expiringBatches.length,
          earliestExpiration: expiringBatches.first.expirationDate,
        );
      }
    }

    return suggestions;
  }

  // Calculate total available items for a food item
  static int getTotalAvailable({
    required List<InventoryBatch> batches,
    required String foodItemName,
  }) {
    final relevantBatches = batches.where(
      (batch) => batch.item.name.toLowerCase() == foodItemName.toLowerCase(),
    );

    return relevantBatches.fold<int>(
      0,
      (sum, batch) => sum + batch.count,
    );
  }
}

class ConsumptionResult {
  final List<InventoryBatch> updatedBatches;
  final int itemsConsumed;
  final bool success;
  final String message;
  final List<String> consumedBatchIds;

  ConsumptionResult({
    required this.updatedBatches,
    required this.itemsConsumed,
    required this.success,
    required this.message,
    this.consumedBatchIds = const [],
  });
}

class SuggestedConsumption {
  final String foodName;
  final int totalItems;
  final double itemsPerDay;
  final int daysUntilExpiration;
  final int batchCount;
  final DateTime earliestExpiration;

  SuggestedConsumption({
    required this.foodName,
    required this.totalItems,
    required this.itemsPerDay,
    required this.daysUntilExpiration,
    required this.batchCount,
    required this.earliestExpiration,
  });
}
