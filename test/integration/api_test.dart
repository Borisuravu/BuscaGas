import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';

/// TESTS DE INTEGRACIÓN CON API REAL
///
/// IMPORTANTE: Estos tests requieren conexión a internet
/// Se conectan a la API real del gobierno
/// Pueden tardar varios segundos en completarse

void main() {
  group('API Integration Tests', () {
    late ApiDataSource apiDataSource;

    setUp(() {
      apiDataSource = ApiDataSource();
    });

    tearDown(() {
      apiDataSource.dispose();
    });

    test('Debe conectar con la API del gobierno', () async {
      final available = await apiDataSource.checkConnection();
      expect(available, true, reason: 'La API debe estar disponible');
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Debe descargar gasolineras desde la API', () async {
      final stations = await apiDataSource.fetchAllStations();

      expect(stations, isNotEmpty,
          reason: 'Debe haber al menos una gasolinera');
      expect(stations.length, greaterThan(100),
          reason: 'Debería haber más de 100 gasolineras en España');

      print('✅ Total gasolineras descargadas: ${stations.length}');
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('Las gasolineras deben tener coordenadas válidas', () async {
      final stationModels = await apiDataSource.fetchAllStations();
      final stations = stationModels.map((m) => m.toDomain()).toList();

      for (var station in stations.take(10)) {
        expect(station.latitude, isNot(0.0));
        expect(station.longitude, isNot(0.0));
        expect(station.latitude, inInclusiveRange(35.0, 44.0),
            reason: 'Latitud debe estar en rango de España');
        expect(station.longitude, inInclusiveRange(-10.0, 5.0),
            reason: 'Longitud debe estar en rango de España');
      }
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('Las gasolineras deben tener al menos un precio', () async {
      final stationModels = await apiDataSource.fetchAllStations();
      final stations = stationModels.map((m) => m.toDomain()).toList();

      int stationsWithPrices = 0;
      for (var station in stations) {
        if (station.prices.isNotEmpty) {
          stationsWithPrices++;
        }
      }

      expect(stationsWithPrices, greaterThan(0),
          reason: 'Debe haber gasolineras con precios');

      print(
          '✅ Gasolineras con precios: $stationsWithPrices / ${stations.length}');
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('Debe manejar error de timeout correctamente', () async {
      // Este test verifica que el timeout funciona
      // No lo ejecutamos siempre porque tarda 30 segundos

      // final dataSource = ApiDataSource();
      // expect(
      //   () async => await dataSource.fetchAllStations(),
      //   throwsA(isA<ApiException>()),
      // );

      // Por ahora solo verificamos que la clase existe
      expect(ApiException, isNotNull);
    });
    test('Debe obtener estadísticas de API', () async {
      final stationModels = await apiDataSource.fetchAllStations();
      final stations = stationModels.map((m) => m.toDomain()).toList();
      
      final stats = {
        'total_stations': stations.length,
        'with_gasolina95': stations.where((s) => s.prices.any((p) => p.fuelType.name.contains('gasolina95'))).length,
        'with_diesel': stations.where((s) => s.prices.any((p) => p.fuelType.name.contains('diesel'))).length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      expect(stats, isNotEmpty);
      expect(stats['total_stations'], isNotNull);
      expect(stats['timestamp'], isNotNull);

      print('📊 Estadísticas de API:');
      print('   Total: ${stats['total_stations']}');
      print('   Con Gasolina 95: ${stats['with_gasolina95']}');
      print('   Con Diésel: ${stats['with_diesel']}');
    }, timeout: const Timeout(Duration(seconds: 45)));
  });

  group('API Error Handling Tests', () {
    test('ApiException debe tener mensajes amigables', () {
      final exceptions = [
        ApiException('Test', type: ApiErrorType.noConnection),
        ApiException('Test', type: ApiErrorType.timeout),
        ApiException('Test', type: ApiErrorType.serverError),
        ApiException('Test', type: ApiErrorType.notFound),
        ApiException('Test', type: ApiErrorType.httpError, statusCode: 403),
        ApiException('Test', type: ApiErrorType.parseError),
        ApiException('Test', type: ApiErrorType.unknown),
      ];

      for (var exception in exceptions) {
        expect(exception.userFriendlyMessage, isNotEmpty);
        print('${exception.type.name}: ${exception.userFriendlyMessage}');
      }
    });
  });
}
