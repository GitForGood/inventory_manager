import 'package:equatable/equatable.dart';
import 'package:inventory_manager/models/app_settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

// Initial state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

// Loading state
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

// Loaded state with settings data
class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];

  // CopyWith for state updates
  SettingsLoaded copyWith({AppSettings? settings}) {
    return SettingsLoaded(settings ?? this.settings);
  }
}

// Error state
class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseDeleting extends SettingsState{
  const DatabaseDeleting();
}