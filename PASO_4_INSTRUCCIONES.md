# PASO 4: Configurar Base de Datos Local

## Información extraída de la Documentación V3 para el Paso 4

---

## 🎯 OBJETIVO DEL PASO 4
- Implementar esquema SQLite para almacenamiento local
- Crear servicio de base de datos (DatabaseDataSource)
- Implementar operaciones CRUD básicas
- Configurar caché de gasolineras y precios

---

## 📊 ESQUEMA DE BASE DE DATOS (SQLite)

### Tabla 1: gas_stations

**Propósito:** Almacenar información de gasolineras descargadas de la API

**Esquema SQL:**
```sql
CREATE TABLE gas_stations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    address TEXT,
    locality TEXT,
    operator TEXT,
    cached_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_location (latitude, longitude)
);
```

**Campos:**
- `id`: Identificador único de la API (TEXT PRIMARY KEY)
- `name`: Nombre comercial de la gasolinera (TEXT NOT NULL)
- `latitude`: Coordenada latitud WGS84 (REAL NOT NULL)
- `longitude`: Coordenada longitud WGS84 (REAL NOT NULL)
- `address`: Dirección completa, puede ser nula (TEXT)
- `locality`: Municipio/localidad, puede ser nula (TEXT)
- `operator`: Empresa operadora, puede ser nula (TEXT)
- `cached_at`: Timestamp de cuándo se guardó (DATETIME NOT NULL)

**Índice:**
- `idx_location` sobre `(latitude, longitude)` para búsquedas geográficas rápidas

---

### Tabla 2: fuel_prices

**Propósito:** Almacenar precios de combustible asociados a cada gasolinera

**Esquema SQL:**
```sql
CREATE TABLE fuel_prices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    station_id TEXT NOT NULL,
    fuel_type TEXT NOT NULL,
    price REAL NOT NULL,
    updated_at DATETIME NOT NULL,
    FOREIGN KEY (station_id) REFERENCES gas_stations(id) ON DELETE CASCADE,
    UNIQUE(station_id, fuel_type)
);
```

**Campos:**
- `id`: ID autogenerado (INTEGER PRIMARY KEY AUTOINCREMENT)
- `station_id`: Referencia a `gas_stations.id` (TEXT NOT NULL)
- `fuel_type`: Tipo de combustible ("gasolina95" o "dieselGasoleoA") (TEXT NOT NULL)
- `price`: Precio en euros por litro (REAL NOT NULL)
- `updated_at`: Fecha de actualización del precio (DATETIME NOT NULL)

**Restricciones:**
- Foreign Key hacia `gas_stations(id)` con `ON DELETE CASCADE`
- UNIQUE constraint en `(station_id, fuel_type)` para evitar duplicados

---

### Tabla 3: app_settings

**Propósito:** Almacenar configuración del usuario (patrón singleton)

**Esquema SQL:**
```sql
CREATE TABLE app_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    search_radius INTEGER NOT NULL DEFAULT 10,
    preferred_fuel TEXT NOT NULL DEFAULT 'gasolina95',
    dark_mode INTEGER NOT NULL DEFAULT 0,
    last_api_sync DATETIME
);
```

**Campos:**
- `id`: Siempre 1 (INTEGER PRIMARY KEY CHECK (id = 1))
- `search_radius`: Radio de búsqueda en km (5, 10, 20, 50) (INTEGER NOT NULL DEFAULT 10)
- `preferred_fuel`: Combustible preferido (TEXT NOT NULL DEFAULT 'gasolina95')
- `dark_mode`: 0 = claro, 1 = oscuro (INTEGER NOT NULL DEFAULT 0)
- `last_api_sync`: Timestamp de última sincronización con API (DATETIME, nullable)

**Inicialización por defecto:**
```sql
INSERT INTO app_settings (id) VALUES (1);
```

---

## 🗂️ DICCIONARIO DE DATOS COMPLETO

### Tabla GASOLINERA (gas_stations)

