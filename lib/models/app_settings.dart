import 'package:flutter/material.dart';

class AppSettings {
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final int expirationWarningDays;
  final double dailyCalorieTarget;
  final double dailyCarbohydratesTarget;
  final double dailyFatsTarget;
  final double dailyProteinTarget;

  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.dark,
    this.expirationWarningDays = 7,
    this.dailyCalorieTarget = 2000.0,
    this.dailyCarbohydratesTarget = 250.0,
    this.dailyFatsTarget = 70.0,
    this.dailyProteinTarget = 50.0,
  });

  // CopyWith method for immutable updates
  AppSettings copyWith({
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    int? expirationWarningDays,
    double? dailyCalorieTarget,
    double? dailyCarbohydratesTarget,
    double? dailyFatsTarget,
    double? dailyProteinTarget,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      expirationWarningDays: expirationWarningDays ?? this.expirationWarningDays,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dailyCarbohydratesTarget: dailyCarbohydratesTarget ?? this.dailyCarbohydratesTarget,
      dailyFatsTarget: dailyFatsTarget ?? this.dailyFatsTarget,
      dailyProteinTarget: dailyProteinTarget ?? this.dailyProteinTarget,
    );
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.notificationsEnabled == notificationsEnabled &&
        other.themeMode == themeMode &&
        other.expirationWarningDays == expirationWarningDays &&
        other.dailyCalorieTarget == dailyCalorieTarget &&
        other.dailyCarbohydratesTarget == dailyCarbohydratesTarget &&
        other.dailyFatsTarget == dailyFatsTarget &&
        other.dailyProteinTarget == dailyProteinTarget;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode {
    return Object.hash(
      notificationsEnabled,
      themeMode,
      expirationWarningDays,
      dailyCalorieTarget,
      dailyCarbohydratesTarget,
      dailyFatsTarget,
      dailyProteinTarget,
    );
  }

  // ToString for debugging
  @override
  String toString() {
    return 'AppSettings('
           'notifications: $notificationsEnabled, '
           'theme: $themeMode, '
           'warningDays: $expirationWarningDays, '
           'calories: $dailyCalorieTarget, '
           'carbs: $dailyCarbohydratesTarget, '
           'fats: $dailyFatsTarget, '
           'protein: $dailyProteinTarget)';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.index,
      'expirationWarningDays': expirationWarningDays,
      'dailyCalorieTarget': dailyCalorieTarget,
      'dailyCarbohydratesTarget': dailyCarbohydratesTarget,
      'dailyFatsTarget': dailyFatsTarget,
      'dailyProteinTarget': dailyProteinTarget,
    };
  }

  // Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? ThemeMode.dark.index],
      expirationWarningDays: json['expirationWarningDays'] as int? ?? 7,
      dailyCalorieTarget: (json['dailyCalorieTarget'] as num?)?.toDouble() ?? 2000.0,
      dailyCarbohydratesTarget: (json['dailyCarbohydratesTarget'] as num?)?.toDouble() ?? 250.0,
      dailyFatsTarget: (json['dailyFatsTarget'] as num?)?.toDouble() ?? 70.0,
      dailyProteinTarget: (json['dailyProteinTarget'] as num?)?.toDouble() ?? 50.0,
    );
  }
}
