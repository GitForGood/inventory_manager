import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/models/food_item_group.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/models/ingredient.dart';
import 'package:inventory_manager/models/recipe.dart';
import 'package:inventory_manager/repositories/recipe_repository.dart';
import 'package:inventory_manager/widgets/assist_chip.dart';
import 'package:inventory_manager/widgets/outlined_card.dart';
import 'package:inventory_manager/widgets/recipe_carousel.dart';
import 'package:inventory_manager/views/food_item_edit_view.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Detailed view showing all batches for a specific food item
class FoodItemDetailView extends StatefulWidget {
  final FoodItemGroup group;

  const FoodItemDetailView({
    super.key,
    required this.group,
  });

  @override
  State<FoodItemDetailView> createState() => _FoodItemDetailViewState();
}

class _FoodItemDetailViewState extends State<FoodItemDetailView> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  List<Recipe>? _recipes;
  bool _loadingRecipes = false;
  List<Ingredient>? _ingredients;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadRecipes();
    _loadIngredients();
  }

  Future<void> _loadRecipes() async {
    setState(() => _loadingRecipes = true);
    try {
      final repository = context.read<RecipeRepository>();
      final recipes = await repository.getRecipesForFoodItem(widget.group.foodItem.id);
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _loadingRecipes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRecipes = false);
      }
    }
  }

  Future<void> _loadIngredients() async {
    try {
      final repository = context.read<RecipeRepository>();
      final ingredients = await repository.getFoodItemIngredients(widget.group.foodItem.id);
      if (mounted) {
        setState(() {
          _ingredients = ingredients;
        });
      }
    } catch (e) {
      // Silently fail - ingredients are optional
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show FAB when scrolled down more than 200 pixels
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _navigateToEditView(BuildContext context, FoodItemGroup currentGroup) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodItemEditView(group: currentGroup),
      ),
    );

    // Reload ingredients and recipes after returning from edit view
    if (mounted) {
      _loadIngredients();
      _loadRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        // Rebuild the group from the current inventory state
        final FoodItemGroup currentGroup;
        if (state is InventoryLoaded) {
          // Filter batches for this food item and create an updated group
          final currentBatches = state.batches
              .where((batch) => batch.item.id == widget.group.foodItem.id)
              .toList();
          currentGroup = FoodItemGroup(
            foodItem: widget.group.foodItem,
            batches: currentBatches,
          );
        } else {
          // Fallback to the original group if state is not loaded
          currentGroup = widget.group;
        }

        
        final batches = currentGroup.batchesSortedByExpiration;

        return _buildScaffold(context, currentGroup, batches);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    FoodItemGroup currentGroup,
    List<InventoryBatch> batches,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentGroup.foodItem.name, style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteAllBatches(context),
            tooltip: 'Delete all batches',
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            itemCount: batches.length + (_recipes != null && _recipes!.isNotEmpty ? 3 : 2), // +2 for summary and header, +1 for recipes if available
            itemBuilder: (context, index) {
          // Summary card
          if (index == 0) {
            return OutlinedCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentGroup.foodItem.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _navigateToEditView(context, currentGroup),
                          tooltip: 'Edit food item',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Horizontally scrollable chip row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AssistChip(
                          icon: Symbols.package_2,
                          labelText: '${currentGroup.totalCount} Items',
                        ),
                        AssistChip(
                          icon: Symbols.trolley,
                          labelText: '${currentGroup.batchCount} Batches',
                        ),
                        AssistChip(
                          icon: Icons.scale,
                          labelText: '~${(currentGroup.totalCount * currentGroup.foodItem.weightPerItemGrams/1000).toStringAsFixed(1)}kg',
                        ),
                        AssistChip(
                          icon: Icons.local_fire_department,
                          labelText: '${(currentGroup.totalCount * currentGroup.foodItem.weightPerItemGrams / 1000 * currentGroup.foodItem.kcalPerHundredGrams * 10).toStringAsFixed(0)} total kcal',
                        ),
                        // Ingredient tags
                        if (_ingredients != null && _ingredients!.isNotEmpty)
                          ..._ingredients!.map((ingredient) => AssistChip(
                                icon: Icons.local_offer,
                                labelText: ingredient.name,
                              )),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // Recipe carousel (if recipes available)
          if (index == 1 && _recipes != null && _recipes!.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                RecipeCarousel(recipes: _recipes!),
                const SizedBox(height: 8),
              ],
            );
          }

          // Header with spacing
          final headerIndex = _recipes != null && _recipes!.isNotEmpty ? 2 : 1;
          if (index == headerIndex) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Batches',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      FilledButton.icon(
                        onPressed: () => _showQuickRestockDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Batch'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }

          // List items
          final offset = _recipes != null && _recipes!.isNotEmpty ? 3 : 2;
          final batchIndex = index - offset;
          final batch = batches[batchIndex];
          final isExpired = batch.isExpired();

          final colorScheme = Theme.of(context).colorScheme;
          return Card(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: ListTile(
              title: Text(
                'Batch ${batchIndex + 1}',
              ),
              subtitle: Text(
                'Expires: ${_formatDate(batch.expirationDate)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      batch.count.toString(),
                      style: Theme.of(context).textTheme.labelLarge
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              onTap: () => _showBatchOptionsDialog(context, batch),
            ),
          );
        },
          ),
          // Scroll-to-top FAB
          if (_showScrollToTop)
            Positioned(
              top: 8,
              left: MediaQuery.of(context).size.width / 2 - 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _scrollToTop,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showQuickRestockDialog(BuildContext context) {
    final countController = TextEditingController(text: '1');
    DateTime expirationDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add ${widget.group.foodItem.name} Batch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: countController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.all(0),
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expirationDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setState(() {
                        expirationDate = picked;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Expiration Date:', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.normal)),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatDate(expirationDate),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final count = int.tryParse(countController.text);
                if (count == null || count <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid quantity'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                // Create new batch with same food item
                final newBatch = InventoryBatch(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  item: widget.group.foodItem,
                  count: count,
                  initialCount: count,
                  expirationDate: expirationDate,
                  dateAdded: DateTime.now(),
                );

                context.read<InventoryBloc>().add(AddInventoryBatch(newBatch));

                // Generate consumption quotas for this batch
                context.read<ConsumptionQuotaBloc>().add(GenerateQuotasForBatch(newBatch));

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Batch added successfully'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchOptionsDialog(BuildContext context, InventoryBatch batch) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batch Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Change Amount'),
              onTap: () {
                Navigator.pop(dialogContext);
                _showChangeAmountDialog(context, batch);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Change Expiration Date'),
              onTap: () {
                Navigator.pop(dialogContext);
                _showChangeExpirationDialog(context, batch);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text('Delete Batch', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(dialogContext);
                _confirmDeleteBatch(context, batch.id);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangeAmountDialog(BuildContext context, InventoryBatch batch) {
    final countController = TextEditingController(text: batch.count.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Amount'),
        content: TextFormField(
          controller: countController,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(countController.text);
              if (count == null || count < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid quantity'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }

              final updatedBatch = batch.copyWith(count: count);
              context.read<InventoryBloc>().add(UpdateInventoryBatch(updatedBatch));

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Amount updated successfully'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeExpirationDialog(BuildContext context, InventoryBatch batch) {
    DateTime expirationDate = batch.expirationDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Expiration Date'),
          content: Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: expirationDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 25)),
                );
                if (picked != null) {
                  setState(() {
                    expirationDate = picked;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Expiration Date:', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.normal)),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(expirationDate),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedBatch = batch.copyWith(expirationDate: expirationDate);
                context.read<InventoryBloc>().add(UpdateInventoryBatch(updatedBatch));

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Expiration date updated successfully'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBatch(BuildContext context, String batchId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Batch'),
        content: const Text('Are you sure you want to delete this batch?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: Theme.of(context).textTheme.titleSmall,),
          ),
          TextButton(
            onPressed: () {
              context.read<InventoryBloc>().add(DeleteInventoryBatch(batchId));

              Navigator.pop(dialogContext);

              // If this was the last batch, navigate back
              final currentState = context.read<InventoryBloc>().state;
              if (currentState is InventoryLoaded) {
                final remainingBatches = currentState.batches
                    .where((b) => b.item.id == widget.group.foodItem.id)
                    .length;
                if (remainingBatches == 0) {
                  Navigator.pop(context);
                }
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Batch deleted'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllBatches(BuildContext context) {
    // Get current batches from the bloc state
    final state = context.read<InventoryBloc>().state;
    if (state is! InventoryLoaded) return;

    final currentBatches = state.batches
        .where((batch) => batch.item.id == widget.group.foodItem.id)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Batches'),
        content: Text(
          'Are you sure you want to delete all ${currentBatches.length} batches of ${widget.group.foodItem.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete all batches
              for (final batch in currentBatches) {
                context.read<InventoryBloc>().add(DeleteInventoryBatch(batch.id));
              }

              Navigator.pop(dialogContext);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All batches deleted'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );
            },
            child: Text('Delete All', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}