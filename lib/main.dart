import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'data/database/database_helper.dart';
import 'data/database/initial_quotes.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicio de notificaciones
  await NotificationService.instance.initialize();

  // 🆕 Configurar canal para widget
  WidgetService.setupMethodChannel();

  // Cargar frases iniciales en la base de datos
  await _loadInitialQuotes();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(MyApp());
}

/// Cargar frases iniciales si es la primera vez
Future<void> _loadInitialQuotes() async {
  final db = DatabaseHelper.instance;
  final quotes = await db.getAllQuotes();

  // Si no hay frases, cargar las iniciales
  if (quotes.isEmpty) {
    print('📝 Cargando frases iniciales...');
    final initialQuotes = InitialQuotes.getQuotes();
    for (final quote in initialQuotes) {
      await db.insertQuote(quote);
    }
    print('✅ ${initialQuotes.length} frases cargadas');
  } else {
    print('ℹ️ Ya hay ${quotes.length} frases en la base de datos');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motivation PRO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SplashScreen(), // ← SIN const
    );
  }
}
