import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../data/database/database_helper.dart';
import '../../data/models/quote.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar notificaciones locales
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  /// Inicializar servicio de notificaciones
  Future<void> initialize() async {
    print('🔔 Inicializando NotificationService...');

    // Inicializar zonas horarias
    tz.initializeTimeZones();

    // Configuración Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración general
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Inicializar plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones
    await _createNotificationChannel();

    // Solicitar permisos (Android 13+)
    await _requestPermissions();

    print('✅ NotificationService inicializado');
  }

  /// Crear canal de notificaciones Android
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'daily_quotes_channel',
      'Frases Diarias',
      description: 'Notificaciones con frases motivacionales',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✅ Canal de notificaciones creado');
  }

  /// Solicitar permisos de notificación
  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      print('✅ Permisos de notificación solicitados');
    }
  }

  /// Manejar tap en notificación
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notificación tocada: ${response.payload}');
  }

  /// Mostrar notificación inmediata de prueba
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_quotes_channel',
      'Frases Diarias',
      channelDescription: 'Notificaciones con frases motivacionales',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      '🎯 Prueba de Notificación',
      'Si ves esto, las notificaciones funcionan correctamente',
      details,
    );

    print('✅ Notificación de prueba enviada');
  }

  /// Mostrar notificación con frase aleatoria
  Future<void> showQuoteNotification() async {
    try {
      final db = DatabaseHelper.instance;
      final Quote? quote = await db.getRandomQuote();

      if (quote == null) {
        print('⚠️ No hay frases disponibles para notificación');
        return;
      }

      final title = '💡 ${quote.category}';
      final body = quote.text.length > 100
          ? '${quote.text.substring(0, 100)}...'
          : quote.text;

      const androidDetails = AndroidNotificationDetails(
        'daily_quotes_channel',
        'Frases Diarias',
        channelDescription: 'Notificaciones con frases motivacionales',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: quote.id?.toString(),
      );

      if (quote.id != null) {
        final updatedQuote = quote.copyWith(
          lastShown: DateTime.now(),
          viewCount: quote.viewCount + 1,
        );
        await db.updateQuote(updatedQuote);
      }

      print('✅ Notificación mostrada: ${quote.text.substring(0, 50)}...');
    } catch (e) {
      print('❌ Error mostrando notificación: $e');
    }
  }

  /// Programar recordatorio de racha diario a las 21:00
  /// Solo se programa si el usuario tiene racha activa y no abrió la app hoy
  Future<void> scheduleStreakReminder(int streak) async {
    if (streak <= 0) return;

    const notifId = 999;
    await _notifications.cancel(notifId);

    final prefs = await SharedPreferences.getInstance();
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    // Si ya se programó hoy, no volver a programar
    if (prefs.getString('streak_reminder_date') == today) return;
    await prefs.setString('streak_reminder_date', today);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21, // 21:00
    );
    // Si ya pasaron las 21:00, no programar para hoy
    if (scheduled.isBefore(now)) return;

    const androidDetails = AndroidNotificationDetails(
      'daily_quotes_channel',
      'Frases Diarias',
      channelDescription: 'Notificaciones con frases motivacionales',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notifications.zonedSchedule(
      notifId,
      '🔥 ¡Tu racha de $streak ${streak == 1 ? 'día' : 'días'} está en juego!',
      'Abre la app antes de medianoche para no perderla.',
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('✅ Recordatorio de racha programado para las 21:00');
  }

  /// Cancelar todas las notificaciones programadas
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Todas las notificaciones canceladas');
  }
}
