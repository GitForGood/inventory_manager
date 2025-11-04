import 'package:flutter/material.dart';
import 'package:inventory_manager/models/recipe.dart';
import 'package:inventory_manager/views/recipe_view.dart';

/// A horizontal carousel showing up to 3 recipes
/// Used in quota and inventory views to show recipes that can be made with a food item
class RecipeCarousel extends StatelessWidget {
  final List<Recipe> recipes;
  final VoidCallback? onSeeAll;

  const RecipeCarousel({
    super.key,
    required this.recipes,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayRecipes = recipes.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recipe Ideas',
                style: Theme.of(context).textTheme.titleLarge
              ),
              if (recipes.length > 3 && onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text('See all ${recipes.length}'),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: displayRecipes.map((recipe) => _RecipeCard(recipe: recipe)).toList(),
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => RecipeView(recipe: recipe)
              )
            );
          },
          child: Column(
            children: [
              // Recipe image or placeholder
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 32,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  )
                ),
              ),
              
              // Recipe details
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.readyInMinutes} min',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.people,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servings}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
