import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/inventory_batch.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

// Load all inventory batches
class LoadInventory extends InventoryEvent {
  const LoadInventory();
}

// Add a new batch to inventory
class AddInventoryBatch extends InventoryEvent {
  final InventoryBatch batch;

  const AddInventoryBatch(this.batch);

  @override
  List<Object?> get props => [batch];
}

// Update an existing batch
class UpdateInventoryBatch extends InventoryEvent {
  final InventoryBatch batch;

  const UpdateInventoryBatch(this.batch);

  @override
  List<Object?> get props => [batch];
}

// Delete a batch from inventory
class DeleteInventoryBatch extends InventoryEvent {
  final String batchId;

  const DeleteInventoryBatch(this.batchId);

  @override
  List<Object?> get props => [batchId];
}

// Filter inventory by criteria
class FilterInventory extends InventoryEvent {
  final InventoryFilter filter;

  const FilterInventory(this.filter);

  @override
  List<Object?> get props => [filter];
}

// Sort inventory by criteria
class SortInventory extends InventoryEvent {
  final InventorySortCriteria sortBy;

  const SortInventory(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}

// Consume from inventory (FIFO)
class ConsumeFromInventory extends InventoryEvent {
  final String foodItemName;
  final int itemCount;

  const ConsumeFromInventory({
    required this.foodItemName,
    required this.itemCount,
  });

  @override
  List<Object?> get props => [foodItemName, itemCount];
}

// Enum for filtering options
enum InventoryFilter {
  all,
  expired,
  expiringSoon,
  fresh,
}

// Enum for sorting options
enum InventorySortCriteria {
  nameAscending,
  nameDescending,
  expirationDateAscending,
  expirationDateDescending,
  quantityAscending,
  quantityDescending,
}
