import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_event.dart';
import 'package:inventory_manager/bloc/settings/settings_state.dart';
import 'package:inventory_manager/repositories/settings_repository.dart';
import 'package:inventory_manager/models/app_settings.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc({required this.repository}) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<UpdateExpirationWarningDays>(_onUpdateExpirationWarningDays);
    on<UpdateDailyTargets>(_onUpdateDailyTargets);
    on<ResetSettings>(_onResetSettings);
  }

  // Load settings from repository
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final settings = await repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  // Toggle notifications
  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          notificationsEnabled: event.enabled,
        );
        await repository.saveSettings(updatedSettings);
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update notifications: $e'));
      }
    }
  }

  // Change theme mode
  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          themeMode: event.themeMode,
        );
        await repository.saveSettings(updatedSettings);
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update theme: $e'));
      }
    }
  }

  // Update expiration warning days
  Future<void> _onUpdateExpirationWarningDays(
    UpdateExpirationWarningDays event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          expirationWarningDays: event.days,
        );
        await repository.saveSettings(updatedSettings);
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update expiration warning: $e'));
      }
    }
  }

  // Update daily targets
  Future<void> _onUpdateDailyTargets(
    UpdateDailyTargets event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          dailyCalorieTarget: event.calories,
          dailyCarbohydratesTarget: event.carbohydrates,
          dailyFatsTarget: event.fats,
          dailyProteinTarget: event.protein,
        );
        await repository.saveSettings(updatedSettings);
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update daily targets: $e'));
      }
    }
  }

  // Reset settings to defaults
  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      await repository.clearSettings();
      const defaultSettings = AppSettings();
      await repository.saveSettings(defaultSettings);
      emit(const SettingsLoaded(defaultSettings));
    } catch (e) {
      emit(SettingsError('Failed to reset settings: $e'));
    }
  }
}
