class Unit {
  final int? id;
  final String name;

  const Unit({
    this.id,
    required this.name,
  });

  // CopyWith method for immutable updates
  Unit copyWith({
    int? id,
    String? name,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Unit && other.id == id;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode => id.hashCode;

  // ToString for debugging
  @override
  String toString() {
    return 'Unit(id: $id, name: $name)';
  }

  // Convert to JSON/Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Create from Map (database row)
  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}
