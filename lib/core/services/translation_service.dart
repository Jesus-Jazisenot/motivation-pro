import 'package:translator/translator.dart';

class TranslationService {
  static final TranslationService instance = TranslationService._init();

  TranslationService._init();

  final GoogleTranslator _translator = GoogleTranslator();

  /// Traducir texto de inglés a español
  Future<String> translateToSpanish(String text) async {
    try {
      print('🔄 Traduciendo: ${text.substring(0, 30)}...');

      final translation = await _translator
          .translate(text, from: 'en', to: 'es')
          .timeout(Duration(seconds: 5));

      print('✅ Traducido: ${translation.text.substring(0, 30)}...');
      return translation.text;
    } catch (e) {
      print('❌ Error en traducción: $e');
      // Si falla, retornar texto original
      return text;
    }
  }

  /// Traducir texto de español a inglés
  Future<String> translateToEnglish(String text) async {
    try {
      print('🔄 Traduciendo a inglés: ${text.substring(0, 30)}...');

      final translation = await _translator
          .translate(text, from: 'es', to: 'en')
          .timeout(Duration(seconds: 5));

      print('✅ Traducido: ${translation.text.substring(0, 30)}...');
      return translation.text;
    } catch (e) {
      print('❌ Error en traducción: $e');
      return text;
    }
  }

  /// Detectar si un texto está en español
  bool isSpanish(String text) {
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
    ];

    final words = text.toLowerCase().split(' ');
    int spanishCount = 0;

    for (final word in words) {
      if (spanishWords.contains(word)) {
        spanishCount++;
      }
    }

    return spanishCount > words.length * 0.2;
  }
}
