import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/models/food_item_group.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/widgets/assist_chip.dart';
import 'package:inventory_manager/widgets/outlined_card.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Detailed view showing all batches for a specific food item
class FoodItemDetailView extends StatelessWidget {
  final FoodItemGroup group;

  const FoodItemDetailView({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        // Rebuild the group from the current inventory state
        final FoodItemGroup currentGroup;
        if (state is InventoryLoaded) {
          // Filter batches for this food item and create an updated group
          final currentBatches = state.batches
              .where((batch) => batch.item.id == group.foodItem.id)
              .toList();
          currentGroup = FoodItemGroup(
            foodItem: group.foodItem,
            batches: currentBatches,
          );
        } else {
          // Fallback to the original group if state is not loaded
          currentGroup = group;
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
        title: Text(currentGroup.foodItem.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteAllBatches(context),
            tooltip: 'Delete all batches',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Add batch'),
        icon: Icon(Icons.add),
        onPressed: () => _showQuickRestockDialog(context)
        ),
      body: Column(
        children: [
          // Fixed Summary Card
          OutlinedCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Summary: ${currentGroup.foodItem.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditNutritionDialog(context, currentGroup),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Horizontally scrollable chip row
                  Wrap(
                    spacing: 8,
                    children: [
                      AssistChip(
                        icon: Icons.inventory_2,
                        labelText: '${currentGroup.totalCount} Items',
                      ),
                      AssistChip(
                        icon: Symbols.package_2,
                        labelText: '${currentGroup.batchCount} Batches',
                      ),
                      AssistChip(
                        icon: Icons.scale,
                        labelText: '~${(currentGroup.totalCount * currentGroup.foodItem.weightPerItemGrams/1000).toStringAsFixed(1)}kg',
                      ),
                      AssistChip(
                        icon: Icons.local_fire_department,
                        labelText: '${(currentGroup.totalCount * currentGroup.foodItem.weightPerItemGrams / 1000 * currentGroup.foodItem.kcalPerHundredGrams * 10).toStringAsFixed(0)} kcal',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Fixed Batches Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Batches',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),

          // Scrollable Batches List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];
                final isExpired = batch.isExpired();
                final isExpiringSoon = batch.isExpiringSoon();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isExpired
                          ? Theme.of(context).colorScheme.error
                          : isExpiringSoon
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.tertiary,
                      child: Text(
                        batch.count.toString(),
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    title: Text(
                      'Batch ${index + 1}',
                    ),
                    subtitle: Text(
                      'Expires: ${_formatDate(batch.expirationDate)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditBatchDialog(context, batch),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDeleteBatch(context, batch.id),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showEditNutritionDialog(BuildContext context, FoodItemGroup currentGroup) {
    final carbsController = TextEditingController(
      text: currentGroup.foodItem.carbohydratesPerHundredGrams.toString(),
    );
    final fatsController = TextEditingController(
      text: currentGroup.foodItem.fatsPerHundredGrams.toString(),
    );
    final proteinController = TextEditingController(
      text: currentGroup.foodItem.proteinPerHundredGrams.toString(),
    );
    final caloriesController = TextEditingController(
      text: currentGroup.foodItem.kcalPerHundredGrams.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with edit icon
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Nutrition',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Values per 100g',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                // Nutrition fields
                TextFormField(
                  controller: carbsController,
                  decoration: const InputDecoration(
                    labelText: 'Carbohydrates',
                    suffixText: 'g',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grain),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fatsController,
                  decoration: const InputDecoration(
                    labelText: 'Fats',
                    suffixText: 'g',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.water_drop),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: proteinController,
                  decoration: const InputDecoration(
                    labelText: 'Protein',
                    suffixText: 'g',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    suffixText: 'kcal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_fire_department),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                // Placeholder for future barcode reset feature
                // const SizedBox(height: 16),
                // if (hasBarcode) TextButton.icon(
                //   onPressed: () => _resetToOriginalNutrition(),
                //   icon: const Icon(Icons.restore),
                //   label: const Text('Reset to Original'),
                // ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final carbs = double.tryParse(carbsController.text);
                          final fats = double.tryParse(fatsController.text);
                          final protein = double.tryParse(proteinController.text);
                          final calories = double.tryParse(caloriesController.text);

                          if (carbs == null || fats == null || protein == null || calories == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please enter valid numbers for all fields'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            return;
                          }

                          if (carbs < 0 || fats < 0 || protein < 0 || calories < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Values cannot be negative'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            return;
                          }

                          // Update the food item with new nutrition values
                          final updatedFoodItem = currentGroup.foodItem.copyWith(
                            carbohydratesPerHundredGrams: carbs,
                            fatsPerHundredGrams: fats,
                            proteinPerHundredGrams: protein,
                            kcalPerHundredGrams: calories,
                          );

                          // Update all batches with the new food item
                          for (final batch in currentGroup.batches) {
                            final updatedBatch = batch.copyWith(item: updatedFoodItem);
                            context.read<InventoryBloc>().add(UpdateInventoryBatch(updatedBatch));
                          }

                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Nutrition values updated'),
                              backgroundColor: Theme.of(context).colorScheme.tertiary,
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickRestockDialog(BuildContext context) {
    final countController = TextEditingController(text: '1');
    DateTime expirationDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add ${group.foodItem.name} Batch'),
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
                        const Text('Expiration Date'),
                        Row(
                          children: [
                            Text(
                              _formatDate(expirationDate),
                              style: Theme.of(context).textTheme.titleMedium,
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
                  item: group.foodItem,
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

  void _showEditBatchDialog(BuildContext context, InventoryBatch batch) {
    final countController = TextEditingController(text: batch.count.toString());
    DateTime expirationDate = batch.expirationDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 64),
          title: const Text('Edit Batch'),
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
                if (count == null || count < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid quantity'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                // Update batch
                final updatedBatch = batch.copyWith(
                  count: count,
                  expirationDate: expirationDate,
                );

                context.read<InventoryBloc>().add(UpdateInventoryBatch(updatedBatch));

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Batch updated successfully'),
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

              // Delete quotas for this batch
              context.read<ConsumptionQuotaBloc>().add(DeleteQuotasForBatch(batchId));

              Navigator.pop(dialogContext);

              // If this was the last batch, navigate back
              final currentState = context.read<InventoryBloc>().state;
              if (currentState is InventoryLoaded) {
                final remainingBatches = currentState.batches
                    .where((b) => b.item.id == group.foodItem.id)
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
        .where((batch) => batch.item.id == group.foodItem.id)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Batches'),
        content: Text(
          'Are you sure you want to delete all ${currentBatches.length} batches of ${group.foodItem.name}?',
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
                // Delete quotas for this batch
                context.read<ConsumptionQuotaBloc>().add(DeleteQuotasForBatch(batch.id));
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