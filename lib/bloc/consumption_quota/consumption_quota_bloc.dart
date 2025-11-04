import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_event.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_state.dart';
import 'package:inventory_manager/models/consumption_quota.dart';
import 'package:inventory_manager/repositories/consumption_quota_repository.dart';
import 'package:inventory_manager/services/quota_generation_service.dart';
import 'package:inventory_manager/services/recipe_database.dart';
import 'package:inventory_manager/services/consumption_service.dart';
import 'package:inventory_manager/services/notification_service.dart';
import 'package:inventory_manager/services/quota_notification_helper.dart';

class ConsumptionQuotaBloc extends Bloc<ConsumptionQuotaEvent, ConsumptionQuotaState> {
  final ConsumptionQuotaRepository _repository = ConsumptionQuotaRepository();
  final RecipeDatabase _database = RecipeDatabase.instance;

  ConsumptionQuotaBloc() : super(const ConsumptionQuotaInitial()) {
    on<LoadConsumptionQuotas>(_onLoadConsumptionQuotas);
    on<LoadCurrentPeriodQuotas>(_onLoadCurrentPeriodQuotas);
    on<GenerateQuotasForBatch>(_onGenerateQuotasForBatch);
    on<CompleteQuota>(_onCompleteQuota);
    on<ChangePreferredPeriod>(_onChangePreferredPeriod);
    on<RegenerateAllQuotas>(_onRegenerateAllQuotas);
    on<DeleteQuotasForBatch>(_onDeleteQuotasForBatch);
    on<RefreshQuotas>(_onRefreshQuotas);
    on<ClearAndRegenerateAllQuotas>(_onClearAndRegenerateAllQuotas);
  }

