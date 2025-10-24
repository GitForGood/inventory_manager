# Recipe System Refactoring Guide

## Overview

The recipe system has been refactored to use a local SQLite database instead of SharedPreferences. This provides better performance, structured data storage, and new features like ingredient tagging for food items.

## Database Structure

### Tables

1. **recipes**
   - `id` (INTEGER PRIMARY KEY) - Auto-increment
   - `title` (TEXT)
   - `readyInMinutes` (INTEGER)
   - `servings` (INTEGER)
   - `imageUrl` (TEXT)
   - `summary` (TEXT)
   - `isFavorite` (INTEGER) - 0 or 1

2. **ingredients**
   - `id` (INTEGER PRIMARY KEY) - Auto-increment
   - `name` (TEXT UNIQUE)

3. **units**
   - `id` (INTEGER PRIMARY KEY) - Auto-increment
   - `name` (TEXT UNIQUE)
   - Pre-populated with common units: piece, g, kg, ml, l, tsp, tbsp, cup, oz, lb, pinch, handful, slice, clove, can, package, bunch

4. **recipe_ingredients**
   - `recipeId` (INTEGER)
   - `ingredientId` (INTEGER)
   - `amount` (REAL)
   - `unitId` (INTEGER)
   - Links recipes to their ingredients with amounts

5. **recipe_steps**
   - `recipeId` (INTEGER)
   - `stepNumber` (INTEGER)
   - `instruction` (TEXT)
   - Stores recipe instructions in order

6. **food_item_ingredients**
   - `foodItemId` (TEXT)
   - `ingredientId` (INTEGER)
   - Tags food items with ingredients for recipe lookup

## New Models

### Ingredient
```dart
class Ingredient {
  final int? id;
  final String name;
}
```

### Unit
```dart
class Unit {
  final int? id;
  final String name;
}
```

### RecipeIngredient
```dart
class RecipeIngredient {
  final int? recipeId;
  final int ingredientId;
  final double amount;
  final int unitId;
  final Ingredient? ingredient; // For display
  final Unit? unit; // For display
}
```

### Updated Recipe Model
- Changed `id` from `String` to `int?`
- Changed `ingredients` from `List<String>` to `List<RecipeIngredient>`
- Added `isFavorite` field

### Updated FoodItem Model
- Added `ingredientIds` field to tag food items with ingredients

## New Features

### 1. Lazy Loading
- **On app startup**: Only favorited recipes are loaded
- **On navigation to recipe view**: All recipes are loaded
- This improves startup performance when the recipe database grows large

### 2. Ingredient-Based Search
```dart
// Search recipes by ingredient IDs
bloc.add(SearchByIngredients([ingredientId1, ingredientId2]));
```

### 3. Food Item Recipe Lookup
```dart
// Get recipes that use ingredients tagged to a food item
bloc.add(GetRecipesForFoodItem(foodItemId));
```

### 4. Load All Recipes
```dart
// Load all recipes (lazy loaded when needed)
bloc.add(LoadAllRecipes());
```

## New BLoC Events

1. **LoadFavorites** - Load only favorite recipes (startup)
2. **LoadAllRecipes** - Load all recipes (lazy loaded)
3. **SearchRecipes** - Search recipes by title in local database
4. **SearchByIngredients** - Search recipes by ingredient IDs
5. **GetRecipesForFoodItem** - Get recipes for a specific food item
6. **ToggleFavorite** - Toggle favorite status
7. **ClearSearch** - Clear search results
8. **SetApiKey** - Set Spoonacular API key (kept for compatibility)

## Repository Changes

### RecipeRepository (replaces FavoritesRepository)

#### Recipe Operations
```dart
// Load only favorites (for startup)
Future<List<Recipe>> loadFavorites()

// Load all recipes (for recipe view)
Future<List<Recipe>> loadAllRecipes()

// Get single recipe
Future<Recipe?> getRecipe(int id)

// Search by title
Future<List<Recipe>> searchRecipes(String query)

// Search by ingredients
Future<List<Recipe>> searchByIngredients(List<int> ingredientIds)

// Get recipes for food item
Future<List<Recipe>> getRecipesForFoodItem(String foodItemId)

// Add new recipe
Future<Recipe> addRecipe(Recipe recipe)

// Update recipe
Future<void> updateRecipe(Recipe recipe)

// Toggle favorite
Future<void> toggleFavorite(int recipeId)

// Remove recipe
Future<void> removeRecipe(int recipeId)
```

#### Ingredient Operations
```dart
// Get or create ingredient
Future<Ingredient> getOrCreateIngredient(String name)

// Get all ingredients
Future<List<Ingredient>> getAllIngredients()

// Search ingredients
Future<List<Ingredient>> searchIngredients(String query)
```

#### Unit Operations
```dart
// Get or create unit
Future<Unit> getOrCreateUnit(String name)

// Get all units
Future<List<Unit>> getAllUnits()
```

#### Food Item Tagging
```dart
// Tag food item with ingredient
Future<void> tagFoodItemWithIngredient(String foodItemId, int ingredientId)

// Remove tag
Future<void> untagFoodItemIngredient(String foodItemId, int ingredientId)

// Get food item ingredients
Future<List<Ingredient>> getFoodItemIngredients(String foodItemId)
```

