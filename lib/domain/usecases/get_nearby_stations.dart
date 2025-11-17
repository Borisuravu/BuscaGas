/// Caso de uso: Obtener gasolineras cercanas a una ubicación
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';

class GetNearbyStationsUseCase {
  final GasStationRepository repository;
  
  /// Constructor con inyección de dependencias
  GetNearbyStationsUseCase(this.repository);
  
  /// Ejecutar caso de uso
  /// 
  /// Obtiene las estaciones de servicio cercanas a las coordenadas especificadas
  /// dentro del radio dado, ordenadas por distancia.
  /// 
  /// [latitude] Latitud de la ubicación del usuario
  /// [longitude] Longitud de la ubicación del usuario
  /// [radiusKm] Radio de búsqueda en kilómetros (5, 10, 20, 50)
  /// 
  /// Retorna lista de [GasStation] ordenadas por distancia (más cercanas primero)
  /// 
  /// Lanza [Exception] si hay error al obtener datos
  Future<List<GasStation>> call({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // Delegar en el repositorio
      final stations = await repository.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      
      return stations;
      
    } catch (e) {
      throw Exception('Error al obtener gasolineras cercanas: $e');
    }
  }
}
