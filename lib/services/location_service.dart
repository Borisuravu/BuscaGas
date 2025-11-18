import 'package:geolocator/geolocator.dart';

/// Servicio para gestionar la geolocalización del usuario
/// 
/// Responsabilidades:
/// - Verificar y solicitar permisos de ubicación
/// - Obtener coordenadas GPS actuales
/// - Verificar disponibilidad de servicios de ubicación
/// - Manejar errores de GPS
class LocationService {
  // Configuración de precisión de ubicación
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100, // Actualizar cada 100 metros
  );
  
  /// Obtener la posición actual del usuario
  /// 
  /// Lanza [LocationServiceDisabledException] si GPS está deshabilitado
  /// Lanza [PermissionDeniedException] si no hay permisos
  /// Lanza [TimeoutException] si tarda más de 10 segundos
  Future<Position> getCurrentPosition() async {
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
        throw const PermissionDeniedException('Permisos de ubicación denegados');
      }
    }
    
    // 3. Obtener posición actual
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    );
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
