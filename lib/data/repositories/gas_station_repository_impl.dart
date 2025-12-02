/// Implementación concreta del repositorio de gasolineras
/// Combina fuentes de datos remotas (API) y locales (SQLite)
library;

import 'dart:math';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

class GasStationRepositoryImpl implements GasStationRepository {
  final ApiDataSource _apiDataSource;
  final DatabaseDataSource _databaseDataSource;

  /// Constructor con inyección de dependencias
  ///
  /// [_apiDataSource] Fuente de datos remota (API gubernamental)
  /// [_databaseDataSource] Fuente de datos local (SQLite)
  GasStationRepositoryImpl(
    this._apiDataSource,
    this._databaseDataSource,
  );

  @override
  Future<List<GasStation>> fetchRemoteStations() async {
    try {
      // 1. Descargar modelos desde API
      final gasStationModels = await _apiDataSource.fetchAllStations();

      // 2. Convertir modelos a entidades de dominio
      final gasStations =
          gasStationModels.map((model) => model.toDomain()).toList();

      return gasStations;
    } on ApiException {
      // Re-lanzar excepciones de API para que capa superior las maneje
      rethrow;
    } catch (e) {
      throw Exception('Error al obtener estaciones remotas: $e');
    }
  }

  @override
  Future<List<GasStation>> getCachedStations() async {
    try {
      // Obtener todas las estaciones de la base de datos local
      return await _databaseDataSource.getAllStations();
    } catch (e) {
      throw Exception('Error al obtener estaciones en caché: $e');
    }
  }

  @override
  Future<void> updateCache(List<GasStation> stations) async {
    try {
      // 1. Borrar todos los datos antiguos
      await _databaseDataSource.clearAll();

      // 2. Insertar nuevos datos en batch (más eficiente)
      await _databaseDataSource.insertBatch(stations);

      // 3. Actualizar timestamp de última sincronización
      await _databaseDataSource.updateLastSync(DateTime.now());
    } catch (e) {
      throw Exception('Error al actualizar caché: $e');
    }
  }

  @override
  Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // 1. Obtener todas las estaciones del caché
      final allStations = await getCachedStations();

      // 2. Filtrar estaciones dentro del radio especificado
      final nearbyStations = allStations.where((station) {
        return station.isWithinRadius(latitude, longitude, radiusKm);
      }).toList();

      // 3. Ordenar por distancia usando la fórmula de Haversine
      nearbyStations.sort((a, b) {
        final distanceA =
            _calculateDistance(a.latitude, a.longitude, latitude, longitude);
        final distanceB =
            _calculateDistance(b.latitude, b.longitude, latitude, longitude);
        return distanceA.compareTo(distanceB);
      });

      return nearbyStations;
    } catch (e) {
      throw Exception('Error al obtener estaciones cercanas: $e');
    }
  }

  /// Calcular distancia entre dos puntos usando fórmula de Haversine
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

  /// Convertir grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
