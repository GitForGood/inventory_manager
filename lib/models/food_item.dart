class FoodItem {
  //id and info
  final String id;
  final String name;
  final double weightPerItemGrams; // Weight of one item in grams
  //nutrition
  final double carbohydratesPerHundredGrams;
  final double fatsPerHundredGrams;
  final double proteinPerHundredGrams;
  final double kcalPerHundredGrams;

  FoodItem({
    required this.id,
    required this.name,
    this.weightPerItemGrams = 100.0, // Default 100g per item
    required this.carbohydratesPerHundredGrams,
    required this.fatsPerHundredGrams,
    required this.proteinPerHundredGrams,
    required this.kcalPerHundredGrams,
  });

  // CopyWith method for immutable updates
  FoodItem copyWith({
    String? id,
    String? name,
    double? weightPerItemGrams,
    double? carbohydratesPerHundredGrams,
    double? fatsPerHundredGrams,
    double? proteinPerHundredGrams,
    double? kcalPerHundredGrams,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      weightPerItemGrams: weightPerItemGrams ?? this.weightPerItemGrams,
      carbohydratesPerHundredGrams: carbohydratesPerHundredGrams ?? this.carbohydratesPerHundredGrams,
      fatsPerHundredGrams: fatsPerHundredGrams ?? this.fatsPerHundredGrams,
      proteinPerHundredGrams: proteinPerHundredGrams ?? this.proteinPerHundredGrams,
      kcalPerHundredGrams: kcalPerHundredGrams ?? this.kcalPerHundredGrams,
    );
  }

  // Calculate nutrition for a number of items
  Map<String, double> getNutritionForItems(int itemCount) {
    final totalGrams = itemCount * weightPerItemGrams;
    return getNutritionForWeight(totalGrams);
  }

  // Calculate nutrition for specific weight in grams
  Map<String, double> getNutritionForWeight(double grams) {
    final multiplier = grams / 100.0;
    return {
      'carbohydrates': carbohydratesPerHundredGrams * multiplier,
      'fats': fatsPerHundredGrams * multiplier,
      'protein': proteinPerHundredGrams * multiplier,
      'kcal': kcalPerHundredGrams * multiplier,
    };
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem &&
        other.id == id &&
        other.name == name &&
        other.weightPerItemGrams == weightPerItemGrams &&
        other.carbohydratesPerHundredGrams == carbohydratesPerHundredGrams &&
        other.fatsPerHundredGrams == fatsPerHundredGrams &&
        other.proteinPerHundredGrams == proteinPerHundredGrams &&
        other.kcalPerHundredGrams == kcalPerHundredGrams;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      weightPerItemGrams,
      carbohydratesPerHundredGrams,
      fatsPerHundredGrams,
      proteinPerHundredGrams,
      kcalPerHundredGrams,
    );
  }

  // ToString for debugging
  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, weight: ${weightPerItemGrams}g/item, '
           'carbs: ${carbohydratesPerHundredGrams}g, fats: ${fatsPerHundredGrams}g, '
           'protein: ${proteinPerHundredGrams}g, kcal: $kcalPerHundredGrams)';
  }
}
