import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async'; // ⬅️ IMPORT AGREGADO

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._init();

  ConnectivityService._init();

  final Connectivity _connectivity = Connectivity();

  /// Verificar si hay conexión a internet
  Future<bool> hasConnection() async {
    try {
      // Paso 1: Verificar conectividad del dispositivo
      final result = await _connectivity.checkConnectivity();

      print('🔍 Connectivity result: $result');

      // Verificar tipo de conexión
      final hasNetworkConnection = result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet) ||
          result.contains(ConnectivityResult.vpn);

      if (!hasNetworkConnection) {
        print('⚠️ Sin conexión de red detectada');
        print('📱 Tipo de conexión: $result');
        return false;
      }

      print('✅ Conexión de red detectada: $result');

      // Paso 2: Verificar conectividad real a internet (ping a Google)
      try {
        print('🌐 Verificando conectividad real a internet...');
        final testResult = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 5),
        );

        if (testResult.isNotEmpty && testResult[0].rawAddress.isNotEmpty) {
          print('✅ Conexión a internet CONFIRMADA');
          return true;
        }
      } on SocketException catch (e) {
        print('⚠️ Ping falló: $e');
        print('📡 Puede tener conexión de red pero sin acceso a internet');
        return false;
      } on TimeoutException {
        print('⚠️ Timeout verificando internet');
        return false;
      }

      print('⚠️ Sin conexión a internet');
      return false;
    } catch (e) {
      print('❌ Error verificando conexión: $e');
      return false;
    }
  }

  /// Obtener tipo de conexión actual
  Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (result.contains(ConnectivityResult.mobile)) {
        return 'Datos móviles';
      } else if (result.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else if (result.contains(ConnectivityResult.vpn)) {
        return 'VPN';
      } else {
        return 'Sin conexión';
      }
    } catch (e) {
      print('❌ Error obteniendo tipo de conexión: $e');
      return 'Desconocido';
    }
  }

  /// Stream de cambios de conectividad
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Verificación ligera (solo conectividad, sin ping)
  Future<bool> hasConnectionLight() async {
    try {
      final result = await _connectivity.checkConnectivity();

      final hasConnection = result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet) ||
          result.contains(ConnectivityResult.vpn);

      if (hasConnection) {
        print('✅ Conexión de red disponible (verificación ligera)');
      } else {
        print('⚠️ Sin conexión de red (verificación ligera)');
      }

      return hasConnection;
    } catch (e) {
      print('❌ Error en verificación ligera: $e');
      return false;
    }
  }
}
