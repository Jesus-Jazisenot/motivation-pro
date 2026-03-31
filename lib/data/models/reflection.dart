class Reflection {
  final int? id;
  final int? quoteId;
  final String quoteText;
  final String text;
  final DateTime createdAt;

  Reflection({
    this.id,
    this.quoteId,
    required this.quoteText,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'quote_id': quoteId,
      'quote_text': quoteText,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Reflection.fromMap(Map<String, dynamic> map) {
    return Reflection(
      id: map['id'] as int?,
      quoteId: map['quote_id'] as int?,
      quoteText: map['quote_text'] as String,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Reflection copyWith({
    int? id,
    int? quoteId,
    String? quoteText,
    String? text,
    DateTime? createdAt,
  }) {
    return Reflection(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      quoteText: quoteText ?? this.quoteText,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
