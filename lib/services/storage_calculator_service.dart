import 'package:inventory_manager/models/inventory_batch.dart';

class StorageCalculatorService {
  // Calculate total calories across all batches
  static double calculateTotalCalories(
    List<InventoryBatch> batches,
  ) {
    return batches.fold(
      0.0,
      (sum, batch) => sum + batch.getTotalCalories(),
    );
  }

  static double? calculateDaysOfStorage(
    List<InventoryBatch> batches, {
    int? dailyCalorieConsumption,
  }) {
    // Only calculate if daily consumption is set (via calculator)
    if (dailyCalorieConsumption == null || dailyCalorieConsumption <= 0) {
      return null;
    }

    final calories = calculateTotalCalories(batches);
    return calories / dailyCalorieConsumption;
  }

  // Get storage status summary
  static StorageStatus getStorageStatus({
    required List<InventoryBatch> batches,
    int? dailyCalorieConsumption,
  }) {
    final totalCalories = calculateTotalCalories(batches);
    final daysOfStorage = calculateDaysOfStorage(
      batches,
      dailyCalorieConsumption: dailyCalorieConsumption,
    );

    return StorageStatus(
      totalItems: batches.fold(0, (sum, batch) => sum + batch.count),
      totalBatches: batches.length,
      totalCalories: totalCalories,
      estimatedDays: daysOfStorage,
      limitingFactor: '',
    );
  }

}

class StorageStatus {
  final int totalItems;
  final int totalBatches;
  final double totalCalories;
  final double? estimatedDays; // Nullable - only calculated when daily consumption is configured
  final String limitingFactor;

  StorageStatus({
    required this.totalItems,
    required this.totalBatches,
    required this.totalCalories,
    required this.estimatedDays,
    required this.limitingFactor,
  });
}
