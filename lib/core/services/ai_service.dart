import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/user_profile.dart';
import '../services/translation_service.dart';
import '../constants/api_keys.dart';
import 'dart:math';

class AiService {
  static final AiService instance = AiService._init();

  AiService._init();

  late final GenerativeModel _model;
  bool _useAi = true;

  // Diccionario de traducciones comunes (offline)
  final Map<String, String> _commonTranslations = {
    'motivation': 'motivación',
    'productivity': 'productividad',
    'wellness': 'bienestar',
    'mindset': 'mentalidad',
    'goals': 'metas',
    'habits': 'hábitos',
    'focus': 'enfoque',
    'discipline': 'disciplina',
    'consistency': 'constancia',
    'growth': 'crecimiento',
    'success': 'éxito',
    'balance': 'equilibrio',
    'energy': 'energía',
    'confidence': 'confianza',
    'perseverance': 'perseverancia',
    'improve english': 'mejorar inglés',
    'learn english': 'aprender inglés',
    'study': 'estudiar',
    'exercise': 'hacer ejercicio',
    'work out': 'entrenar',
    'read more': 'leer más',
    'wake up early': 'despertar temprano',
    'sleep better': 'dormir mejor',
    'eat healthy': 'comer saludable',
    'save money': 'ahorrar dinero',
    'be more organized': 'ser más organizado',
    'be consistent': 'ser constante',
    'finish projects': 'terminar proyectos',
    'reduce stress': 'reducir estrés',
  };

