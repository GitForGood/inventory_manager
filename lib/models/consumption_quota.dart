class ConsumptionQuota {
  final String id;
  final String batchId; // Links to specific batch
  final String foodItemId; // For grouping by food item
  final String foodItemName; // Display name
  final DateTime targetDate; // When to consume by
  final int targetCount; // Items to consume on this date
  final int consumedCount; // Items consumed so far
  final DateTime? lastConsumed;

  const ConsumptionQuota({
    required this.id,
    required this.batchId,
    required this.foodItemId,
    required this.foodItemName,
    required this.targetDate,
    required this.targetCount,
    this.consumedCount = 0,
    this.lastConsumed,
  });

  // Check if quota is completed
  bool get isCompleted => consumedCount >= targetCount;

  // Get progress percentage
  double get progressPercentage {
    if (targetCount == 0) return 0.0;
    return (consumedCount / targetCount * 100).clamp(0.0, 100.0);
  }

  // Get remaining count
  int get remainingCount {
    return (targetCount - consumedCount).clamp(0, targetCount);
  }

  // Check if quota is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  // Check if quota is due soon (within 2 days)
  bool get isDueSoon {
    final now = DateTime.now();
    final daysUntilDue = targetDate.difference(now).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 2 && !isCompleted;
  }

  // Check if quota should be hidden from main view (completed)
  bool get shouldHideFromView {
    return isCompleted;
  }

  // CopyWith method for immutable updates
  ConsumptionQuota copyWith({
    String? id,
    String? batchId,
    String? foodItemId,
    String? foodItemName,
    DateTime? targetDate,
    int? targetCount,
    int? consumedCount,
    DateTime? lastConsumed,
  }) {
    return ConsumptionQuota(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      foodItemId: foodItemId ?? this.foodItemId,
      foodItemName: foodItemName ?? this.foodItemName,
      targetDate: targetDate ?? this.targetDate,
      targetCount: targetCount ?? this.targetCount,
      consumedCount: consumedCount ?? this.consumedCount,
      lastConsumed: lastConsumed ?? this.lastConsumed,
    );
  }

  // Increment consumption by count
  ConsumptionQuota consume(int count) {
    return copyWith(
      consumedCount: consumedCount + count,
      lastConsumed: DateTime.now(),
    );
  }

  // Reset consumption
  ConsumptionQuota reset() {
    return copyWith(
      consumedCount: 0,
      lastConsumed: null,
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsumptionQuota && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConsumptionQuota(id: $id, name: $foodItemName, consumed: $consumedCount/$targetCount, '
        'targetDate: ${targetDate.toIso8601String()})';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'foodItemId': foodItemId,
      'foodItemName': foodItemName,
      'targetDate': targetDate.toIso8601String(),
      'targetCount': targetCount,
      'consumedCount': consumedCount,
      'lastConsumed': lastConsumed?.toIso8601String(),
    };
  }

  // Create from JSON
  factory ConsumptionQuota.fromJson(Map<String, dynamic> json) {
    return ConsumptionQuota(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      foodItemId: json['foodItemId'] as String,
      foodItemName: json['foodItemName'] as String,
      targetDate: DateTime.parse(json['targetDate'] as String),
      targetCount: json['targetCount'] as int,
      consumedCount: json['consumedCount'] as int? ?? 0,
      lastConsumed: json['lastConsumed'] != null
          ? DateTime.parse(json['lastConsumed'] as String)
          : null,
    );
  }
}
