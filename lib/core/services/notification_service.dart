import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../data/database/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  NotificationService._init();

  /// Inicializar servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    // Configuración Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración de inicialización
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Inicializar
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    print('✅ Notification service initialized');
  }

  /// Manejar tap en notificación
  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // TODO: Navegar a la app o a una pantalla específica
  }

  /// Solicitar permisos
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      print('✅ Notification permission already granted');
      return true;
    }

    final status = await Permission.notification.request();

    if (status.isGranted) {
      print('✅ Notification permission granted');
      return true;
    } else {
      print('❌ Notification permission denied');
      return false;
    }
  }

  /// Mostrar notificación inmediata (para testing)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Notificaciones instantáneas de prueba',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      title,
      body,
      details,
    );
  }

  /// Programar notificación diaria con frase motivacional
  Future<void> scheduleDailyQuoteNotification({
    required int hour,
    required int minute,
  }) async {
    // Obtener una frase aleatoria
    final db = DatabaseHelper.instance;
    final quote = await db.getRandomQuote();

    if (quote == null) {
      print('❌ No hay frases disponibles para notificación');
      return;
    }

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si ya pasó la hora de hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'daily_quote_channel',
      'Daily Quote',
      channelDescription: 'Frase motivacional diaria',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      1, // ID único para notificación diaria
      '✨ Frase del Día',
      quote.author != null ? '"${quote.text}" - ${quote.author}' : quote.text,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
    );

    print('🔔 Daily notification scheduled for $hour:$minute');
    print('📝 Quote: ${quote.text}');
  }

  /// Programar múltiples notificaciones (mañana, tarde, noche)
  Future<void> scheduleMultipleNotifications({
    List<String> times = const ['morning', 'afternoon', 'night'],
  }) async {
    await cancelAllNotifications();

    int notificationId = 1;

    for (final time in times) {
      int hour, minute;

      switch (time) {
        case 'morning':
          hour = 8;
          minute = 0;
          break;
        case 'afternoon':
          hour = 14;
          minute = 0;
          break;
        case 'night':
          hour = 20;
          minute = 0;
          break;
        default:
          continue;
      }

      await _scheduleSingleNotification(
        id: notificationId++,
        hour: hour,
        minute: minute,
      );
    }

    print('✅ Scheduled ${times.length} daily notifications');
  }

  /// Programar una sola notificación
  Future<void> _scheduleSingleNotification({
    required int id,
    required int hour,
    required int minute,
  }) async {
    final db = DatabaseHelper.instance;
    final quote = await db.getRandomQuote();

    if (quote == null) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'daily_quote_channel',
      'Daily Quote',
      channelDescription: 'Frase motivacional diaria',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      '✨ Tu momento de inspiración',
      quote.author != null ? '"${quote.text}" - ${quote.author}' : quote.text,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🔕 All notifications cancelled');
  }

  /// Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🔕 Notification $id cancelled');
  }

  /// Verificar si hay notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
