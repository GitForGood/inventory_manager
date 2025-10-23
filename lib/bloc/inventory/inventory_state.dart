import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/bloc/inventory/inventory_event.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

// Initial state
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

// Loading state
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

// Loaded state with data
class InventoryLoaded extends InventoryState {
  final List<InventoryBatch> batches;
  final InventoryFilter currentFilter;
  final InventorySortCriteria currentSort;

  const InventoryLoaded({
    required this.batches,
    this.currentFilter = InventoryFilter.all,
    this.currentSort = InventorySortCriteria.expirationDateAscending,
  });

  // Convenience getters
  List<InventoryBatch> get expiredBatches =>
      batches.where((batch) => batch.isExpired()).toList();

  List<InventoryBatch> get expiringSoonBatches =>
      batches.where((batch) => batch.isExpiringSoon()).toList();

  List<InventoryBatch> get freshBatches =>
      batches.where((batch) => !batch.isExpired() && !batch.isExpiringSoon()).toList();

  int get totalItemCount =>
      batches.fold(0, (sum, batch) => sum + batch.count);

  // Get filtered batches based on current filter
  List<InventoryBatch> get filteredBatches {
    switch (currentFilter) {
      case InventoryFilter.expired:
        return expiredBatches;
      case InventoryFilter.expiringSoon:
        return expiringSoonBatches;
      case InventoryFilter.fresh:
        return freshBatches;
      case InventoryFilter.all:
        return batches;
    }
  }

  @override
  List<Object?> get props => [batches, currentFilter, currentSort];

  // CopyWith for state updates
  InventoryLoaded copyWith({
    List<InventoryBatch>? batches,
    InventoryFilter? currentFilter,
    InventorySortCriteria? currentSort,
  }) {
    return InventoryLoaded(
      batches: batches ?? this.batches,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSort: currentSort ?? this.currentSort,
    );
  }
}

// Error state
class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