| Campo      | Tipo            | Nulo | Descripción                                      |
|------------|-----------------|------|--------------------------------------------------|
| id         | VARCHAR(50)     | NO   | Identificador único proporcionado por la API     |
| name       | VARCHAR(200)    | NO   | Nombre comercial de la estación                  |
| latitude   | DECIMAL(10,8)   | NO   | Coordenada de latitud (WGS84)                    |
| longitude  | DECIMAL(11,8)   | NO   | Coordenada de longitud (WGS84)                   |
| address    | VARCHAR(300)    | SÍ   | Dirección completa (calle, número, etc.)         |
| locality   | VARCHAR(100)    | SÍ   | Nombre de la localidad o municipio               |
| operator   | VARCHAR(100)    | SÍ   | Empresa operadora de la estación                 |
| cached_at  | DATETIME        | NO   | Fecha y hora de la última sincronización/caché   |

### Tabla PRECIO (fuel_prices)

| Campo            | Tipo            | Nulo | Descripción                                          |
|------------------|-----------------|------|------------------------------------------------------|
| id               | INTEGER (auto)  | NO   | Identificador único del registro de precio           |
| station_id       | VARCHAR(50)     | NO   | FK que referencia id en gas_stations                 |
| fuel_type        | VARCHAR(20)     | NO   | Tipo de combustible ("gasolina95", "dieselGasoleoA") |
| price            | DECIMAL(5,3)    | NO   | Precio en euros por litro (ej.: 1.459)               |
| updated_at       | DATETIME        | NO   | Fecha y hora de la última actualización del precio   |

### Tabla CONFIGURACION (app_settings)

| Campo           | Tipo            | Nulo | Descripción                                               |
|-----------------|-----------------|------|-----------------------------------------------------------|
| id              | INTEGER         | NO   | Siempre 1 (singleton)                                     |
| search_radius   | INTEGER         | NO   | Radio de búsqueda en km (5, 10, 20, 50)                   |
| preferred_fuel  | VARCHAR(20)     | NO   | Combustible preferido ('gasolina95', 'dieselGasoleoA')    |
| dark_mode       | BOOLEAN         | NO   | true = modo oscuro, false = modo claro                    |
| last_api_sync   | DATETIME        | SÍ   | Fecha de última sincronización con API                    |

---

## 💾 SERVICIO DE BASE DE DATOS

### Ubicación del archivo:
`lib/data/datasources/local/database_datasource.dart`

### Clase: DatabaseDataSource

**Responsabilidades:**
1. Inicializar base de datos SQLite
2. Crear tablas y esquema
3. Operaciones CRUD para gasolineras
4. Operaciones CRUD para precios
5. Gestión de configuración (singleton)
6. Consultas geográficas optimizadas

**Dependencias necesarias:**
```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3
```

---

## 📝 IMPLEMENTACIÓN COMPLETA

### Código del DatabaseDataSource:

```dart
/// Fuente de datos local: Base de datos SQLite
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/app_settings.dart';

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
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM gas_stations');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Verificar si hay datos en caché
  Future<bool> hasData() async {
    final count = await getStationCount();
    return count > 0;
  }
}
```

---

## 🔧 OPERACIONES CRUD PRINCIPALES

### 1. **Insertar una gasolinera:**
```dart
await databaseDataSource.insertStation(gasStation);
```

### 2. **Insertar múltiples gasolineras (batch):**
```dart
await databaseDataSource.insertBatch(listOfStations);
```
- Usa `Batch` para mejor rendimiento
- Incluye precios automáticamente

### 3. **Obtener todas las gasolineras:**
```dart
List<GasStation> stations = await databaseDataSource.getAllStations();
```

### 4. **Obtener gasolineras cercanas (bounding box):**
```dart
List<GasStation> nearby = await databaseDataSource.getStationsByLocation(
  centerLat: 40.4168,
  centerLon: -3.7038,
  radiusKm: 10.0,
);
```

### 5. **Limpiar toda la caché:**
```dart
await databaseDataSource.clearAll();
```

### 6. **Actualizar configuración:**
```dart
await databaseDataSource.updateSettings({
  'search_radius': 20,
  'preferred_fuel': 'dieselGasoleoA',
  'dark_mode': 1,
});
```

### 7. **Registrar sincronización:**
```dart
await databaseDataSource.updateLastSync(DateTime.now());
```

---

