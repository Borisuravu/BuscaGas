import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/calculate_distance.dart';

void main() {
  group('CalculateDistanceUseCase', () {
    late CalculateDistanceUseCase useCase;

    setUp(() {
      useCase = CalculateDistanceUseCase();
    });

    test('debe calcular distancia entre Madrid y Barcelona', () {
      // Arrange: Coordenadas reales
      const madridLat = 40.4168;
      const madridLon = -3.7038;
      const barcelonaLat = 41.3851;
      const barcelonaLon = 2.1734;

      // Act
      final distance = useCase(
        lat1: madridLat,
        lon1: madridLon,
        lat2: barcelonaLat,
        lon2: barcelonaLon,
      );

      // Assert: La distancia real es ~504 km
      expect(distance, greaterThan(500));
      expect(distance, lessThan(510));
    });

    test('debe retornar 0 para la misma ubicación', () {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;

      // Act
      final distance = useCase(
        lat1: lat,
        lon1: lon,
        lat2: lat,
        lon2: lon,
      );

      // Assert
      expect(distance, 0.0);
    });

    test('debe calcular distancia pequeña correctamente', () {
      // Arrange: Dos puntos muy cercanos (~1 km)
      const lat1 = 40.4168;
      const lon1 = -3.7038;
      const lat2 = 40.4268; // ~1 km al norte
      const lon2 = -3.7038;

      // Act
      final distance = useCase(
        lat1: lat1,
        lon1: lon1,
        lat2: lat2,
        lon2: lon2,
      );

      // Assert
      expect(distance, greaterThan(0.9));
      expect(distance, lessThan(1.2));
    });
  });
}
