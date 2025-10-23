class QuotaItem {
  final String id;
  final String foodItemName; // Name of the food item from inventory
  final int targetCount; // Target number of items to consume
  final int consumedCount; // Number of items consumed so far
  final DateTime? lastConsumed;

  const QuotaItem({
    required this.id,
    required this.foodItemName,
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

  // CopyWith method for immutable updates
  QuotaItem copyWith({
    String? id,
    String? foodItemName,
    int? targetCount,
    int? consumedCount,
    DateTime? lastConsumed,
  }) {
    return QuotaItem(
      id: id ?? this.id,
      foodItemName: foodItemName ?? this.foodItemName,
      targetCount: targetCount ?? this.targetCount,
      consumedCount: consumedCount ?? this.consumedCount,
      lastConsumed: lastConsumed ?? this.lastConsumed,
    );
  }

  // Increment consumption by count
  QuotaItem consume(int count) {
    return copyWith(
      consumedCount: consumedCount + count,
      lastConsumed: DateTime.now(),
    );
  }

  // Reset consumption for new period
  QuotaItem reset() {
    return copyWith(
      consumedCount: 0,
      lastConsumed: null,
    );
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuotaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuotaItem(id: $id, name: $foodItemName, consumed: $consumedCount/$targetCount items)';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodItemName': foodItemName,
      'targetCount': targetCount,
      'consumedCount': consumedCount,
      'lastConsumed': lastConsumed?.toIso8601String(),
    };
  }

  // Create from JSON
  factory QuotaItem.fromJson(Map<String, dynamic> json) {
    return QuotaItem(
      id: json['id'] as String,
      foodItemName: json['foodItemName'] as String,
      targetCount: json['targetCount'] as int,
      consumedCount: json['consumedCount'] as int? ?? 0,
      lastConsumed: json['lastConsumed'] != null
          ? DateTime.parse(json['lastConsumed'] as String)
          : null,
    );
  }
}
