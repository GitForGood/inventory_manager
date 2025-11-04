import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/daily_calorie_target.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

// Load settings from storage
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

// Toggle notifications
class ToggleNotifications extends SettingsEvent {
  final bool enabled;

  const ToggleNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Toggle high contrast mode
class ChangeThemeMode extends SettingsEvent {
  final bool highContrast;

  const ChangeThemeMode(this.highContrast);

  @override
  List<Object?> get props => [highContrast];
}

// Update expiration warning days
class UpdateExpirationWarningDays extends SettingsEvent {
  final int days;

  const UpdateExpirationWarningDays(this.days);

  @override
  List<Object?> get props => [days];
}

// Update expiration notifications
class UpdateExpirationNotifications extends SettingsEvent {
  final bool enabled;

  const UpdateExpirationNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Update quota generation notifications
class UpdateQuotaGenerationNotifications extends SettingsEvent {
  final bool enabled;

  const UpdateQuotaGenerationNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

// Update preferred quota interval
class UpdatePreferredQuotaInterval extends SettingsEvent {
  final int intervalIndex;

  const UpdatePreferredQuotaInterval(this.intervalIndex);

  @override
  List<Object?> get props => [intervalIndex];
}

// Update inventory calorie target
class UpdateInventoryCalorieTarget extends SettingsEvent {
  final int? calorieTarget;

  const UpdateInventoryCalorieTarget(this.calorieTarget);

  @override
  List<Object?> get props => [calorieTarget];
}

abstract class DailyCalorieTargetEvent extends SettingsEvent{
  final DailyCalorieTarget? target;

  const DailyCalorieTargetEvent(this.target);
}

class SetManualCalorieTarget extends DailyCalorieTargetEvent {
  final ManualCalorieTarget manualTarget;

  const SetManualCalorieTarget(this.manualTarget) : super(manualTarget);

  @override
  List<Object?> get props => [manualTarget.target];
}

class SetCalculateedDailyCalorieTarget extends DailyCalorieTargetEvent {
  final CalculatedCalorieTarget calculatedTarget;

  const SetCalculateedDailyCalorieTarget(this.calculatedTarget): super(calculatedTarget);
  
  @override
  List<Object?> get props => [
    calculatedTarget.people,
    calculatedTarget.days,
    calculatedTarget.caloriesPerPerson,
    calculatedTarget.target
  ];
}

class ClearDailyCalorieTarget extends DailyCalorieTargetEvent {
  const ClearDailyCalorieTarget(): super(null);
}


// Update daily calorie consumption
class UpdateDailyCalorieConsumption extends SettingsEvent {
  final int? dailyCalories;

  const UpdateDailyCalorieConsumption(this.dailyCalories);

  @override
  List<Object?> get props => [dailyCalories];
}

// Reset all settings to defaults
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
