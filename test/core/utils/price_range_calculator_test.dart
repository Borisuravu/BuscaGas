/// Pruebas unitarias: PriceRangeCalculator
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/core/utils/price_range_calculator.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/price_range.dart';

void main() {
  group('PriceRangeCalculator', () {
    test('asigna rangos correctamente con distribución normal', () {
      // Arrange: 10 gasolineras con precios de 1.00 a 1.90 (incrementos de 0.10)
      final stations = List.generate(10, (i) {
        final price = 1.00 + (i * 0.10);
        return GasStation(
          id: 'station_$i',
          name: 'Estación $i',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: price,
              updatedAt: DateTime.now(),
            ),
          ],
        );
      });

      // Act
      PriceRangeCalculator.assignPriceRanges(stations, FuelType.gasolina95);

      // Assert: Verificar distribución ~33% en cada rango
      final counts = PriceRangeCalculator.countByRange(stations);
      
      expect(counts[PriceRange.low], greaterThanOrEqualTo(2));
      expect(counts[PriceRange.medium], greaterThanOrEqualTo(2));
      expect(counts[PriceRange.high], greaterThanOrEqualTo(2));
      
      // Verificar que los precios más bajos están en low
      expect(stations[0].priceRange, equals(PriceRange.low));
      expect(stations[1].priceRange, equals(PriceRange.low));
      
      // Verificar que los precios más altos están en high
      expect(stations[8].priceRange, equals(PriceRange.high));
      expect(stations[9].priceRange, equals(PriceRange.high));
    });

    test('asigna PriceRange.medium cuando todas tienen el mismo precio', () {
      // Arrange: 5 gasolineras con el mismo precio
      final stations = List.generate(5, (i) {
        return GasStation(
          id: 'station_$i',
          name: 'Estación $i',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.50,
              updatedAt: DateTime.now(),
            ),
          ],
        );
      });

      // Act
      PriceRangeCalculator.assignPriceRanges(stations, FuelType.dieselGasoleoA);

      // Assert: Todas deben ser PriceRange.medium
      for (var station in stations) {
        expect(station.priceRange, equals(PriceRange.medium));
      }
    });

    test('asigna PriceRange.medium cuando solo hay una estación', () {
      // Arrange
      final stations = [
        GasStation(
          id: 'station_1',
          name: 'Estación única',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.75,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      // Act
      PriceRangeCalculator.assignPriceRanges(stations, FuelType.gasolina95);

      // Assert
      expect(stations[0].priceRange, equals(PriceRange.medium));
    });

    test('ignora estaciones sin precio para el combustible seleccionado', () {
      // Arrange
      final stations = [
        GasStation(
          id: 'station_1',
          name: 'Estación 1',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.50,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStation(
          id: 'station_2',
          name: 'Estación 2',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.40,
              updatedAt: DateTime.now(),
            ), // Combustible diferente
          ],
        ),
        GasStation(
          id: 'station_3',
          name: 'Estación 3',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.60,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      // Act
      PriceRangeCalculator.assignPriceRanges(stations, FuelType.gasolina95);

      // Assert: Solo las estaciones 1 y 3 deben tener rango asignado
      expect(stations[0].priceRange, isNotNull);
      expect(stations[1].priceRange, isNull); // No tiene gasolina95
      expect(stations[2].priceRange, isNotNull);
    });

    test('retorna lista vacía cuando no hay estaciones válidas', () {
      // Arrange
      final stations = [
        GasStation(
          id: 'station_1',
          name: 'Estación sin precios',
          latitude: 0.0,
          longitude: 0.0,
          prices: [],
        ),
      ];

      // Act
      final result = PriceRangeCalculator.assignPriceRanges(
        stations,
        FuelType.gasolina95,
      );

      // Assert
      expect(result, equals(stations));
      expect(stations[0].priceRange, isNull);
    });

    test('calcula estadísticas correctamente', () {
      // Arrange
      final stations = [
        GasStation(
          id: 'station_1',
          name: 'Estación 1',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.20,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStation(
          id: 'station_2',
          name: 'Estación 2',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.40,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStation(
          id: 'station_3',
          name: 'Estación 3',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.60,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      // Act
      final stats = PriceRangeCalculator.calculateStatistics(
        stations,
        FuelType.dieselGasoleoA,
      );

      // Assert
      expect(stats['min'], equals(1.20));
      expect(stats['max'], equals(1.60));
      expect(stats['mean'], closeTo(1.40, 0.01));
      expect(stats['p33'], isNotNull);
      expect(stats['p66'], isNotNull);
    });

    test('cuenta estaciones por rango correctamente', () {
      // Arrange
      final stations = [
        GasStation(
          id: 'station_1',
          name: 'Estación 1',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.20,
              updatedAt: DateTime.now(),
            ),
          ],
          priceRange: PriceRange.low,
        ),
        GasStation(
          id: 'station_2',
          name: 'Estación 2',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.50,
              updatedAt: DateTime.now(),
            ),
          ],
          priceRange: PriceRange.medium,
        ),
        GasStation(
          id: 'station_3',
          name: 'Estación 3',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.80,
              updatedAt: DateTime.now(),
            ),
          ],
          priceRange: PriceRange.high,
        ),
      ];

      // Act
      final counts = PriceRangeCalculator.countByRange(stations);

      // Assert
      expect(counts[PriceRange.low], equals(1));
      expect(counts[PriceRange.medium], equals(1));
      expect(counts[PriceRange.high], equals(1));
    });

    test('calcula percentiles con interpolación lineal correctamente', () {
      // Arrange: 100 gasolineras con precios de 1.00 a 2.00
      final stations = List.generate(100, (i) {
        final price = 1.00 + (i * 0.01);
        return GasStation(
          id: 'station_$i',
          name: 'Estación $i',
          latitude: 0.0,
          longitude: 0.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: price,
              updatedAt: DateTime.now(),
            ),
          ],
        );
      });

      // Act
      PriceRangeCalculator.assignPriceRanges(stations, FuelType.gasolina95);
      final stats = PriceRangeCalculator.calculateStatistics(
        stations,
        FuelType.gasolina95,
      );

      // Assert: Con 100 valores de 1.00 a 2.00
      // P33 debería estar alrededor de 1.33
      // P66 debería estar alrededor de 1.66
      expect(stats['p33'], closeTo(1.33, 0.05));
      expect(stats['p66'], closeTo(1.66, 0.05));
      
      // Verificar distribución aproximadamente uniforme
      final counts = PriceRangeCalculator.countByRange(stations);
      expect(counts[PriceRange.low], greaterThanOrEqualTo(25));
      expect(counts[PriceRange.low], lessThanOrEqualTo(40));
      expect(counts[PriceRange.medium], greaterThanOrEqualTo(25));
      expect(counts[PriceRange.medium], lessThanOrEqualTo(40));
      expect(counts[PriceRange.high], greaterThanOrEqualTo(25));
      expect(counts[PriceRange.high], lessThanOrEqualTo(40));
    });
  });
}

