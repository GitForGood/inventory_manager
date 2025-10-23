import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_manager/models/recipe.dart';

class FavoritesRepository {
  static const String _favoritesKey = 'favorite_recipes';
  static const String _apiKeyKey = 'spoonacular_api_key';

  // Save favorite recipes
  Future<void> saveFavorites(List<Recipe> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = favorites.map((recipe) => recipe.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save favorites: $e');
    }
  }

  // Load favorite recipes
  Future<List<Recipe>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);

      if (jsonString == null) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list if loading fails
      return [];
    }
  }

  // Add a recipe to favorites
  Future<void> addFavorite(Recipe recipe) async {
    final favorites = await loadFavorites();

    // Check if already favorited
    if (!favorites.any((r) => r.id == recipe.id)) {
      favorites.add(recipe);
      await saveFavorites(favorites);
    }
  }

  // Remove a recipe from favorites
  Future<void> removeFavorite(String recipeId) async {
    final favorites = await loadFavorites();
    favorites.removeWhere((r) => r.id == recipeId);
    await saveFavorites(favorites);
  }

  // Check if a recipe is favorited
  Future<bool> isFavorite(String recipeId) async {
    final favorites = await loadFavorites();
    return favorites.any((r) => r.id == recipeId);
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
    } catch (e) {
      throw Exception('Failed to clear favorites: $e');
    }
  }

  // Save API key
  Future<void> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
    } catch (e) {
      throw Exception('Failed to save API key: $e');
    }
  }

  // Load API key
  Future<String?> loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_apiKeyKey);
    } catch (e) {
      return null;
    }
  }
}
