import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

// Change theme mode
class ChangeThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const ChangeThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

// Update expiration warning days
class UpdateExpirationWarningDays extends SettingsEvent {
  final int days;

  const UpdateExpirationWarningDays(this.days);

  @override
  List<Object?> get props => [days];
}

// Update daily nutritional targets
class UpdateDailyTargets extends SettingsEvent {
  final double? calories;
  final double? carbohydrates;
  final double? fats;
  final double? protein;

  const UpdateDailyTargets({
    this.calories,
    this.carbohydrates,
    this.fats,
    this.protein,
  });

  @override
  List<Object?> get props => [calories, carbohydrates, fats, protein];
}

// Reset all settings to defaults
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
