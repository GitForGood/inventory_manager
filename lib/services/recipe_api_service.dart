import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_manager/models/recipe.dart';

class RecipeApiService {
  // Using Spoonacular API - users will need to get their own API key
  // Free tier: 150 requests/day
  // Sign up at: https://spoonacular.com/food-api
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';

  // NOTE: This should be stored securely, not hardcoded
  // For now, we'll make it configurable
  static String? _apiKey;

  static void setApiKey(String key) {
    _apiKey = key;
  }

  // Search recipes by query
  static Future<List<Recipe>> searchRecipes({
    required String query,
    int number = 10,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key not set. Please configure your Spoonacular API key.');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/complexSearch?query=$query&number=$number&addRecipeInformation=true&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;

        return results
            .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 402) {
        throw Exception('API quota exceeded');
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching recipes: $e');
    }
  }

  // Get recipe details by ID
  static Future<Recipe> getRecipeDetails(String id) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key not set');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/$id/information?includeNutrition=true&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Recipe.fromJson(data);
      } else {
        throw Exception('Failed to load recipe details');
      }
    } catch (e) {
      throw Exception('Error fetching recipe details: $e');
    }
  }

  // Get random recipes
  static Future<List<Recipe>> getRandomRecipes({int number = 10}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key not set');
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/random?number=$number&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final recipes = data['recipes'] as List<dynamic>;

        return recipes
            .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load random recipes');
      }
    } catch (e) {
      throw Exception('Error fetching random recipes: $e');
    }
  }

  // Search recipes by ingredients (from inventory)
  static Future<List<Recipe>> searchByIngredients({
    required List<String> ingredients,
    int number = 10,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key not set');
    }

    try {
      final ingredientsString = ingredients.join(',');
      final url = Uri.parse(
        '$_baseUrl/findByIngredients?ingredients=$ingredientsString&number=$number&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        // Get full details for each recipe
        final recipes = <Recipe>[];
        for (final item in data.take(number)) {
          final id = item['id'].toString();
          try {
            final recipe = await getRecipeDetails(id);
            recipes.add(recipe);
          } catch (e) {
            // Skip recipes that fail to load
            continue;
          }
        }

        return recipes;
      } else {
        throw Exception('Failed to search by ingredients');
      }
    } catch (e) {
      throw Exception('Error searching by ingredients: $e');
    }
  }
}
