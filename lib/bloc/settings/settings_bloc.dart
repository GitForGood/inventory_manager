import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/settings/settings_event.dart';
import 'package:inventory_manager/bloc/settings/settings_state.dart';
import 'package:inventory_manager/repositories/settings_repository.dart';
import 'package:inventory_manager/models/app_settings.dart';
import 'package:inventory_manager/models/quota_schedule.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc({required this.repository}) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<UpdateExpirationWarningDays>(_onUpdateExpirationWarningDays);
    on<UpdateExpirationNotifications>(_onUpdateExpirationNotifications);
    on<UpdateQuotaGenerationNotifications>(_onUpdateQuotaGenerationNotifications);
    on<UpdatePreferredQuotaInterval>(_onUpdatePreferredQuotaInterval);
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

  // Change high contrast mode
  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          highContrast: event.highContrast,
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

  // Update expiration notifications
  Future<void> _onUpdateExpirationNotifications(
    UpdateExpirationNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          expirationNotificationsEnabled: event.enabled,
        );
        await repository.saveSettings(updatedSettings);
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update expiration notifications: $e'));
      }
    }
  }

  // Update quota generation notifications
  Future<void> _onUpdateQuotaGenerationNotifications(
    UpdateQuotaGenerationNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          quotaGenerationNotificationsEnabled: event.enabled,
        );
        await repository.saveSettings(updatedSettings);
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update quota generation notifications: $e'));
      }
    }
  }

  // Update preferred quota interval
  Future<void> _onUpdatePreferredQuotaInterval(
    UpdatePreferredQuotaInterval event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      try {
        final updatedSettings = currentState.settings.copyWith(
          preferredQuotaInterval: event.intervalIndex >= 0 && event.intervalIndex < 3
              ? [SchedulePeriod.weekly, SchedulePeriod.monthly, SchedulePeriod.quarterly][event.intervalIndex]
              : currentState.settings.preferredQuotaInterval,
        );
        await repository.saveSettings(updatedSettings);
        emit(SettingsLoaded(updatedSettings));
      } catch (e) {
        emit(SettingsError('Failed to update quota interval: $e'));
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
