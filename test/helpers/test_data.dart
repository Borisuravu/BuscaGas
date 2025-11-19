import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/data/models/gas_station_model.dart';

/// Datos de prueba reutilizables para tests

// ==================== ENTIDADES DE PRUEBA ====================

final testStation1 = GasStation(
  id: '1',
  name: 'Repsol Madrid',
  latitude: 40.4168,
  longitude: -3.7038,
  address: 'Calle Mayor 1',
  locality: 'Madrid',
  operator: 'Repsol',
  prices: [
    FuelPrice(
      fuelType: FuelType.gasolina95,
      value: 1.459,
      updatedAt: DateTime(2024, 1, 15),
    ),
  ],
);

final testStation2 = GasStation(
  id: '2',
  name: 'Cepsa Barcelona',
  latitude: 41.3851,
  longitude: 2.1734,
  address: 'Rambla Catalunya 10',
  locality: 'Barcelona',
  operator: 'Cepsa',
  prices: [
    FuelPrice(
      fuelType: FuelType.dieselGasoleoA,
      value: 1.389,
      updatedAt: DateTime(2024, 1, 15),
    ),
  ],
);

final testStation3 = GasStation(
  id: '3',
  name: 'Shell Valencia',
  latitude: 39.4699,
  longitude: -0.3763,
  address: 'Avenida del Puerto 50',
  locality: 'Valencia',
  operator: 'Shell',
  prices: [
    FuelPrice(
      fuelType: FuelType.gasolina95,
      value: 1.429,
      updatedAt: DateTime(2024, 1, 15),
    ),
    FuelPrice(
      fuelType: FuelType.dieselGasoleoA,
      value: 1.359,
      updatedAt: DateTime(2024, 1, 15),
    ),
  ],
);

// ==================== MODELOS DE PRUEBA ====================

final testModel1 = GasStationModel.fromEntity(testStation1);
final testModel2 = GasStationModel.fromEntity(testStation2);
final testModel3 = GasStationModel.fromEntity(testStation3);

// ==================== LISTAS DE PRUEBA ====================

final testStations = [testStation1, testStation2, testStation3];
final testModels = [testModel1, testModel2, testModel3];
