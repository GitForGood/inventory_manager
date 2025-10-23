import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/quota_schedule.dart';
import 'package:inventory_manager/models/quota_item.dart';

abstract class QuotaEvent extends Equatable {
  const QuotaEvent();

  @override
  List<Object?> get props => [];
}

// Load all schedules
class LoadQuotaSchedules extends QuotaEvent {
  const LoadQuotaSchedules();
}

// Create new schedule
class CreateQuotaSchedule extends QuotaEvent {
  final QuotaSchedule schedule;

  const CreateQuotaSchedule(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

// Update existing schedule
class UpdateQuotaSchedule extends QuotaEvent {
  final QuotaSchedule schedule;

  const UpdateQuotaSchedule(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

// Delete schedule
class DeleteQuotaSchedule extends QuotaEvent {
  final String scheduleId;

  const DeleteQuotaSchedule(this.scheduleId);

  @override
  List<Object?> get props => [scheduleId];
}

// Set active schedule
class SetActiveSchedule extends QuotaEvent {
  final String scheduleId;

  const SetActiveSchedule(this.scheduleId);

  @override
  List<Object?> get props => [scheduleId];
}

// Consume quota item (increment progress)
class ConsumeQuotaItem extends QuotaEvent {
  final String scheduleId;
  final String itemId;
  final int count;

  const ConsumeQuotaItem({
    required this.scheduleId,
    required this.itemId,
    required this.count,
  });

  @override
  List<Object?> get props => [scheduleId, itemId, count];
}

// Add item to schedule
class AddQuotaItem extends QuotaEvent {
  final String scheduleId;
  final QuotaItem item;

  const AddQuotaItem({
    required this.scheduleId,
    required this.item,
  });

  @override
  List<Object?> get props => [scheduleId, item];
}

// Remove item from schedule
class RemoveQuotaItem extends QuotaEvent {
  final String scheduleId;
  final String itemId;

  const RemoveQuotaItem({
    required this.scheduleId,
    required this.itemId,
  });

  @override
  List<Object?> get props => [scheduleId, itemId];
}

// Reset schedule (new period)
class ResetSchedule extends QuotaEvent {
  final String scheduleId;

  const ResetSchedule(this.scheduleId);

  @override
  List<Object?> get props => [scheduleId];
}

// Check and auto-reset schedules if needed
class CheckScheduleResets extends QuotaEvent {
  const CheckScheduleResets();
}
