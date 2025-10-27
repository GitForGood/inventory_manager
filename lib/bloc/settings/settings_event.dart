import 'package:equatable/equatable.dart';

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

// Reset all settings to defaults
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
