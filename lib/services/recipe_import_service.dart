import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_manager/models/ingredient.dart';
import 'package:inventory_manager/models/recipe.dart';
import 'package:inventory_manager/models/recipe_ingredient.dart';
import 'package:inventory_manager/models/unit.dart';
import 'package:inventory_manager/services/recipe_database.dart';

/// Service for importing recipes from a JSON file
class RecipeImportService {
  final RecipeDatabase _database = RecipeDatabase.instance;

  /// Import recipes from a JSON URL
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "recipes": [
  ///     {
  ///       "title": "Recipe Name",
  ///       "readyInMinutes": 30,
  ///       "servings": 4,
  ///       "summary": "Recipe description",
  ///       "isFavorite": false,
  ///       "steps": [
  ///         {
  ///           "stepNumber": 1,
  ///           "instruction": "Step instruction"
  ///         }
  ///       ],
  ///       "ingredients": [
  ///         {
  ///           "name": "Ingredient Name",
  ///           "amount": 2,
  ///           "unit": "g"
  ///         }
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  Future<ImportResult> importRecipesFromUrl(String url) async {
    try {
      // Fetch JSON from URL
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return ImportResult(
          success: false,
          error: 'Failed to fetch recipes: HTTP ${response.statusCode}',
        );
      }

      // Parse JSON
      final jsonData = json.decode(response.body) as Map<String, dynamic>;

      if (!jsonData.containsKey('recipes')) {
        return ImportResult(
          success: false,
          error: 'Invalid JSON format: missing "recipes" field',
        );
      }

      final recipesList = jsonData['recipes'] as List<dynamic>;

      int successCount = 0;
      int failCount = 0;
      int skipCount = 0;
      final errors = <String>[];

      // Import each recipe
      for (final recipeData in recipesList) {
        try {
          await _importSingleRecipe(recipeData as Map<String, dynamic>);
          successCount++;
        } catch (e) {
          final title = recipeData['title'] ?? 'Unknown';
          if (e.toString().contains('Recipe already exists')) {
            skipCount++;
          } else {
            failCount++;
            errors.add('Failed to import "$title": $e');
          }
        }
      }

      return ImportResult(
        success: true,
        recipesImported: successCount,
        recipesFailed: failCount,
        recipesSkipped: skipCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Failed to import recipes: $e',
      );
    }
  }

