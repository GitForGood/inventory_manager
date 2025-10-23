import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_manager/models/app_settings.dart';

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

  Future<void> updateThemeMode(int themeModeIndex) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(
      themeMode: themeModeIndex >= 0 && themeModeIndex < 3
          ? [null, null, null][themeModeIndex] // Will be replaced by enum
          : settings.themeMode,
    ));
  }

  Future<void> updateExpirationWarningDays(int days) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(expirationWarningDays: days));
  }

  Future<void> updateDailyTargets({
    double? calories,
    double? carbohydrates,
    double? fats,
    double? protein,
  }) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(
      dailyCalorieTarget: calories,
      dailyCarbohydratesTarget: carbohydrates,
      dailyFatsTarget: fats,
      dailyProteinTarget: protein,
    ));
  }
}
