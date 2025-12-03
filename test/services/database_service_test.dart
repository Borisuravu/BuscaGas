import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

// NOTA: Para ejecutar estos tests en escritorio/CI, necesitas:
// 1. Agregar a pubspec.yaml en dev_dependencies:
//    sqflite_common_ffi: ^2.3.0
// 2. Descomentar las siguientes líneas:
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//
// void main() {
//   setUpAll(() {
//     sqfliteFfiInit();
//     databaseFactory = databaseFactoryFfi;
//   });
//
// Por ahora, estos tests solo funcionan en dispositivo/emulador Android

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseDataSource Tests', () {
    late DatabaseDataSource dbDataSource;

    setUp(() async {
      dbDataSource = DatabaseDataSource();
      await dbDataSource.clearAll();
    });

    tearDown(() async {
      await dbDataSource.clearAll();
    });

    test('Debe inicializar la base de datos sin errores', () async {
      final hasData = await dbDataSource.hasData();
      expect(hasData, false); // Debería estar vacía después de clearAll
    });

    test('Debe guardar y recuperar gasolineras', () async {
      final testStations = [
        GasStation(
          id: '1',
          name: 'Test Station 1',
          latitude: 40.4168,
          longitude: -3.7038,
          address: 'Calle Test 1',
          locality: 'Madrid',
          operator: 'Repsol',
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.459,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStation(
          id: '2',
          name: 'Test Station 2',
          latitude: 40.4200,
          longitude: -3.7050,
          address: 'Calle Test 2',
          locality: 'Madrid',
          operator: 'Cepsa',
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.389,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      await dbDataSource.insertBatch(testStations);

      final retrieved = await dbDataSource.getAllStations();
      expect(retrieved.length, 2);
      expect(retrieved[0].name, 'Test Station 1');
      expect(retrieved[1].name, 'Test Station 2');
    });

    test('Debe obtener gasolineras cercanas', () async {
      final testStations = [
        GasStation(
          id: '1',
          name: 'Cerca',
          latitude: 40.4168,
          longitude: -3.7038,
          address: 'Cerca',
          locality: 'Madrid',
          operator: 'Repsol',
          prices: [],
        ),
        GasStation(
          id: '2',
          name: 'Lejos',
          latitude: 41.3851,
          longitude: 2.1734,
          address: 'Lejos',
          locality: 'Barcelona',
          operator: 'Cepsa',
          prices: [],
        ),
      ];

      await dbDataSource.insertBatch(testStations);

      final nearby = await dbDataSource.getStationsByLocation(
        centerLat: 40.4168,
        centerLon: -3.7038,
        radiusKm: 10,
      );

      expect(nearby.length, 1);
      expect(nearby[0].name, 'Cerca');
    });

    test('Debe actualizar configuración', () async {
      await dbDataSource.updateSettings({
        'search_radius': 20,
        'preferred_fuel': FuelType.dieselGasoleoA.name,
        'dark_mode': 1,
      });

      final settings = await dbDataSource.getSettings();
      expect(settings?['search_radius'], 20);
      expect(settings?['preferred_fuel'], 'dieselGasoleoA');
      expect(settings?['dark_mode'], 1);
    });

    test('Debe verificar si hay datos en caché', () async {
      final hasDataBefore = await dbDataSource.hasData();
      expect(hasDataBefore, false); // No hay datos inicialmente

      // Guardar datos
      await dbDataSource.insertBatch([
        GasStation(
          id: '1',
          name: 'Test',
          latitude: 40.4168,
          longitude: -3.7038,
          address: '',
          locality: '',
          operator: '',
          prices: [],
        ),
      ]);

      final hasDataAfter = await dbDataSource.hasData();
      expect(hasDataAfter, true); // Ahora sí hay datos
    });
  });
}
