import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

void main() {
  group('AppSettings Entity', () {
    test('debe crear instancia con valores por defecto', () {
      // Arrange & Act
      final settings = AppSettings();

      // Assert
      expect(settings.searchRadius, equals(10));
      expect(settings.preferredFuel, equals(FuelType.gasolina95));
      expect(settings.darkMode, equals(false));
      expect(settings.lastUpdateTimestamp, isNull);
    });

    test('debe crear instancia con valores personalizados', () {
      // Arrange
      final timestamp = DateTime.now();

      // Act
      final settings = AppSettings(
        searchRadius: 20,
        preferredFuel: FuelType.dieselGasoleoA,
        darkMode: true,
        lastUpdateTimestamp: timestamp,
      );

      // Assert
      expect(settings.searchRadius, equals(20));
      expect(settings.preferredFuel, equals(FuelType.dieselGasoleoA));
      expect(settings.darkMode, equals(true));
      expect(settings.lastUpdateTimestamp, equals(timestamp));
    });

    test('debe permitir modificar searchRadius', () {
      // Arrange
      final settings = AppSettings();

      // Act
      settings.searchRadius = 50;

      // Assert
      expect(settings.searchRadius, equals(50));
    });

    test('debe permitir modificar preferredFuel', () {
      // Arrange
      final settings = AppSettings();

      // Act
      settings.preferredFuel = FuelType.dieselGasoleoA;

      // Assert
      expect(settings.preferredFuel, equals(FuelType.dieselGasoleoA));
    });

    test('debe permitir modificar darkMode', () {
      // Arrange
      final settings = AppSettings();

      // Act
      settings.darkMode = true;

      // Assert
      expect(settings.darkMode, equals(true));
    });

    test('debe permitir modificar lastUpdateTimestamp', () {
      // Arrange
      final settings = AppSettings();
      final timestamp = DateTime.now();

      // Act
      settings.lastUpdateTimestamp = timestamp;

      // Assert
      expect(settings.lastUpdateTimestamp, equals(timestamp));
    });

    test('debe aceptar valores válidos de searchRadius (5, 10, 20, 50)', () {
      // Arrange
      final validRadii = [5, 10, 20, 50];

      // Act & Assert
      for (var radius in validRadii) {
        final settings = AppSettings(searchRadius: radius);
        expect(settings.searchRadius, equals(radius));
      }
    });

    test('debe aceptar todos los tipos de combustible válidos', () {
      // Arrange
      final validFuels = FuelType.values;

      // Act & Assert
      for (var fuel in validFuels) {
        final settings = AppSettings(preferredFuel: fuel);
        expect(settings.preferredFuel, equals(fuel));
      }
    });

    test('debe manejar timestamps en el pasado', () {
      // Arrange
      final pastTimestamp = DateTime.now().subtract(const Duration(days: 30));

      // Act
      final settings = AppSettings(lastUpdateTimestamp: pastTimestamp);

      // Assert
      expect(settings.lastUpdateTimestamp, equals(pastTimestamp));
      expect(settings.lastUpdateTimestamp!.isBefore(DateTime.now()), isTrue);
    });

    test('debe manejar timestamps en el futuro', () {
      // Arrange
      final futureTimestamp = DateTime.now().add(const Duration(days: 1));

      // Act
      final settings = AppSettings(lastUpdateTimestamp: futureTimestamp);

      // Assert
      expect(settings.lastUpdateTimestamp, equals(futureTimestamp));
      expect(settings.lastUpdateTimestamp!.isAfter(DateTime.now()), isTrue);
    });

    test('debe permitir crear múltiples instancias independientes', () {
      // Arrange & Act
      final settings1 = AppSettings(searchRadius: 10);
      final settings2 = AppSettings(searchRadius: 20);

      // Modificar settings1
      settings1.darkMode = true;

      // Assert - settings2 no debe verse afectado
      expect(settings1.darkMode, isTrue);
      expect(settings2.darkMode, isFalse);
      expect(settings1.searchRadius, equals(10));
      expect(settings2.searchRadius, equals(20));
    });

    test('debe mantener la mutabilidad de campos', () {
      // Arrange
      final settings = AppSettings(
        searchRadius: 10,
        preferredFuel: FuelType.gasolina95,
        darkMode: false,
      );

      // Act - Modificar todos los campos
      settings.searchRadius = 50;
      settings.preferredFuel = FuelType.dieselGasoleoA;
      settings.darkMode = true;
      settings.lastUpdateTimestamp = DateTime.now();

      // Assert
      expect(settings.searchRadius, equals(50));
      expect(settings.preferredFuel, equals(FuelType.dieselGasoleoA));
      expect(settings.darkMode, isTrue);
      expect(settings.lastUpdateTimestamp, isNotNull);
    });

    // NOTA: Los tests de save() y load() requieren mocks de DatabaseService
    // y se implementarán en los tests de integración, ya que son operaciones I/O
    test('save debe ser un método asíncrono', () {
      // Arrange
      final settings = AppSettings();

      // Act
      final saveResult = settings.save();

      // Assert - save() debe retornar un Future<void>
      expect(saveResult, isA<Future<void>>());
    });

    test('load debe ser un método estático asíncrono', () {
      // Arrange & Act
      final loadResult = AppSettings.load();

      // Assert - load() debe retornar un Future<AppSettings>
      expect(loadResult, isA<Future<AppSettings>>());
    });

    test('debe manejar cambios frecuentes de configuración', () {
      // Arrange
      final settings = AppSettings();

      // Act - Simular usuario cambiando configuración múltiples veces
      settings.searchRadius = 5;
      settings.searchRadius = 10;
      settings.searchRadius = 20;
      settings.preferredFuel = FuelType.dieselGasoleoA;
      settings.preferredFuel = FuelType.gasolina95;
      settings.darkMode = true;
      settings.darkMode = false;
      settings.darkMode = true;

      // Assert - Debe mantener los últimos valores
      expect(settings.searchRadius, equals(20));
      expect(settings.preferredFuel, equals(FuelType.gasolina95));
      expect(settings.darkMode, isTrue);
    });
  });
}
