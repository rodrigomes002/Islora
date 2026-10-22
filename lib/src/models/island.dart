class Island {
  const Island({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;
  final String name;
  final String description;

  factory Island.fromMap(Map<String, Object?> map) {
    return Island(
      id: map['id']! as int,
      name: map['name']! as String,
      description: map['description']! as String,
    );
  }

  Map<String, Object?> toMap() {
    return {'name': name, 'description': description};
  }
}
