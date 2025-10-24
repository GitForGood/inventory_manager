import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/recipe.dart';

abstract class RecipesEvent extends Equatable {
  const RecipesEvent();

  @override
  List<Object?> get props => [];
}

// Load favorites from storage
class LoadFavorites extends RecipesEvent {
  const LoadFavorites();
}

// Search recipes by query
class SearchRecipes extends RecipesEvent {
  final String query;

  const SearchRecipes(this.query);

  @override
  List<Object?> get props => [query];
}

// Search by ingredients from inventory (by ingredient IDs)
class SearchByIngredients extends RecipesEvent {
  final List<int> ingredientIds;

  const SearchByIngredients(this.ingredientIds);

  @override
  List<Object?> get props => [ingredientIds];
}

// Load all recipes (lazy loaded when navigating to recipe view)
class LoadAllRecipes extends RecipesEvent {
  const LoadAllRecipes();
}

// Get recipes for a specific food item
class GetRecipesForFoodItem extends RecipesEvent {
  final String foodItemId;

  const GetRecipesForFoodItem(this.foodItemId);

  @override
  List<Object?> get props => [foodItemId];
}

// Toggle favorite status
class ToggleFavorite extends RecipesEvent {
  final Recipe recipe;

  const ToggleFavorite(this.recipe);

  @override
  List<Object?> get props => [recipe];
}

// Clear search results
class ClearSearch extends RecipesEvent {
  const ClearSearch();
}
