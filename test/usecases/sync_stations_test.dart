import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/usecases/sync_stations.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

@GenerateMocks([GasStationRepository])
import 'sync_stations_test.mocks.dart';

void main() {
  group('SyncStationsUseCase', () {
    late SyncStationsUseCase useCase;
    late MockGasStationRepository mockRepository;

    setUp(() {
      mockRepository = MockGasStationRepository();
      useCase = SyncStationsUseCase(mockRepository);
    });

    test('debe sincronizar gasolineras correctamente', () async {
      // Arrange
      final mockStations = List.generate(
          100,
          (i) => GasStation(
                id: '$i',
                name: 'Gasolinera $i',
                latitude: 40.0,
                longitude: -3.0,
              ));

      when(mockRepository.fetchRemoteStations())
          .thenAnswer((_) async => mockStations);
      when(mockRepository.updateCache(any)).thenAnswer((_) async => {});

      // Act
      final count = await useCase();

      // Assert
      expect(count, 100);
      verify(mockRepository.fetchRemoteStations()).called(1);
      verify(mockRepository.updateCache(mockStations)).called(1);
    });

    test('debe lanzar excepción si API retorna lista vacía', () async {
      // Arrange
      when(mockRepository.fetchRemoteStations()).thenAnswer((_) async => []);

      // Act & Assert
      expect(() => useCase(), throwsException);
    });

    test('debe lanzar excepción si falla la descarga', () async {
      // Arrange
      when(mockRepository.fetchRemoteStations())
          .thenThrow(Exception('Error de red'));

      // Act & Assert
      expect(() => useCase(), throwsException);
    });
  });
}
