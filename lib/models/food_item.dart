class FoodItem {
  //id and info
  final String id;
  final String name;
  final double weightPerItemGrams; // Weight of one item in grams
  final double kcalPerHundredGrams; // Calories per 100g
  // ingredient tags for recipe lookup
  final List<int> ingredientIds; // IDs of ingredients this food item corresponds to

  FoodItem({
    required this.id,
    required this.name,
    this.weightPerItemGrams = 100.0, // Default 100g per item
    required this.kcalPerHundredGrams,
    this.ingredientIds = const [],
  });

  // CopyWith method for immutable updates
  FoodItem copyWith({
    String? id,
    String? name,
    double? weightPerItemGrams,
    double? kcalPerHundredGrams,
    List<int>? ingredientIds,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      weightPerItemGrams: weightPerItemGrams ?? this.weightPerItemGrams,
      kcalPerHundredGrams: kcalPerHundredGrams ?? this.kcalPerHundredGrams,
      ingredientIds: ingredientIds ?? this.ingredientIds,
    );
  }

  // Calculate calories for a number of items
  double getKcalForItems(int itemCount) {
    final totalGrams = itemCount * weightPerItemGrams;
    return getKcalForWeight(totalGrams);
  }

  // Calculate calories for specific weight in grams
  double getKcalForWeight(double grams) {
    final multiplier = grams / 100.0;
    return kcalPerHundredGrams * multiplier;
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem &&
        other.id == id &&
        other.name == name &&
        other.weightPerItemGrams == weightPerItemGrams &&
        other.kcalPerHundredGrams == kcalPerHundredGrams &&
        _listEquals(other.ingredientIds, ingredientIds);
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      weightPerItemGrams,
      kcalPerHundredGrams,
      Object.hashAll(ingredientIds),
    );
  }

  // ToString for debugging
  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, weight: ${weightPerItemGrams}g/item, kcal: $kcalPerHundredGrams/100g)';
  }
}
