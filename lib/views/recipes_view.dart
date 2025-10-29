import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/recipes/recipes_barrel.dart';
import 'package:inventory_manager/models/recipe.dart';
import 'package:inventory_manager/widgets/recipe_form_view.dart';

class RecipesView extends StatefulWidget {
  const RecipesView({super.key});

  @override
  State<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends State<RecipesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with 2 tabs, Favorites tab is index 0 (default)
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);

    // Load all recipes when the view is opened (lazy loading)
    context.read<RecipesBloc>().add(const LoadAllRecipes());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'All Recipes'),
          ],
        ),
      ),
      body: BlocListener<RecipesBloc, RecipesState>(
        listener: (context, state) {
          if (state is RecipesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFavoritesTab(),
            _buildAllRecipesTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecipeFormView(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Recipe'),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return BlocBuilder<RecipesBloc, RecipesState>(
      builder: (context, state) {
        if (state is RecipesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecipesLoaded) {
          if (state.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite recipes yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Browse recipes and tap the heart to save them'),
                ],
              ),
            );
          }

          return _buildRecipeGrid(state.favorites, state);
        }

        return const Center(child: Text('Loading favorites...'));
      },
    );
  }

  Widget _buildAllRecipesTab() {
    return BlocBuilder<RecipesBloc, RecipesState>(
      builder: (context, state) {
        if (state is RecipesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecipesLoaded) {
          return Column(
            children: [
              _buildSearchBar(state),
              if (state.searchResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${state.searchResults.length} recipe${state.searchResults.length == 1 ? '' : 's'}${state.lastQuery != null ? ' - ${state.lastQuery}' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Expanded(
                  child: _buildRecipeGrid(state.searchResults, state),
                ),
              ] else
                Expanded(
                  child: _buildEmptyState(),
                ),
            ],
          );
        }

        return const Center(child: Text('Loading recipes...'));
      },
    );
  }

  Widget _buildSearchBar(RecipesLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search recipes by title...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<RecipesBloc>().add(const LoadAllRecipes());
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            context.read<RecipesBloc>().add(SearchRecipes(value));
          } else {
            context.read<RecipesBloc>().add(const LoadAllRecipes());
          }
        },
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipes, RecipesLoaded state) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final isFavorite = state.isFavorite(recipe.id);

        return _RecipeCard(
          recipe: recipe,
          isFavorite: isFavorite,
          onTap: () => _showRecipeDetails(recipe, isFavorite),
          onFavoriteToggle: () {
            context.read<RecipesBloc>().add(ToggleFavorite(recipe));
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No recipes found',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Try a different search or create a new recipe'),
        ],
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe, bool isFavorite) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _RecipeDetailsSheet(
            recipe: recipe,
            isFavorite: isFavorite,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _RecipeCard({
    required this.recipe,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                    Image.network(
                      recipe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 48),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 48),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: onFavoriteToggle,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.readyInMinutes} min',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const Spacer(),
                      const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.ingredients.length} ing.',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeDetailsSheet extends StatelessWidget {
  final Recipe recipe;
  final bool isFavorite;
  final ScrollController scrollController;

  const _RecipeDetailsSheet({
    required this.recipe,
    required this.isFavorite,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            recipe.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: Text('${recipe.readyInMinutes} minutes'),
              ),
              Chip(
                avatar: const Icon(Icons.people, size: 16),
                label: Text('${recipe.servings} servings'),
              ),
              Chip(
                avatar: const Icon(Icons.restaurant, size: 16),
                label: Text('${recipe.ingredients.length} ingredients'),
              ),
            ],
          ),
          if (recipe.summary != null && recipe.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_stripHtml(recipe.summary!)),
          ],
          if (recipe.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recipe.ingredients
                .map((ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(ingredient.displayString)),
                        ],
                      ),
                    )),
          ],
          if (recipe.instructions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recipe.instructions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(entry.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
