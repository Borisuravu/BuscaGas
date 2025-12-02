import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/core/utils/performance_monitor.dart';

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
      debugPrint('✅ Base de datos inicializada correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar base de datos: $e');
      rethrow;
    }
  }

  /// Verificar si la base de datos tiene datos
  Future<bool> hasData() async {
    try {
      return await _dataSource.hasData();
    } catch (e) {
      debugPrint('Error verificando datos: $e');
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

      debugPrint('✅ ${stations.length} gasolineras guardadas en caché');
    } catch (e) {
      debugPrint('❌ Error guardando gasolineras: $e');
      rethrow;
    }
  }

  /// Obtener todas las gasolineras del caché
  Future<List<GasStation>> getAllStations() async {
    try {
      return await _dataSource.getAllStations();
    } catch (e) {
      debugPrint('Error obteniendo gasolineras: $e');
      return [];
    }
  }

  /// Obtener gasolineras cercanas a una ubicación
  Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
    FuelType? fuelType,
  }) async {
    return PerformanceMonitor.measure('getNearbyStations', () async {
      try {
        final db = await _dataSource.database;

        // 1. Calcular bounding box (mucho más rápido que Haversine en todos)
        final latDelta = radiusKm / 111.0; // Aprox. 111 km por grado
        final lonDelta = radiusKm / (111.0 * cos(latitude * pi / 180));

        final minLat = latitude - latDelta;
        final maxLat = latitude + latDelta;
        final minLon = longitude - lonDelta;
        final maxLon = longitude + lonDelta;

        // 2. Query con bounding box (usa índices)
        String query = '''
          SELECT DISTINCT s.*, p.fuel_type, p.price, p.updated_at
          FROM gas_stations s
          INNER JOIN fuel_prices p ON s.id = p.station_id
          WHERE s.latitude BETWEEN ? AND ?
            AND s.longitude BETWEEN ? AND ?
        ''';

        List<dynamic> args = [minLat, maxLat, minLon, maxLon];

        // 3. Filtrar por combustible si se especifica
        if (fuelType != null) {
          query += ' AND p.fuel_type = ?';
          args.add(fuelType.toString().split('.').last);
        }

        // 4. Ejecutar query
        final results = await db.rawQuery(query, args);

        // 5. Convertir resultados
        Map<String, GasStation> stationsMap = {};

        for (var row in results) {
          final stationId = row['id'] as String;

          if (!stationsMap.containsKey(stationId)) {
            stationsMap[stationId] = GasStation(
              id: stationId,
              name: row['name'] as String,
              latitude: row['latitude'] as double,
              longitude: row['longitude'] as double,
              address: row['address'] as String? ?? '',
              locality: row['locality'] as String? ?? '',
              operator: row['operator'] as String? ?? '',
              prices: [],
            );
          }

          // Agregar precio
          stationsMap[stationId]!.prices.add(
            FuelPrice(
              fuelType: _parseFuelType(row['fuel_type'] as String),
              value: row['price'] as double,
              updatedAt: DateTime.parse(row['updated_at'] as String),
            ),
          );
        }

        // 6. Calcular distancias reales solo para candidatos (no 11,000)
        List<GasStation> stations = stationsMap.values.toList();
        for (var station in stations) {
          station.distance = _calculateDistance(
            latitude,
            longitude,
            station.latitude,
            station.longitude,
          );
        }

        // 7. Filtrar por radio exacto y ordenar
        stations = stations.where((s) => s.distance! <= radiusKm).toList();
        stations.sort((a, b) => a.distance!.compareTo(b.distance!));

        return stations;
      } catch (e) {
        debugPrint('Error getNearbyStations: $e');
        return [];
      }
    });
  }

  /// Parsear string de tipo de combustible a enum
  FuelType _parseFuelType(String fuelTypeStr) {
    switch (fuelTypeStr) {
      case 'gasolina95':
        return FuelType.gasolina95;
      case 'dieselGasoleoA':
        return FuelType.dieselGasoleoA;
      default:
        return FuelType.gasolina95;
    }
  }

  /// Agregar una sola gasolinera
  Future<void> addStation(GasStation station) async {
    try {
      await _dataSource.insertStation(station);
    } catch (e) {
      debugPrint('Error agregando gasolinera: $e');
      rethrow;
    }
  }

  /// Limpiar caché de gasolineras
  Future<void> clearCache() async {
    try {
      await _dataSource.clearAll();
      debugPrint('✅ Caché de gasolineras limpiado');
    } catch (e) {
      debugPrint('❌ Error limpiando caché: $e');
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
      debugPrint('Error actualizando precio: $e');
      rethrow;
    }
  }

  // ==================== CONFIGURACIÓN ====================

  /// Obtener configuración de la app
  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      return await _dataSource.getSettings();
    } catch (e) {
      debugPrint('Error obteniendo configuración: $e');
      return null;
    }
  }

  /// Actualizar radio de búsqueda
  Future<void> updateSearchRadius(int radiusKm) async {
    try {
      await _dataSource.updateSettings({'search_radius': radiusKm});
    } catch (e) {
      debugPrint('Error actualizando radio de búsqueda: $e');
      rethrow;
    }
  }

  /// Actualizar combustible preferido
  Future<void> updatePreferredFuel(FuelType fuelType) async {
    try {
      await _dataSource.updateSettings({'preferred_fuel': fuelType.name});
    } catch (e) {
      debugPrint('Error actualizando combustible preferido: $e');
      rethrow;
    }
  }

  /// Actualizar modo oscuro
  Future<void> updateDarkMode(bool isDark) async {
    try {
      await _dataSource.updateSettings({'dark_mode': isDark ? 1 : 0});
    } catch (e) {
      debugPrint('Error actualizando modo oscuro: $e');
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
      debugPrint('Error obteniendo timestamp de sincronización: $e');
      return null;
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener número de gasolineras en caché
  Future<int> getCachedStationCount() async {
    try {
      return await _dataSource.getStationCount();
    } catch (e) {
      debugPrint('Error obteniendo conteo: $e');
      return 0;
    }
  }

  /// Verificar si el caché está desactualizado
  Future<bool> isCacheStale(
      {Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final lastSync = await getLastSyncTime();
      if (lastSync == null) return true;

      final age = DateTime.now().difference(lastSync);
      return age > maxAge;
    } catch (e) {
      debugPrint('Error verificando antigüedad del caché: $e');
      return true;
    }
  }

  /// Optimizar base de datos (ejecutar semanalmente)
  /// 
  /// VACUUM: Reconstruye la base de datos eliminando fragmentación
  /// ANALYZE: Actualiza estadísticas para el optimizador de queries
  Future<void> optimizeDatabase() async {
    try {
      PerformanceMonitor.start('Database Optimization');
      final db = await _dataSource.database;

      // VACUUM: Reconstruye BD, elimina fragmentación
      await db.execute('VACUUM');

      // ANALYZE: Actualiza estadísticas para query optimizer
      await db.execute('ANALYZE');

      PerformanceMonitor.stop('Database Optimization');
      debugPrint('✅ Base de datos optimizada');
    } catch (e) {
      debugPrint('Error optimizando BD: $e');
    }
  }

  /// Obtener timestamp de última optimización
  Future<DateTime?> getLastOptimizationTime() async {
    try {
      final settings = await _dataSource.getSettings();
      if (settings != null && settings['last_optimization'] != null) {
        return DateTime.parse(settings['last_optimization'] as String);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo timestamp de optimización: $e');
      return null;
    }
  }

  /// Actualizar timestamp de última optimización
  Future<void> updateLastOptimizationTime() async {
    try {
      await _dataSource.updateSettings({
        'last_optimization': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error actualizando timestamp de optimización: $e');
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
      debugPrint('✅ Base de datos cerrada');
    } catch (e) {
      debugPrint('❌ Error cerrando base de datos: $e');
    }
  }
}
