import 'package:inventory_manager/models/inventory_batch.dart';

class StorageCalculatorService {
  // Calculate total nutrition across all batches
  static Map<String, double> calculateTotalNutrition(
    List<InventoryBatch> batches,
  ) {
    double totalCarbs = 0;
    double totalFats = 0;
    double totalProtein = 0;
    double totalKcal = 0;

    for (final batch in batches) {
      final nutrition = batch.getTotalNutrition();
      totalCarbs += nutrition['carbohydrates']!;
      totalFats += nutrition['fats']!;
      totalProtein += nutrition['protein']!;
      totalKcal += nutrition['kcal']!;
    }

    return {
      'carbohydrates': totalCarbs,
      'fats': totalFats,
      'protein': totalProtein,
      'kcal': totalKcal,
    };
  }

  // Calculate how many days the current storage can sustain based on daily targets
  static Map<String, double> calculateDaysOfStorage({
    required Map<String, double> totalNutrition,
    required double dailyCalorieTarget,
    required double dailyCarbohydratesTarget,
    required double dailyFatsTarget,
    required double dailyProteinTarget,
  }) {
    final daysFromCalories = totalNutrition['kcal']! / dailyCalorieTarget;
    final daysFromCarbs =
        totalNutrition['carbohydrates']! / dailyCarbohydratesTarget;
    final daysFromFats = totalNutrition['fats']! / dailyFatsTarget;
    final daysFromProtein = totalNutrition['protein']! / dailyProteinTarget;

    // The limiting factor is the nutrient that runs out first
    final minDays = [
      daysFromCalories,
      daysFromCarbs,
      daysFromFats,
      daysFromProtein,
    ].reduce((a, b) => a < b ? a : b);

    return {
      'daysFromCalories': daysFromCalories,
      'daysFromCarbs': daysFromCarbs,
      'daysFromFats': daysFromFats,
      'daysFromProtein': daysFromProtein,
      'minDays': minDays,
    };
  }

  // Get storage status summary
  static StorageStatus getStorageStatus({
    required List<InventoryBatch> batches,
  }) {
    final totalNutrition = calculateTotalNutrition(batches);

    return StorageStatus(
      totalItems: batches.fold(0, (sum, batch) => sum + batch.count),
      totalBatches: batches.length,
      totalNutrition: totalNutrition,
      estimatedDays: 0,
      limitingFactor: '',
    );
  }

}

class StorageStatus {
  final int totalItems;
  final int totalBatches;
  final Map<String, double> totalNutrition;
  final double estimatedDays;
  final String limitingFactor;

  StorageStatus({
    required this.totalItems,
    required this.totalBatches,
    required this.totalNutrition,
    required this.estimatedDays,
    required this.limitingFactor,
  });
}
