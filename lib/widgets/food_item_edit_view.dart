import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/models/food_item_group.dart';
import 'package:inventory_manager/models/ingredient.dart';
import 'package:inventory_manager/repositories/recipe_repository.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';

/// Tabbed view for editing food item details and ingredient tags
class FoodItemEditView extends StatefulWidget {
  final FoodItemGroup group;

  const FoodItemEditView({
    super.key,
    required this.group,
  });

  @override
  State<FoodItemEditView> createState() => _FoodItemEditViewState();
}

class _FoodItemEditViewState extends State<FoodItemEditView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _kcalController;
  List<Ingredient> _selectedIngredients = [];
  List<Ingredient> _availableIngredients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.group.foodItem.name);
    _weightController = TextEditingController(
      text: widget.group.foodItem.weightPerItemGrams.toString(),
    );
    _kcalController = TextEditingController(
      text: widget.group.foodItem.kcalPerHundredGrams.toString(),
    );
    _loadIngredients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    final repository = context.read<RecipeRepository>();
    final currentIngredients =
        await repository.getFoodItemIngredients(widget.group.foodItem.id);
    final allIngredients = await repository.getAllIngredients();

    if (mounted) {
      setState(() {
        _selectedIngredients = currentIngredients;
        _availableIngredients = allIngredients;
        _loading = false;
      });
    }
  }

  void _saveChanges() {
    // Validate inputs
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a food item name'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid weight per item'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final kcal = double.tryParse(_kcalController.text);
    if (kcal == null || kcal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter valid calories per 100g'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Update the food item
    final updatedFoodItem = widget.group.foodItem.copyWith(
      name: name,
      weightPerItemGrams: weight,
      kcalPerHundredGrams: kcal,
      ingredientIds: _selectedIngredients.map((i) => i.id!).toList(),
    );

    // Update all batches with the new food item
    for (final batch in widget.group.batches) {
      final updatedBatch = batch.copyWith(item: updatedFoodItem);
      context.read<InventoryBloc>().add(UpdateInventoryBatch(updatedBatch));
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Food item updated successfully'),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Food Item'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Details'),
            Tab(icon: Icon(Icons.label), text: 'Tags'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
            tooltip: 'Save changes',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildTagsTab(),
              ],
            ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Food Item Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fastfood),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight per item (grams)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              suffixText: 'g',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _kcalController,
            decoration: const InputDecoration(
              labelText: 'Calories per 100g',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_fire_department),
              suffixText: 'kcal',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          Text(
            'These changes will apply to all ${widget.group.batchCount} batch${widget.group.batchCount == 1 ? '' : 'es'} of this item.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsTab() {
    return Column(
      children: [
        // Selected tags section
        if (_selectedIngredients.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Tags',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedIngredients.map((ingredient) {
                    return Chip(
                      label: Text(ingredient.name),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedIngredients.remove(ingredient);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(),
        ],

        // Available tags section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: _showCreateIngredientDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('New Tag'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableIngredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = _availableIngredients[index];
                    final isSelected = _selectedIngredients
                        .any((i) => i.id == ingredient.id);

                    return CheckboxListTile(
                      title: Text(ingredient.name),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIngredients.add(ingredient);
                          } else {
                            _selectedIngredients.removeWhere(
                              (i) => i.id == ingredient.id,
                            );
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateIngredientDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tag name',
            border: OutlineInputBorder(),
            hintText: 'e.g. Chicken, Rice, Tomato',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final repository = context.read<RecipeRepository>();
        final newIngredient = await repository.getOrCreateIngredient(result);

        setState(() {
          if (!_availableIngredients.any((i) => i.id == newIngredient.id)) {
            _availableIngredients.add(newIngredient);
          }
          if (!_selectedIngredients.any((i) => i.id == newIngredient.id)) {
            _selectedIngredients.add(newIngredient);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created and added "$result"'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create tag: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
