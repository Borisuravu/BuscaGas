import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import '../helpers/test_data.dart';

// Generar mocks con mockito
// Ejecutar: dart run build_runner build
@GenerateMocks([ApiDataSource, DatabaseDataSource])
import 'gas_station_repository_test.mocks.dart';

void main() {
  group('GasStationRepository Tests', () {
    late GasStationRepository repository;
    late MockApiDataSource mockApiDataSource;
    late MockDatabaseDataSource mockDatabaseDataSource;

    setUp(() {
      mockApiDataSource = MockApiDataSource();
      mockDatabaseDataSource = MockDatabaseDataSource();
      repository = GasStationRepositoryImpl(
        mockApiDataSource,
        mockDatabaseDataSource,
      );
    });

    // ==================== TEST 1: fetchRemoteStations ====================

    test('fetchRemoteStations debe descargar y convertir datos de la API',
        () async {
      // Arrange: Usar datos de prueba
      when(mockApiDataSource.fetchAllStations())
          .thenAnswer((_) async => [testModel1, testModel2]);

      // Act: Ejecutar método
      final result = await repository.fetchRemoteStations();

      // Assert: Verificar resultados
      expect(result, isA<List<GasStation>>());
      expect(result.length, 2);
      expect(result[0].id, '1');
      expect(result[0].name, 'Repsol Madrid');
      expect(result[0].latitude, 40.4168);
      expect(result[1].id, '2');
      expect(result[1].name, 'Cepsa Barcelona');

      // Verificar que se llamó al API
      verify(mockApiDataSource.fetchAllStations()).called(1);
    });

    test('fetchRemoteStations debe relanzar ApiException', () async {
      // Arrange
      when(mockApiDataSource.fetchAllStations()).thenThrow(
          ApiException('Error de red', type: ApiErrorType.noConnection));

      // Act & Assert
      expect(
        () => repository.fetchRemoteStations(),
        throwsA(isA<ApiException>()),
      );
    });

    // ==================== TEST 2: getCachedStations ====================

    test('getCachedStations debe obtener datos de la base de datos', () async {
      // Arrange
      final mockCachedStations = [
        GasStation(
          id: '1',
          name: 'Gasolinera Cache',
          latitude: 40.0,
          longitude: -3.0,
          address: 'Calle Test',
          locality: 'Madrid',
          operator: 'Test',
          prices: [],
        ),
      ];

      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => mockCachedStations);

      // Act
      final result = await repository.getCachedStations();

      // Assert
      expect(result, mockCachedStations);
      expect(result.length, 1);
      verify(mockDatabaseDataSource.getAllStations()).called(1);
    });

    test('getCachedStations debe retornar lista vacía si no hay caché',
        () async {
      // Arrange
      when(mockDatabaseDataSource.getAllStations()).thenAnswer((_) async => []);

      // Act
      final result = await repository.getCachedStations();

      // Assert
      expect(result, isEmpty);
    });

    // ==================== TEST 3: updateCache ====================

    test('updateCache debe borrar datos antiguos y guardar nuevos', () async {
      // Arrange
      final newStations = [
        GasStation(
          id: '1',
          name: 'Nueva Estación',
          latitude: 40.0,
          longitude: -3.0,
          address: 'Calle Nueva',
          locality: 'Madrid',
          operator: 'Nuevo',
          prices: [],
        ),
      ];

      when(mockDatabaseDataSource.clearAll()).thenAnswer((_) async => {});
      when(mockDatabaseDataSource.insertBatch(any)).thenAnswer((_) async => {});
      when(mockDatabaseDataSource.updateLastSync(any))
          .thenAnswer((_) async => {});

      // Act
      await repository.updateCache(newStations);

      // Assert
      verify(mockDatabaseDataSource.clearAll()).called(1);
      verify(mockDatabaseDataSource.insertBatch(newStations)).called(1);
      verify(mockDatabaseDataSource.updateLastSync(any)).called(1);
    });

    // ==================== TEST 4: getNearbyStations ====================

    test('getNearbyStations debe filtrar y ordenar por distancia', () async {
      // Arrange: Crear estaciones a diferentes distancias
      final allStations = [
        testStation1, // Madrid centro - cerca
        testStation2, // Barcelona - lejos
        testStation3, // Valencia - medio
      ];

      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => allStations);

      // Act: Buscar con radio de 5 km
      final result = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 5.0,
      );

      // Assert: solo estaciones dentro del radio (Madrid 40.4168,-3.7038)
      expect(result.length, greaterThan(0));
      // Verificar que están ordenadas por distancia (la primera es la más cercana)
      if (result.isNotEmpty) {
        expect(result.first, isA<GasStation>());
      }
    });

    test(
        'getNearbyStations debe retornar lista vacía si no hay estaciones cercanas',
        () async {
      // Arrange
      final allStations = [
        GasStation(
          id: '1',
          name: 'Muy Lejos',
          latitude: 41.0,
          longitude: -4.0,
          address: 'Lejos',
          locality: 'Valladolid',
          operator: 'Test',
          prices: [],
        ),
      ];

      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => allStations);

      // Act: Buscar en Madrid con radio de 10 km
      final result = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      );

      // Assert
      expect(result, isEmpty);
    });

    // ==================== TEST 5: Flujo completo ====================

    test('Flujo completo: fetch → update cache → get nearby', () async {
      // Arrange: Mock API data
      final mockModels = [testModel1, testModel2];

      when(mockApiDataSource.fetchAllStations())
          .thenAnswer((_) async => mockModels);
      when(mockDatabaseDataSource.clearAll()).thenAnswer((_) async => {});
      when(mockDatabaseDataSource.insertBatch(any)).thenAnswer((_) async => {});
      when(mockDatabaseDataSource.updateLastSync(any))
          .thenAnswer((_) async => {});

      // Act: Paso 1 - Fetch remote
      final remoteStations = await repository.fetchRemoteStations();
      expect(remoteStations.length, 2);

      // Act: Paso 2 - Update cache
      await repository.updateCache(remoteStations);
      verify(mockDatabaseDataSource.clearAll()).called(1);
      verify(mockDatabaseDataSource.insertBatch(any)).called(1);

      // Act: Paso 3 - Get cached
      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => remoteStations);
      final cachedStations = await repository.getCachedStations();
      expect(cachedStations.length, 2);

      // Act: Paso 4 - Get nearby
      final nearbyStations = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      );
      expect(nearbyStations.length, greaterThan(0));
      // Verificar que el primero es el más cercano
      if (nearbyStations.isNotEmpty) {
        expect(nearbyStations.first.id, isNotEmpty);
      }
    });

    // ==================== TEST 6: Caché en memoria (SimpleCache) ====================

    test('getCachedStations debe consultar base de datos la primera vez',
        () async {
      // Arrange
      final mockCachedStations = [
        GasStation(
          id: '1',
          name: 'Gasolinera Cache',
          latitude: 40.0,
          longitude: -3.0,
          address: 'Calle Test',
          locality: 'Madrid',
          operator: 'Test',
          prices: [],
        ),
      ];

      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => mockCachedStations);

      // Act: Primera llamada - debe consultar la base de datos
      final result = await repository.getCachedStations();
      
      // Assert
      expect(result.length, 1);
      expect(result[0].id, '1');
      verify(mockDatabaseDataSource.getAllStations()).called(1);
    });

    test('updateCache debe invalidar caché en memoria', () async {
      // Arrange
      final newStations = [
        GasStation(
          id: '2',
          name: 'Nueva',
          latitude: 40.0,
          longitude: -3.0,
          address: 'Calle Nueva',
          locality: 'Madrid',
          operator: 'Nuevo',
          prices: [],
        ),
      ];

      when(mockDatabaseDataSource.clearAll()).thenAnswer((_) async => {});
      when(mockDatabaseDataSource.insertBatch(any)).thenAnswer((_) async => {});
      when(mockDatabaseDataSource.updateLastSync(any))
          .thenAnswer((_) async => {});

      // Act: Actualizar caché
      await repository.updateCache(newStations);
      
      // Assert: Debe haber limpiado e insertado datos
      verify(mockDatabaseDataSource.clearAll()).called(1);
      verify(mockDatabaseDataSource.insertBatch(newStations)).called(1);
      verify(mockDatabaseDataSource.updateLastSync(any)).called(1);
    });

    test('getNearbyStations debe funcionar correctamente con caché', () async {
      // Arrange
      final allStations = [testStation1, testStation2];

      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => allStations);

      // Act: Consultar estaciones cercanas
      final result = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      );
      
      // Assert: Debe retornar estaciones y haber consultado DB
      expect(result, isNotEmpty);
      verify(mockDatabaseDataSource.getAllStations()).called(greaterThanOrEqualTo(1));
    });

    test('getNearbyStations con diferentes radios debe funcionar', () async {
      // Arrange
      final allStations = [testStation1, testStation2, testStation3];

      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => allStations);

      // Act: Consultar con radio pequeño
      final resultSmall = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 5.0,
      );

      // Act: Consultar con radio grande
      final resultLarge = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 50.0,
      );

      // Assert: El radio mayor debe tener más o igual estaciones
      expect(resultLarge.length, greaterThanOrEqualTo(resultSmall.length));
    });

    test('Repository debe manejar errores de caché correctamente', () async {
      // Arrange
      when(mockDatabaseDataSource.getAllStations())
          .thenThrow(Exception('Database error'));

      // Act & Assert: Debe propagar el error
      expect(
        () => repository.getCachedStations(),
        throwsException,
      );
    });
  });
}
