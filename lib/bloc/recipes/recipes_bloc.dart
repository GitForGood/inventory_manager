import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/recipes/recipes_event.dart';
import 'package:inventory_manager/bloc/recipes/recipes_state.dart';
import 'package:inventory_manager/repositories/favorites_repository.dart';
import 'package:inventory_manager/services/recipe_api_service.dart';

class RecipesBloc extends Bloc<RecipesEvent, RecipesState> {
  final FavoritesRepository repository;

  RecipesBloc({required this.repository}) : super(const RecipesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<SearchRecipes>(_onSearchRecipes);
    on<LoadRandomRecipes>(_onLoadRandomRecipes);
    on<SearchByIngredients>(_onSearchByIngredients);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ClearSearch>(_onClearSearch);
    on<SetApiKey>(_onSetApiKey);
  }

  // Load favorites from repository
  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<RecipesState> emit,
  ) async {
    emit(const RecipesLoading());
    try {
      final favorites = await repository.loadFavorites();
      final apiKey = await repository.loadApiKey();

      if (apiKey != null && apiKey.isNotEmpty) {
        RecipeApiService.setApiKey(apiKey);
      }

      emit(RecipesLoaded(
        favorites: favorites,
        hasApiKey: apiKey != null && apiKey.isNotEmpty,
      ));
    } catch (e) {
      emit(RecipesError('Failed to load favorites: $e'));
    }
  }

  // Search recipes
  Future<void> _onSearchRecipes(
    SearchRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;

      if (!currentState.hasApiKey) {
        emit(const RecipesError('Please set your Spoonacular API key in settings'));
        emit(currentState);
        return;
      }

      emit(const RecipesLoading());
      try {
        final results = await RecipeApiService.searchRecipes(
          query: event.query,
          number: 20,
        );

        emit(currentState.copyWith(
          searchResults: results,
          lastQuery: event.query,
        ));
      } catch (e) {
        emit(RecipesError('Search failed: $e'));
        emit(currentState);
      }
    }
  }

  // Load random recipes
  Future<void> _onLoadRandomRecipes(
    LoadRandomRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;

      if (!currentState.hasApiKey) {
        emit(const RecipesError('Please set your Spoonacular API key in settings'));
        emit(currentState);
        return;
      }

      emit(const RecipesLoading());
      try {
        final results = await RecipeApiService.getRandomRecipes(number: 10);

        emit(currentState.copyWith(
          searchResults: results,
          lastQuery: 'Random Recipes',
        ));
      } catch (e) {
        emit(RecipesError('Failed to load random recipes: $e'));
        emit(currentState);
      }
    }
  }

  // Search by ingredients
  Future<void> _onSearchByIngredients(
    SearchByIngredients event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;

      if (!currentState.hasApiKey) {
        emit(const RecipesError('Please set your Spoonacular API key in settings'));
        emit(currentState);
        return;
      }

      emit(const RecipesLoading());
      try {
        final results = await RecipeApiService.searchByIngredients(
          ingredients: event.ingredients,
          number: 15,
        );

        emit(currentState.copyWith(
          searchResults: results,
          lastQuery: 'By Ingredients',
        ));
      } catch (e) {
        emit(RecipesError('Search by ingredients failed: $e'));
        emit(currentState);
      }
    }
  }

  // Toggle favorite status
  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;
      try {
        final isFav = currentState.isFavorite(event.recipe.id);

        if (isFav) {
          await repository.removeFavorite(event.recipe.id);
        } else {
          await repository.addFavorite(event.recipe);
        }

        final updatedFavorites = await repository.loadFavorites();

        emit(currentState.copyWith(favorites: updatedFavorites));
      } catch (e) {
        emit(RecipesError('Failed to update favorites: $e'));
        emit(currentState);
      }
    }
  }

  // Clear search results
  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;
      emit(currentState.copyWith(
        searchResults: [],
        lastQuery: null,
      ));
    }
  }

  // Set API key
  Future<void> _onSetApiKey(
    SetApiKey event,
    Emitter<RecipesState> emit,
  ) async {
    try {
      await repository.saveApiKey(event.apiKey);
      RecipeApiService.setApiKey(event.apiKey);

      if (state is RecipesLoaded) {
        final currentState = state as RecipesLoaded;
        emit(currentState.copyWith(hasApiKey: true));
      } else {
        emit(const RecipesLoaded(hasApiKey: true));
      }
    } catch (e) {
      emit(RecipesError('Failed to save API key: $e'));
    }
  }
}
