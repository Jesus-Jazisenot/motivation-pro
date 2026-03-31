import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/notification_schedule.dart';
import 'notification_service.dart';

/// Callback para AlarmManager (debe ser función top-level)
@pragma('vm:entry-point')
void alarmCallback() async {
  print('🔔 Alarm ejecutando...');
  try {
    await NotificationService.instance.showQuoteNotification();
    print('✅ Notificación mostrada desde alarm');
  } catch (e) {
    print('❌ Error en alarm: $e');
  }
}

/// Servicio para programar notificaciones usando AlarmManager
class NotificationScheduler {
  static final NotificationScheduler instance = NotificationScheduler._init();
  NotificationScheduler._init();

  /// Inicializar AlarmManager
  Future<void> initialize() async {
    print('⏰ Inicializando NotificationScheduler...');
    try {
      await AndroidAlarmManager.initialize();

      // Solicitar permisos de alarmas exactas
      await _requestExactAlarmPermission();

      print('✅ AlarmManager inicializado');
    } catch (e) {
      print('❌ Error inicializando AlarmManager: $e');
    }
  }

  /// Solicitar permiso de alarmas exactas (Android 12+)
  Future<void> _requestExactAlarmPermission() async {
    try {
      // Verificar si ya tiene permiso
      final status = await Permission.scheduleExactAlarm.status;

      if (!status.isGranted) {
        print('⚠️ Solicitando permiso de alarmas exactas...');
        final result = await Permission.scheduleExactAlarm.request();

        if (result.isGranted) {
          print('✅ Permiso de alarmas exactas concedido');
        } else {
          print('❌ Permiso de alarmas exactas denegado');
        }
      } else {
        print('✅ Permiso de alarmas exactas ya concedido');
      }
    } catch (e) {
      print('⚠️ Error solicitando permiso: $e');
    }
  }

  /// Programar todas las notificaciones según horarios guardados
  Future<void> scheduleAllNotifications() async {
    try {
      print('📅 Programando notificaciones...');

      // Verificar permisos primero
      final status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        print('⚠️ Sin permiso de alarmas exactas - solicitando...');
        await _requestExactAlarmPermission();
      }

      // Cancelar todas las alarmas anteriores
      for (int i = 0; i < 100; i++) {
        await AndroidAlarmManager.cancel(i);
      }
      print('🗑️ Alarmas anteriores canceladas');

      // Obtener horarios activos
      final db = DatabaseHelper.instance;
      final schedules = await db.getAllSchedules();
      final activeSchedules = schedules.where((s) => s.enabled).toList();

      if (activeSchedules.isEmpty) {
        print('⚠️ No hay horarios activos');
        return;
      }

      print('📋 ${activeSchedules.length} horarios activos');

      // Programar cada horario
      for (int i = 0; i < activeSchedules.length; i++) {
        await _scheduleNotification(activeSchedules[i], i);
      }

      print('✅ Todas las notificaciones programadas');
    } catch (e) {
      print('❌ Error programando notificaciones: $e');
    }
  }

  /// Programar una notificación individual
  Future<void> _scheduleNotification(
      NotificationSchedule schedule, int alarmId) async {
    try {
      print('📅 Programando: ${schedule.label} (ID: $alarmId)');

      final timeParts = schedule.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = DateTime.now();
      var nextExecution = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Si ya pasó hoy, programar para mañana
      if (nextExecution.isBefore(now)) {
        nextExecution = nextExecution.add(const Duration(days: 1));
      }

      // Ajustar según días de la semana
      while (!schedule.days.contains(nextExecution.weekday % 7)) {
        nextExecution = nextExecution.add(const Duration(days: 1));
      }

      print('⏰ Programando para: $nextExecution');

      // Programar alarma
      final success = await AndroidAlarmManager.oneShotAt(
        nextExecution,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      if (success) {
        print('✅ Alarma programada exitosamente');
      } else {
        print('❌ Falló programar alarma');
      }
    } catch (e) {
      print('❌ ERROR programando horario: $e');
    }
  }

  /// Probar notificación inmediata
  Future<void> testNotification() async {
    print('🧪 Programando prueba en 5 segundos...');

    try {
      final success = await AndroidAlarmManager.oneShot(
        const Duration(seconds: 5),
        999, // ID especial para test
        alarmCallback,
        exact: true,
        wakeup: true,
      );

      if (success) {
        print('✅ Test programado');
      } else {
        print('❌ Falló programar test');
      }
    } catch (e) {
      print('❌ Error en test: $e');
    }
  }

  /// Obtener estado
  Future<Map<String, dynamic>> getScheduleStatus() async {
    final db = DatabaseHelper.instance;
    final schedules = await db.getAllSchedules();
    final activeCount = schedules.where((s) => s.enabled).length;

    return {
      'total': schedules.length,
      'active': activeCount,
      'inactive': schedules.length - activeCount,
    };
  }
}
