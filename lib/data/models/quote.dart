/// Modelo de una frase motivacional
class Quote {
  final int? id;
  final String text;
  final String? author;
  final String category;
  final String source; // 'local' o 'api'
  final String language; // 'es' o 'en'
  final int length;
  final DateTime createdAt;
  final DateTime? lastShown;
  final int viewCount;
  final bool isFavorite;

  Quote({
    this.id,
    required this.text,
    this.author,
    required this.category,
    this.source = 'local',
    this.language = 'es',
    int? length,
    DateTime? createdAt,
    this.lastShown,
    this.viewCount = 0,
    this.isFavorite = false,
  })  : length = length ?? text.length,
        createdAt = createdAt ?? DateTime.now();

  /// Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
      'source': source,
      'language': language,
      'length': length,
      'created_at': createdAt.toIso8601String(),
      'last_shown': lastShown?.toIso8601String(),
      'view_count': viewCount,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Crear desde Map de SQLite
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as int?,
      text: map['text'] as String,
      author: map['author'] as String?,
      category: map['category'] as String,
      source: map['source'] as String? ?? 'local',
      language: map['language'] as String? ?? 'es',
      length: map['length'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastShown: map['last_shown'] != null
          ? DateTime.parse(map['last_shown'] as String)
          : null,
      viewCount: map['view_count'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int?) == 1,
    );
  }

  /// Copiar con cambios
  Quote copyWith({
    int? id,
    String? text,
    String? author,
    String? category,
    String? source,
    String? language,
    int? length,
    DateTime? createdAt,
    DateTime? lastShown,
    int? viewCount,
    bool? isFavorite,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      category: category ?? this.category,
      source: source ?? this.source,
      language: language ?? this.language,
      length: length ?? this.length,
      createdAt: createdAt ?? this.createdAt,
      lastShown: lastShown ?? this.lastShown,
      viewCount: viewCount ?? this.viewCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Detectar idioma de la frase
  String get detectedLanguage {
    // Si ya tiene idioma asignado, usarlo
    if (language != null && language!.isNotEmpty) {
      return language!;
    }

    // Palabras comunes en español
    final spanishWords = [
      'el',
      'la',
      'los',
      'las',
      'de',
      'que',
      'es',
      'en',
      'y',
      'a',
      'por',
      'un',
      'para',
      'con',
      'no',
      'una',
      'su',
      'al',
      'lo',
      'como',
      'más',
      'pero',
      'sus',
      'le',
      'ya',
      'o',
      'este',
      'si',
      'porque',
      'esta',
      'entre',
      'cuando',
      'muy',
      'sin',
      'sobre',
      'también',
      'me',
      'hasta',
      'hay',
      'donde',
      'quien',
      'desde',
      'todo',
      'nos',
      'durante',
      'todos',
      'uno',
      'les',
      'ni',
      'contra',
      'otros',
      'ese',
      'eso',
      'ante',
      'ellos',
      'e',
      'esto',
      'mí',
      'antes',
      'algunos',
      'qué',
      'unos',
      'yo',
      'del',
      'tiempo',
      'vida',
      'día',
      'año',
      'mucho',
      'poco',
      'mismo',
      'otro',
    ];

    // Convertir texto a minúsculas y separar por palabras
    final words = text.toLowerCase().split(' ');

    // Contar palabras en español
    int spanishCount = 0;
    for (final word in words) {
      if (spanishWords.contains(word)) {
        spanishCount++;
      }
    }

    // Si más del 20% son palabras en español, es español
    if (spanishCount > words.length * 0.2) {
      return 'es';
    }

    // Si no, es inglés (las de API vienen en inglés)
    return 'en';
  }

  @override
  String toString() {
    return 'Quote(id: $id, text: $text, author: $author, category: $category)';
  }
}
