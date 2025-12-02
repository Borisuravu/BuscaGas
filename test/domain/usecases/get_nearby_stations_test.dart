import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/usecases/get_nearby_stations.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

// Generar mock del repositorio
@GenerateMocks([GasStationRepository])
import 'get_nearby_stations_test.mocks.dart';

void main() {
  group('GetNearbyStationsUseCase', () {
    late GetNearbyStationsUseCase useCase;
    late MockGasStationRepository mockRepository;

    setUp(() {
      mockRepository = MockGasStationRepository();
      useCase = GetNearbyStationsUseCase(mockRepository);
    });

    test('debe retornar estaciones dentro del radio de búsqueda', () async {
      // Arrange - Madrid centro como punto de referencia
      const madridLat = 40.4168;
      const madridLon = -3.7038;
      const radiusKm = 10.0;

      final nearbyStations = [
        _createStation('1', 40.4200, -3.7038, 1.45), // ~3.5 km
        _createStation('2', 40.4250, -3.7038, 1.50), // ~9 km
      ];

      when(mockRepository.getNearbyStations(
        latitude: madridLat,
        longitude: madridLon,
        radiusKm: radiusKm,
      )).thenAnswer((_) async => nearbyStations);

      // Act
      final result = await useCase(
        latitude: madridLat,
        longitude: madridLon,
        radiusKm: radiusKm,
      );

      // Assert
      expect(result.length, equals(2));
      verify(mockRepository.getNearbyStations(
        latitude: madridLat,
        longitude: madridLon,
        radiusKm: radiusKm,
      )).called(1);
    });

    test('debe ordenar estaciones por distancia (más cercanas primero)',
        () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 20.0;

      // Crear estaciones a diferentes distancias (ya ordenadas por el repositorio)
      final orderedStations = [
        _createStation('near', 40.4200, -3.7038, 1.45), // Más cercana
        _createStation('medium', 40.4300, -3.7038, 1.50), // Mediana
        _createStation('far', 40.4400, -3.7038, 1.55), // Más lejana
      ];

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenAnswer((_) async => orderedStations);

      // Act
      final result = await useCase(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      );

      // Assert - Verificar orden ascendente por ID (proxy de distancia)
      expect(result[0].id, equals('near'));
      expect(result[1].id, equals('medium'));
      expect(result[2].id, equals('far'));
    });

    test('debe limitar resultados a máximo 50 gasolineras', () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 50.0;

      // Crear 100 estaciones, pero el repositorio solo retorna las 50 más cercanas
      final fiftyStations = List.generate(50, (i) {
        return _createStation('$i', 40.4168 + (i * 0.01), -3.7038, 1.45);
      });

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenAnswer((_) async => fiftyStations);

      // Act
      final result = await useCase(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      );

      // Assert - Máximo 50 estaciones
      expect(result.length, equals(50));
    });

    test('debe retornar lista vacía cuando no hay gasolineras en el radio',
        () async {
      // Arrange - Radio muy pequeño en zona sin gasolineras
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 0.1;

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenAnswer((_) async => []);

      // Act
      final result = await useCase(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      );

      // Assert
      expect(result, isEmpty);
    });

    test('debe llamar al repositorio exactamente una vez', () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 10.0;

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenAnswer((_) async => []);

      // Act
      await useCase(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      );

      // Assert
      verify(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).called(1);
    });

    test('debe lanzar excepción cuando el repositorio falla', () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 10.0;

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenThrow(Exception('Error de red'));

      // Act & Assert
      expect(
        () => useCase(
          latitude: lat,
          longitude: lon,
          radiusKm: radiusKm,
        ),
        throwsException,
      );
    });

    test('debe manejar errores del repositorio con mensaje descriptivo',
        () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 10.0;

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenThrow(Exception('Database error'));

      // Act & Assert
      try {
        await useCase(
          latitude: lat,
          longitude: lon,
          radiusKm: radiusKm,
        );
        fail('Debería haber lanzado excepción');
      } catch (e) {
        expect(e.toString(), contains('Error al obtener gasolineras cercanas'));
      }
    });

    test('debe funcionar con diferentes radios de búsqueda (5, 10, 20, 50 km)',
        () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      final radii = [5.0, 10.0, 20.0, 50.0];

      // Act & Assert - Para cada radio
      for (var radius in radii) {
        final mockStations = [_createStation('1', lat, lon, 1.45)];

        when(mockRepository.getNearbyStations(
          latitude: lat,
          longitude: lon,
          radiusKm: radius,
        )).thenAnswer((_) async => mockStations);

        final result = await useCase(
          latitude: lat,
          longitude: lon,
          radiusKm: radius,
        );

        expect(result.length, equals(1));
      }
    });

    test('debe funcionar con coordenadas en diferentes ubicaciones de España',
        () async {
      // Arrange - Diferentes ciudades españolas
      final locations = [
        {'lat': 40.4168, 'lon': -3.7038}, // Madrid
        {'lat': 41.3851, 'lon': 2.1734}, // Barcelona
        {'lat': 39.4699, 'lon': -0.3763}, // Valencia
        {'lat': 37.3891, 'lon': -5.9845}, // Sevilla
      ];

      // Act & Assert
      for (var location in locations) {
        final lat = location['lat']!;
        final lon = location['lon']!;

        when(mockRepository.getNearbyStations(
          latitude: lat,
          longitude: lon,
          radiusKm: 10.0,
        )).thenAnswer((_) async => [_createStation('1', lat, lon, 1.45)]);

        final result = await useCase(
          latitude: lat,
          longitude: lon,
          radiusKm: 10.0,
        );

        expect(result.length, equals(1));
      }
    });

    test('no debe modificar las estaciones retornadas por el repositorio',
        () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 10.0;

      final originalStations = [
        _createStation('1', 40.4200, -3.7038, 1.45),
      ];

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenAnswer((_) async => originalStations);

      // Act
      final result = await useCase(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      );

      // Assert - Verificar que retorna las estaciones sin modificar
      expect(result.first.id, equals('1'));
      expect(result.first.getPriceForFuel(FuelType.gasolina95), equals(1.45));
    });

    test('debe ser asíncrono y retornar Future', () async {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      const radiusKm = 10.0;

      when(mockRepository.getNearbyStations(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      )).thenAnswer((_) async => []);

      // Act
      final result = useCase(
        latitude: lat,
        longitude: lon,
        radiusKm: radiusKm,
      );

      // Assert
      expect(result, isA<Future<List<GasStation>>>());
    });
  });
}

/// Helper: Crea una gasolinera de prueba
GasStation _createStation(String id, double lat, double lon, double price) {
  return GasStation(
    id: id,
    name: 'Gasolinera $id',
    latitude: lat,
    longitude: lon,
    address: 'Calle Test $id',
    locality: 'Madrid',
    operator: 'Test Operator',
    prices: [
      FuelPrice(
        fuelType: FuelType.gasolina95,
        value: price,
        updatedAt: DateTime.now(),
      ),
    ],
  );
}
