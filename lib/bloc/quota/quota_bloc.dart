import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/quota/quota_event.dart';
import 'package:inventory_manager/bloc/quota/quota_state.dart';
import 'package:inventory_manager/repositories/quota_repository.dart';
import 'package:inventory_manager/models/quota_schedule.dart';
import 'package:inventory_manager/models/quota_item.dart';

class QuotaBloc extends Bloc<QuotaEvent, QuotaState> {
  final QuotaRepository repository;

  QuotaBloc({required this.repository}) : super(const QuotaInitial()) {
    on<LoadQuotaSchedules>(_onLoadSchedules);
    on<CreateQuotaSchedule>(_onCreateSchedule);
    on<UpdateQuotaSchedule>(_onUpdateSchedule);
    on<DeleteQuotaSchedule>(_onDeleteSchedule);
    on<SetActiveSchedule>(_onSetActiveSchedule);
    on<ConsumeQuotaItem>(_onConsumeItem);
    on<AddQuotaItem>(_onAddItem);
    on<RemoveQuotaItem>(_onRemoveItem);
    on<ResetSchedule>(_onResetSchedule);
    on<CheckScheduleResets>(_onCheckResets);
  }

  // Load schedules
  Future<void> _onLoadSchedules(
    LoadQuotaSchedules event,
    Emitter<QuotaState> emit,
  ) async {
    emit(const QuotaLoading());
    try {
      final schedules = await repository.loadSchedules();
      final activeId = await repository.getActiveScheduleId();

      emit(QuotaLoaded(
        schedules: schedules,
        activeScheduleId: activeId,
      ));

      // Auto-check for resets
      add(const CheckScheduleResets());
    } catch (e) {
      emit(QuotaError('Failed to load schedules: $e'));
    }
  }

