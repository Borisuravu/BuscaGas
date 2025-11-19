import 'dart:math';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

/// Servicio de base de datos SQLite
/// 
/// Responsabilidades:
/// - Proporcionar interfaz simplificada para operaciones de BD
/// - Gestionar ciclo de vida de la base de datos
/// - Coordinar operaciones complejas entre tablas
/// - Manejar errores de base de datos
class DatabaseService {
  final DatabaseDataSource _dataSource = DatabaseDataSource();
  
  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  // ==================== INICIALIZACIÓN ====================
  
  /// Inicializar la base de datos
  /// Debe llamarse al inicio de la app (en SplashScreen o main.dart)
  Future<void> initialize() async {
    try {
      // Acceder a la base de datos para forzar su creación
      await _dataSource.database;
      print('✅ Base de datos inicializada correctamente');
    } catch (e) {
      print('❌ Error al inicializar base de datos: $e');
      rethrow;
    }
  }
  
  /// Verificar si la base de datos tiene datos
  Future<bool> hasData() async {
    try {
      return await _dataSource.hasData();
    } catch (e) {
      print('Error verificando datos: $e');
      return false;
    }
  }
  
  // ==================== GASOLINERAS ====================
  
  /// Guardar lista de gasolineras (reemplaza todo el caché)
  Future<void> saveStations(List<GasStation> stations) async {
    try {
      // Limpiar datos antiguos
      await _dataSource.clearAll();
      
      // Insertar nuevos datos en batch
      await _dataSource.insertBatch(stations);
      
      // Actualizar timestamp de sincronización
      await _dataSource.updateLastSync(DateTime.now());
      
      print('✅ ${stations.length} gasolineras guardadas en caché');
    } catch (e) {
      print('❌ Error guardando gasolineras: $e');
      rethrow;
    }
  }
  
  /// Obtener todas las gasolineras del caché
  Future<List<GasStation>> getAllStations() async {
    try {
      return await _dataSource.getAllStations();
    } catch (e) {
      print('Error obteniendo gasolineras: $e');
      return [];
    }
  }
  
  /// Obtener gasolineras cercanas a una ubicación
  Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final stations = await _dataSource.getStationsByLocation(
        centerLat: latitude,
        centerLon: longitude,
        radiusKm: radiusKm,
      );
      
      // Calcular y asignar distancia a cada gasolinera
      for (var station in stations) {
        station.distance = _calculateDistance(
          latitude,
          longitude,
          station.latitude,
          station.longitude,
        );
      }
      
      // Ordenar por distancia
      stations.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
      
      return stations;
    } catch (e) {
      print('Error obteniendo gasolineras cercanas: $e');
      return [];
    }
  }
  
  /// Agregar una sola gasolinera
  Future<void> addStation(GasStation station) async {
    try {
      await _dataSource.insertStation(station);
    } catch (e) {
      print('Error agregando gasolinera: $e');
      rethrow;
    }
  }
  
  /// Limpiar caché de gasolineras
  Future<void> clearCache() async {
    try {
      await _dataSource.clearAll();
      print('✅ Caché de gasolineras limpiado');
    } catch (e) {
      print('❌ Error limpiando caché: $e');
      rethrow;
    }
  }
  
  // ==================== PRECIOS ====================
  
  /// Actualizar precio de una gasolinera
  Future<void> updateStationPrice({
    required String stationId,
    required FuelPrice price,
  }) async {
    try {
      await _dataSource.updatePrice(stationId, price);
    } catch (e) {
      print('Error actualizando precio: $e');
      rethrow;
    }
  }
  
  // ==================== CONFIGURACIÓN ====================
  
  /// Obtener configuración de la app
  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      return await _dataSource.getSettings();
    } catch (e) {
      print('Error obteniendo configuración: $e');
      return null;
    }
  }
  
  /// Actualizar radio de búsqueda
  Future<void> updateSearchRadius(int radiusKm) async {
    try {
      await _dataSource.updateSettings({'search_radius': radiusKm});
    } catch (e) {
      print('Error actualizando radio de búsqueda: $e');
      rethrow;
    }
  }
  
  /// Actualizar combustible preferido
  Future<void> updatePreferredFuel(FuelType fuelType) async {
    try {
      await _dataSource.updateSettings({'preferred_fuel': fuelType.name});
    } catch (e) {
      print('Error actualizando combustible preferido: $e');
      rethrow;
    }
  }
  
  /// Actualizar modo oscuro
  Future<void> updateDarkMode(bool isDark) async {
    try {
      await _dataSource.updateSettings({'dark_mode': isDark ? 1 : 0});
    } catch (e) {
      print('Error actualizando modo oscuro: $e');
      rethrow;
    }
  }
  
  /// Obtener timestamp de última sincronización
  Future<DateTime?> getLastSyncTime() async {
    try {
      final settings = await _dataSource.getSettings();
      if (settings != null && settings['last_api_sync'] != null) {
        return DateTime.parse(settings['last_api_sync'] as String);
      }
      return null;
    } catch (e) {
      print('Error obteniendo timestamp de sincronización: $e');
      return null;
    }
  }
  
  // ==================== ESTADÍSTICAS ====================
  
  /// Obtener número de gasolineras en caché
  Future<int> getCachedStationCount() async {
    try {
      return await _dataSource.getStationCount();
    } catch (e) {
      print('Error obteniendo conteo: $e');
      return 0;
    }
  }
  
  /// Verificar si el caché está desactualizado
  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final lastSync = await getLastSyncTime();
      if (lastSync == null) return true;
      
      final age = DateTime.now().difference(lastSync);
      return age > maxAge;
    } catch (e) {
      print('Error verificando antigüedad del caché: $e');
      return true;
    }
  }
  
  // ==================== UTILIDADES ====================
  
  /// Calcular distancia entre dos puntos (fórmula de Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  /// Cerrar conexión a la base de datos
  Future<void> close() async {
    try {
      await _dataSource.close();
      print('✅ Base de datos cerrada');
    } catch (e) {
      print('❌ Error cerrando base de datos: $e');
    }
  }
}
