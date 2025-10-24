import 'package:inventory_manager/models/ingredient.dart';
import 'package:inventory_manager/models/unit.dart';

class RecipeIngredient {
  final int? recipeId;
  final int ingredientId;
  final double amount;
  final int unitId;

  // Optional: For displaying full ingredient information
  final Ingredient? ingredient;
  final Unit? unit;

  const RecipeIngredient({
    this.recipeId,
    required this.ingredientId,
    required this.amount,
    required this.unitId,
    this.ingredient,
    this.unit,
  });

  // CopyWith method for immutable updates
  RecipeIngredient copyWith({
    int? recipeId,
    int? ingredientId,
    double? amount,
    int? unitId,
    Ingredient? ingredient,
    Unit? unit,
  }) {
    return RecipeIngredient(
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      amount: amount ?? this.amount,
      unitId: unitId ?? this.unitId,
      ingredient: ingredient ?? this.ingredient,
      unit: unit ?? this.unit,
    );
  }

  // ToString for debugging
  @override
  String toString() {
    final ingredientName = ingredient?.name ?? 'Ingredient($ingredientId)';
    final unitName = unit?.name ?? 'Unit($unitId)';
    return 'RecipeIngredient(recipe: $recipeId, amount: $amount $unitName of $ingredientName)';
  }

  // Display string for UI
  String get displayString {
    final ingredientName = ingredient?.name ?? '';
    final unitName = unit?.name ?? '';
    return '$amount $unitName $ingredientName';
  }

  // Convert to JSON/Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'ingredientId': ingredientId,
      'amount': amount,
      'unitId': unitId,
    };
  }

  // Create from Map (database row)
  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      recipeId: map['recipeId'] as int?,
      ingredientId: map['ingredientId'] as int,
      amount: map['amount'] as double,
      unitId: map['unitId'] as int,
    );
  }

  // Create from Map with joined ingredient and unit data
  factory RecipeIngredient.fromMapWithDetails(Map<String, dynamic> map) {
    return RecipeIngredient(
      recipeId: map['recipeId'] as int?,
      ingredientId: map['ingredientId'] as int,
      amount: map['amount'] as double,
      unitId: map['unitId'] as int,
      ingredient: map['ingredientName'] != null
          ? Ingredient(id: map['ingredientId'] as int, name: map['ingredientName'] as String)
          : null,
      unit: map['unitName'] != null
          ? Unit(id: map['unitId'] as int, name: map['unitName'] as String)
          : null,
    );
  }
}
