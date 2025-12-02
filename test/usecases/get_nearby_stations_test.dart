import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/usecases/get_nearby_stations.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

// Generar mock con build_runner
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

    test('debe retornar lista de gasolineras cercanas', () async {
      // Arrange
      final mockStations = [
        GasStation(
          id: '1',
          name: 'Repsol Madrid',
          latitude: 40.4168,
          longitude: -3.7038,
          address: 'Calle Mayor 1',
          locality: 'Madrid',
          operator: 'Repsol',
        ),
      ];

      when(mockRepository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      )).thenAnswer((_) async => mockStations);

      // Act
      final result = await useCase(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      );

      // Assert
      expect(result, mockStations);
      expect(result.length, 1);
      expect(result.first.name, 'Repsol Madrid');

      verify(mockRepository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      )).called(1);
    });

    test('debe lanzar excepción si el repositorio falla', () async {
      // Arrange
      when(mockRepository.getNearbyStations(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        radiusKm: anyNamed('radiusKm'),
      )).thenThrow(Exception('Error de red'));

      // Act & Assert
      expect(
        () => useCase(latitude: 40.4168, longitude: -3.7038, radiusKm: 10.0),
        throwsException,
      );
    });
  });
}