  // Create schedule
  Future<void> _onCreateSchedule(
    CreateQuotaSchedule event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        await repository.saveSchedule(event.schedule);
        final updatedSchedules = List<QuotaSchedule>.from(currentState.schedules)
          ..add(event.schedule);

        emit(currentState.copyWith(schedules: updatedSchedules));
      } catch (e) {
        emit(QuotaError('Failed to create schedule: $e'));
        emit(currentState);
      }
    }
  }

  // Update schedule
  Future<void> _onUpdateSchedule(
    UpdateQuotaSchedule event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        await repository.saveSchedule(event.schedule);
        final updatedSchedules = currentState.schedules.map((s) {
          return s.id == event.schedule.id ? event.schedule : s;
        }).toList();

        emit(currentState.copyWith(schedules: updatedSchedules));
      } catch (e) {
        emit(QuotaError('Failed to update schedule: $e'));
        emit(currentState);
      }
    }
  }

  // Delete schedule
  Future<void> _onDeleteSchedule(
    DeleteQuotaSchedule event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        await repository.deleteSchedule(event.scheduleId);
        final updatedSchedules = currentState.schedules
            .where((s) => s.id != event.scheduleId)
            .toList();

        final clearActive = currentState.activeScheduleId == event.scheduleId;

        emit(currentState.copyWith(
          schedules: updatedSchedules,
          clearActiveSchedule: clearActive,
        ));
      } catch (e) {
        emit(QuotaError('Failed to delete schedule: $e'));
        emit(currentState);
      }
    }
  }

  // Set active schedule
  Future<void> _onSetActiveSchedule(
    SetActiveSchedule event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        await repository.setActiveSchedule(event.scheduleId);
        emit(currentState.copyWith(activeScheduleId: event.scheduleId));
      } catch (e) {
        emit(QuotaError('Failed to set active schedule: $e'));
        emit(currentState);
      }
    }
  }

  // Consume quota item
  Future<void> _onConsumeItem(
    ConsumeQuotaItem event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        final scheduleIndex = currentState.schedules
            .indexWhere((s) => s.id == event.scheduleId);

        if (scheduleIndex == -1) {
          emit(const QuotaError('Schedule not found'));
          emit(currentState);
          return;
        }

        final schedule = currentState.schedules[scheduleIndex];
        final itemIndex = schedule.items.indexWhere((i) => i.id == event.itemId);

        if (itemIndex == -1) {
          emit(const QuotaError('Item not found'));
          emit(currentState);
          return;
        }

        // Update item consumption
        final updatedItem = schedule.items[itemIndex].consume(event.count);
        final updatedItems = List<QuotaItem>.from(schedule.items);
        updatedItems[itemIndex] = updatedItem;

        final updatedSchedule = schedule.copyWith(items: updatedItems);
        await repository.saveSchedule(updatedSchedule);

        final updatedSchedules = List<QuotaSchedule>.from(currentState.schedules);
        updatedSchedules[scheduleIndex] = updatedSchedule;

        emit(currentState.copyWith(schedules: updatedSchedules));
      } catch (e) {
        emit(QuotaError('Failed to consume item: $e'));
        emit(currentState);
      }
    }
  }

  // Add item to schedule
  Future<void> _onAddItem(
    AddQuotaItem event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        final scheduleIndex = currentState.schedules
            .indexWhere((s) => s.id == event.scheduleId);

        if (scheduleIndex == -1) return;

        final schedule = currentState.schedules[scheduleIndex];
        final updatedItems = List<QuotaItem>.from(schedule.items)..add(event.item);
        final updatedSchedule = schedule.copyWith(items: updatedItems);

        await repository.saveSchedule(updatedSchedule);

        final updatedSchedules = List<QuotaSchedule>.from(currentState.schedules);
        updatedSchedules[scheduleIndex] = updatedSchedule;

        emit(currentState.copyWith(schedules: updatedSchedules));
      } catch (e) {
        emit(QuotaError('Failed to add item: $e'));
        emit(currentState);
      }
    }
  }

  // Remove item from schedule
  Future<void> _onRemoveItem(
    RemoveQuotaItem event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        final scheduleIndex = currentState.schedules
            .indexWhere((s) => s.id == event.scheduleId);

        if (scheduleIndex == -1) return;

        final schedule = currentState.schedules[scheduleIndex];
        final updatedItems = schedule.items
            .where((item) => item.id != event.itemId)
            .toList();
        final updatedSchedule = schedule.copyWith(items: updatedItems);

        await repository.saveSchedule(updatedSchedule);

        final updatedSchedules = List<QuotaSchedule>.from(currentState.schedules);
        updatedSchedules[scheduleIndex] = updatedSchedule;

        emit(currentState.copyWith(schedules: updatedSchedules));
      } catch (e) {
        emit(QuotaError('Failed to remove item: $e'));
        emit(currentState);
      }
    }
  }

  // Reset schedule for new period
  Future<void> _onResetSchedule(
    ResetSchedule event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      try {
        final scheduleIndex = currentState.schedules
            .indexWhere((s) => s.id == event.scheduleId);

        if (scheduleIndex == -1) return;

        final schedule = currentState.schedules[scheduleIndex];
        final resetItems = schedule.items.map((item) => item.reset()).toList();
        final updatedSchedule = schedule.copyWith(
          items: resetItems,
          lastReset: DateTime.now(),
        );

        await repository.saveSchedule(updatedSchedule);

        final updatedSchedules = List<QuotaSchedule>.from(currentState.schedules);
        updatedSchedules[scheduleIndex] = updatedSchedule;

        emit(currentState.copyWith(schedules: updatedSchedules));
      } catch (e) {
        emit(QuotaError('Failed to reset schedule: $e'));
        emit(currentState);
      }
    }
  }

  // Check and auto-reset schedules
  Future<void> _onCheckResets(
    CheckScheduleResets event,
    Emitter<QuotaState> emit,
  ) async {
    if (state is QuotaLoaded) {
      final currentState = state as QuotaLoaded;
      bool hasChanges = false;
      final updatedSchedules = <QuotaSchedule>[];

      for (final schedule in currentState.schedules) {
        if (schedule.needsReset) {
          hasChanges = true;
          final resetItems = schedule.items.map((item) => item.reset()).toList();
          final resetSchedule = schedule.copyWith(
            items: resetItems,
            lastReset: DateTime.now(),
          );
          await repository.saveSchedule(resetSchedule);
          updatedSchedules.add(resetSchedule);
        } else {
          updatedSchedules.add(schedule);
        }
      }

      if (hasChanges) {
        emit(currentState.copyWith(schedules: updatedSchedules));
      }
    }
  }
}
