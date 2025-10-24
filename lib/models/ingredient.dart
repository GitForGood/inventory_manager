class Ingredient {
  final int? id;
  final String name;

  const Ingredient({
    this.id,
    required this.name,
  });

  // CopyWith method for immutable updates
  Ingredient copyWith({
    int? id,
    String? name,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  // Equality operator for comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient && other.id == id;
  }

  // HashCode for collections and comparisons
  @override
  int get hashCode => id.hashCode;

  // ToString for debugging
  @override
  String toString() {
    return 'Ingredient(id: $id, name: $name)';
  }

  // Convert to JSON/Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Create from Map (database row)
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}
