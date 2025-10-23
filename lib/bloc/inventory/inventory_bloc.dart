import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_event.dart';
import 'package:inventory_manager/bloc/inventory/inventory_state.dart';
import 'package:inventory_manager/models/inventory_batch.dart';
import 'package:inventory_manager/services/consumption_service.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc() : super(const InventoryInitial()) {
    on<LoadInventory>(_onLoadInventory);
    on<AddInventoryBatch>(_onAddInventoryBatch);
    on<UpdateInventoryBatch>(_onUpdateInventoryBatch);
    on<DeleteInventoryBatch>(_onDeleteInventoryBatch);
    on<FilterInventory>(_onFilterInventory);
    on<SortInventory>(_onSortInventory);
    on<ConsumeFromInventory>(_onConsumeFromInventory);
  }

  // Load inventory from data source
  Future<void> _onLoadInventory(
    LoadInventory event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      // TODO: Load from repository/database
      // For now, start with empty list
      final batches = <InventoryBatch>[];
      emit(InventoryLoaded(batches: batches));
    } catch (e) {
      emit(InventoryError('Failed to load inventory: $e'));
    }
  }

  // Add a new batch
  Future<void> _onAddInventoryBatch(
    AddInventoryBatch event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      try {
        // TODO: Save to repository/database
        final updatedBatches = List<InventoryBatch>.from(currentState.batches)
          ..add(event.batch);
        final sortedBatches = _sortBatches(updatedBatches, currentState.currentSort);
        emit(currentState.copyWith(batches: sortedBatches));
      } catch (e) {
        emit(InventoryError('Failed to add batch: $e'));
      }
    }
  }

  // Update an existing batch
  Future<void> _onUpdateInventoryBatch(
    UpdateInventoryBatch event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      try {
        // TODO: Update in repository/database
        final updatedBatches = currentState.batches.map((batch) {
          return batch.id == event.batch.id ? event.batch : batch;
        }).toList();
        final sortedBatches = _sortBatches(updatedBatches, currentState.currentSort);
        emit(currentState.copyWith(batches: sortedBatches));
      } catch (e) {
        emit(InventoryError('Failed to update batch: $e'));
      }
    }
  }

  // Delete a batch
  Future<void> _onDeleteInventoryBatch(
    DeleteInventoryBatch event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      try {
        // TODO: Delete from repository/database
        final updatedBatches = currentState.batches
            .where((batch) => batch.id != event.batchId)
            .toList();
        emit(currentState.copyWith(batches: updatedBatches));
      } catch (e) {
        emit(InventoryError('Failed to delete batch: $e'));
      }
    }
  }

  // Apply filter
  Future<void> _onFilterInventory(
    FilterInventory event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      emit(currentState.copyWith(currentFilter: event.filter));
    }
  }

  // Apply sort
  Future<void> _onSortInventory(
    SortInventory event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      final sortedBatches = _sortBatches(currentState.batches, event.sortBy);
      emit(currentState.copyWith(
        batches: sortedBatches,
        currentSort: event.sortBy,
      ));
    }
  }

  // Consume from inventory using FIFO
  Future<void> _onConsumeFromInventory(
    ConsumeFromInventory event,
    Emitter<InventoryState> emit,
  ) async {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      try {
        final result = ConsumptionService.consumeFromBatches(
          batches: currentState.batches,
          foodItemName: event.foodItemName,
          itemCount: event.itemCount,
        );

        if (result.success) {
          // TODO: Save updated batches to repository/database
          final sortedBatches = _sortBatches(
            result.updatedBatches,
            currentState.currentSort,
          );
          emit(currentState.copyWith(batches: sortedBatches));
        } else {
          emit(InventoryError(result.message));
          emit(currentState);
        }
      } catch (e) {
        emit(InventoryError('Failed to consume from inventory: $e'));
        emit(currentState);
      }
    }
  }

  // Helper method to sort batches
  List<InventoryBatch> _sortBatches(
    List<InventoryBatch> batches,
    InventorySortCriteria sortBy,
  ) {
    final sortedBatches = List<InventoryBatch>.from(batches);
    switch (sortBy) {
      case InventorySortCriteria.nameAscending:
        sortedBatches.sort((a, b) => a.item.name.compareTo(b.item.name));
      case InventorySortCriteria.nameDescending:
        sortedBatches.sort((a, b) => b.item.name.compareTo(a.item.name));
      case InventorySortCriteria.expirationDateAscending:
        sortedBatches.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
      case InventorySortCriteria.expirationDateDescending:
        sortedBatches.sort((a, b) => b.expirationDate.compareTo(a.expirationDate));
      case InventorySortCriteria.quantityAscending:
        sortedBatches.sort((a, b) => a.count.compareTo(b.count));
      case InventorySortCriteria.quantityDescending:
        sortedBatches.sort((a, b) => b.count.compareTo(a.count));
    }
    return sortedBatches;
  }
}
