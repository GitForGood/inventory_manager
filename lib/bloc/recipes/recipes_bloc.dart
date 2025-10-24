import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/recipes/recipes_event.dart';
import 'package:inventory_manager/bloc/recipes/recipes_state.dart';
import 'package:inventory_manager/repositories/recipe_repository.dart';

class RecipesBloc extends Bloc<RecipesEvent, RecipesState> {
  final RecipeRepository repository;

  RecipesBloc({required this.repository}) : super(const RecipesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<LoadAllRecipes>(_onLoadAllRecipes);
    on<SearchRecipes>(_onSearchRecipes);
    on<SearchByIngredients>(_onSearchByIngredients);
    on<GetRecipesForFoodItem>(_onGetRecipesForFoodItem);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ClearSearch>(_onClearSearch);
  }

  // Load favorites from database (called on app startup)
  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<RecipesState> emit,
  ) async {
    emit(const RecipesLoading());
    try {
      final favorites = await repository.loadFavorites();

      emit(RecipesLoaded(
        favorites: favorites,
      ));
    } catch (e) {
      emit(RecipesError('Failed to load favorites: $e'));
    }
  }

  // Load all recipes (lazy loaded when navigating to recipe view)
  Future<void> _onLoadAllRecipes(
    LoadAllRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;
      emit(const RecipesLoading());
      try {
        final allRecipes = await repository.loadAllRecipes();

        emit(currentState.copyWith(
          searchResults: allRecipes,
          lastQuery: 'All Recipes',
        ));
      } catch (e) {
        emit(RecipesError('Failed to load recipes: $e'));
        emit(currentState);
      }
    }
  }

  // Search recipes (searches local database first, can be extended for API)
  Future<void> _onSearchRecipes(
    SearchRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;

      emit(const RecipesLoading());
      try {
        // Search local database
        final results = await repository.searchRecipes(event.query);

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


  // Search by ingredients (uses local database)
  Future<void> _onSearchByIngredients(
    SearchByIngredients event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;

      emit(const RecipesLoading());
      try {
        final results = await repository.searchByIngredients(event.ingredientIds);

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

  // Get recipes for a specific food item
  Future<void> _onGetRecipesForFoodItem(
    GetRecipesForFoodItem event,
    Emitter<RecipesState> emit,
  ) async {
    if (state is RecipesLoaded) {
      final currentState = state as RecipesLoaded;

      emit(const RecipesLoading());
      try {
        final results = await repository.getRecipesForFoodItem(event.foodItemId);

        emit(currentState.copyWith(
          searchResults: results,
          lastQuery: 'Recipes for Food Item',
        ));
      } catch (e) {
        emit(RecipesError('Failed to load recipes for food item: $e'));
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
        if (event.recipe.id == null) {
          emit(const RecipesError('Cannot favorite a recipe without an ID'));
          emit(currentState);
          return;
        }

        await repository.toggleFavorite(event.recipe.id!);
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
}
