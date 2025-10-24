# Recipe System Quick Start Guide

## What Changed

The recipe system now uses a **SQLite database** instead of SharedPreferences, with the following structure:

### Database Tables
- **recipes**: id, title, readyInMinutes, servings, imageUrl, summary, isFavorite
- **ingredients**: id, name (e.g., "flour", "sugar")
- **units**: id, name (e.g., "cup", "tsp", "g")
- **recipe_ingredients**: links recipes to ingredients with amounts
- **recipe_steps**: stores recipe instructions in order
- **food_item_ingredients**: tags food items with ingredients for recipe lookup

## Quick Integration Steps

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Initialize Database in main.dart
```dart
import 'package:inventory_manager/services/app_initialization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitialization.initialize(); // Add this line
  runApp(MyApp());
}
```

### 3. Update BLoC Instantiation
Replace `FavoritesRepository` with `RecipeRepository`:

```dart
// OLD
import 'package:inventory_manager/repositories/favorites_repository.dart';
RecipesBloc(repository: FavoritesRepository())

// NEW
import 'package:inventory_manager/repositories/recipe_repository.dart';
RecipesBloc(repository: RecipeRepository())
```

### 4. Update UI Code
Change how you display recipe ingredients:

```dart
// OLD
Text(recipe.ingredients[0]) // was List<String>

// NEW
Text(recipe.ingredients[0].displayString) // now List<RecipeIngredient>
```

### 5. Add Lazy Loading (Optional but Recommended)
In your recipe view, load all recipes when the view opens:

```dart
@override
void initState() {
  super.initState();
  context.read<RecipesBloc>().add(const LoadAllRecipes());
}
```

## Key Features

### 🚀 Performance
- **Favorites load on startup** (fast, small dataset)
- **All recipes load lazily** when user navigates to recipe view
- **Indexed queries** for fast searching

### 🏷️ Ingredient Tagging
Tag food items with ingredients to find relevant recipes:

```dart
final repository = RecipeRepository();

// Tag food item
await repository.tagFoodItemWithIngredient(foodItemId, flourIngredientId);

// Find recipes for food item
bloc.add(GetRecipesForFoodItem(foodItemId));
```

### 🔍 Search by Ingredients
```dart
// Search recipes that use specific ingredients
bloc.add(SearchByIngredients([flourId, eggsId, milkId]));
```

## Creating Recipes

### Example: Add a Recipe Programmatically
```dart
final repository = RecipeRepository();

// Get or create ingredients
final flour = await repository.getOrCreateIngredient('flour');
final sugar = await repository.getOrCreateIngredient('sugar');
final eggs = await repository.getOrCreateIngredient('eggs');

// Get or create units
final cup = await repository.getOrCreateUnit('cup');
final piece = await repository.getOrCreateUnit('piece');

// Create recipe
final recipe = Recipe(
  title: 'Simple Cake',
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
    RecipeIngredient(
      ingredientId: eggs.id!,
      amount: 3.0,
      unitId: piece.id!,
    ),
  ],
  instructions: [
    'Preheat oven to 350°F',
    'Mix dry ingredients in a bowl',
    'Add eggs and mix well',
    'Pour into greased pan',
    'Bake for 30-35 minutes',
  ],
  isFavorite: false,
);

await repository.addRecipe(recipe);
```

## New BLoC Events

```dart
// Load favorites (automatically called on startup)
bloc.add(const LoadFavorites());

// Load all recipes (call when user opens recipe view)
bloc.add(const LoadAllRecipes());

// Search by title
bloc.add(const SearchRecipes('chocolate'));

// Search by ingredient IDs
bloc.add(SearchByIngredients([ingredientId1, ingredientId2]));

// Get recipes for food item
bloc.add(GetRecipesForFoodItem(foodItemId));

// Toggle favorite
bloc.add(ToggleFavorite(recipe));

// Clear search
bloc.add(const ClearSearch());
```

## Breaking Changes

⚠️ **Important changes to be aware of:**

1. **Recipe.id**: `String` → `int?`
2. **Recipe.ingredients**: `List<String>` → `List<RecipeIngredient>`
3. **Repository**: `FavoritesRepository` → `RecipeRepository`
4. **Ingredient display**: Use `.displayString` property

## Import Options

Since you're starting fresh, here are ways to populate recipes:

### Option 1: Manual Entry
Create a UI form for users to add recipes manually.

### Option 2: JSON Import
Create a JSON import feature (see RECIPE_REFACTORING_GUIDE.md for code example).

### Option 3: API Integration
Parse recipes from an API (like Spoonacular) into the database format.

### Option 4: Seed Data
Add sample recipes in your app initialization:

```dart
static Future<void> _seedSampleRecipes() async {
  final repository = RecipeRepository();

  // Check if recipes already exist
  final existing = await repository.loadAllRecipes();
  if (existing.isNotEmpty) return;

  // Add sample recipes here...
}
```

## Common Tasks

### Toggle Favorite
```dart
// In UI
onPressed: () {
  context.read<RecipesBloc>().add(ToggleFavorite(recipe));
}
```

### Display Recipe Ingredients
```dart
ListView.builder(
  itemCount: recipe.ingredients.length,
  itemBuilder: (context, index) {
    final ingredient = recipe.ingredients[index];
    return ListTile(
      title: Text(ingredient.displayString),
      // e.g., "2.0 cup flour"
    );
  },
)
```

### Search Recipes
```dart
TextField(
  onSubmitted: (query) {
    context.read<RecipesBloc>().add(SearchRecipes(query));
  },
)
```

## Need More Details?

See [RECIPE_REFACTORING_GUIDE.md](RECIPE_REFACTORING_GUIDE.md) for:
- Complete database schema
- Full API documentation
- Advanced usage examples
- Performance optimization tips
- Future enhancement ideas

## Files Changed/Added

**New Files:**
- `lib/models/ingredient.dart`
- `lib/models/unit.dart`
- `lib/models/recipe_ingredient.dart`
- `lib/services/recipe_database.dart`
- `lib/services/app_initialization.dart`
- `lib/repositories/recipe_repository.dart`

**Updated Files:**
- `lib/models/recipe.dart`
- `lib/models/food_item.dart`
- `lib/bloc/recipes/recipes_bloc.dart`
- `lib/bloc/recipes/recipes_event.dart`
- `lib/bloc/recipes/recipes_state.dart`
- `pubspec.yaml`
