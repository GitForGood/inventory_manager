import 'package:inventory_manager/models/recipe_ingredient.dart';

class Recipe {
  final int? id; // Changed to int? for database auto-increment
  final String title;
  final String? imageUrl;
  final int readyInMinutes; // renamed from time
  final int servings; // renamed from portions
  final String? summary;
  final List<RecipeIngredient> ingredients; // Changed to RecipeIngredient list
  final List<String> instructions; // This will be stored as recipe_steps
  final Map<String, double>? nutrition; // Optional nutritional info
  final bool isFavorite; // Added for favoriting

  const Recipe({
    this.id,
    required this.title,
    this.imageUrl,
    required this.readyInMinutes,
    required this.servings,
    this.summary,
    required this.ingredients,
    required this.instructions,
    this.nutrition,
    this.isFavorite = false,
  });

  // CopyWith method for immutable updates
  Recipe copyWith({
    int? id,
    String? title,
    String? imageUrl,
    int? readyInMinutes,
    int? servings,
    String? summary,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    Map<String, double>? nutrition,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      servings: servings ?? this.servings,
      summary: summary ?? this.summary,
      ingredients: ingredients ?? List.from(this.ingredients),
      instructions: instructions ?? List.from(this.instructions),
      nutrition: nutrition ?? this.nutrition,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode => id.hashCode;

  // ToString for debugging
  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, readyIn: $readyInMinutes min, servings: $servings, favorite: $isFavorite)';
  }

  // Convert to Map for database storage (recipes table only)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'summary': summary,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  // Convert to JSON for legacy API compatibility
  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'title': title,
      'imageUrl': imageUrl,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'summary': summary,
      'ingredients': ingredients.map((i) => i.displayString).toList(),
      'instructions': instructions,
      'nutrition': nutrition,
      'isFavorite': isFavorite,
    };
  }

  // Create from Map (database row) - requires separate loading of ingredients/steps
  factory Recipe.fromMap(Map<String, dynamic> map, {
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
  }) {
    return Recipe(
      id: map['id'] as int?,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String?,
      readyInMinutes: map['readyInMinutes'] as int,
      servings: map['servings'] as int,
      summary: map['summary'] as String?,
      ingredients: ingredients ?? [],
      instructions: instructions ?? [],
      isFavorite: (map['isFavorite'] as int?) == 1,
    );
  }

  // Create from JSON (for API responses and legacy data)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      title: json['title'] as String? ?? 'Unknown Recipe',
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String?,
      readyInMinutes: (json['readyInMinutes'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      summary: json['summary'] as String?,
      ingredients: _parseIngredientsFromJson(json),
      instructions: _parseInstructions(json),
      nutrition: _parseNutrition(json),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  // Parse ingredients from API JSON - creates RecipeIngredient objects
  // Note: This is a temporary solution for API data, proper database storage should be used
  static List<RecipeIngredient> _parseIngredientsFromJson(Map<String, dynamic> json) {
    if (json['extendedIngredients'] != null) {
      // API response format - we'll need to convert these to proper RecipeIngredient objects
      // For now, return empty list as this requires ingredient/unit lookup
      return [];
    } else if (json['ingredients'] != null && json['ingredients'] is List) {
      // Already in our format or legacy format
      if ((json['ingredients'] as List).isNotEmpty &&
          (json['ingredients'] as List).first is Map) {
        // Assume it's RecipeIngredient format
        return [];
      }
    }
    return [];
  }

  static List<String> _parseInstructions(Map<String, dynamic> json) {
    if (json['analyzedInstructions'] != null &&
        (json['analyzedInstructions'] as List).isNotEmpty) {
      final List<dynamic> steps =
          json['analyzedInstructions'][0]['steps'] as List<dynamic>;
      return steps
          .map((step) => step['step'] as String? ?? '')
          .where((str) => str.isNotEmpty)
          .toList();
    } else if (json['instructions'] != null) {
      if (json['instructions'] is List) {
        return (json['instructions'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      } else if (json['instructions'] is String) {
        return [json['instructions'] as String];
      }
    }
    return [];
  }

  static Map<String, double>? _parseNutrition(Map<String, dynamic> json) {
    if (json['nutrition'] != null) {
      final nutrition = json['nutrition'] as Map<String, dynamic>;
      if (nutrition['nutrients'] != null) {
        final nutrients = nutrition['nutrients'] as List<dynamic>;
        final Map<String, double> result = {};

        for (final nutrient in nutrients) {
          final name = (nutrient['name'] as String?)?.toLowerCase();
          final amount = (nutrient['amount'] as num?)?.toDouble();

          if (name != null && amount != null) {
            if (name.contains('carb')) {
              result['carbohydrates'] = amount;
            } else if (name.contains('fat') && !name.contains('saturated')) {
              result['fats'] = amount;
            } else if (name.contains('protein')) {
              result['protein'] = amount;
            } else if (name.contains('calorie')) {
              result['kcal'] = amount;
            }
          }
        }
        return result.isNotEmpty ? result : null;
      }
    }
    return json['nutrition'] as Map<String, double>?;
  }
}
