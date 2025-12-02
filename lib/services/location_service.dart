import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:buscagas/core/utils/performance_monitor.dart';

/// Servicio para gestionar la geolocalización del usuario
///
/// Responsabilidades:
/// - Verificar y solicitar permisos de ubicación
/// - Obtener coordenadas GPS actuales
/// - Verificar disponibilidad de servicios de ubicación
/// - Manejar errores de GPS
/// - Optimizar consumo de batería con distanceFilter
class LocationService {
  // Configuración de precisión de ubicación optimizada
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 50, // Solo actualizar si se mueve >50 metros (optimización batería)
    timeLimit: Duration(seconds: 30), // Timeout de 30 segundos
  );

  // Stream subscription para control
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Obtener la posición actual del usuario
  ///
  /// Lanza [LocationServiceDisabledException] si GPS está deshabilitado
  /// Lanza [PermissionDeniedException] si no hay permisos
  /// Lanza [TimeoutException] si tarda más de 30 segundos
  Future<Position> getCurrentPosition() async {
    return PerformanceMonitor.measure('GPS', () async {
      // 1. Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationServiceDisabledException();
      }

      // 2. Verificar permisos
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        // Intentar solicitar permisos
        bool granted = await requestLocationPermission();
        if (!granted) {
          throw const PermissionDeniedException(
              'Permisos de ubicación denegados');
        }
      }

      // 3. Obtener posición actual con timeout
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('GPS timeout después de 30 segundos');
          },
        );

        return position;
      } catch (e) {
        // Si falla, intentar obtener última ubicación conocida
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }

        // Si no hay última ubicación, lanzar excepción
        rethrow;
      }
    });
  }

  /// Verificar si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verificar si la aplicación tiene permisos de ubicación
  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Solicitar permisos de ubicación al usuario
  ///
  /// Retorna true si se concedieron los permisos
  /// Retorna false si se denegaron
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    // Si ya están concedidos, retornar true
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    // Si están denegados permanentemente, no se puede solicitar
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Solicitar permisos
    permission = await Geolocator.requestPermission();

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Abrir la configuración de la aplicación para que el usuario
  /// pueda habilitar los permisos manualmente
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abrir la configuración de la aplicación
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Obtener un stream de actualizaciones de posición
  ///
  /// Útil para seguimiento en tiempo real (opcional para MVP)
  /// Usa accuracy medium para reducir consumo de batería
  Stream<Position> getPositionStream({int distanceFilterMeters = 100}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium, // Reducir a medium en stream
        distanceFilter: distanceFilterMeters,
        timeLimit: const Duration(seconds: 60),
      ),
    );
  }

  /// Pausar actualizaciones de GPS para ahorrar batería
  /// 
  /// Llamar cuando la app entra en background
  void pauseLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    print('📍 GPS pausado para ahorrar batería');
  }

  /// Reanudar actualizaciones de GPS
  /// 
  /// Llamar cuando la app vuelve a foreground
  void resumeLocationUpdates() {
    // Reactivar stream si es necesario
    // Nota: La lógica específica depende de cómo se use el stream
    print('📍 GPS reanudado');
  }

  /// Calcular la distancia entre dos puntos en metros
  ///
  /// Útil para verificar si el usuario se ha movido significativamente
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Obtener una posición predeterminada (Madrid centro)
  ///
  /// Usar solo como fallback cuando no se puede obtener ubicación real
  Position getDefaultPosition() {
    return Position(
      latitude: 40.416775,
      longitude: -3.703790,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}
