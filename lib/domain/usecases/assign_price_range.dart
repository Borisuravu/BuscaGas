/// Caso de uso: Asignar rangos de precio a gasolineras
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/price_range.dart';

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
  /// 
  /// [stations] Lista de gasolineras a clasificar (se modifica)
  /// [fuelType] Tipo de combustible para calcular rangos
  /// 
  /// Algoritmo:
  /// 1. Extraer todos los precios válidos del combustible especificado
  /// 2. Ordenar precios de menor a mayor
  /// 3. Calcular percentiles 33 y 66
  /// 4. Asignar PriceRange.low si precio <= p33
  /// 5. Asignar PriceRange.medium si p33 < precio <= p66
  /// 6. Asignar PriceRange.high si precio > p66
  void call({
    required List<GasStation> stations,
    required FuelType fuelType,
  }) {
    // 1. Extraer todos los precios válidos para el combustible
    List<double> prices = stations
        .map((station) => station.getPriceForFuel(fuelType))
        .whereType<double>() // Filtrar nulls
        .where((price) => price > 0) // Filtrar precios inválidos
        .toList();
    
    // Si no hay precios, no hay nada que clasificar
    if (prices.isEmpty) {
      // Asignar null a todas las estaciones
      for (var station in stations) {
        station.priceRange = null;
      }
      return;
    }
    
    // Si solo hay 1 o 2 precios, todos son "medium"
    if (prices.length <= 2) {
      for (var station in stations) {
        final price = station.getPriceForFuel(fuelType);
        if (price != null && price > 0) {
          station.priceRange = PriceRange.medium;
        } else {
          station.priceRange = null;
        }
      }
      return;
    }
    
    // 2. Ordenar precios de menor a mayor
    prices.sort();
    
    // 3. Calcular percentiles 33 y 66
    final int count = prices.length;
    final int p33Index = (count * 0.33).floor();
    final int p66Index = (count * 0.66).floor();
    
    final double p33 = prices[p33Index];
    final double p66 = prices[p66Index];
    
    // 4. Asignar rangos a cada estación
    for (var station in stations) {
      final double? price = station.getPriceForFuel(fuelType);
      
      if (price == null || price <= 0) {
        station.priceRange = null;
        continue;
      }
      
      if (price <= p33) {
        station.priceRange = PriceRange.low; // Verde (barato)
      } else if (price <= p66) {
        station.priceRange = PriceRange.medium; // Naranja (medio)
      } else {
        station.priceRange = PriceRange.high; // Rojo (caro)
      }
    }
  }
}