## 🗺️ OPTIMIZACIONES GEOGRÁFICAS

### Bounding Box para búsquedas eficientes:

**Concepto:**
- En lugar de calcular distancia a TODAS las gasolineras
- Primero filtrar por un rectángulo aproximado
- Luego calcular distancia exacta con Haversine

**Aproximación:**
- 1 grado de latitud ≈ 111 km
- 1 grado de longitud ≈ 111 km × cos(latitud)

**Código incluido en `getStationsByLocation()`:**
```dart
double latDelta = radiusKm / 111.0;
double lonDelta = radiusKm / (111.0 * cos(centerLat * π / 180));

double minLat = centerLat - latDelta;
double maxLat = centerLat + latDelta;
double minLon = centerLon - lonDelta;
double maxLon = centerLon + lonDelta;
```

**Query SQL resultante:**
```sql
SELECT * FROM gas_stations 
WHERE latitude BETWEEN minLat AND maxLat 
  AND longitude BETWEEN minLon AND maxLon
```

**Beneficio del índice:**
- `INDEX idx_location (latitude, longitude)` acelera esta consulta

---

## ✅ CHECKLIST PASO 4

### Archivos a crear:

1. ✅ `lib/data/datasources/local/database_datasource.dart`
   - Clase DatabaseDataSource con patrón singleton
   - Método `_initDatabase()` para inicializar SQLite
   - Método `_onCreate()` con creación de 3 tablas + índice
   - Operaciones CRUD para gasolineras
   - Operaciones CRUD para precios
   - Operaciones para configuración singleton
   - Métodos de consulta geográfica optimizada

### Tareas:

1. ✅ Agregar dependencias en `pubspec.yaml`:
   ```yaml
   dependencies:
     sqflite: ^2.3.0
     path: ^1.8.3
   ```

2. ✅ Crear directorio `lib/data/datasources/local/`

3. ✅ Implementar `database_datasource.dart` completo

4. ✅ Ejecutar `flutter pub get`

5. ✅ Verificar compilación con `flutter analyze`

6. ✅ (Opcional) Probar en emulador:
   ```dart
   // En main.dart o test
   final db = DatabaseDataSource();
   await db.insertStation(testStation);
   final stations = await db.getAllStations();
   print('Gasolineras en caché: ${stations.length}');
   ```

---

## 🎯 CRITERIOS DE ÉXITO DEL PASO 4

**El Paso 4 está completo cuando:**
- ✅ SQLite configurado con 3 tablas (gas_stations, fuel_prices, app_settings)
- ✅ DatabaseDataSource implementado con patrón singleton
- ✅ Operaciones CRUD funcionando correctamente
- ✅ Índice geográfico creado para búsquedas optimizadas
- ✅ `flutter analyze` sin errores
- ✅ Base de datos se crea correctamente en primera ejecución

---

## 🔍 NOTAS IMPORTANTES

### Patrón Singleton:
- La base de datos usa singleton para evitar múltiples conexiones
- `DatabaseDataSource()` siempre devuelve la misma instancia

### Manejo de Foreign Keys:
- SQLite requiere habilitarlas manualmente (no implementado en esta versión básica)
- `ON DELETE CASCADE` funciona automáticamente al eliminar gasolineras

### Tipos de datos SQLite vs Dart:
- SQLite `TEXT` → Dart `String`
- SQLite `REAL` → Dart `double`
- SQLite `INTEGER` → Dart `int`
- SQLite `TEXT` (ISO8601) → Dart `DateTime`

### Convenciones de nombrado:
- Tablas: snake_case (`gas_stations`, `fuel_prices`)
- Campos: snake_case (`station_id`, `updated_at`)
- Clases Dart: PascalCase (`DatabaseDataSource`)

### Sincronización con AppSettings:
- La tabla `app_settings` duplica datos de `SharedPreferences`
- Esto permite consultas SQL más complejas en el futuro
- Mantener ambas sincronizadas

---

**Fecha de creación:** 17 de noviembre de 2025  
**Basado en:** BuscaGas Documentacion V3 (Métrica v3)  
**Sección:** DSI 5 - Diseño de la Arquitectura de Datos, ASI 5 - Elaboración del Modelo de Datos
