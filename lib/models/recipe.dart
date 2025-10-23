class Recipe {
  final String id;
  final String title;
  final String? imageUrl;
  final int readyInMinutes;
  final int servings;
  final String? summary;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, double>? nutrition; // Optional nutritional info

  const Recipe({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.readyInMinutes,
    required this.servings,
    this.summary,
    required this.ingredients,
    required this.instructions,
    this.nutrition,
  });

  // CopyWith method for immutable updates
  Recipe copyWith({
    String? id,
    String? title,
    String? imageUrl,
    int? readyInMinutes,
    int? servings,
    String? summary,
    List<String>? ingredients,
    List<String>? instructions,
    Map<String, double>? nutrition,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      servings: servings ?? this.servings,
      summary: summary ?? this.summary,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutrition: nutrition ?? this.nutrition,
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
    return 'Recipe(id: $id, title: $title, readyIn: $readyInMinutes min, servings: $servings)';
  }

  // Convert to JSON for storage (favorites)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'summary': summary,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutrition': nutrition,
    };
  }

  // Create from JSON (for favorites and API responses)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Recipe',
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String?,
      readyInMinutes: (json['readyInMinutes'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      summary: json['summary'] as String?,
      ingredients: _parseIngredients(json),
      instructions: _parseInstructions(json),
      nutrition: _parseNutrition(json),
    );
  }

  static List<String> _parseIngredients(Map<String, dynamic> json) {
    if (json['extendedIngredients'] != null) {
      final List<dynamic> extendedIngredients = json['extendedIngredients'] as List<dynamic>;
      return extendedIngredients
          .map((ing) => ing['original'] as String? ?? '')
          .where((str) => str.isNotEmpty)
          .toList();
    } else if (json['ingredients'] != null) {
      return (json['ingredients'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
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
