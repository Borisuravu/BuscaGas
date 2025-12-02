/// Fuente de datos local: Base de datos SQLite
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class DatabaseDataSource {
  static final DatabaseDataSource _instance = DatabaseDataSource._internal();
  static Database? _database;

  factory DatabaseDataSource() => _instance;

  DatabaseDataSource._internal();

  /// Obtener instancia de la base de datos (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializar base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'buscagas.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Crear esquema de base de datos
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de gasolineras
    await db.execute('''
      CREATE TABLE gas_stations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT,
        locality TEXT,
        operator TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Índice para búsquedas geográficas
    await db.execute('''
      CREATE INDEX idx_location ON gas_stations(latitude, longitude)
    ''');

    // Tabla de precios
    await db.execute('''
      CREATE TABLE fuel_prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id TEXT NOT NULL,
        fuel_type TEXT NOT NULL,
        price REAL NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (station_id) REFERENCES gas_stations(id) ON DELETE CASCADE,
        UNIQUE(station_id, fuel_type)
      )
    ''');

    // Tabla de configuración (singleton)
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        search_radius INTEGER NOT NULL DEFAULT 10,
        preferred_fuel TEXT NOT NULL DEFAULT 'gasolina95',
        dark_mode INTEGER NOT NULL DEFAULT 0,
        last_api_sync TEXT
      )
    ''');

    // Insertar configuración por defecto
    await db.insert('app_settings', {
      'id': 1,
      'search_radius': 10,
      'preferred_fuel': 'gasolina95',
      'dark_mode': 0,
    });
  }

  // ==================== OPERACIONES GASOLINERAS ====================

  /// Insertar una gasolinera
  Future<void> insertStation(GasStation station) async {
    final db = await database;

    await db.insert(
      'gas_stations',
      {
        'id': station.id,
        'name': station.name,
        'latitude': station.latitude,
        'longitude': station.longitude,
        'address': station.address,
        'locality': station.locality,
        'operator': station.operator,
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insertar precios asociados
    for (var price in station.prices) {
      await insertPrice(station.id, price);
    }
  }

  /// Insertar múltiples gasolineras (batch)
  Future<void> insertBatch(List<GasStation> stations) async {
    final db = await database;
    Batch batch = db.batch();

    for (var station in stations) {
      batch.insert(
        'gas_stations',
        {
          'id': station.id,
          'name': station.name,
          'latitude': station.latitude,
          'longitude': station.longitude,
          'address': station.address,
          'locality': station.locality,
          'operator': station.operator,
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insertar precios
      for (var price in station.prices) {
        batch.insert(
          'fuel_prices',
          {
            'station_id': station.id,
            'fuel_type': price.fuelType.name,
            'price': price.value,
            'updated_at': price.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);
  }

  /// Obtener todas las gasolineras con sus precios
  Future<List<GasStation>> getAllStations() async {
    final db = await database;

    final stationMaps = await db.query('gas_stations');
    List<GasStation> stations = [];

    for (var stationMap in stationMaps) {
      // Obtener precios asociados
      final priceMaps = await db.query(
        'fuel_prices',
        where: 'station_id = ?',
        whereArgs: [stationMap['id']],
      );

      List<FuelPrice> prices = priceMaps.map((priceMap) {
        FuelType fuelType = FuelType.values.firstWhere(
          (e) => e.name == priceMap['fuel_type'],
          orElse: () => FuelType.gasolina95,
        );

        return FuelPrice(
          fuelType: fuelType,
          value: priceMap['price'] as double,
          updatedAt: DateTime.parse(priceMap['updated_at'] as String),
        );
      }).toList();

      stations.add(GasStation(
        id: stationMap['id'] as String,
        name: stationMap['name'] as String,
        latitude: stationMap['latitude'] as double,
        longitude: stationMap['longitude'] as double,
        address: stationMap['address'] as String? ?? '',
        locality: stationMap['locality'] as String? ?? '',
        operator: stationMap['operator'] as String? ?? '',
        prices: prices,
      ));
    }

    return stations;
  }

  /// Obtener gasolineras por ubicación (dentro de un bounding box)
  Future<List<GasStation>> getStationsByLocation({
    required double centerLat,
    required double centerLon,
    required double radiusKm,
  }) async {
    final db = await database;

    // Aproximación simple: calcular bounding box
    // 1 grado ≈ 111 km
    double latDelta = radiusKm / 111.0;
    double lonDelta = radiusKm / (111.0 * (centerLat * 3.14159 / 180).abs());

    double minLat = centerLat - latDelta;
    double maxLat = centerLat + latDelta;
    double minLon = centerLon - lonDelta;
    double maxLon = centerLon + lonDelta;

    final stationMaps = await db.query(
      'gas_stations',
      where: 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?',
      whereArgs: [minLat, maxLat, minLon, maxLon],
    );

    List<GasStation> stations = [];

    for (var stationMap in stationMaps) {
      final priceMaps = await db.query(
        'fuel_prices',
        where: 'station_id = ?',
        whereArgs: [stationMap['id']],
      );

      List<FuelPrice> prices = priceMaps.map((priceMap) {
        FuelType fuelType = FuelType.values.firstWhere(
          (e) => e.name == priceMap['fuel_type'],
          orElse: () => FuelType.gasolina95,
        );

        return FuelPrice(
          fuelType: fuelType,
          value: priceMap['price'] as double,
          updatedAt: DateTime.parse(priceMap['updated_at'] as String),
        );
      }).toList();

      stations.add(GasStation(
        id: stationMap['id'] as String,
        name: stationMap['name'] as String,
        latitude: stationMap['latitude'] as double,
        longitude: stationMap['longitude'] as double,
        address: stationMap['address'] as String? ?? '',
        locality: stationMap['locality'] as String? ?? '',
        operator: stationMap['operator'] as String? ?? '',
        prices: prices,
      ));
    }

    return stations;
  }

  /// Limpiar todas las gasolineras
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('fuel_prices'); // Se eliminarán automáticamente por CASCADE
    await db.delete('gas_stations');
  }

  // ==================== OPERACIONES PRECIOS ====================

  /// Insertar precio
  Future<void> insertPrice(String stationId, FuelPrice price) async {
    final db = await database;

    await db.insert(
      'fuel_prices',
      {
        'station_id': stationId,
        'fuel_type': price.fuelType.name,
        'price': price.value,
        'updated_at': price.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualizar precio de una gasolinera
  Future<void> updatePrice(String stationId, FuelPrice price) async {
    final db = await database;

    await db.update(
      'fuel_prices',
      {
        'price': price.value,
        'updated_at': price.updatedAt.toIso8601String(),
      },
      where: 'station_id = ? AND fuel_type = ?',
      whereArgs: [stationId, price.fuelType.name],
    );
  }

  // ==================== OPERACIONES CONFIGURACIÓN ====================

  /// Obtener configuración (singleton)
  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    final results = await db.query('app_settings', where: 'id = 1');

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Actualizar configuración
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.update(
      'app_settings',
      settings,
      where: 'id = 1',
    );
  }

  /// Actualizar timestamp de sincronización
  Future<void> updateLastSync(DateTime timestamp) async {
    final db = await database;
    await db.update(
      'app_settings',
      {'last_api_sync': timestamp.toIso8601String()},
      where: 'id = 1',
    );
  }

  // ==================== UTILIDADES ====================

  /// Cerrar base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Contar gasolineras en caché
  Future<int> getStationCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM gas_stations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Verificar si hay datos en caché
  Future<bool> hasData() async {
    final count = await getStationCount();
    return count > 0;
  }
}
