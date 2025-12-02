/// Caso de uso: Filtrar gasolineras por tipo de combustible
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class FilterByFuelTypeUseCase {
  /// Ejecutar caso de uso
  ///
  /// Filtra la lista de gasolineras para retornar solo aquellas que tienen
  /// precio disponible para el tipo de combustible especificado.
  ///
  /// [stations] Lista completa de gasolineras
  /// [fuelType] Tipo de combustible a filtrar (gasolina95, dieselA)
  ///
  /// Retorna lista filtrada de [GasStation] que tienen el combustible
  List<GasStation> call({
    required List<GasStation> stations,
    required FuelType fuelType,
  }) {
    // Filtrar estaciones que tienen precio para el combustible solicitado
    final filteredStations = stations.where((station) {
      final price = station.getPriceForFuel(fuelType);
      return price != null && price > 0;
    }).toList();

    return filteredStations;
  }
}
