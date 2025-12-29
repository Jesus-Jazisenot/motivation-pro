import 'package:google_generative_ai/google_generative_ai.dart';
import '../../data/models/user_profile.dart';
import '../services/translation_service.dart';
import 'dart:math';

class AiService {
  static final AiService instance = AiService._init();

  AiService._init();

  static const String _apiKey = 'AIzaSyDAj8XYhPsaSLi3VB_esyxhjQkJn9aeTAs';

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
        model: 'gemini-pro',
        apiKey: _apiKey,
      );
      print('✅ Servicio de IA inicializado (Gemini Pro)');
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

  /// Generador LOCAL MEJORADO con traducción automática
  Future<String> _generateAdvancedLocalQuote(UserProfile profile) async {
    final random = Random();
    final name = profile.name;

    // ⬅️ TRADUCIR RETO ANTES DE USAR
    final challenge = await _translateChallenge(profile);

    final structure = random.nextInt(5);

    switch (structure) {
      case 0:
        return _buildFromComponents(
          _getOpening(name, random),
          _getMotivation(challenge, random),
          _getAction(random),
        );

      case 1:
        return _buildDirect(name, challenge, random);

      case 2:
        return _buildReflective(name, challenge, random);

      case 3:
        return _buildEnergetic(name, challenge, profile.tonePreference, random);

      default:
        return _buildToneBased(name, challenge, profile.tonePreference, random);
    }
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

  // === COMPONENTES MODULARES (sin cambios) ===

  List<String> _getOpenings(String name) => [
        '$name,',
        'Hoy es tu día, $name.',
        'Escucha esto, $name:',
        '$name, recuerda que',
        'No lo olvides, $name:',
        'Piensa en esto, $name:',
        '$name, ten presente que',
        'Cada día, $name,',
        'Aquí va algo importante, $name:',
        '$name, la verdad es que',
      ];

  String _getOpening(String name, Random random) {
    final openings = _getOpenings(name);
    return openings[random.nextInt(openings.length)];
  }

  List<String> _getMotivations(String challenge) => [
        'cada esfuerzo en $challenge cuenta más de lo que crees',
        'el progreso en $challenge se construye día a día',
        'tu dedicación a $challenge está transformándote',
        'cada paso hacia $challenge te define',
        'la persistencia en $challenge es tu superpoder',
        'avanzar en $challenge es avanzar en la vida',
        'tu compromiso con $challenge habla de quién eres',
        'dominar $challenge es dominar tu futuro',
        'invertir en $challenge es invertir en ti',
        'cada momento dedicado a $challenge multiplica tus resultados',
      ];

  String _getMotivation(String challenge, Random random) {
    final motivations = _getMotivations(challenge);
    return motivations[random.nextInt(motivations.length)];
  }

  List<String> _getActions() => [
        'Sigue adelante.',
        'No te detengas.',
        'Continúa así.',
        'Mantén el rumbo.',
        'Persevera.',
        'Dale con todo.',
        'Confía en el proceso.',
        'Cada día cuenta.',
        'Tú puedes.',
        'Hazlo realidad.',
      ];

  String _getAction(Random random) {
    final actions = _getActions();
    return actions[random.nextInt(actions.length)];
  }

  String _buildFromComponents(
      String opening, String motivation, String action) {
    return '$opening $motivation. $action';
  }

  String _buildDirect(String name, String challenge, Random random) {
    final templates = [
      '$name, $challenge no es solo una meta, es tu camino hacia quien quieres ser.',
      'Lo directo, $name: $challenge requiere tu mejor versión hoy.',
      '$name, cada acción hacia $challenge es una inversión en tu futuro.',
      'Simple y claro, $name: $challenge se conquista con constancia diaria.',
      '$name, no subestimes tu poder para dominar $challenge.',
      '$challenge es tu desafío, $name, pero también tu oportunidad de brillar.',
      '$name, el tiempo que dedicas a $challenge nunca se pierde.',
      'Enfócate, $name: $challenge es donde tu esfuerzo se convierte en resultados.',
    ];
    return templates[random.nextInt(templates.length)];
  }

  String _buildReflective(String name, String challenge, Random random) {
    final templates = [
      'Reflexiona un momento, $name: $challenge te está moldeando cada día.',
      '$name, cada pequeño avance en $challenge es un logro que celebrar.',
      'Tómate un segundo, $name. El progreso en $challenge es más visible de lo que crees.',
      '$name, respira y reconoce: ya has avanzado mucho en $challenge.',
      'Mira atrás, $name. Tu dedicación a $challenge te ha traído hasta aquí.',
      '$name, cada obstáculo en $challenge es una lección disfrazada.',
      'Piénsalo, $name: $challenge no solo te desafía, te transforma.',
      '$name, el esfuerzo que pones en $challenge construye más que resultados.',
    ];
    return templates[random.nextInt(templates.length)];
  }

  String _buildEnergetic(
      String name, String challenge, String tone, Random random) {
    if (tone == 'energetic') {
      final templates = [
        '¡Dale, $name! Hoy es el día perfecto para avanzar en $challenge. ¡Vamos!',
        '¡Arriba, $name! $challenge es tu momento de demostrar de qué estás hecho.',
        '¡Vamos, $name! La energía que pones en $challenge transformará tu realidad.',
        '¡Hoy es el día, $name! $challenge te espera y tú estás más que listo.',
        '¡A por ello, $name! Cada acción hacia $challenge te acerca a tu meta.',
        '¡Con todo, $name! $challenge es tu oportunidad de brillar hoy.',
      ];
      return templates[random.nextInt(templates.length)];
    }

    final templates = [
      '$name, hoy da un paso más en $challenge. Pequeños pasos, grandes resultados.',
      '$name, mantén el enfoque en $challenge. Tu consistencia marca la diferencia.',
      'Avanza con confianza, $name. $challenge está a tu alcance.',
      '$name, cada día dedicado a $challenge te fortalece.',
    ];
    return templates[random.nextInt(templates.length)];
  }

  String _buildToneBased(
      String name, String challenge, String tone, Random random) {
    switch (tone) {
      case 'calm':
        final templates = [
          '$name, respira. El progreso en $challenge viene con paciencia.',
          'Tómate tu tiempo, $name. $challenge se logra con serenidad.',
          '$name, cada paso tranquilo hacia $challenge es un paso firme.',
          'Calma, $name. Tu ritmo en $challenge es el correcto para ti.',
          '$name, la constancia serena en $challenge supera la prisa.',
        ];
        return templates[random.nextInt(templates.length)];

      case 'direct':
        final templates = [
          '$name: actúa hoy en $challenge. Sin excusas.',
          '$challenge no se resuelve solo, $name. Tú tienes el control.',
          'Sin vueltas, $name: $challenge requiere tu acción ahora.',
          '$name, lo que hagas hoy en $challenge definirá mañana.',
          'Directo al grano, $name: $challenge espera tu movimiento.',
        ];
        return templates[random.nextInt(templates.length)];

      case 'balanced':
        final templates = [
          '$name, encuentra el equilibrio. $challenge es importante, pero también tu bienestar.',
          '$name, avanza en $challenge sin perder de vista lo que realmente importa.',
          'Balance, $name. $challenge es parte del camino, no todo el camino.',
          '$name, dedica tiempo a $challenge, pero también a ti.',
          'Equilibrio, $name: $challenge y tu paz mental van de la mano.',
        ];
        return templates[random.nextInt(templates.length)];

      default:
        final templates = [
          '$name, cada esfuerzo en $challenge te acerca a tu mejor versión.',
          '$name, tu dedicación a $challenge está dando frutos.',
          'Mantén el curso, $name. $challenge es tu camino al crecimiento.',
          '$name, confía en tu proceso con $challenge.',
        ];
        return templates[random.nextInt(templates.length)];
    }
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
    final challenges = profile.challenges.isNotEmpty
        ? profile.challenges
        : 'superar obstáculos';

    final tone = _getToneDescription(profile.tonePreference);

    return '''
Genera UNA frase motivacional para ${profile.name}.

Contexto:
- Retos: $challenges
- Tono: $tone

Instrucciones:
1. Incluir el nombre "${profile.name}"
2. Mencionar: $challenges
3. Máximo 3 líneas
4. Sin comillas
5. En español

Solo la frase.
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
