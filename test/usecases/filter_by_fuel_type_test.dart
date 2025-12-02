import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/filter_by_fuel_type.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';

void main() {
  group('FilterByFuelTypeUseCase', () {
    late FilterByFuelTypeUseCase useCase;

    setUp(() {
      useCase = FilterByFuelTypeUseCase();
    });

    test('debe filtrar gasolineras que tienen gasolina95', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Con Gasolina',
          latitude: 40.4168,
          longitude: -3.7038,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.45,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStation(
          id: '2',
          name: 'Solo Diesel',
          latitude: 41.3851,
          longitude: 2.1734,
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.38,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert
      expect(result.length, 1);
      expect(result.first.name, 'Con Gasolina');
    });

    test('debe retornar lista vacía si ninguna tiene el combustible', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Sin Precios',
          latitude: 40.4168,
          longitude: -3.7038,
          prices: [],
        ),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert
      expect(result, isEmpty);
    });
  });
}
