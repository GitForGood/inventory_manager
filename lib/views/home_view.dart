import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/services/storage_calculator_service.dart';
import 'package:inventory_manager/views/barcode_scanner_view.dart';
import 'package:inventory_manager/views/batch_form_view.dart';
import 'package:inventory_manager/views/food_item_detail_view.dart';
import 'package:inventory_manager/widgets/storage_summary_card.dart';
import 'package:inventory_manager/models/food_item_group.dart';
import 'package:material_symbols_icons/symbols.dart';
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          PopupMenuButton<InventoryFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            offset: const Offset(0, 48),
            onSelected: (InventoryFilter filter) {
              context.read<InventoryBloc>().add(FilterInventory(filter));
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: InventoryFilter.all,
                child: ListTile(
                  leading: Icon(Icons.all_inclusive),
                  title: Text('All Items'),
                ),
              ),
              PopupMenuItem(
                value: InventoryFilter.fresh,
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Fresh Items'),
                ),
              ),
              PopupMenuItem(
                value: InventoryFilter.expiringSoon,
                child: ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('Expiring Soon'),
                ),
              ),
              PopupMenuItem(
                value: InventoryFilter.expired,
                child: ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('Expired'),
                ),
              ),
            ],
          ),
          PopupMenuButton<InventorySortCriteria>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            offset: const Offset(0, 48),
            onSelected: (InventorySortCriteria criteria) {
              context.read<InventoryBloc>().add(SortInventory(criteria));
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: InventorySortCriteria.nameAscending,
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text('Name (A-Z)'),
                ),
              ),
              PopupMenuItem(
                value: InventorySortCriteria.nameDescending,
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text('Name (Z-A)'),
                ),
              ),
              PopupMenuItem(
                value: InventorySortCriteria.expirationDateAscending,
                child: ListTile(
                  leading: Icon(Icons.date_range),
                  title: Text('Expiration (Earliest First)'),
                ),
              ),
              PopupMenuItem(
                value: InventorySortCriteria.expirationDateDescending,
                child: ListTile(
                  leading: Icon(Icons.date_range),
                  title: Text('Expiration (Latest First)'),
                ),
              ),
            ],
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
                  );
                }

                if (filteredBatches.isEmpty) {
                  return Column(
                    children: [
                      if (storageStatus != null)
                        StorageSummaryCard(status: storageStatus),
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

                // Group batches by food item
                final groupedItems = FoodItemGroup.groupBatches(filteredBatches);

                return Column(
                  children: [
                    if (storageStatus != null)
                      StorageSummaryCard(status: storageStatus),
                    Expanded(
                      child: ListView.builder(
                        itemCount: groupedItems.length,
                        itemBuilder: (context, index) {
                          final group = groupedItems[index];
                          final status = group.expirationStatus;

                          Color statusColor;
                          switch (status) {
                            case ExpirationStatus.expired:
                              statusColor = Colors.red;
                              break;
                            case ExpirationStatus.expiringSoon:
                              statusColor = Colors.orange;
                              break;
                            case ExpirationStatus.fresh:
                              statusColor = Colors.green;
                              break;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            shape: Theme.of(context).cardTheme.shape,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor,
                                child: Text(
                                  group.totalCount.toString(),
                                  style: TextStyle(color: Theme.of(context).primaryColor),
                                ),
                              ),
                              title: Text(group.foodItem.name),
                              subtitle: Text(
                                //'Oldest batch expiry: ${_formatDate(group.closestExpirationDate)}\n'
                                group.daysUntilClosestExpiration >= 0 ? "${group.daysUntilClosestExpiration} days remaining" : "Expired ${-group.daysUntilClosestExpiration} days ago",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    group.batchCount.toString(),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                  SizedBox(width: 8,),
                                  Icon(Symbols.package_2),
                                ],
                              ), 
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FoodItemDetailView(group: group),
                                  ),
                                );
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
            label: 'Restock Existing Item',
            onTap: () {
              _showRestockDialog(context);
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.barcode_reader),
            label: 'Scan Barcode',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerView(),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.keyboard),
            label: 'Enter Manually',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BatchFormView(
                    barcode: null,
                    productData: null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context) {
    final inventoryState = context.read<InventoryBloc>().state;

    if (inventoryState is! InventoryLoaded || inventoryState.batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items in inventory to restock. Add a new item first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Group batches to get unique food items
    final groups = FoodItemGroup.groupBatches(inventoryState.batches);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restock Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    group.totalCount.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(group.foodItem.name),
                subtitle: Text('${group.batchCount} batch${group.batchCount > 1 ? "es" : ""}'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodItemDetailView(group: group),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}



