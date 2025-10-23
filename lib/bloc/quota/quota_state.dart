import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/quota_schedule.dart';

abstract class QuotaState extends Equatable {
  const QuotaState();

  @override
  List<Object?> get props => [];
}

// Initial state
class QuotaInitial extends QuotaState {
  const QuotaInitial();
}

// Loading state
class QuotaLoading extends QuotaState {
  const QuotaLoading();
}

// Loaded state with schedules
class QuotaLoaded extends QuotaState {
  final List<QuotaSchedule> schedules;
  final String? activeScheduleId;

  const QuotaLoaded({
    required this.schedules,
    this.activeScheduleId,
  });

  // Get active schedule
  QuotaSchedule? get activeSchedule {
    if (activeScheduleId == null) return null;
    try {
      return schedules.firstWhere((s) => s.id == activeScheduleId);
    } catch (e) {
      return null;
    }
  }

  // Get inactive schedules
  List<QuotaSchedule> get inactiveSchedules {
    if (activeScheduleId == null) return schedules;
    return schedules.where((s) => s.id != activeScheduleId).toList();
  }

  @override
  List<Object?> get props => [schedules, activeScheduleId];

  // CopyWith for state updates
  QuotaLoaded copyWith({
    List<QuotaSchedule>? schedules,
    String? activeScheduleId,
    bool clearActiveSchedule = false,
  }) {
    return QuotaLoaded(
      schedules: schedules ?? this.schedules,
      activeScheduleId: clearActiveSchedule ? null : (activeScheduleId ?? this.activeScheduleId),
    );
  }
}

// Error state
class QuotaError extends QuotaState {
  final String message;

  const QuotaError(this.message);

  @override
  List<Object?> get props => [message];
}
