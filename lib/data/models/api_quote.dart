class ApiQuote {
  final String text;
  final String author;
  final List<String> tags;

  ApiQuote({
    required this.text,
    required this.author,
    this.tags = const [],
  });

  factory ApiQuote.fromQuotable(Map<String, dynamic> json) {
    return ApiQuote(
      text: json['content'] as String,
      author: json['author'] as String,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [],
    );
  }

  factory ApiQuote.fromZenQuotes(Map<String, dynamic> json) {
    return ApiQuote(
      text: json['q'] as String,
      author: json['a'] as String,
      tags: [],
    );
  }

  String get category {
    // Mapear tags a nuestras categorías
    if (tags.isEmpty) return 'Motivación';

    final tag = tags.first.toLowerCase();

    if (tag.contains('motivat') || tag.contains('inspir')) {
      return 'Motivación';
    } else if (tag.contains('life') || tag.contains('wisdom')) {
      return 'Mentalidad';
    } else if (tag.contains('success') || tag.contains('business')) {
      return 'Metas';
    } else if (tag.contains('friend') || tag.contains('love')) {
      return 'Relaciones';
    } else if (tag.contains('happiness') || tag.contains('health')) {
      return 'Bienestar';
    } else if (tag.contains('time') || tag.contains('work')) {
      return 'Productividad';
    }

    return 'Motivación';
  }
}
