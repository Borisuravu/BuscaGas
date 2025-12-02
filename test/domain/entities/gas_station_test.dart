import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/price_range.dart';

void main() {
  group('GasStation Entity', () {
    test('debe crear instancia válida con todos los campos requeridos', () {
      // Arrange & Act
      final station = GasStation(
        id: 'test_001',
        name: 'Repsol Test',
        latitude: 40.4168,
        longitude: -3.7038,
        address: 'Calle Gran Vía, 1',
        locality: 'Madrid',
        operator: 'Repsol',
        prices: [
          FuelPrice(
            fuelType: FuelType.gasolina95,
            value: 1.459,
            updatedAt: DateTime.now(),
          ),
        ],
      );

      // Assert - No debe lanzar excepciones
      expect(station, isNotNull);
      expect(station.id, equals('test_001'));
      expect(station.name, equals('Repsol Test'));
      expect(station.latitude, equals(40.4168));
      expect(station.longitude, equals(-3.7038));
    });

    test('debe retornar precio correcto para combustible específico', () {
      // Arrange
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
        prices: [
          FuelPrice(
            fuelType: FuelType.gasolina95,
            value: 1.459,
            updatedAt: DateTime.now(),
          ),
          FuelPrice(
            fuelType: FuelType.dieselGasoleoA,
            value: 1.329,
            updatedAt: DateTime.now(),
          ),
        ],
      );

      // Act
      final gasolinaPrice = station.getPriceForFuel(FuelType.gasolina95);
      final dieselPrice = station.getPriceForFuel(FuelType.dieselGasoleoA);

      // Assert
      expect(gasolinaPrice, equals(1.459));
      expect(dieselPrice, equals(1.329));
    });

    test('debe retornar null para combustible no disponible', () {
      // Arrange
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
        prices: [
          FuelPrice(
            fuelType: FuelType.gasolina95,
            value: 1.459,
            updatedAt: DateTime.now(),
          ),
        ],
      );

      // Act
      final dieselPrice = station.getPriceForFuel(FuelType.dieselGasoleoA);

      // Assert
      expect(dieselPrice, isNull);
    });

    test('debe calcular correctamente si está dentro del radio', () {
      // Arrange - Gasolinera en Madrid centro
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.4168,
        longitude: -3.7038,
      );

      // Act & Assert - Punto cercano (~1 km)
      final isNear = station.isWithinRadius(40.4200, -3.7038, 2.0);
      expect(isNear, isTrue);

      // Act & Assert - Punto lejano (~500 km)
      final isFar = station.isWithinRadius(41.3851, 2.1734, 10.0);
      expect(isFar, isFalse);
    });

    test('debe calcular distancia a cero para el mismo punto', () {
      // Arrange
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.4168,
        longitude: -3.7038,
      );

      // Act
      final isWithin = station.isWithinRadius(40.4168, -3.7038, 0.1);

      // Assert - Mismo punto debe estar dentro de cualquier radio
      expect(isWithin, isTrue);
    });

    test('debe permitir asignar priceRange', () {
      // Arrange
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
      );

      // Act
      station.priceRange = PriceRange.low;

      // Assert
      expect(station.priceRange, equals(PriceRange.low));
    });

    test('debe permitir asignar distance', () {
      // Arrange
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
      );

      // Act
      station.distance = 5.5;

      // Assert
      expect(station.distance, equals(5.5));
    });

    test('debe crear instancia con valores por defecto para campos opcionales',
        () {
      // Arrange & Act - Sin especificar address, locality, operator, prices
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
      );

      // Assert
      expect(station.address, equals(''));
      expect(station.locality, equals(''));
      expect(station.operator, equals(''));
      expect(station.prices, isEmpty);
      expect(station.distance, isNull);
      expect(station.priceRange, isNull);
    });

    test('debe manejar lista vacía de precios sin errores', () {
      // Arrange
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
        prices: [],
      );

      // Act
      final price = station.getPriceForFuel(FuelType.gasolina95);

      // Assert
      expect(price, isNull);
    });

    test('debe calcular distancia correctamente (método interno)', () {
      // Arrange - Gasolinera en Madrid
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.4168,
        longitude: -3.7038,
      );

      // Act - Barcelona está a ~504 km de Madrid
      final isWithin500km = station.isWithinRadius(41.3851, 2.1734, 510.0);
      final isWithin100km = station.isWithinRadius(41.3851, 2.1734, 100.0);

      // Assert
      expect(isWithin500km, isTrue); // 504 km < 510 km
      expect(isWithin100km, isFalse); // 504 km > 100 km
    });

    test('debe manejar múltiples precios del mismo combustible', () {
      // Arrange - Esto no debería pasar en producción, pero test de robustez
      final now = DateTime.now();
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
        prices: [
          FuelPrice(
            fuelType: FuelType.gasolina95,
            value: 1.459,
            updatedAt: now,
          ),
          FuelPrice(
            fuelType: FuelType.gasolina95,
            value: 1.479, // Precio duplicado (error)
            updatedAt: now.add(const Duration(hours: 1)),
          ),
        ],
      );

      // Act - firstWhere retorna el primero
      final price = station.getPriceForFuel(FuelType.gasolina95);

      // Assert - Debe retornar el primer precio encontrado
      expect(price, equals(1.459));
    });

    test('priceRange debe poder ser null inicialmente', () {
      // Arrange & Act
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
      );

      // Assert
      expect(station.priceRange, isNull);
    });

    test('distance debe poder ser null inicialmente', () {
      // Arrange & Act
      final station = GasStation(
        id: 'test_001',
        name: 'Test Station',
        latitude: 40.0,
        longitude: -3.0,
      );

      // Assert
      expect(station.distance, isNull);
    });

    test('debe manejar coordenadas límite válidas', () {
      // Arrange & Act - Coordenadas en límites de lat/lon
      final stationNorthPole = GasStation(
        id: 'north',
        name: 'North Pole Station',
        latitude: 90.0,
        longitude: 0.0,
      );

      final stationSouthPole = GasStation(
        id: 'south',
        name: 'South Pole Station',
        latitude: -90.0,
        longitude: 0.0,
      );

      final stationDateLine = GasStation(
        id: 'dateline',
        name: 'Dateline Station',
        latitude: 0.0,
        longitude: 180.0,
      );

      // Assert - No debe lanzar excepciones
      expect(stationNorthPole, isNotNull);
      expect(stationSouthPole, isNotNull);
      expect(stationDateLine, isNotNull);
    });
  });
}
