import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/ai_service.dart';
import 'core/services/widget_service.dart';
import 'data/database/database_helper.dart';
import 'data/models/quote.dart';
import 'core/theme/theme_service.dart'; // ⬅️ NUEVO IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicio de notificaciones
  await NotificationService.instance.initialize();

  // Configurar canal para widget
  WidgetService.setupMethodChannel();

  // Cargar frases iniciales en la base de datos
  await _loadInitialQuotes();

  // Configurar orientación
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar servicio de IA
  AiService.instance.initialize();

  // ⬅️ NUEVO: Inicializar servicio de temas
  await ThemeService.instance.initialize();

  // Configurar estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

// ⬅️ CAMBIAR A StatefulWidget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // ⬅️ Escuchar cambios de tema
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;

    return MaterialApp(
      title: 'Motivation PRO',
      theme: themeService.currentTheme.toThemeData(), // ⬅️ TEMA DINÁMICO
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Cargar frases iniciales en la base de datos
Future<void> _loadInitialQuotes() async {
  final db = DatabaseHelper.instance;

  // Verificar si ya hay frases
  final existingQuotes = await db.getAllQuotes();
  if (existingQuotes.isNotEmpty) {
    print('✅ Base de datos ya tiene ${existingQuotes.length} frases');
    return;
  }

  print('📚 Cargando frases iniciales...');

  // Frases iniciales en español
  final initialQuotes = [
    Quote(
      text: 'El éxito es la suma de pequeños esfuerzos repetidos día tras día.',
      author: 'Robert Collier',
      category: 'Motivación',
      source: 'local',
      language: 'es',
    ),
    Quote(
      text: 'No cuentes los días, haz que los días cuenten.',
      author: 'Muhammad Ali',
      category: 'Productividad',
      source: 'local',
      language: 'es',
    ),
    Quote(
      text: 'La disciplina es el puente entre metas y logros.',
      author: 'Jim Rohn',
      category: 'Disciplina',
      source: 'local',
      language: 'es',
    ),
    Quote(
      text: 'El único modo de hacer un gran trabajo es amar lo que haces.',
      author: 'Steve Jobs',
      category: 'Pasión',
      source: 'local',
      language: 'es',
    ),
    Quote(
      text:
          'Tu tiempo es limitado, no lo desperdicies viviendo la vida de otro.',
      author: 'Steve Jobs',
      category: 'Autenticidad',
      source: 'local',
      language: 'es',
    ),
  ];

  // Insertar frases
  for (final quote in initialQuotes) {
    try {
      await db.insertQuote(quote);
    } catch (e) {
      print('Error insertando frase: $e');
    }
  }

  print('✅ ${initialQuotes.length} frases iniciales cargadas');
}