## Importing Recipes

Since you're starting fresh, you'll need to implement a way to import recipes into the database. Here are some options:

### Option 1: Manual Recipe Creation in UI
Create a UI form that allows users to:
1. Enter recipe details (title, time, servings, etc.)
2. Add ingredients by searching/creating ingredients and units
3. Add step-by-step instructions
4. Save to database

### Option 2: Import from JSON
Create a JSON import feature:

```dart
Future<void> importRecipesFromJson(String jsonString) async {
  final repository = RecipeRepository();
  final List<dynamic> recipesJson = jsonDecode(jsonString);

  for (final recipeJson in recipesJson) {
    // Parse ingredients
    final ingredients = <RecipeIngredient>[];
    for (final ing in recipeJson['ingredients']) {
      final ingredient = await repository.getOrCreateIngredient(ing['name']);
      final unit = await repository.getOrCreateUnit(ing['unit']);
      ingredients.add(RecipeIngredient(
        ingredientId: ingredient.id!,
        amount: ing['amount'],
        unitId: unit.id!,
      ));
    }

    // Create recipe
    final recipe = Recipe(
      title: recipeJson['title'],
      readyInMinutes: recipeJson['time'],
      servings: recipeJson['portions'],
      ingredients: ingredients,
      instructions: List<String>.from(recipeJson['steps']),
      imageUrl: recipeJson['imageUrl'],
      summary: recipeJson['summary'],
    );

    await repository.addRecipe(recipe);
  }
}
```

### Option 3: Import from API
If you have recipes from an API (like Spoonacular), you can parse and store them in the database format.

## Usage Examples

### Creating a Recipe
```dart
final repository = RecipeRepository();

// Create or get ingredients
final flour = await repository.getOrCreateIngredient('flour');
final sugar = await repository.getOrCreateIngredient('sugar');

// Create or get units
final cup = await repository.getOrCreateUnit('cup');
final tsp = await repository.getOrCreateUnit('tsp');

// Create recipe with ingredients
final recipe = Recipe(
  title: 'Chocolate Cake',
  readyInMinutes: 45,
  servings: 8,
  ingredients: [
    RecipeIngredient(
      ingredientId: flour.id!,
      amount: 2.0,
      unitId: cup.id!,
    ),
    RecipeIngredient(
      ingredientId: sugar.id!,
      amount: 1.5,
      unitId: cup.id!,
    ),
  ],
  instructions: [
    'Preheat oven to 350°F',
    'Mix dry ingredients',
    'Add wet ingredients',
    'Bake for 30 minutes',
  ],
  isFavorite: false,
);

final savedRecipe = await repository.addRecipe(recipe);
```

### Tagging Food Items
```dart
// Tag a food item with an ingredient
await repository.tagFoodItemWithIngredient(
  'food_item_uuid',
  flourIngredientId,
);

// Get recipes that can be made with this food item
final recipes = await repository.getRecipesForFoodItem('food_item_uuid');
```

### Using the BLoC
```dart
// Load favorites on startup
recipesBloc.add(const LoadFavorites());

// When user navigates to recipe view, load all recipes
recipesBloc.add(const LoadAllRecipes());

// Search recipes
recipesBloc.add(const SearchRecipes('chocolate'));

// Search by ingredients
recipesBloc.add(SearchByIngredients([flourId, sugarId]));

// Get recipes for a food item
recipesBloc.add(GetRecipesForFoodItem(foodItemId));

// Toggle favorite
recipesBloc.add(ToggleFavorite(recipe));
```

## Breaking Changes

1. **Recipe.id** changed from `String` to `int?`
2. **Recipe.ingredients** changed from `List<String>` to `List<RecipeIngredient>`
3. **FavoritesRepository** replaced with **RecipeRepository**
4. **RecipesBloc** now requires **RecipeRepository** instead of **FavoritesRepository**
5. Recipe state checking uses `int?` for IDs instead of `String`

## Next Steps

1. **Run `flutter pub get`** to install the new dependencies (sqflite, path)
2. **Update app initialization** to call `AppInitialization.initialize()`
3. **Update RecipesBloc instantiation** to use `RecipeRepository`
4. **Update UI** to handle the new Recipe structure (RecipeIngredient instead of String)
5. **Add UI for importing/creating recipes** (manual entry, JSON import, or API)
6. **Add UI for tagging food items** with ingredients
7. **Add UI for ingredient-based search**

## Performance Considerations

- Favorited recipes load on startup (fast, small dataset)
- All recipes load lazily when needed (only when user navigates to recipe view)
- Indexes on frequently queried fields improve search performance
- Consider adding pagination if recipe count exceeds 1000+

## Future Enhancements

1. Add full-text search on recipe ingredients and instructions
2. Add nutrition calculation based on ingredient amounts
3. Add recipe categories/tags
4. Add recipe ratings
5. Sync recipes across devices
6. Import/export recipes in standard formats (JSON, RecipeML)