  void initialize() {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: ApiKeys.gemini,
      );
      print('✅ Servicio de IA inicializado (Gemini 1.5 Flash - Gratis)');
    } catch (e) {
      print('⚠️ Error inicializando IA, usando modo fallback: $e');
      _useAi = false;
    }
  }

  Future<String?> generatePersonalizedQuote(UserProfile profile) async {
    if (_useAi) {
      try {
        print('🤖 Intentando generar con IA...');

        final prompt = _buildPrompt(profile);
        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content).timeout(
              Duration(seconds: 15),
            );

        if (response.text != null && response.text!.isNotEmpty) {
          final quote = _cleanQuote(response.text!);
          print('✅ Frase generada con IA real');
          return quote;
        }
      } catch (e) {
        print('⚠️ IA falló, usando generador local: $e');
        _useAi = false;
      }
    }

    print('🎲 Generando frase personalizada (modo local avanzado)');
    return await _generateAdvancedLocalQuote(profile);
  }

  /// Generador LOCAL — frases reales basadas en el tema del usuario
  Future<String> _generateAdvancedLocalQuote(UserProfile profile) async {
    final random = Random();
    final topic = await _translateChallenge(profile);
    final tone = profile.tonePreference;

    // Banco de frases reales por tono
    final energeticQuotes = [
      'La acción constante sobre $topic convierte la intención en resultado.',
      'No esperes el momento perfecto para avanzar en $topic. El momento eres tú.',
      'Cada día que trabajas en $topic eres una versión más difícil de rendirse.',
      'El que domina $topic no lo hace por motivación. Lo hace por hábito.',
      'Empiezas en $topic con lo que tienes. Terminas con lo que construiste.',
    ];

    final calmQuotes = [
      'El progreso en $topic no se mide en días, sino en la dirección que eliges.',
      'La paciencia con $topic no es esperar. Es avanzar sin prisa y sin pausa.',
      'Cada pequeño paso en $topic deja una huella más profunda que los grandes saltos.',
      'La serenidad en $topic es la fuerza que los impacientes nunca encuentran.',
      'No se trata de dominar $topic rápido. Se trata de no abandonarlo.',
    ];

    final directQuotes = [
      'O actúas hoy en $topic, o mañana seguirás en el mismo lugar.',
      '$topic no se resuelve con intención. Se resuelve con ejecución.',
      'El tiempo que no dedicas a $topic no regresa. El que dedicas, tampoco.',
      'Sin compromiso real con $topic, el resto son solo palabras.',
      'La diferencia en $topic está en lo que haces cuando nadie te obliga.',
    ];

    final balancedQuotes = [
      'El verdadero avance en $topic ocurre cuando dejas de medir el esfuerzo.',
      'Construir en $topic exige constancia, no perfección.',
      'La mejor versión de ti mismo se forja día a día en $topic.',
      'Lo que inviertes en $topic hoy es interés que cobra el futuro.',
      'El camino en $topic no siempre es recto. Lo importante es no detenerse.',
    ];

    final pool = switch (tone) {
      'energetic' => energeticQuotes,
      'calm'      => calmQuotes,
      'direct'    => directQuotes,
      _           => balancedQuotes,
    };

    return pool[random.nextInt(pool.length)];
  }

  /// Traducir reto con sistema híbrido
  Future<String> _translateChallenge(UserProfile profile) async {
    // ⬅️ CORREGIDO: challenges es List<String>
    if (profile.challenges.isEmpty) {
      return 'tus metas';
    }

    // Tomar primer reto de la lista
    final originalChallenge = profile.challenges.first.toLowerCase().trim();

    print('🔤 Reto original: $originalChallenge');

    // PASO 1: Verificar si ya está en español
    if (_isSpanish(originalChallenge)) {
      print('✅ Ya está en español');
      return profile.challenges.first;
    }

    // PASO 2: Buscar en diccionario offline
    if (_commonTranslations.containsKey(originalChallenge)) {
      final translated = _commonTranslations[originalChallenge]!;
      print('📖 Traducido (diccionario): $translated');
      return translated;
    }

    // PASO 3: Traducir con API (si hay internet)
    try {
      final translationService = TranslationService.instance;
      final translated =
          await translationService.translateToSpanish(originalChallenge);

      if (translated != originalChallenge) {
        print('🌐 Traducido (API): $translated');
        return translated;
      }
    } catch (e) {
      print('⚠️ Error traduciendo, usando original: $e');
    }

    // PASO 4: Fallback - usar original si todo falla
    print('⚠️ Usando reto original (no se pudo traducir)');
    return profile.challenges.first;
  }

  /// Detectar si texto está en español
  bool _isSpanish(String text) {
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
      'con',
      'para',
      'mi',
      'tu',
      'su',
      'más',
      'ser',
      'hay',
      'todo',
      'como',
      'pero',
      'muy',
      'hacer',
      'día',
      'año',
      'vida',
    ];

    final words = text.toLowerCase().split(' ');
    int spanishCount = 0;

    for (final word in words) {
      if (spanishWords.contains(word)) {
        spanishCount++;
      }
    }

    // Si más del 30% son palabras en español, consideramos que ya está en español
    return spanishCount > words.length * 0.3;
  }

  Future<String?> generateQuickQuote(String theme) async {
    if (_useAi) {
      try {
        final prompt = '''
Genera UNA frase motivacional corta sobre: $theme
Requisitos:
- Máximo 2 líneas
- Sin comillas
- En español
- Tono inspirador

Solo la frase.
''';

        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content).timeout(
              Duration(seconds: 10),
            );

        if (response.text != null && response.text!.isNotEmpty) {
          return _cleanQuote(response.text!);
        }
      } catch (e) {
        print('⚠️ IA falló en frase rápida: $e');
      }
    }

    final quickTemplates = {
      'motivación':
          'Cada día es una nueva oportunidad para ser tu mejor versión.',
      'productividad':
          'La productividad no es hacer más, es hacer lo importante.',
      'bienestar': 'Cuida tu mente y tu cuerpo. Todo lo demás sigue.',
      'default': 'El éxito es la suma de pequeños esfuerzos diarios.',
    };

    return quickTemplates[theme.toLowerCase()] ?? quickTemplates['default'];
  }

  String _buildPrompt(UserProfile profile) {
    final topics = profile.challenges.isNotEmpty
        ? profile.challenges.join(', ')
        : profile.values.isNotEmpty
            ? profile.values.join(', ')
            : 'superación personal';

    final tone = _getToneDescription(profile.tonePreference);

    return '''
Genera UNA frase motivacional original y poderosa sobre: $topics.
Tono: $tone.

Reglas estrictas:
- Suena como una cita de un filósofo, escritor o pensador reconocido
- NO menciones nombres de personas
- NO uses frases genéricas o clichés conocidos
- Máximo 2 oraciones cortas
- En español
- Sin comillas ni signos innecesarios
- Sin explicaciones, solo la frase

Ejemplos del estilo buscado:
"La disciplina es la puerta que separa el deseo de la realidad."
"No buscas motivación. La construyes acción por acción."
"El progreso silencioso supera siempre al ruido del que nunca empieza."
''';
  }

  String _getToneDescription(String tone) {
    switch (tone) {
      case 'energetic':
        return 'Energético y motivador';
      case 'calm':
        return 'Calmado y reflexivo';
      case 'balanced':
        return 'Balanceado';
      case 'direct':
        return 'Directo y claro';
      default:
        return 'Motivador';
    }
  }

  String _cleanQuote(String text) {
    var cleaned = text.trim();

    if (cleaned.startsWith('"') || cleaned.startsWith('"')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith('"') || cleaned.endsWith('"')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    cleaned = cleaned.replaceAll('**', '');
    cleaned = cleaned.replaceAll('*', '');
    cleaned = cleaned.replaceAll('\n\n\n', '\n\n');

    return cleaned.trim();
  }

  /// Genera un micro-desafío del día basado en el perfil del usuario
  Future<String> generateDailyChallenge(UserProfile profile) async {
    if (_useAi) {
      try {
        final challenge = profile.challenges.isNotEmpty
            ? profile.challenges.first
            : 'mejorar personalmente';
        final prompt = '''
Genera UN micro-desafío concreto y alcanzable para hoy relacionado con: $challenge.
El desafío es para ${profile.name}, con tono ${_getToneDescription(profile.tonePreference)}.
Requisitos:
- Una sola acción concreta (máximo 15 palabras)
- Alcanzable en el día de hoy
- Sin emojis
- Solo el texto del desafío, sin explicaciones

Ejemplo: "Dedica 10 minutos a leer sobre tu tema de interés antes de dormir."
''';
        final response = await _model
            .generateContent([Content.text(prompt)]).timeout(
          const Duration(seconds: 12),
        );
        if (response.text != null && response.text!.isNotEmpty) {
          return _cleanQuote(response.text!);
        }
      } catch (e) {
        print('⚠️ IA falló para desafío, usando local: $e');
      }
    }
    return _localDailyChallenge(profile);
  }

  String _localDailyChallenge(UserProfile profile) {
    final random = Random();
    final challenge = profile.challenges.isNotEmpty
        ? profile.challenges.first
        : 'tus metas';
    final name = profile.name;
    final templates = [
      'Dedica 15 minutos hoy a avanzar en $challenge, $name.',
      '$name, escribe 3 cosas que puedes hacer hoy para mejorar en $challenge.',
      'Haz una sola acción pequeña relacionada con $challenge antes de que termine el día.',
      '$name, comparte tu progreso en $challenge con alguien de confianza hoy.',
      'Identifica el mayor obstáculo en $challenge y escribe cómo superarlo.',
      'Dedica tiempo de calidad, sin distracciones, a $challenge por 20 minutos.',
    ];
    return templates[random.nextInt(templates.length)];
  }

  Future<bool> isAvailable() async {
    if (!_useAi) return false;

    try {
      final content = [Content.text('test')];
      await _model.generateContent(content).timeout(
            Duration(seconds: 5),
          );
      print('✅ Servicio de IA disponible');
      return true;
    } catch (e) {
      print('❌ IA no disponible: $e');
      _useAi = false;
      return false;
    }
  }
}