  // Load all consumption quotas
  Future<void> _onLoadConsumptionQuotas(
    LoadConsumptionQuotas event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    emit(const ConsumptionQuotaLoading());
    try {
      final period = await _repository.getPreferredPeriod();
      final allQuotas = await _repository.getAllQuotas();

      // Check if quotas need regeneration (expired or missing)
      final needsRegeneration = QuotaGenerationService.needsRegeneration(
        existingQuotas: allQuotas,
        period: period,
      );

      if (needsRegeneration) {
        // Automatically regenerate expired quotas
        add(const ClearAndRegenerateAllQuotas());
        return;
      }

      // Quotas are still valid, load them normally
      final quotasByFoodItem = await _repository.getQuotasGroupedByFoodItem();

      emit(ConsumptionQuotaLoaded(
        quotasByFoodItem: quotasByFoodItem,
        selectedPeriod: period,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(ConsumptionQuotaError('Failed to load quotas: $e'));
    }
  }

  // Load quotas for the current period
  Future<void> _onLoadCurrentPeriodQuotas(
    LoadCurrentPeriodQuotas event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    emit(const ConsumptionQuotaLoading());
    try {
      final period = await _repository.getPreferredPeriod();
      final allQuotas = await _repository.getAllQuotas();

      // Check if quotas need regeneration (expired or missing)
      final needsRegeneration = QuotaGenerationService.needsRegeneration(
        existingQuotas: allQuotas,
        period: period,
      );

      if (needsRegeneration) {
        // Automatically regenerate expired quotas
        add(const ClearAndRegenerateAllQuotas());
        return;
      }

      // Quotas are still valid, load current period only
      final quotasByFoodItem = await _repository.getCurrentPeriodQuotas();

      emit(ConsumptionQuotaLoaded(
        quotasByFoodItem: quotasByFoodItem,
        selectedPeriod: period,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(ConsumptionQuotaError('Failed to load current period quotas: $e'));
    }
  }
  
  // Generate quotas for a new batch - triggers full regeneration
  Future<void> _onGenerateQuotasForBatch(
    GenerateQuotasForBatch event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    try {
      // When a new batch is added, regenerate all quotas to include it
      add(const ClearAndRegenerateAllQuotas());
    } catch (e) {
      emit(ConsumptionQuotaError('Failed to generate quotas for batch: $e'));
    }
  }

  // Complete/increment a quota
  Future<void> _onCompleteQuota(
    CompleteQuota event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    if (state is ConsumptionQuotaLoaded) {
      final currentState = state as ConsumptionQuotaLoaded;

      try {
        // Get the quota
        final quota = await _repository.getQuota(event.quotaId);
        if (quota == null) {
          emit(const ConsumptionQuotaError('Quota not found'));
          emit(currentState);
          return;
        }

        // Get all inventory batches for this food item
        final allBatches = await _database.getAllInventoryBatches();

        // Consume from inventory using FIFO with overflow
        final consumptionResult = ConsumptionService.consumeFromBatches(
          batches: allBatches,
          foodItemName: quota.foodItemName,
          itemCount: event.itemCount,
        );

        if (!consumptionResult.success) {
          emit(ConsumptionQuotaError(consumptionResult.message));
          emit(currentState);
          return;
        }

        // Update batches in database
        for (final batch in consumptionResult.updatedBatches) {
          // Only update batches that were affected
          final originalBatch = allBatches.firstWhere(
            (b) => b.id == batch.id,
            orElse: () => batch,
          );
          if (originalBatch.count != batch.count) {
            await _database.updateInventoryBatch(batch);
          }
        }

        // Delete fully consumed batches
        for (final batchId in consumptionResult.consumedBatchIds) {
          await _database.deleteInventoryBatch(batchId);
          // Also delete quotas for the consumed batch
          await _repository.deleteQuotasForBatch(batchId);
        }

        // Increment quota consumption
        final updatedQuota = quota.consume(event.itemCount);
        await _repository.updateQuota(updatedQuota);

        // Update state with new quota
        final updatedQuotasByFoodItem = Map<String, List<ConsumptionQuota>>.from(
          currentState.quotasByFoodItem,
        );

        // Find and update the quota in the grouped map
        if (updatedQuotasByFoodItem.containsKey(quota.foodItemName)) {
          final quotasList = List<ConsumptionQuota>.from(
            updatedQuotasByFoodItem[quota.foodItemName]!,
          );

          final index = quotasList.indexWhere((q) => q.id == quota.id);
          if (index != -1) {
            quotasList[index] = updatedQuota;
            updatedQuotasByFoodItem[quota.foodItemName] = quotasList;
          }
        }

        emit(currentState.copyWith(
          quotasByFoodItem: updatedQuotasByFoodItem,
          lastUpdated: DateTime.now(),
        ));
      } catch (e) {
        emit(ConsumptionQuotaError('Failed to complete quota: $e'));
        emit(currentState);
      }
    }
  }

  // Change preferred period
  Future<void> _onChangePreferredPeriod(
    ChangePreferredPeriod event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    try {
      await _repository.setPreferredPeriod(event.newPeriod);

      // Reload quotas with new period
      add(const LoadConsumptionQuotas());
    } catch (e) {
      emit(ConsumptionQuotaError('Failed to change preferred period: $e'));
    }
  }

  // Regenerate all quotas with a new period
  Future<void> _onRegenerateAllQuotas(
    RegenerateAllQuotas event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    emit(const ConsumptionQuotaLoading());
    try {
      // This would require getting all batches and regenerating quotas
      // For now, just change the period and reload
      await _repository.setPreferredPeriod(event.newPeriod);

      final quotasByFoodItem = await _repository.getQuotasGroupedByFoodItem();

      // Reschedule notification for the new period
      await _scheduleQuotaRegenerationNotification(event.newPeriod);

      emit(ConsumptionQuotaLoaded(
        quotasByFoodItem: quotasByFoodItem,
        selectedPeriod: event.newPeriod,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(ConsumptionQuotaError('Failed to regenerate quotas: $e'));
    }
  }

  // Delete quotas for a batch
  Future<void> _onDeleteQuotasForBatch(
    DeleteQuotasForBatch event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    if (state is ConsumptionQuotaLoaded) {
      final currentState = state as ConsumptionQuotaLoaded;

      try {
        await _repository.deleteQuotasForBatch(event.batchId);

        // Reload quotas
        add(const LoadConsumptionQuotas());
      } catch (e) {
        emit(ConsumptionQuotaError('Failed to delete quotas for batch: $e'));
        emit(currentState);
      }
    }
  }

  // Refresh quotas
  Future<void> _onRefreshQuotas(
    RefreshQuotas event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    add(const LoadConsumptionQuotas());
  }

  // Clear all quotas and regenerate from current batches
  Future<void> _onClearAndRegenerateAllQuotas(
    ClearAndRegenerateAllQuotas event,
    Emitter<ConsumptionQuotaState> emit,
  ) async {
    emit(const ConsumptionQuotaLoading());
    try {
      // Get all quotas and delete them
      final allQuotas = await _repository.getAllQuotas();
      for (final quota in allQuotas) {
        await _repository.deleteQuota(quota.id);
      }

      // Get all batches and regenerate quotas (aggregated by food item)
      final period = await _repository.getPreferredPeriod();
      final allBatches = await _database.getAllInventoryBatches();

      // Generate aggregated quotas for current period
      final quotas = QuotaGenerationService.generateQuotasForCurrentPeriod(
        batches: allBatches,
        period: period,
      );

      await _repository.createQuotas(quotas);

      // Schedule notification for next period regeneration
      await _scheduleQuotaRegenerationNotification(period);

      // Reload quotas to update state
      add(const LoadConsumptionQuotas());
    } catch (e) {
      emit(ConsumptionQuotaError('Failed to clear and regenerate quotas: $e'));
    }
  }

  /// Schedule a notification for the next quota regeneration
  Future<void> _scheduleQuotaRegenerationNotification(
    period,
  ) async {
    try {
      final notificationService = NotificationService();
      final nextNotificationTime =
          QuotaNotificationHelper.calculateNextNotificationTime(period);
      final periodName = QuotaNotificationHelper.getPeriodName(period);

      await notificationService.scheduleQuotaRegenerationNotification(
        scheduledDate: nextNotificationTime,
        periodName: periodName,
      );
    } catch (e) {
      // Notification scheduling failure shouldn't block quota operations
      // Log error if you have logging set up
    }
  }
}
