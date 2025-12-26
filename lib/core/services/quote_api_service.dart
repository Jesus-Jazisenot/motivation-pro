import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/api_quote.dart';
import '../../data/models/quote.dart';

class QuoteApiService {
  static final QuoteApiService instance = QuoteApiService._init();

  QuoteApiService._init();

  // Quotable API
  static const _quotableBaseUrl = 'https://api.quotable.io';

  // ZenQuotes API
  static const _zenQuotesBaseUrl = 'https://zenquotes.io/api';

  /// Obtener frase aleatoria de Quotable
  Future<ApiQuote?> _getFromQuotable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_quotableBaseUrl/random?maxLength=200'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiQuote.fromQuotable(json);
      }
    } catch (e) {
      print('Quotable API error: $e');
    }
    return null;
  }

  /// Obtener frase aleatoria de ZenQuotes
  Future<ApiQuote?> _getFromZenQuotes() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_zenQuotesBaseUrl/random'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        if (json.isNotEmpty) {
          return ApiQuote.fromZenQuotes(json[0] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('ZenQuotes API error: $e');
    }
    return null;
  }

  /// Obtener frase de APIs (con fallback)
  /// Obtener frase de APIs (con fallback mejorado)
  Future<ApiQuote?> getRandomQuote() async {
    // Intenta Type.fit primero (sin problemas SSL)
    var quote = await _getFromTypefit();
    if (quote != null) {
      print('✅ Quote from Type.fit API');
      return quote;
    }

    // Intenta ZenQuotes
    quote = await _getFromZenQuotes();
    if (quote != null) {
      print('✅ Quote from ZenQuotes API');
      return quote;
    }

    // Intenta Quotable (puede fallar en emulador)
    quote = await _getFromQuotable();
    if (quote != null) {
      print('✅ Quote from Quotable API');
      return quote;
    }

    print('❌ All APIs failed');
    return null;
  }

  /// Obtener frase de API tipo.fit (sin problemas SSL)
  Future<ApiQuote?> _getFromTypefit() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://type.fit/api/quotes'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        if (json.isNotEmpty) {
          // Obtener una frase aleatoria
          final randomIndex =
              DateTime.now().millisecondsSinceEpoch % json.length;
          final quote = json[randomIndex] as Map<String, dynamic>;

          return ApiQuote(
            text: quote['text'] as String,
            author: (quote['author'] as String?)?.split(',').first ?? 'Anónimo',
            tags: [],
          );
        }
      }
    } catch (e) {
      print('Typefit API error: $e');
    }
    return null;
  }

  /// Convertir ApiQuote a Quote (modelo local)
  Quote apiQuoteToQuote(ApiQuote apiQuote) {
    return Quote(
      text: apiQuote.text,
      author: apiQuote.author,
      category: apiQuote.category,
      lastShown: DateTime.now(),
      viewCount: 1,
    );
  }

  /// Obtener múltiples frases para cache
  Future<List<ApiQuote>> getMultipleQuotes(int count) async {
    final quotes = <ApiQuote>[];

    for (var i = 0; i < count; i++) {
      final quote = await getRandomQuote();
      if (quote != null) {
        quotes.add(quote);
        // Pequeña pausa para no saturar la API
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return quotes;
  }

  /// Buscar frases por categoría/tag (Quotable)
  Future<List<ApiQuote>> searchByTag(String tag) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_quotableBaseUrl/quotes?tags=$tag&limit=10'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final results = json['results'] as List<dynamic>;

        return results
            .map((item) => ApiQuote.fromQuotable(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Search API error: $e');
    }
    return [];
  }

  /// Verificar conectividad
  /// Verificar conectividad (mejorado)
  Future<bool> isApiAvailable() async {
    try {
      // Probar con Type.fit primero (más confiable)
      final response = await http
          .get(Uri.parse('https://type.fit/api/quotes'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ API connection verified');
        return true;
      }
    } catch (e) {
      print('API check error: $e');
    }

    // Fallback: intentar con ZenQuotes
    try {
      final response = await http
          .get(Uri.parse('$_zenQuotesBaseUrl/random'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('✅ API connection verified (ZenQuotes)');
        return true;
      }
    } catch (e) {
      print('ZenQuotes check error: $e');
    }

    return false;
  }
}
