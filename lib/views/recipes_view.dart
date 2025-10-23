import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/recipes/recipes_barrel.dart';
import 'package:inventory_manager/models/recipe.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(icon: Icon(Icons.search), text: 'Browse'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
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
            _buildBrowseTab(),
            _buildFavoritesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseTab() {
    return BlocBuilder<RecipesBloc, RecipesState>(
      builder: (context, state) {
        if (state is RecipesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecipesLoaded) {
          if (!state.hasApiKey) {
            return _buildApiKeyPrompt();
          }

          return Column(
            children: [
              _buildSearchBar(state),
              if (state.searchResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${state.searchResults.length} results for "${state.lastQuery}"',
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

  Widget _buildSearchBar(RecipesLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<RecipesBloc>().add(const ClearSearch());
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
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<RecipesBloc>().add(const LoadRandomRecipes());
                  },
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Random'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showApiKeyDialog();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('API Key'),
                ),
              ),
            ],
          ),
        ],
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
            'Search for recipes',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Try searching or get random recipes'),
        ],
      ),
    );
  }

  Widget _buildApiKeyPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.key, size: 64),
            const SizedBox(height: 16),
            const Text(
              'API Key Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To browse recipes, you need a free Spoonacular API key.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showApiKeyDialog,
              child: const Text('Set API Key'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Open Spoonacular website
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visit: spoonacular.com/food-api'),
                  ),
                );
              },
              child: const Text('Get a free API key at Spoonacular'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spoonacular API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Spoonacular API key to browse recipes.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<RecipesBloc>().add(SetApiKey(controller.text));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
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
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (recipe.imageUrl != null)
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.readyInMinutes} min',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.people, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.servings}',
                        style: const TextStyle(fontSize: 12),
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
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: Text('${recipe.readyInMinutes} min'),
              ),
              const SizedBox(width: 8),
              Chip(
                avatar: const Icon(Icons.people, size: 16),
                label: Text('${recipe.servings} servings'),
              ),
            ],
          ),
          if (recipe.summary != null) ...[
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
                          Expanded(child: Text(ingredient)),
                        ],
                      ),
                    ))
                ,
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key + 1}. '),
                        Expanded(child: Text(entry.value)),
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
