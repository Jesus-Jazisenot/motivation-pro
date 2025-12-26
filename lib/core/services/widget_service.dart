import 'package:flutter/services.dart';
import '../../data/database/database_helper.dart';

class WidgetService {
  static const platform = MethodChannel('com.example.motivation_pro/widget');

  /// Obtener frase para el widget
  static Future<Map<String, String>> getQuoteForWidget() async {
    final db = DatabaseHelper.instance;
    final quote = await db.getRandomQuote();

    if (quote == null) {
      return {
        'text': 'Abre la app para ver frases motivacionales',
        'author': 'Motivation PRO',
        'category': 'Motivación',
      };
    }

    return {
      'text': quote.text,
      'author': quote.author ?? 'Anónimo',
      'category': quote.category,
    };
  }

  /// Configurar el canal de comunicación con Android
  static void setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'getQuote') {
        return await getQuoteForWidget();
      }
      return null;
    });
  }

  /// Actualizar widget desde Flutter
  static Future<void> updateWidget() async {
    try {
      await platform.invokeMethod('updateWidget');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}
