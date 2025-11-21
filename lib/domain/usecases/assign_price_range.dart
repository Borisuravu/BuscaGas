/// Caso de uso: Asignar rangos de precio a gasolineras
library;

import 'package:buscagas/core/utils/price_range_calculator.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

/// Clasificador de gasolineras por rangos de precio
/// 
/// Utiliza percentiles para dividir las gasolineras en 3 grupos:
/// - PriceRange.low: 33% más baratas (verde)
/// - PriceRange.medium: 33% intermedias (amarillo/naranja)
/// - PriceRange.high: 33% más caras (rojo)
class AssignPriceRangeUseCase {
  /// Ejecutar caso de uso
  /// 
  /// Modifica IN-PLACE el campo priceRange de cada GasStation
  /// utilizando el algoritmo de percentiles del PriceRangeCalculator
  /// 
  /// [stations] Lista de gasolineras a clasificar (se modifica)
  /// [fuelType] Tipo de combustible para calcular rangos
  /// 
  /// Algoritmo:
  /// 1. Extraer todos los precios válidos del combustible especificado
  /// 2. Ordenar precios de menor a mayor
  /// 3. Calcular percentiles P33 y P66 con interpolación lineal
  /// 4. Asignar PriceRange.low si precio <= P33
  /// 5. Asignar PriceRange.medium si P33 < precio <= P66
  /// 6. Asignar PriceRange.high si precio > P66
  void call({
    required List<GasStation> stations,
    required FuelType fuelType,
  }) {
    // Delegar al PriceRangeCalculator para la lógica de clasificación
    PriceRangeCalculator.assignPriceRanges(stations, fuelType);
  }
}
