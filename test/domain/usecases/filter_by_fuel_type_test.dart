import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/filter_by_fuel_type.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

void main() {
  group('FilterByFuelTypeUseCase', () {
    late FilterByFuelTypeUseCase useCase;

    setUp(() {
      useCase = FilterByFuelTypeUseCase();
    });

    test('debe filtrar correctamente por Gasolina 95', () {
      // Arrange - 10 gasolineras (5 con Gasolina 95, 5 sin)
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.45),
        _createStation('2', FuelType.dieselGasoleoA, 1.35),
        _createStation('3', FuelType.gasolina95, 1.50),
        _createStation('4', FuelType.dieselGasoleoA, 1.40),
        _createStation('5', FuelType.gasolina95, 1.55),
        _createStation('6', FuelType.dieselGasoleoA, 1.45),
        _createStation('7', FuelType.gasolina95, 1.48),
        _createStation('8', FuelType.dieselGasoleoA, 1.38),
        _createStation('9', FuelType.gasolina95, 1.52),
        _createStation('10', FuelType.dieselGasoleoA, 1.42),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert - Debe retornar exactamente 5 gasolineras
      expect(result.length, equals(5));
      // Verificar que todas tienen Gasolina 95
      for (var station in result) {
        expect(station.getPriceForFuel(FuelType.gasolina95), isNotNull);
      }
    });

    test('debe filtrar correctamente por Diésel Gasóleo A', () {
      // Arrange - 8 gasolineras (3 con diesel, 5 sin)
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.45),
        _createStation('2', FuelType.dieselGasoleoA, 1.35),
        _createStation('3', FuelType.gasolina95, 1.50),
        _createStation('4', FuelType.dieselGasoleoA, 1.40),
        _createStation('5', FuelType.gasolina95, 1.55),
        _createStation('6', FuelType.dieselGasoleoA, 1.45),
        _createStation('7', FuelType.gasolina95, 1.48),
        _createStation('8', FuelType.gasolina95, 1.52),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.dieselGasoleoA,
      );

      // Assert - Debe retornar exactamente 3 gasolineras
      expect(result.length, equals(3));
      // Verificar que todas tienen Diesel
      for (var station in result) {
        expect(station.getPriceForFuel(FuelType.dieselGasoleoA), isNotNull);
      }
    });

    test(
        'debe incluir gasolinera con múltiples combustibles si tiene el solicitado',
        () {
      // Arrange - Gasolinera con ambos combustibles
      final stations = [
        _createStationWithMultipleFuels('1', {
          FuelType.gasolina95: 1.45,
          FuelType.dieselGasoleoA: 1.35,
        }),
        _createStation('2', FuelType.gasolina95, 1.50),
      ];

      // Act
      final resultGasolina = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      final resultDiesel = useCase(
        stations: stations,
        fuelType: FuelType.dieselGasoleoA,
      );

      // Assert - La estación 1 debe aparecer en ambos filtros
      expect(resultGasolina.length, equals(2));
      expect(resultDiesel.length, equals(1));
      expect(resultDiesel.first.id, equals('1'));
    });

    test('debe excluir gasolineras sin precio para el combustible solicitado',
        () {
      // Arrange
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.45),
        _createStation('2', FuelType.gasolina95, 1.50),
        _createStation('3', FuelType.dieselGasoleoA, 1.35), // Solo diesel
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert - Solo 2 gasolineras con gasolina
      expect(result.length, equals(2));
      expect(result.any((s) => s.id == '3'), isFalse);
    });

    test('debe excluir gasolineras con precio 0 o negativo', () {
      // Arrange
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.45),
        _createStation('2', FuelType.gasolina95, 0.0), // Precio inválido
        _createStation('3', FuelType.gasolina95, -1.0), // Precio negativo
        _createStation('4', FuelType.gasolina95, 1.50),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert - Solo gasolineras con precio > 0
      expect(result.length, equals(2));
      expect(result.any((s) => s.id == '2'), isFalse);
      expect(result.any((s) => s.id == '3'), isFalse);
    });

    test('debe retornar lista vacía cuando no hay coincidencias', () {
      // Arrange - Solo gasolineras con diesel
      final stations = [
        _createStation('1', FuelType.dieselGasoleoA, 1.35),
        _createStation('2', FuelType.dieselGasoleoA, 1.40),
        _createStation('3', FuelType.dieselGasoleoA, 1.45),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert
      expect(result, isEmpty);
    });

    test('debe retornar lista vacía cuando recibe lista vacía', () {
      // Arrange
      final stations = <GasStation>[];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert
      expect(result, isEmpty);
    });

    test('debe manejar gasolineras sin ningún precio', () {
      // Arrange
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.45),
        GasStation(
          id: '2',
          name: 'Sin precios',
          latitude: 40.0,
          longitude: -3.0,
          prices: [], // Sin precios
        ),
        _createStation('3', FuelType.gasolina95, 1.50),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert - Solo 2 gasolineras válidas
      expect(result.length, equals(2));
      expect(result.any((s) => s.id == '2'), isFalse);
    });

    test('no debe modificar la lista original', () {
      // Arrange
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.45),
        _createStation('2', FuelType.dieselGasoleoA, 1.35),
        _createStation('3', FuelType.gasolina95, 1.50),
      ];

      final originalLength = stations.length;

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert - La lista original debe permanecer intacta
      expect(stations.length, equals(originalLength));
      expect(result.length, lessThan(originalLength));
    });

    test('debe retornar nueva lista, no la misma referencia', () {
      // Arrange
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.45),
        _createStation('2', FuelType.gasolina95, 1.50),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert - Debe ser una nueva lista
      expect(identical(result, stations), isFalse);
    });

    test('debe preservar el orden original de las gasolineras', () {
      // Arrange
      final stations = [
        _createStation('1', FuelType.gasolina95, 1.55),
        _createStation('2', FuelType.gasolina95, 1.45),
        _createStation('3', FuelType.gasolina95, 1.50),
      ];

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert - El orden debe mantenerse (55, 45, 50)
      expect(result[0].id, equals('1'));
      expect(result[1].id, equals('2'));
      expect(result[2].id, equals('3'));
    });

    test('debe funcionar con todos los tipos de combustible del enum', () {
      // Arrange
      final allFuelTypes = FuelType.values;

      // Act & Assert - No debe lanzar excepciones para ningún tipo
      for (var fuelType in allFuelTypes) {
        final stations = [_createStation('1', fuelType, 1.45)];
        final result = useCase(stations: stations, fuelType: fuelType);
        expect(result.length, equals(1));
      }
    });

    test('debe manejar listas grandes eficientemente', () {
      // Arrange - 1000 gasolineras (500 con gasolina, 500 con diesel)
      final stations = List.generate(1000, (i) {
        final fuelType =
            i.isEven ? FuelType.gasolina95 : FuelType.dieselGasoleoA;
        return _createStation('$i', fuelType, 1.45 + (i * 0.001));
      });

      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );

      // Assert
      expect(result.length, equals(500));
    });
  });
}

/// Helper: Crea una gasolinera de prueba con un solo combustible
GasStation _createStation(String id, FuelType fuelType, double price) {
  return GasStation(
    id: id,
    name: 'Gasolinera $id',
    latitude: 40.0,
    longitude: -3.0,
    prices: [
      FuelPrice(
        fuelType: fuelType,
        value: price,
        updatedAt: DateTime.now(),
      ),
    ],
  );
}

/// Helper: Crea una gasolinera con múltiples combustibles
GasStation _createStationWithMultipleFuels(
    String id, Map<FuelType, double> fuels) {
  return GasStation(
    id: id,
    name: 'Gasolinera $id',
    latitude: 40.0,
    longitude: -3.0,
    prices: fuels.entries
        .map((e) => FuelPrice(
              fuelType: e.key,
              value: e.value,
              updatedAt: DateTime.now(),
            ))
        .toList(),
  );
}
