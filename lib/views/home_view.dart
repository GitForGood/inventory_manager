import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/services/storage_calculator_service.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterMenu(context),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortMenu(context),
            tooltip: 'Sort',
          ),
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryInitial) {
            return const Center(child: Text('Loading inventory...'));
          } else if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is InventoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InventoryBloc>().add(const LoadInventory());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is InventoryLoaded) {
            final batches = state.batches;
            final filteredBatches = state.filteredBatches;

            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                StorageStatus? storageStatus;

                if (settingsState is SettingsLoaded && batches.isNotEmpty) {
                  storageStatus = StorageCalculatorService.getStorageStatus(
                    batches: batches,
                    dailyCalorieTarget:
                        settingsState.settings.dailyCalorieTarget,
                    dailyCarbohydratesTarget:
                        settingsState.settings.dailyCarbohydratesTarget,
                    dailyFatsTarget: settingsState.settings.dailyFatsTarget,
                    dailyProteinTarget:
                        settingsState.settings.dailyProteinTarget,
                  );
                }

                if (filteredBatches.isEmpty) {
                  return Column(
                    children: [
                      if (storageStatus != null)
                        _StorageSummaryCard(status: storageStatus),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'No inventory items match filter',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text('Clear filters or add items'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    if (storageStatus != null)
                      _StorageSummaryCard(status: storageStatus),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredBatches.length,
                        itemBuilder: (context, index) {
                          final batch = filteredBatches[index];
                          final isExpired = batch.isExpired();
                          final isExpiringSoon = batch.isExpiringSoon();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                              title: Text(batch.item.name),
                              subtitle: Text(
                                'Expires: ${_formatDate(batch.expirationDate)}\n'
                                '${batch.daysUntilExpiration()} days remaining',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  _confirmDelete(context, batch.id);
                                },
                              ),
                              onTap: () {
                                // TODO: Navigate to batch details
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add, // icon when closed
        activeIcon: Icons.close, // icon when open
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 8,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.inventory),
            label: 'Restock Item in Inventory',
            onTap: () {
              debugPrint('Tried to restock');
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.barcode_reader),
            label: 'Scan Barcode',
            onTap: () {
              debugPrint('Tried to open camera');
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.keyboard),
            label: 'Enter Barcode Manually',
            onTap: () {
              debugPrint('Tried to manually enter barcode');
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return BlocProvider.value(
          value: context.read<InventoryBloc>(),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('All Items'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const FilterInventory(InventoryFilter.all),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Fresh Items'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const FilterInventory(InventoryFilter.fresh),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: const Text('Expiring Soon'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const FilterInventory(InventoryFilter.expiringSoon),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: const Text('Expired'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const FilterInventory(InventoryFilter.expired),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return BlocProvider.value(
          value: context.read<InventoryBloc>(),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha),
                  title: const Text('Name (A-Z)'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const SortInventory(InventorySortCriteria.nameAscending),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha),
                  title: const Text('Name (Z-A)'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const SortInventory(InventorySortCriteria.nameDescending),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Expiration (Earliest First)'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const SortInventory(
                        InventorySortCriteria.expirationDateAscending,
                      ),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Expiration (Latest First)'),
                  onTap: () {
                    context.read<InventoryBloc>().add(
                      const SortInventory(
                        InventorySortCriteria.expirationDateDescending,
                      ),
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String batchId) {
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
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddBatchDialog(BuildContext context) {
    // TODO: Implement proper add batch form
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose item'),
        children: [
          ListTile(title: Text('Scan barcode')),
          ListTile(title: Text('Choose from storage')),
          ListTile(title: Text('Manually enter barcode')),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add batch form coming soon!')),
    );
  }
}

class _StorageSummaryCard extends StatelessWidget {
  final StorageStatus status;

  const _StorageSummaryCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Storage Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.inventory_2,
                  label: 'Items',
                  value: status.totalItems.toString(),
                  color: Colors.blue,
                ),
                _SummaryItem(
                  icon: Icons.category,
                  label: 'Batches',
                  value: status.totalBatches.toString(),
                  color: Colors.purple,
                ),
                _SummaryItem(
                  icon: Icons.calendar_today,
                  label: 'Days',
                  value: status.estimatedDays.toStringAsFixed(1),
                  color: status.estimatedDays < 7
                      ? Colors.red
                      : status.estimatedDays < 14
                      ? Colors.orange
                      : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Limited by ${status.limitingFactor} (~${status.estimatedDays.toStringAsFixed(1)} days)',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NutrientChip(
                  label: 'Carbs',
                  value: status.totalNutrition['carbohydrates']!,
                  color: Colors.orange,
                ),
                _NutrientChip(
                  label: 'Fats',
                  value: status.totalNutrition['fats']!,
                  color: Colors.yellow,
                ),
                _NutrientChip(
                  label: 'Protein',
                  value: status.totalNutrition['protein']!,
                  color: Colors.red,
                ),
                _NutrientChip(
                  label: 'Kcal',
                  value: status.totalNutrition['kcal']!,
                  color: Colors.deepOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _NutrientChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value > 1000
                ? '${(value / 1000).toStringAsFixed(1)}k'
                : value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
