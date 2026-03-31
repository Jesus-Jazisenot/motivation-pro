class Affirmation {
  final int? id;
  final String text;
  final bool active;
  final DateTime createdAt;

  const Affirmation({
    this.id,
    required this.text,
    this.active = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'active': active ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Affirmation.fromMap(Map<String, dynamic> map) => Affirmation(
        id: map['id'] as int?,
        text: map['text'] as String,
        active: (map['active'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Affirmation copyWith({
    int? id,
    String? text,
    bool? active,
    DateTime? createdAt,
  }) =>
      Affirmation(
        id: id ?? this.id,
        text: text ?? this.text,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
}