  /// Import recipes from a local asset file
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "recipes": [
  ///     {
  ///       "title": "Recipe Name",
  ///       "readyInMinutes": 30,
  ///       "servings": 4,
  ///       "summary": "Recipe description",
  ///       "isFavorite": false,
  ///       "steps": [
  ///         {
  ///           "stepNumber": 1,
  ///           "instruction": "Step instruction"
  ///         }
  ///       ],
  ///       "ingredients": [
  ///         {
  ///           "name": "Ingredient Name",
  ///           "amount": 2,
  ///           "unit": "g"
  ///         }
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  Future<ImportResult> importRecipesFromAsset(String assetPath) async {
    try {
      // Load JSON from asset
      final String jsonString = await rootBundle.loadString(assetPath);

      // Parse JSON
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      if (!jsonData.containsKey('recipes')) {
        return ImportResult(
          success: false,
          error: 'Invalid JSON format: missing "recipes" field',
        );
      }

      final recipesList = jsonData['recipes'] as List<dynamic>;

      int successCount = 0;
      int failCount = 0;
      int skipCount = 0;
      final errors = <String>[];

      // Import each recipe
      for (final recipeData in recipesList) {
        try {
          await _importSingleRecipe(recipeData as Map<String, dynamic>);
          successCount++;
        } catch (e) {
          final title = recipeData['title'] ?? 'Unknown';
          if (e.toString().contains('Recipe already exists')) {
            skipCount++;
          } else {
            failCount++;
            errors.add('Failed to import "$title": $e');
          }
        }
      }

      return ImportResult(
        success: true,
        recipesImported: successCount,
        recipesFailed: failCount,
        recipesSkipped: skipCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: 'Failed to import recipes: $e',
      );
    }
  }

  /// Import a single recipe from JSON data
  Future<void> _importSingleRecipe(Map<String, dynamic> recipeData) async {
    // Check if recipe already exists
    final title = recipeData['title'] as String;
    final exists = await _database.recipeExistsByTitle(title);
    if (exists) {
      throw Exception('Recipe already exists');
    }

    // Parse instructions/steps
    final instructions = <String>[];

    // Support both formats: direct "instructions" array or nested "steps" array
    if (recipeData.containsKey('instructions')) {
      final instructionsList = recipeData['instructions'] as List<dynamic>;
      for (final instruction in instructionsList) {
        instructions.add(instruction as String);
      }
    } else if (recipeData.containsKey('steps')) {
      final steps = recipeData['steps'] as List<dynamic>;
      // Sort by step number to ensure correct order
      final sortedSteps = List<Map<String, dynamic>>.from(
        steps.map((e) => e as Map<String, dynamic>),
      )..sort((a, b) => (a['stepNumber'] as int).compareTo(b['stepNumber'] as int));

      for (final stepData in sortedSteps) {
        instructions.add(stepData['instruction'] as String);
      }
    }

    // Parse ingredients
    final recipeIngredients = <RecipeIngredient>[];
    if (recipeData.containsKey('ingredients')) {
      final ingredients = recipeData['ingredients'] as List<dynamic>;
      for (final ingredientData in ingredients) {
        final ingredientMap = ingredientData as Map<String, dynamic>;

        // Get or create the ingredient
        // Support both "ingredient" and "name" fields
        final ingredientName = (ingredientMap['ingredient'] ?? ingredientMap['name']) as String;
        Ingredient? ingredient = await _database.getIngredientByName(ingredientName);
        ingredient ??= await _database.createIngredient(ingredientName);

        // Get or create the unit (with default if not specified)
        final unitName = (ingredientMap['unit'] ?? 'piece') as String;
        Unit? unit = await _database.getUnitByName(unitName);
        unit ??= await _database.createUnit(unitName);

        // Create recipe ingredient (with amount defaulting to 1 if not specified)
        final amount = (ingredientMap['amount'] as num?)?.toDouble() ?? 1.0;
        recipeIngredients.add(RecipeIngredient(
          ingredientId: ingredient.id!,
          amount: amount,
          unitId: unit.id!,
          ingredient: ingredient,
          unit: unit,
        ));
      }
    }

    // Create the complete recipe object
    final recipe = Recipe(
      title: recipeData['title'] as String,
      readyInMinutes: recipeData['readyInMinutes'] as int,
      servings: recipeData['servings'] as int,
      imageUrl: recipeData['imageUrl'] as String?,
      summary: recipeData['summary'] as String?,
      isFavorite: (recipeData['isFavorite'] as bool?) ?? false,
      ingredients: recipeIngredients,
      instructions: instructions,
    );

    // Save to database
    await _database.createRecipe(recipe);
  }
}

/// Result of a recipe import operation
class ImportResult {
  final bool success;
  final int recipesImported;
  final int recipesFailed;
  final int recipesSkipped;
  final String? error;
  final List<String> errors;

  ImportResult({
    required this.success,
    this.recipesImported = 0,
    this.recipesFailed = 0,
    this.recipesSkipped = 0,
    this.error,
    this.errors = const [],
  });

  String get message {
    if (!success) {
      return error ?? 'Import failed';
    }

    final parts = <String>[];
    if (recipesImported > 0) {
      parts.add('$recipesImported imported');
    }
    if (recipesSkipped > 0) {
      parts.add('$recipesSkipped skipped');
    }
    if (recipesFailed > 0) {
      parts.add('$recipesFailed failed');
    }

    if (parts.isEmpty) {
      return 'No recipes to import';
    }

    return 'Import complete: ${parts.join(', ')}';
  }

  bool get hasErrors => errors.isNotEmpty;
}
