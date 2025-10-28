import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_manager/models/app_settings.dart';
import 'package:inventory_manager/models/consumption_period.dart';

class SettingsRepository {
  static const String _settingsKey = 'app_settings';

  // Save settings to SharedPreferences
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  // Load settings from SharedPreferences
  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);

      if (jsonString == null) {
        // Return default settings if none exist
        return const AppSettings();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      // Return default settings if loading fails
      return const AppSettings();
    }
  }

  // Clear all settings (reset to defaults)
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
    } catch (e) {
      throw Exception('Failed to clear settings: $e');
    }
  }

  // Update individual setting values
  Future<void> updateNotifications(bool enabled) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(notificationsEnabled: enabled));
  }

  Future<void> updateHighContrast(bool enabled) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(highContrast: enabled));
  }

  Future<void> updateExpirationWarningDays(int days) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(expirationWarningDays: days));
  }

  Future<void> updateExpirationNotifications(bool enabled) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(expirationNotificationsEnabled: enabled));
  }

  Future<void> updateQuotaGenerationNotifications(bool enabled) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(quotaGenerationNotificationsEnabled: enabled));
  }

  Future<void> updatePreferredQuotaInterval(int intervalIndex) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(
      preferredQuotaInterval: intervalIndex >= 0 && intervalIndex < 3
          ? [ConsumptionPeriod.weekly, ConsumptionPeriod.monthly, ConsumptionPeriod.quarterly][intervalIndex]
          : settings.preferredQuotaInterval,
    ));
  }
}
