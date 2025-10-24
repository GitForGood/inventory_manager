import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/models/food_item_group.dart';
import 'package:inventory_manager/models/inventory_batch.dart';

/// Detailed view showing all batches for a specific food item
class FoodItemDetailView extends StatelessWidget {
  final FoodItemGroup group;

  const FoodItemDetailView({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final nutrition = group.getTotalNutrition();
    final batches = group.batchesSortedByExpiration;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.foodItem.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteAllBatches(context),
            tooltip: 'Delete all batches',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        label: 'Total Items',
                        value: group.totalCount.toString(),
                        icon: Icons.inventory_2,
                      ),
                      _SummaryItem(
                        label: 'Batches',
                        value: group.batchCount.toString(),
                        icon: Icons.layers,
                      ),
                      _SummaryItem(
                        label: 'Weight/Item',
                        value: '${group.foodItem.weightPerItemGrams.toStringAsFixed(0)}g',
                        icon: Icons.scale,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nutrition Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Nutrition',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NutritionItem(
                        label: 'Calories',
                        value: nutrition['kcal']!.toStringAsFixed(0),
                        unit: 'kcal',
                      ),
                      _NutritionItem(
                        label: 'Carbs',
                        value: nutrition['carbohydrates']!.toStringAsFixed(1),
                        unit: 'g',
                      ),
                      _NutritionItem(
                        label: 'Fats',
                        value: nutrition['fats']!.toStringAsFixed(1),
                        unit: 'g',
                      ),
                      _NutritionItem(
                        label: 'Protein',
                        value: nutrition['protein']!.toStringAsFixed(1),
                        unit: 'g',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Batches Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showQuickRestockDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Batch'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Batches List
          ...batches.map((batch) {
            final isExpired = batch.isExpired();
            final isExpiringSoon = batch.isExpiringSoon();
            final daysUntilExpiration = batch.daysUntilExpiration();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isExpired
                      ? Colors.red
                      : isExpiringSoon
                          ? Colors.orange
                          : Colors.green,
                  child: Text(
                    batch.count.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  'Batch ${batches.indexOf(batch) + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Expires: ${_formatDate(batch.expirationDate)}\n'
                  '${daysUntilExpiration >= 0 ? "$daysUntilExpiration days remaining" : "Expired ${-daysUntilExpiration} days ago"}',
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
          }),
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
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.orange,
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
                );

                context.read<InventoryBloc>().add(AddInventoryBatch(newBatch));

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Batch added successfully'),
                    backgroundColor: Colors.green,
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
                if (count == null || count < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.orange,
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
                  const SnackBar(
                    content: Text('Batch updated successfully'),
                    backgroundColor: Colors.green,
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<InventoryBloc>().add(DeleteInventoryBatch(batchId));
              Navigator.pop(dialogContext);

              // If this was the last batch, navigate back
              if (group.batchCount == 1) {
                Navigator.pop(context);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Batch deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllBatches(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Batches'),
        content: Text(
          'Are you sure you want to delete all ${group.batchCount} batches of ${group.foodItem.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete all batches
              for (final batch in group.batches) {
                context.read<InventoryBloc>().add(DeleteInventoryBatch(batch.id));
              }

              Navigator.pop(dialogContext);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All batches deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a summary item
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Widget for displaying a nutrition item
class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _NutritionItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
