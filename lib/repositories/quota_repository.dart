import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_manager/models/quota_schedule.dart';

class QuotaRepository {
  static const String _schedulesKey = 'quota_schedules';
  static const String _activeScheduleKey = 'active_schedule_id';

  // Save all schedules
  Future<void> saveSchedules(List<QuotaSchedule> schedules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = schedules.map((schedule) => schedule.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_schedulesKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save schedules: $e');
    }
  }

  // Load all schedules
  Future<List<QuotaSchedule>> loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_schedulesKey);

      if (jsonString == null) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => QuotaSchedule.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list if loading fails
      return [];
    }
  }

  // Save a single schedule (updates if exists, adds if new)
  Future<void> saveSchedule(QuotaSchedule schedule) async {
    final schedules = await loadSchedules();
    final index = schedules.indexWhere((s) => s.id == schedule.id);

    if (index != -1) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }

    await saveSchedules(schedules);
  }

  // Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    final schedules = await loadSchedules();
    schedules.removeWhere((s) => s.id == scheduleId);
    await saveSchedules(schedules);

    // Clear active schedule if it was deleted
    final activeId = await getActiveScheduleId();
    if (activeId == scheduleId) {
      await clearActiveSchedule();
    }
  }

  // Set active schedule
  Future<void> setActiveSchedule(String scheduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeScheduleKey, scheduleId);
    } catch (e) {
      throw Exception('Failed to set active schedule: $e');
    }
  }

  // Get active schedule ID
  Future<String?> getActiveScheduleId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeScheduleKey);
    } catch (e) {
      return null;
    }
  }

  // Clear active schedule
  Future<void> clearActiveSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeScheduleKey);
    } catch (e) {
      throw Exception('Failed to clear active schedule: $e');
    }
  }

  // Get active schedule
  Future<QuotaSchedule?> getActiveSchedule() async {
    final activeId = await getActiveScheduleId();
    if (activeId == null) return null;

    final schedules = await loadSchedules();
    try {
      return schedules.firstWhere((s) => s.id == activeId);
    } catch (e) {
      return null;
    }
  }

  // Clear all schedules
  Future<void> clearAllSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_schedulesKey);
      await prefs.remove(_activeScheduleKey);
    } catch (e) {
      throw Exception('Failed to clear schedules: $e');
    }
  }
}
