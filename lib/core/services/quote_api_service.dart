import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/api_quote.dart';
import '../../data/models/quote.dart';
import 'dart:io'; // ⬅️ AGREGAR LÍNEA

class QuoteApiService {
  static final QuoteApiService instance = QuoteApiService._init();

  QuoteApiService._init() {
    // SOLO DESARROLLO - Ignorar SSL
    HttpOverrides.global = _DevelopmentHttpOverrides();
  }

  // Quotable API
  static const _quotableBaseUrl = 'https://api.quotable.io';

  // ZenQuotes API
  static const _zenQuotesBaseUrl = 'https://zenquotes.io/api';
  // SOLO DESARROLLO - Ignorar SSL

  /// Obtener frase aleatoria de Quotable
  Future<ApiQuote?> _getFromQuotable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_quotableBaseUrl/random?maxLength=200'),
          )
          .timeout(Duration(seconds: 5));

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
          .timeout(Duration(seconds: 5));

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

  /// Obtener frase de APIs con rotación inteligente
  Future<ApiQuote?> getRandomQuote() async {
    // Lista de APIs en orden de prioridad (más frases = más prioridad)
    final apis = [
      () => _getFromZenQuotes(), // Prioridad 1: 50,000+ frases ⭐
      () => _getFromQuotable(), // Prioridad 2: 2,000+ frases
      () => _getFromTypefit(), // Prioridad 3: 1,600 frases
    ];

    // Rotar APIs basado en el segundo actual para variedad
    final now = DateTime.now();
    final rotation = now.second % apis.length;

    // Intentar cada API en orden rotado
    for (int i = 0; i < apis.length; i++) {
      final index = (rotation + i) % apis.length;

      try {
        final quote = await apis[index]().timeout(
          Duration(seconds: 5),
        );

        if (quote != null) {
          final apiName = index == 0
              ? 'ZenQuotes (50K+)'
              : index == 1
                  ? 'Quotable (2K)'
                  : 'Type.fit (1.6K)';
          print('✅ Quote from $apiName API');
          return quote;
        }
      } catch (e) {
        final apiName = index == 0
            ? 'ZenQuotes'
            : index == 1
                ? 'Quotable'
                : 'Type.fit';
        print('⚠️ $apiName API falló: $e');
        continue;
      }
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
          .timeout(Duration(seconds: 5));

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
        await Future.delayed(Duration(milliseconds: 500));
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
          .timeout(Duration(seconds: 5));

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
          .timeout(Duration(seconds: 5));

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
          .timeout(Duration(seconds: 5));

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

// SOLO DESARROLLO - Remover antes de producción
class _DevelopmentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('⚠️ SSL bypass para desarrollo: $host');
        return true;
      };
  }
}
