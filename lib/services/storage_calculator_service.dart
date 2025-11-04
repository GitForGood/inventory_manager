import 'package:inventory_manager/models/inventory_batch.dart';

class StorageCalculatorService {
  // Calculate total nutrition across all batches
  static Map<String, double> calculateTotalNutrition(
    List<InventoryBatch> batches,
  ) {

    double totalKcal = 0;

    for (final batch in batches) {
      final nutrition = batch.getTotalNutrition();
      totalKcal += nutrition['kcal']!;
    }
    return {
      'kcal': totalKcal,
    };
  }

  static double? calculateDaysOfStorage(
    List<InventoryBatch> batches, {
    int? dailyCalorieConsumption,
  }) {
    // Only calculate if daily consumption is set (via calculator)
    if (dailyCalorieConsumption == null || dailyCalorieConsumption <= 0) {
      return null;
    }

    final calories = batches.fold(0.0, (sum, batch) => sum + (batch.getTotalNutrition()['kcal'] ?? 0));
    return calories / dailyCalorieConsumption;
  }

  // Get storage status summary
  static StorageStatus getStorageStatus({
    required List<InventoryBatch> batches,
    int? dailyCalorieConsumption,
  }) {
    final totalNutrition = calculateTotalNutrition(batches);
    final daysOfStorage = calculateDaysOfStorage(
      batches,
      dailyCalorieConsumption: dailyCalorieConsumption,
    );

    return StorageStatus(
      totalItems: batches.fold(0, (sum, batch) => sum + batch.count),
      totalBatches: batches.length,
      totalNutrition: totalNutrition,
      estimatedDays: daysOfStorage,
      limitingFactor: '',
    );
  }

}

class StorageStatus {
  final int totalItems;
  final int totalBatches;
  final Map<String, double> totalNutrition;
  final double? estimatedDays; // Nullable - only calculated when daily consumption is configured
  final String limitingFactor;

  StorageStatus({
    required this.totalItems,
    required this.totalBatches,
    required this.totalNutrition,
    required this.estimatedDays,
    required this.limitingFactor,
  });
}
