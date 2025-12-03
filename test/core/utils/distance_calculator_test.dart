import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/calculate_distance.dart';

void main() {
  group('DistanceCalculator', () {
    late CalculateDistanceUseCase calculator;

    setUp(() {
      calculator = CalculateDistanceUseCase();
    });

    test('debe calcular distancia Madrid-Barcelona correctamente', () {
      // Arrange - Coordenadas reales de Madrid y Barcelona
      const madridLat = 40.4168;
      const madridLon = -3.7038;
      const barcelonaLat = 41.3851;
      const barcelonaLon = 2.1734;
      const expectedDistance = 504.0; // km (valor aproximado)
      const tolerance = 5.0; // ±5 km de tolerancia

      // Act
      final distance = calculator(
        lat1: madridLat,
        lon1: madridLon,
        lat2: barcelonaLat,
        lon2: barcelonaLon,
      );

      // Assert
      expect(distance, greaterThan(expectedDistance - tolerance));
      expect(distance, lessThan(expectedDistance + tolerance));
    });

    test('debe retornar 0 para el mismo punto', () {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;

      // Act
      final distance = calculator(
        lat1: lat,
        lon1: lon,
        lat2: lat,
        lon2: lon,
      );

      // Assert
      expect(distance, equals(0.0));
    });

    test('debe calcular distancias cortas con precisión (<1 km)', () {
      // Arrange - Dos puntos separados por ~500 metros
      const lat1 = 40.4168;
      const lon1 = -3.7038;
      const lat2 = 40.4213; // ~500 metros al norte
      const lon2 = -3.7038;
      const expectedDistance = 0.5; // km
      const tolerance = 0.05; // ±50 metros

      // Act
      final distance = calculator(
        lat1: lat1,
        lon1: lon1,
        lat2: lat2,
        lon2: lon2,
      );

      // Assert
      expect(distance, greaterThan(expectedDistance - tolerance));
      expect(distance, lessThan(expectedDistance + tolerance));
    });

    test('debe manejar coordenadas en hemisferios opuestos', () {
      // Arrange - Nueva York y Sydney (hemisferios opuestos)
      const nyLat = 40.7128;
      const nyLon = -74.0060;
      const sydneyLat = -33.8688;
      const sydneyLon = 151.2093;

      // Act
      final distance = calculator(
        lat1: nyLat,
        lon1: nyLon,
        lat2: sydneyLat,
        lon2: sydneyLon,
      );

      // Assert - La distancia debe ser muy grande (>15000 km)
      expect(distance, greaterThan(15000));
      expect(distance, lessThan(20000));
    });

    test('debe calcular distancia independientemente del orden de puntos', () {
      // Arrange
      const lat1 = 40.4168;
      const lon1 = -3.7038;
      const lat2 = 41.3851;
      const lon2 = 2.1734;

      // Act
      final distance1 = calculator(
        lat1: lat1,
        lon1: lon1,
        lat2: lat2,
        lon2: lon2,
      );

      final distance2 = calculator(
        lat1: lat2,
        lon1: lon2,
        lat2: lat1,
        lon2: lon1,
      );

      // Assert - Las distancias deben ser iguales (conmutatividad)
      expect(distance1, equals(distance2));
    });

    test('debe manejar coordenadas en el ecuador', () {
      // Arrange - Dos puntos en el ecuador
      const lat1 = 0.0;
      const lon1 = 0.0;
      const lat2 = 0.0;
      const lon2 = 1.0; // ~111 km de diferencia en el ecuador

      // Act
      final distance = calculator(
        lat1: lat1,
        lon1: lon1,
        lat2: lat2,
        lon2: lon2,
      );

      // Assert
      expect(distance, greaterThan(100));
      expect(distance, lessThan(120));
    });

    test('debe manejar coordenadas límite (±90° lat, ±180° lon)', () {
      // Arrange - Polo Norte a Polo Sur
      const northPoleLat = 90.0;
      const northPoleLon = 0.0;
      const southPoleLat = -90.0;
      const southPoleLon = 0.0;
      const expectedDistance = 20015.0; // Aproximadamente medio meridiano

      // Act
      final distance = calculator(
        lat1: northPoleLat,
        lon1: northPoleLon,
        lat2: southPoleLat,
        lon2: southPoleLon,
      );

      // Assert
      expect(distance, greaterThan(expectedDistance - 100));
      expect(distance, lessThan(expectedDistance + 100));
    });

    test('debe tener precisión del ±2% en distancias >10 km', () {
      // Arrange - Valencia a Sevilla (~540 km real)
      const valenciaLat = 39.4699;
      const valenciaLon = -0.3763;
      const sevillaLat = 37.3891;
      const sevillaLon = -5.9845;
      const expectedDistance = 540.0;

      // Act
      final distance = calculator(
        lat1: valenciaLat,
        lon1: valenciaLon,
        lat2: sevillaLat,
        lon2: sevillaLon,
      );

      // Assert - Tolerancia del ±2%
      const tolerance = expectedDistance * 0.02;
      expect(distance, greaterThan(expectedDistance - tolerance));
      expect(distance, lessThan(expectedDistance + tolerance));
    });
  });
}
