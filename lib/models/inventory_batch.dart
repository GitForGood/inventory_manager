import 'package:inventory_manager/models/food_item.dart';

class InventoryBatch {
  final String id;
  final FoodItem item;
  final int count;
  final int initialCount;
  final DateTime expirationDate;
  final DateTime dateAdded;

  InventoryBatch({
    required this.id,
    required this.item,
    required this.count,
    required this.initialCount,
    required this.expirationDate,
    required this.dateAdded,
  });

  // CopyWith method for immutable updates
  InventoryBatch copyWith({
    String? id,
    FoodItem? item,
    int? count,
    int? initialCount,
    DateTime? expirationDate,
    DateTime? dateAdded,
  }) {
    return InventoryBatch(
      id: id ?? this.id,
      item: item ?? this.item,
      count: count ?? this.count,
      initialCount: initialCount ?? this.initialCount,
      expirationDate: expirationDate ?? this.expirationDate,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  // Check if the batch is expired
  bool isExpired([DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    return expirationDate.isBefore(now);
  }

  // Get days until expiration (negative if already expired)
  int daysUntilExpiration([DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    return expirationDate.difference(now).inDays;
  }

  // Check if batch is expiring soon (within specified days)
  bool isExpiringSoon({int daysThreshold = 7, DateTime? currentDate}) {
    final days = daysUntilExpiration(currentDate);
    return days >= 0 && days <= daysThreshold;
  }

  // Get total nutrition for entire batch
  Map<String, double> getTotalNutrition() {
    final nutritionPerItem = item.getNutritionForWeight(100.0);
    return {
      'carbohydrates': nutritionPerItem['carbohydrates']! * count,
      'fats': nutritionPerItem['fats']! * count,
      'protein': nutritionPerItem['protein']! * count,
      'kcal': nutritionPerItem['kcal']! * count,
    };
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryBatch &&
        other.id == id &&
        other.item == item &&
        other.count == count &&
        other.initialCount == initialCount &&
        other.expirationDate == expirationDate;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode {
    return Object.hash(id, item, count, initialCount, expirationDate);
  }

  // ToString for debugging
  @override
  String toString() {
    return 'InventoryBatch(id: $id, item: ${item.name}, count: $count, initialCount: $initialCount'
        'expires: ${expirationDate.toIso8601String()})';
  }
}
