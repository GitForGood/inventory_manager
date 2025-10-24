import 'package:inventory_manager/models/food_item.dart';
import 'package:inventory_manager/models/inventory_batch.dart';

/// Groups multiple batches of the same food item together
class FoodItemGroup {
  final FoodItem foodItem;
  final List<InventoryBatch> batches;

  FoodItemGroup({
    required this.foodItem,
    required this.batches,
  });

  /// Total count across all batches
  int get totalCount {
    return batches.fold(0, (sum, batch) => sum + batch.count);
  }

  /// Total initial count across all batches
  int get totalInitialCount {
    return batches.fold(0, (sum, batch) => sum + batch.initialCount);
  }

  /// Number of batches in this group
  int get batchCount => batches.length;

  /// Earliest (closest) expiration date among all batches
  DateTime get closestExpirationDate {
    if (batches.isEmpty) {
      return DateTime.now();
    }
    return batches
        .map((batch) => batch.expirationDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Days until the closest expiration
  int get daysUntilClosestExpiration {
    final now = DateTime.now();
    return closestExpirationDate.difference(now).inDays;
  }

  /// Check if any batch is expired
  bool get hasExpiredBatch {
    return batches.any((batch) => batch.isExpired());
  }

  /// Check if any batch is expiring soon
  bool get hasExpiringSoonBatch {
    return batches.any((batch) => batch.isExpiringSoon());
  }

  /// Get the expiration status color for the group
  /// Red if any expired, orange if any expiring soon, green otherwise
  ExpirationStatus get expirationStatus {
    if (hasExpiredBatch) {
      return ExpirationStatus.expired;
    } else if (hasExpiringSoonBatch) {
      return ExpirationStatus.expiringSoon;
    } else {
      return ExpirationStatus.fresh;
    }
  }

  /// Get batches sorted by expiration date (earliest first)
  List<InventoryBatch> get batchesSortedByExpiration {
    final sortedBatches = List<InventoryBatch>.from(batches);
    sortedBatches.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    return sortedBatches;
  }

  /// Calculate total nutrition for all items in all batches
  Map<String, double> getTotalNutrition() {
    final totalCarbs = batches.fold<double>(
      0,
      (sum, batch) => sum + batch.getTotalNutrition()['carbohydrates']!,
    );
    final totalFats = batches.fold<double>(
      0,
      (sum, batch) => sum + batch.getTotalNutrition()['fats']!,
    );
    final totalProtein = batches.fold<double>(
      0,
      (sum, batch) => sum + batch.getTotalNutrition()['protein']!,
    );
    final totalKcal = batches.fold<double>(
      0,
      (sum, batch) => sum + batch.getTotalNutrition()['kcal']!,
    );

    return {
      'carbohydrates': totalCarbs,
      'fats': totalFats,
      'protein': totalProtein,
      'kcal': totalKcal,
    };
  }

  @override
  String toString() {
    return 'FoodItemGroup(item: ${foodItem.name}, batches: $batchCount, total: $totalCount)';
  }

  /// Static method to group a list of batches by food item
  static List<FoodItemGroup> groupBatches(List<InventoryBatch> batches) {
    final Map<String, List<InventoryBatch>> grouped = {};

    for (final batch in batches) {
      final key = batch.item.id;
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(batch);
    }

    return grouped.entries.map((entry) {
      final foodItem = entry.value.first.item;
      return FoodItemGroup(
        foodItem: foodItem,
        batches: entry.value,
      );
    }).toList();
  }
}

/// Enum for expiration status
enum ExpirationStatus {
  expired,
  expiringSoon,
  fresh,
}
