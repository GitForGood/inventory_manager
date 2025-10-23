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

// Load random recipes
class LoadRandomRecipes extends RecipesEvent {
  const LoadRandomRecipes();
}

// Search by ingredients from inventory
class SearchByIngredients extends RecipesEvent {
  final List<String> ingredients;

  const SearchByIngredients(this.ingredients);

  @override
  List<Object?> get props => [ingredients];
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

// Set API key
class SetApiKey extends RecipesEvent {
  final String apiKey;

  const SetApiKey(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}
