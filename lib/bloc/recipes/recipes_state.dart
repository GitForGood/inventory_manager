import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/recipe.dart';

abstract class RecipesState extends Equatable {
  const RecipesState();

  @override
  List<Object?> get props => [];
}

// Initial state
class RecipesInitial extends RecipesState {
  const RecipesInitial();
}

// Loading state
class RecipesLoading extends RecipesState {
  const RecipesLoading();
}

// Loaded state with search results and favorites
class RecipesLoaded extends RecipesState {
  final List<Recipe> searchResults;
  final List<Recipe> favorites;
  final bool hasApiKey;
  final String? lastQuery;

  const RecipesLoaded({
    this.searchResults = const [],
    this.favorites = const [],
    this.hasApiKey = false,
    this.lastQuery,
  });

  // Check if a recipe is favorited
  bool isFavorite(String recipeId) {
    return favorites.any((recipe) => recipe.id == recipeId);
  }

  @override
  List<Object?> get props => [searchResults, favorites, hasApiKey, lastQuery];

  // CopyWith for state updates
  RecipesLoaded copyWith({
    List<Recipe>? searchResults,
    List<Recipe>? favorites,
    bool? hasApiKey,
    String? lastQuery,
  }) {
    return RecipesLoaded(
      searchResults: searchResults ?? this.searchResults,
      favorites: favorites ?? this.favorites,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      lastQuery: lastQuery ?? this.lastQuery,
    );
  }
}

// Error state
class RecipesError extends RecipesState {
  final String message;

  const RecipesError(this.message);

  @override
  List<Object?> get props => [message];
}
