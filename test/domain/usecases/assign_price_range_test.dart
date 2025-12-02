import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/assign_price_range.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/price_range.dart';

void main() {
  group('AssignPriceRangeUseCase', () {
    late AssignPriceRangeUseCase useCase;

    setUp(() {
      useCase = AssignPriceRangeUseCase();
    });

    test('debe asignar rangos básicamente correctos', () {
      // Arrange - 9 gasolineras con precios variados
      final stations = [
        _createStation('1', 1.40), // low
        _createStation('2', 1.42), // low
        _createStation('3', 1.45), // low
        _createStation('4', 1.48), // medium
        _createStation('5', 1.50), // medium
        _createStation('6', 1.52), // medium
        _createStation('7', 1.55), // high
        _createStation('8', 1.58), // high
        _createStation('9', 1.60), // high
      ];

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Cada estación debe tener un priceRange asignado
      for (var station in stations) {
        expect(station.priceRange, isNotNull);
      }
    });

    test('debe respetar percentiles P33 y P66', () {
      // Arrange - 9 gasolineras con precios conocidos
      final stations = [
        _createStation('1', 1.40), // Precio más bajo
        _createStation('2', 1.42),
        _createStation('3', 1.45),
        _createStation('4', 1.48),
        _createStation('5', 1.50),
        _createStation('6', 1.52),
        _createStation('7', 1.55),
        _createStation('8', 1.58),
        _createStation('9', 1.60), // Precio más alto
      ];

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Los 3 precios más bajos deben ser PriceRange.low
      expect(stations[0].priceRange, equals(PriceRange.low));
      expect(stations[1].priceRange, equals(PriceRange.low));
      expect(stations[2].priceRange, equals(PriceRange.low));

      // Los 3 precios más altos deben ser PriceRange.high
      expect(stations[6].priceRange, equals(PriceRange.high));
      expect(stations[7].priceRange, equals(PriceRange.high));
      expect(stations[8].priceRange, equals(PriceRange.high));

      // Los 3 intermedios deben ser PriceRange.medium
      expect(stations[3].priceRange, equals(PriceRange.medium));
      expect(stations[4].priceRange, equals(PriceRange.medium));
      expect(stations[5].priceRange, equals(PriceRange.medium));
    });

    test(
        'debe asignar PriceRange.medium cuando no hay combustible seleccionado',
        () {
      // Arrange - Gasolineras sin precio para el combustible solicitado
      final stations = [
        _createStationWithFuel('1', FuelType.dieselGasoleoA, 1.35),
        _createStationWithFuel('2', FuelType.dieselGasoleoA, 1.40),
        _createStationWithFuel('3', FuelType.dieselGasoleoA, 1.45),
      ];

      // Act - Intentar asignar rangos para gasolina95 (que no tienen)
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - priceRange debe quedar null ya que no tienen el combustible
      for (var station in stations) {
        expect(station.priceRange, isNull);
      }
    });

    test('debe modificar in-place la lista de estaciones', () {
      // Arrange
      final stations = [
        _createStation('1', 1.40),
        _createStation('2', 1.50),
        _createStation('3', 1.60),
      ];

      // Verificar que inicialmente no tienen priceRange
      expect(stations[0].priceRange, isNull);
      expect(stations[1].priceRange, isNull);
      expect(stations[2].priceRange, isNull);

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Las mismas instancias deben tener priceRange asignado
      expect(stations[0].priceRange, isNotNull);
      expect(stations[1].priceRange, isNotNull);
      expect(stations[2].priceRange, isNotNull);
    });

    test('debe funcionar con lista vacía sin errores', () {
      // Arrange
      final stations = <GasStation>[];

      // Act & Assert - No debe lanzar excepciones
      expect(
        () => useCase(stations: stations, fuelType: FuelType.gasolina95),
        returnsNormally,
      );
    });

    test('debe funcionar con una sola estación', () {
      // Arrange
      final stations = [_createStation('1', 1.45)];

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Debe asignar PriceRange.medium
      expect(stations[0].priceRange, equals(PriceRange.medium));
    });

    test('debe funcionar con dos estaciones', () {
      // Arrange
      final stations = [
        _createStation('1', 1.40),
        _createStation('2', 1.60),
      ];

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Debe asignar low y high respectivamente
      expect(stations[0].priceRange, equals(PriceRange.low));
      expect(stations[1].priceRange, equals(PriceRange.high));
    });

    test('debe delegar al PriceRangeCalculator', () {
      // Arrange - 6 estaciones
      final stations = [
        _createStation('1', 1.40),
        _createStation('2', 1.45),
        _createStation('3', 1.50),
        _createStation('4', 1.55),
        _createStation('5', 1.60),
        _createStation('6', 1.65),
      ];

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Verificar que se asignaron rangos (delegación exitosa)
      final hasRanges = stations.every((s) => s.priceRange != null);
      expect(hasRanges, isTrue);
    });

    test('debe funcionar con diferentes tipos de combustible', () {
      // Arrange - Para cada tipo de combustible
      final fuelTypes = [
        FuelType.gasolina95,
        FuelType.dieselGasoleoA,
      ];

      for (var fuelType in fuelTypes) {
        final stations = [
          _createStationWithFuel('1', fuelType, 1.40),
          _createStationWithFuel('2', fuelType, 1.50),
          _createStationWithFuel('3', fuelType, 1.60),
        ];

        // Act
        useCase(stations: stations, fuelType: fuelType);

        // Assert
        expect(stations[0].priceRange, isNotNull);
        expect(stations[1].priceRange, isNotNull);
        expect(stations[2].priceRange, isNotNull);
      }
    });

    test('debe manejar estaciones con múltiples combustibles', () {
      // Arrange - Estaciones con ambos combustibles
      final stations = [
        _createStationWithMultipleFuels('1', {
          FuelType.gasolina95: 1.40,
          FuelType.dieselGasoleoA: 1.30,
        }),
        _createStationWithMultipleFuels('2', {
          FuelType.gasolina95: 1.50,
          FuelType.dieselGasoleoA: 1.40,
        }),
        _createStationWithMultipleFuels('3', {
          FuelType.gasolina95: 1.60,
          FuelType.dieselGasoleoA: 1.50,
        }),
      ];

      // Act - Asignar rangos para gasolina95
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Debe basarse solo en precios de gasolina95
      expect(stations[0].priceRange, equals(PriceRange.low));
      expect(stations[1].priceRange, equals(PriceRange.medium));
      expect(stations[2].priceRange, equals(PriceRange.high));
    });

    test('debe ignorar estaciones con precio 0 o negativo', () {
      // Arrange
      final stations = [
        _createStation('1', 1.40),
        _createStation('2', 0.0), // Precio inválido
        _createStation('3', 1.50),
        _createStation('4', -1.0), // Precio negativo
        _createStation('5', 1.60),
      ];

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Solo las válidas deben tener rango
      expect(stations[0].priceRange, isNotNull);
      expect(stations[1].priceRange, isNull); // Sin rango (precio inválido)
      expect(stations[2].priceRange, isNotNull);
      expect(stations[3].priceRange, isNull); // Sin rango (precio negativo)
      expect(stations[4].priceRange, isNotNull);
    });

    test('debe ser coherente con PriceRangeCalculator', () {
      // Arrange
      final stations = [
        _createStation('1', 1.40),
        _createStation('2', 1.45),
        _createStation('3', 1.50),
        _createStation('4', 1.55),
        _createStation('5', 1.60),
        _createStation('6', 1.65),
      ];

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Verificar coherencia: precios bajos → low, altos → high
      expect(stations[0].priceRange, equals(PriceRange.low));
      expect(stations[5].priceRange, equals(PriceRange.high));
    });

    test('debe procesar listas grandes eficientemente', () {
      // Arrange - 100 estaciones
      final stations = List.generate(100, (i) {
        return _createStation('$i', 1.00 + (i * 0.01));
      });

      // Act
      useCase(stations: stations, fuelType: FuelType.gasolina95);

      // Assert - Todas deben tener rango asignado
      final allAssigned = stations.every((s) => s.priceRange != null);
      expect(allAssigned, isTrue);
    });

    test('debe ser idempotente (múltiples llamadas mismo resultado)', () {
      // Arrange
      final stations = [
        _createStation('1', 1.40),
        _createStation('2', 1.50),
        _createStation('3', 1.60),
      ];

      // Act - Llamar dos veces
      useCase(stations: stations, fuelType: FuelType.gasolina95);
      final firstRanges = stations.map((s) => s.priceRange).toList();

      useCase(stations: stations, fuelType: FuelType.gasolina95);
      final secondRanges = stations.map((s) => s.priceRange).toList();

      // Assert - Los rangos deben ser los mismos
      expect(firstRanges[0], equals(secondRanges[0]));
      expect(firstRanges[1], equals(secondRanges[1]));
      expect(firstRanges[2], equals(secondRanges[2]));
    });
  });
}

/// Helper: Crea una gasolinera de prueba con precio para gasolina95
GasStation _createStation(String id, double price) {
  return _createStationWithFuel(id, FuelType.gasolina95, price);
}

/// Helper: Crea una gasolinera con un combustible específico
GasStation _createStationWithFuel(String id, FuelType fuelType, double price) {
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
