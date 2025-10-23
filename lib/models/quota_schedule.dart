import 'package:inventory_manager/models/quota_item.dart';

enum SchedulePeriod {
  weekly,
  monthly,
  quarterly,
}

class QuotaSchedule {
  final String id;
  final String name;
  final SchedulePeriod period;
  final DateTime startDate;
  final List<QuotaItem> items;
  final DateTime? lastReset;
  final bool isActive;

  const QuotaSchedule({
    required this.id,
    required this.name,
    required this.period,
    required this.startDate,
    required this.items,
    this.lastReset,
    this.isActive = true,
  });

  // Get days in current period
  int get daysInPeriod {
    switch (period) {
      case SchedulePeriod.weekly:
        return 7;
      case SchedulePeriod.monthly:
        return 30;
      case SchedulePeriod.quarterly:
        return 90;
    }
  }

  // Calculate when the period should reset
  DateTime get nextResetDate {
    final baseDate = lastReset ?? startDate;
    switch (period) {
      case SchedulePeriod.weekly:
        return baseDate.add(const Duration(days: 7));
      case SchedulePeriod.monthly:
        return DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
      case SchedulePeriod.quarterly:
        return DateTime(baseDate.year, baseDate.month + 3, baseDate.day);
    }
  }

  // Check if schedule needs reset
  bool get needsReset {
    return DateTime.now().isAfter(nextResetDate);
  }

  // Get progress percentage for the schedule
  double get overallProgress {
    if (items.isEmpty) return 0.0;
    final totalProgress = items.fold<double>(
      0.0,
      (sum, item) => sum + item.progressPercentage,
    );
    return totalProgress / items.length;
  }

  // Get number of completed items
  int get completedItemsCount {
    return items.where((item) => item.isCompleted).length;
  }

  // CopyWith method for immutable updates
  QuotaSchedule copyWith({
    String? id,
    String? name,
    SchedulePeriod? period,
    DateTime? startDate,
    List<QuotaItem>? items,
    DateTime? lastReset,
    bool? isActive,
  }) {
    return QuotaSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      items: items ?? this.items,
      lastReset: lastReset ?? this.lastReset,
      isActive: isActive ?? this.isActive,
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuotaSchedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuotaSchedule(id: $id, name: $name, period: $period, items: ${items.length})';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'period': period.index,
      'startDate': startDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'lastReset': lastReset?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Create from JSON
  factory QuotaSchedule.fromJson(Map<String, dynamic> json) {
    return QuotaSchedule(
      id: json['id'] as String,
      name: json['name'] as String,
      period: SchedulePeriod.values[json['period'] as int],
      startDate: DateTime.parse(json['startDate'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => QuotaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastReset: json['lastReset'] != null
          ? DateTime.parse(json['lastReset'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
