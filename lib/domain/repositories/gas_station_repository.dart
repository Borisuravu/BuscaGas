/// Repositorio abstracto para gestión de gasolineras
/// Define el contrato que debe cumplir cualquier implementación
library;

import 'package:buscagas/domain/entities/gas_station.dart';

abstract class GasStationRepository {
  /// Obtener todas las estaciones desde la API remota
  /// 
  /// Lanza [Exception] si hay error de red o parseo
  Future<List<GasStation>> fetchRemoteStations();
  
  /// Obtener todas las estaciones almacenadas en caché local
  /// 
  /// Retorna lista vacía si no hay datos en caché
  Future<List<GasStation>> getCachedStations();
  
  /// Actualizar caché local con nuevos datos
  /// 
  /// Borra todos los datos antiguos y guarda los nuevos
  /// [stations] Lista de estaciones a guardar en caché
  Future<void> updateCache(List<GasStation> stations);
  
  /// Obtener estaciones cercanas a una ubicación específica
  /// 
  /// Filtra estaciones en caché dentro del radio especificado
  /// [latitude] Latitud de la ubicación del usuario
  /// [longitude] Longitud de la ubicación del usuario
  /// [radiusKm] Radio de búsqueda en kilómetros (5, 10, 20, 50)
  /// 
  /// Retorna lista de estaciones dentro del radio, ordenadas por distancia
  Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}
