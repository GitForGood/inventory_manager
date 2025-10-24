import 'package:inventory_manager/models/recipe.dart';
import 'package:inventory_manager/models/ingredient.dart';
import 'package:inventory_manager/models/unit.dart';
import 'package:inventory_manager/services/recipe_database.dart';

class RecipeRepository {
  final RecipeDatabase _database = RecipeDatabase.instance;

  // ===== RECIPE OPERATIONS =====

  /// Load only favorited recipes (called on app startup for performance)
  Future<List<Recipe>> loadFavorites() async {
    return await _database.getFavoriteRecipes();
  }

  /// Load all recipes (called when navigating to recipe search view)
  Future<List<Recipe>> loadAllRecipes() async {
    return await _database.getAllRecipes();
  }

  /// Get a single recipe by ID
  Future<Recipe?> getRecipe(int id) async {
    return await _database.getRecipe(id);
  }

  /// Search recipes by title
  Future<List<Recipe>> searchRecipes(String query) async {
    return await _database.searchRecipes(query);
  }

  /// Search recipes by ingredients
  Future<List<Recipe>> searchByIngredients(List<int> ingredientIds) async {
    return await _database.getRecipesByIngredients(ingredientIds);
  }

  /// Get recipes that can be made with a specific food item
  Future<List<Recipe>> getRecipesForFoodItem(String foodItemId) async {
    return await _database.getRecipesForFoodItem(foodItemId);
  }

  /// Add a new recipe
  Future<Recipe> addRecipe(Recipe recipe) async {
    return await _database.createRecipe(recipe);
  }

  /// Update an existing recipe
  Future<void> updateRecipe(Recipe recipe) async {
    await _database.updateRecipe(recipe);
  }

  /// Toggle favorite status of a recipe
  Future<void> toggleFavorite(int recipeId) async {
    await _database.toggleFavorite(recipeId);
  }

  /// Remove a recipe
  Future<void> removeRecipe(int recipeId) async {
    await _database.deleteRecipe(recipeId);
  }

  // ===== INGREDIENT OPERATIONS =====

  /// Get or create an ingredient by name
  Future<Ingredient> getOrCreateIngredient(String name) async {
    final existing = await _database.getIngredientByName(name);
    if (existing != null) return existing;
    return await _database.createIngredient(name);
  }

  /// Get all ingredients
  Future<List<Ingredient>> getAllIngredients() async {
    return await _database.getAllIngredients();
  }

  /// Search ingredients by name
  Future<List<Ingredient>> searchIngredients(String query) async {
    return await _database.searchIngredients(query);
  }

  // ===== UNIT OPERATIONS =====

  /// Get or create a unit by name
  Future<Unit> getOrCreateUnit(String name) async {
    final existing = await _database.getUnitByName(name);
    if (existing != null) return existing;
    return await _database.createUnit(name);
  }

  /// Get all units
  Future<List<Unit>> getAllUnits() async {
    return await _database.getAllUnits();
  }

  // ===== FOOD ITEM INGREDIENT TAGGING =====

  /// Tag a food item with an ingredient
  Future<void> tagFoodItemWithIngredient(String foodItemId, int ingredientId) async {
    await _database.tagFoodItemWithIngredient(foodItemId, ingredientId);
  }

  /// Remove ingredient tag from food item
  Future<void> untagFoodItemIngredient(String foodItemId, int ingredientId) async {
    await _database.untagFoodItemIngredient(foodItemId, ingredientId);
  }

  /// Get all ingredients tagged to a food item
  Future<List<Ingredient>> getFoodItemIngredients(String foodItemId) async {
    return await _database.getFoodItemIngredients(foodItemId);
  }

}
