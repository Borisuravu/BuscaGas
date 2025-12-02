/// Caso de uso: Sincronizar estaciones desde API a caché local
library;

import 'package:buscagas/domain/repositories/gas_station_repository.dart';

/// Sincronización completa de datos de gasolineras
///
/// Coordina el proceso de:
/// 1. Descargar datos frescos desde la API gubernamental
/// 2. Actualizar la caché local con los nuevos datos
/// 3. Retornar la cantidad de gasolineras sincronizadas
class SyncStationsUseCase {
  final GasStationRepository repository;

  /// Constructor con inyección de dependencias
  SyncStationsUseCase(this.repository);

  /// Ejecutar sincronización completa
  ///
  /// Retorna el número de gasolineras sincronizadas
  ///
  /// Lanza [Exception] si hay error de red o de base de datos
  Future<int> call() async {
    try {
      // 1. Descargar datos frescos desde API remota
      final remoteStations = await repository.fetchRemoteStations();

      if (remoteStations.isEmpty) {
        throw Exception('La API no retornó gasolineras');
      }

      // 2. Actualizar caché local (borra datos antiguos e inserta nuevos)
      await repository.updateCache(remoteStations);

      // 3. Retornar cantidad sincronizada
      return remoteStations.length;
    } catch (e) {
      throw Exception('Error al sincronizar gasolineras: $e');
    }
  }
}
