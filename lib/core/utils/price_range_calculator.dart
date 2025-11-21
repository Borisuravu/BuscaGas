/// Utilidad: Calculadora de rangos de precio
library;

import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/price_range.dart';

/// Clase utilitaria para calcular y asignar rangos de precio
/// basados en percentiles P33 y P66
class PriceRangeCalculator {
  /// Asigna rangos de precio a una lista de gasolineras
  /// basándose en el combustible seleccionado.
  /// 
  /// Algoritmo:
  /// - P33 (percentil 33): separa el 33% más bajo → PriceRange.low
  /// - P66 (percentil 66): separa el 66% más bajo → PriceRange.medium
  /// - El resto (top 34%) → PriceRange.high
  /// 
  /// [stations]: Lista de gasolineras a clasificar
  /// [selectedFuel]: Tipo de combustible para comparar precios
  /// 
  /// Returns: Lista de gasolineras con priceRange asignado
  static List<GasStation> assignPriceRanges(
    List<GasStation> stations,
    FuelType selectedFuel,
  ) {
    // Filtrar estaciones con precio válido para el combustible seleccionado
    final validStations = stations.where((station) {
      final price = station.getPriceForFuel(selectedFuel);
      return price != null && price > 0;
    }).toList();
    
    // Si no hay estaciones válidas, retornar la lista original
    if (validStations.isEmpty) {
      return stations;
    }
    
    // Si solo hay una estación, asignarle rango medio
    if (validStations.length == 1) {
      validStations[0].priceRange = PriceRange.medium;
      return stations;
    }
    
    // Extraer y ordenar precios
    final prices = validStations
        .map((s) => s.getPriceForFuel(selectedFuel)!)
        .toList()
      ..sort();
    
    // Si todos los precios son iguales, asignar rango medio a todos
    if (prices.first == prices.last) {
      for (var station in validStations) {
        station.priceRange = PriceRange.medium;
      }
      return stations;
    }
    
    // Calcular percentiles P33 y P66
    final p33 = _calculatePercentile(prices, 33);
    final p66 = _calculatePercentile(prices, 66);
    
    // Asignar rangos basados en percentiles
    for (var station in validStations) {
      final price = station.getPriceForFuel(selectedFuel)!;
      
      if (price <= p33) {
        station.priceRange = PriceRange.low;
      } else if (price <= p66) {
        station.priceRange = PriceRange.medium;
      } else {
        station.priceRange = PriceRange.high;
      }
    }
    
    return stations;
  }
  
  /// Calcula el percentil especificado de una lista de valores ordenados
  /// 
  /// [sortedValues]: Lista de valores ya ordenados de menor a mayor
  /// [percentile]: Percentil a calcular (0-100)
  /// 
  /// Returns: Valor del percentil calculado
  static double _calculatePercentile(List<double> sortedValues, int percentile) {
    if (sortedValues.isEmpty) return 0.0;
    if (sortedValues.length == 1) return sortedValues[0];
    
    // Calcular índice usando interpolación lineal
    final index = (percentile / 100.0) * (sortedValues.length - 1);
    final lowerIndex = index.floor();
    final upperIndex = index.ceil();
    
    // Si el índice es exacto, retornar ese valor
    if (lowerIndex == upperIndex) {
      return sortedValues[lowerIndex];
    }
    
    // Interpolación lineal entre valores adyacentes
    final lowerValue = sortedValues[lowerIndex];
    final upperValue = sortedValues[upperIndex];
    final fraction = index - lowerIndex;
    
    return lowerValue + (upperValue - lowerValue) * fraction;
  }
  
  /// Calcula estadísticas de distribución de precios (útil para debugging)
  /// 
  /// [stations]: Lista de gasolineras
  /// [selectedFuel]: Tipo de combustible
  /// 
  /// Returns: Map con estadísticas (min, max, p33, p66, mean)
  static Map<String, double> calculateStatistics(
    List<GasStation> stations,
    FuelType selectedFuel,
  ) {
    final prices = stations
        .map((s) => s.getPriceForFuel(selectedFuel))
        .where((p) => p != null && p > 0)
        .map((p) => p!)
        .toList()
      ..sort();
    
    if (prices.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'p33': 0.0,
        'p66': 0.0,
        'mean': 0.0,
      };
    }
    
    final mean = prices.reduce((a, b) => a + b) / prices.length;
    
    return {
      'min': prices.first,
      'max': prices.last,
      'p33': _calculatePercentile(prices, 33),
      'p66': _calculatePercentile(prices, 66),
      'mean': mean,
    };
  }
  
  /// Cuenta cuántas estaciones hay en cada rango de precio
  /// 
  /// [stations]: Lista de gasolineras
  /// 
  /// Returns: Map con conteo por rango
  static Map<PriceRange, int> countByRange(List<GasStation> stations) {
    final counts = {
      PriceRange.low: 0,
      PriceRange.medium: 0,
      PriceRange.high: 0,
    };
    
    for (var station in stations) {
      if (station.priceRange != null) {
        counts[station.priceRange!] = counts[station.priceRange!]! + 1;
      }
    }
    
    return counts;
  }
}
