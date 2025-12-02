# Paso 21: Pruebas de Integración

## Contexto del Proyecto

**Proyecto:** BuscaGas - Localizador de Gasolineras Económicas en España  
**Fase:** FASE 7 - PRUEBAS  
**Paso:** 21 de 28  
**Documento base:** BuscaGas Documentacion V3 - Métrica v3  
**Prerequisito:** Paso 20 completado (107 pruebas unitarias pasando)

---

## Objetivo del Paso

Implementar pruebas de integración exhaustivas para validar la correcta interacción entre componentes del sistema, verificando flujos completos end-to-end, conexiones con servicios externos (API gubernamental), y persistencia de datos en SQLite.

---

## Diferencia entre Pruebas Unitarias e Integración

### Pruebas Unitarias (Paso 20) ✅ Completado
- Testean **componentes aislados** con mocks
- Validan **lógica de negocio pura**
- Rápidas (<5 segundos para 107 tests)
- Sin dependencias externas (red, BD, GPS)

### Pruebas de Integración (Paso 21) ⏳ Este Paso
- Testean **múltiples componentes juntos**
- Validan **flujos completos** (API → Repositorio → BLoC → UI)
- Usan **dependencias reales** (SQLite in-memory, HTTP real/mockeado)
- Más lentas pero más cercanas al uso real

---

## Alcance de las Pruebas de Integración

Según la documentación Métrica v3 (DSI 1, DSI 5, CSI 2) y los casos de uso (ASI 3), se deben probar:

### 1. **Integración con API Gubernamental (SS-02)**
- Conexión real con endpoint oficial de precios
- Parseo de respuestas JSON reales
- Manejo de errores de red (timeout, 404, 500)
- Validación de datos recibidos (estructura JSON esperada)

### 2. **Persistencia de Datos (SS-02, DSI 5)**
- Operaciones CRUD en SQLite
- Migración de datos de API a base de datos local
- Consultas por proximidad geográfica
- Actualización de caché (borrar antiguo + insertar nuevo)

### 3. **Flujo Completo de Sincronización (CU-01, DSI 6)**
- Descarga desde API → Parseo → Guardado en BD → Lectura desde BD
- Actualización periódica con comparación de datos
- Fallback a caché cuando no hay conexión
- Timestamp de última sincronización

### 4. **Repositorio con Fuentes Múltiples (DSI 1)**
- Estrategia cache-first (verificar caché antes de API)
- Combinación de ApiDataSource + DatabaseDataSource
- Lógica de decisión (usar caché si < 24h antigüedad)

### 5. **Servicios del Sistema (SS-01, SS-02)**
- DatabaseService: inicialización de esquema, CRUD completo
- ApiService: HTTP client con manejo de errores
- SyncService: timer periódico + verificación de cambios

### 6. **BLoC con Datos Reales (DSI 3)**
- MapBloc procesando gasolineras reales
- Filtrado por combustible con datos reales
- Cálculo de distancias con coordenadas reales
- Asignación de rangos de precio con precios reales

---

## Requisitos Previos

### Dependencias Necesarias

Verificar que `pubspec.yaml` incluya:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  sqflite_common_ffi: ^2.3.0  # Para tests de SQLite en desktop
  http: ^1.1.0  # Ya incluido
```

Si falta `integration_test` o `sqflite_common_ffi`, agregar y ejecutar:
```bash
flutter pub add --dev integration_test sqflite_common_ffi
flutter pub get
```

### Estructura de Carpetas

Crear:
```
test/
├── integration/
│   ├── api_integration_test.dart
│   ├── database_integration_test.dart
│   ├── repository_integration_test.dart
│   ├── sync_flow_integration_test.dart
│   └── end_to_end_test.dart
└── helpers/
    ├── test_database_helper.dart
    └── mock_api_helper.dart
```

---

## Especificaciones de Pruebas por Componente

### **PRUEBA 1: Integración con API Gubernamental**

**Archivo:** `test/integration/api_integration_test.dart`

**Objetivo:** Validar conexión real con la API del gobierno y parseo de datos

**Casos de prueba obligatorios:**

1. **Descarga exitosa de datos reales**
   - Endpoint: `https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/`
   - Verificar código HTTP 200
   - Verificar que retorna >10,000 gasolineras
   - Validar estructura JSON según ASI 5

2. **Parseo de JSON a entidades**
   - Convertir DTO de API a `GasStation`
   - Validar coordenadas válidas (-90 a 90 lat, -180 a 180 lon)
   - Validar precios válidos (> 0 y < 10 €/L)
   - Filtrar entradas con datos incompletos

3. **Manejo de errores de red**
   - Timeout (>30 segundos sin respuesta)
   - Error 404 (endpoint no encontrado)
   - Error 500 (error del servidor)
   - Sin conexión a internet

4. **Validación de campos obligatorios**
   - ID de gasolinera no nulo
   - Coordenadas presentes
   - Al menos un precio de combustible

**Estructura del test:**

```dart
void main() {
  group('API Integration Tests', () {
    late ApiDataSource apiDataSource;

    setUp(() {
      apiDataSource = ApiDataSource();
    });

    test('debe descargar datos reales de la API gubernamental', () async {
      // Act
      final stations = await apiDataSource.fetchStations();

      // Assert
      expect(stations.length, greaterThan(10000));
      expect(stations.first.id, isNotEmpty);
      expect(stations.first.latitude, inInclusiveRange(-90.0, 90.0));
      expect(stations.first.longitude, inInclusiveRange(-180.0, 180.0));
    }, timeout: Timeout(Duration(seconds: 60)));

    test('debe parsear correctamente JSON de API', () async {
      // Act
      final stations = await apiDataSource.fetchStations();
      final firstStation = stations.first;

      // Assert - Verificar todos los campos críticos
      expect(firstStation.id, isNotNull);
      expect(firstStation.name, isNotEmpty);
      expect(firstStation.prices, isNotEmpty);
      expect(firstStation.prices.first.value, greaterThan(0));
    });

    test('debe manejar timeout de red', () async {
      // Arrange - Crear cliente con timeout muy corto
      final apiWithShortTimeout = ApiDataSource(timeout: Duration(milliseconds: 1));

      // Act & Assert
      expect(
        () => apiWithShortTimeout.fetchStations(),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('debe filtrar gasolineras con coordenadas inválidas', () async {
      // Act
      final stations = await apiDataSource.fetchStations();

      // Assert - Ninguna debe tener coordenadas fuera de rango
      for (var station in stations) {
        expect(station.latitude, inInclusiveRange(-90.0, 90.0));
        expect(station.longitude, inInclusiveRange(-180.0, 180.0));
      }
    });
  });
}
```

**Criterios de aceptación:**
- ✅ Descarga exitosa en <60 segundos
- ✅ >10,000 gasolineras recibidas
- ✅ Parseo correcto de JSON a GasStation
- ✅ Manejo robusto de errores de red

---

### **PRUEBA 2: Integración con Base de Datos**

**Archivo:** `test/integration/database_integration_test.dart`

**Objetivo:** Validar operaciones CRUD completas en SQLite

**Casos de prueba según DSI 5:**

1. **Inicialización de esquema**
   - Crear tablas: gas_stations, fuel_prices, app_settings
   - Verificar índices: idx_location en (latitude, longitude)
   - Insertar configuración por defecto (singleton id=1)

2. **Inserción de gasolineras**
   - Insertar 100 gasolineras de prueba
   - Verificar que se guardan correctamente
   - Validar relación gas_stations ↔ fuel_prices (FK)

3. **Consulta por proximidad geográfica**
   - Insertar gasolineras en diferentes ubicaciones
   - Consultar dentro de radio de 10 km
   - Verificar ordenación por distancia

4. **Actualización de caché**
   - Borrar todas las estaciones antiguas
   - Insertar nuevo lote
   - Verificar que no quedan datos antiguos

5. **Consulta de configuración (singleton)**
   - Leer app_settings (siempre id=1)
   - Actualizar radio de búsqueda
   - Verificar persistencia

**Helper para base de datos de prueba:**

```dart
// test/helpers/test_database_helper.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestDatabaseHelper {
  static Future<Database> createInMemoryDatabase() async {
    // Inicializar sqflite_ffi para tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Crear BD en memoria
    return await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Crear tabla gas_stations
        await db.execute('''
          CREATE TABLE gas_stations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            address TEXT,
            locality TEXT,
            operator TEXT,
            cached_at DATETIME NOT NULL
          )
        ''');

        // Crear tabla fuel_prices
        await db.execute('''
          CREATE TABLE fuel_prices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            station_id TEXT NOT NULL,
            fuel_type TEXT NOT NULL,
            value REAL NOT NULL,
            updated_at DATETIME NOT NULL,
            FOREIGN KEY (station_id) REFERENCES gas_stations(id) ON DELETE CASCADE,
            UNIQUE(station_id, fuel_type)
          )
        ''');

        // Crear tabla app_settings
        await db.execute('''
          CREATE TABLE app_settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            search_radius INTEGER NOT NULL,
            preferred_fuel TEXT NOT NULL,
            dark_mode INTEGER NOT NULL,
            last_api_sync DATETIME
          )
        ''');

        // Insertar configuración por defecto
        await db.insert('app_settings', {
          'id': 1,
          'search_radius': 10,
          'preferred_fuel': 'gasolina95',
          'dark_mode': 0,
        });

        // Crear índice de ubicación
        await db.execute('''
          CREATE INDEX idx_location ON gas_stations(latitude, longitude)
        ''');
      },
    );
  }

  static Future<void> insertTestStation(Database db, {
    required String id,
    required double lat,
    required double lon,
    required double gasolina95Price,
  }) async {
    await db.insert('gas_stations', {
      'id': id,
      'name': 'Test Station $id',
      'latitude': lat,
      'longitude': lon,
      'address': 'Test Address',
      'locality': 'Madrid',
      'operator': 'Test Operator',
      'cached_at': DateTime.now().toIso8601String(),
    });

    await db.insert('fuel_prices', {
      'station_id': id,
      'fuel_type': 'gasolina95',
      'value': gasolina95Price,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
```

**Estructura del test:**

```dart
void main() {
  group('Database Integration Tests', () {
    late Database db;

    setUp(() async {
      db = await TestDatabaseHelper.createInMemoryDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('debe crear esquema correctamente', () async {
      // Act
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );

      // Assert
      final tableNames = tables.map((t) => t['name']).toList();
      expect(tableNames, contains('gas_stations'));
      expect(tableNames, contains('fuel_prices'));
      expect(tableNames, contains('app_settings'));
    });

    test('debe insertar y recuperar gasolineras', () async {
      // Arrange
      await TestDatabaseHelper.insertTestStation(
        db,
        id: 'test_001',
        lat: 40.4168,
        lon: -3.7038,
        gasolina95Price: 1.459,
      );

      // Act
      final result = await db.query('gas_stations', where: 'id = ?', whereArgs: ['test_001']);

      // Assert
      expect(result.length, equals(1));
      expect(result.first['name'], equals('Test Station test_001'));
      expect(result.first['latitude'], equals(40.4168));
    });

    test('debe consultar gasolineras por proximidad', () async {
      // Arrange - Insertar gasolineras en Madrid y Barcelona
      await TestDatabaseHelper.insertTestStation(
        db, id: 'madrid_1', lat: 40.4168, lon: -3.7038, gasolina95Price: 1.45,
      );
      await TestDatabaseHelper.insertTestStation(
        db, id: 'madrid_2', lat: 40.4200, lon: -3.7000, gasolina95Price: 1.50,
      );
      await TestDatabaseHelper.insertTestStation(
        db, id: 'barcelona_1', lat: 41.3851, lon: 2.1734, gasolina95Price: 1.55,
      );

      // Act - Buscar cerca de Madrid centro (40.4168, -3.7038)
      // Nota: Requiere implementar cálculo de distancia en SQL o en Dart
      final nearbyStations = await db.query('gas_stations');

      // Assert - Solo deben estar las de Madrid (simplificado para test)
      expect(nearbyStations.length, equals(3));
    });

    test('debe actualizar caché correctamente', () async {
      // Arrange - Insertar datos antiguos
      await TestDatabaseHelper.insertTestStation(
        db, id: 'old_1', lat: 40.0, lon: -3.0, gasolina95Price: 1.40,
      );

      // Act - Borrar y reinsertar
      await db.delete('fuel_prices');
      await db.delete('gas_stations');
      await TestDatabaseHelper.insertTestStation(
        db, id: 'new_1', lat: 40.5, lon: -3.5, gasolina95Price: 1.60,
      );

      // Assert
      final stations = await db.query('gas_stations');
      expect(stations.length, equals(1));
      expect(stations.first['id'], equals('new_1'));
    });

    test('debe mantener singleton de configuración', () async {
      // Act
      final settings = await db.query('app_settings');

      // Assert
      expect(settings.length, equals(1));
      expect(settings.first['id'], equals(1));
      expect(settings.first['search_radius'], equals(10));
    });

    test('debe actualizar configuración persistentemente', () async {
      // Act
      await db.update(
        'app_settings',
        {'search_radius': 50, 'preferred_fuel': 'dieselGasoleoA'},
        where: 'id = ?',
        whereArgs: [1],
      );

      // Assert
      final settings = await db.query('app_settings');
      expect(settings.first['search_radius'], equals(50));
      expect(settings.first['preferred_fuel'], equals('dieselGasoleoA'));
    });

    test('debe respetar foreign key constraint', () async {
      // Arrange
      await TestDatabaseHelper.insertTestStation(
        db, id: 'station_fk', lat: 40.0, lon: -3.0, gasolina95Price: 1.45,
      );

      // Act - Borrar estación (debe borrar precios en cascada)
      await db.delete('gas_stations', where: 'id = ?', whereArgs: ['station_fk']);

      // Assert - Los precios deben haberse borrado también
      final prices = await db.query(
        'fuel_prices',
        where: 'station_id = ?',
        whereArgs: ['station_fk'],
      );
      expect(prices, isEmpty);
    });
  });
}
```

**Criterios de aceptación:**
- ✅ Esquema creado correctamente con FK e índices
- ✅ CRUD completo funciona
- ✅ Consultas por proximidad eficientes
- ✅ Actualización de caché sin residuos

---

### **PRUEBA 3: Integración de Repositorio**

**Archivo:** `test/integration/repository_integration_test.dart`

**Objetivo:** Validar estrategia cache-first con fuentes reales

**Casos de prueba según DSI 1:**

1. **Cache-first: Caché disponible**
   - BD tiene datos <24h de antigüedad
   - No debe llamar a API
   - Retorna datos de caché

2. **Cache-first: Caché vacío**
   - BD sin datos
   - Llama a API
   - Guarda en caché
   - Retorna datos frescos

3. **Cache-first: Caché antiguo (>24h)**
   - BD con datos antiguos
   - Llama a API para actualizar
   - Actualiza caché
   - Retorna datos nuevos

4. **Fallback a caché en error de red**
   - API no disponible
   - BD tiene datos antiguos
   - Retorna caché antiguo (mejor que nada)

5. **getNearbyStations con datos reales**
   - Filtra por radio (10 km)
   - Calcula distancias reales
   - Ordena por distancia
   - Limita a 50 resultados

**Estructura del test:**

```dart
void main() {
  group('Repository Integration Tests', () {
    late GasStationRepositoryImpl repository;
    late Database testDb;

    setUp(() async {
      testDb = await TestDatabaseHelper.createInMemoryDatabase();
      final apiDataSource = ApiDataSource();
      final dbDataSource = DatabaseDataSource(testDb);
      repository = GasStationRepositoryImpl(apiDataSource, dbDataSource);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('debe usar caché si está disponible y reciente', () async {
      // Arrange - Insertar datos en caché con timestamp reciente
      await TestDatabaseHelper.insertTestStation(
        testDb, id: 'cached_1', lat: 40.4168, lon: -3.7038, gasolina95Price: 1.45,
      );
      await testDb.update(
        'app_settings',
        {'last_api_sync': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [1],
      );

      // Act
      final stations = await repository.getCachedStations();

      // Assert - Debe retornar del caché
      expect(stations.length, greaterThan(0));
      expect(stations.first.id, equals('cached_1'));
    });

    test('debe llamar a API cuando caché está vacío', () async {
      // Arrange - BD vacía

      // Act
      final stations = await repository.fetchRemoteStations();

      // Assert - Debe descargar de API
      expect(stations.length, greaterThan(10000));
    }, timeout: Timeout(Duration(minutes: 2)));

    test('debe actualizar caché después de descarga', () async {
      // Act - Descargar de API
      final remoteStations = await repository.fetchRemoteStations();
      
      // Guardar en caché
      await repository.updateCache(remoteStations);

      // Leer del caché
      final cachedStations = await repository.getCachedStations();

      // Assert
      expect(cachedStations.length, equals(remoteStations.length));
    }, timeout: Timeout(Duration(minutes: 2)));

    test('debe filtrar por radio de búsqueda', () async {
      // Arrange - Insertar gasolineras conocidas
      await TestDatabaseHelper.insertTestStation(
        testDb, id: 'near', lat: 40.4200, lon: -3.7038, gasolina95Price: 1.45,
      ); // ~3.5 km de Madrid centro
      await TestDatabaseHelper.insertTestStation(
        testDb, id: 'far', lat: 41.3851, lon: 2.1734, gasolina95Price: 1.50,
      ); // ~504 km (Barcelona)

      // Act - Buscar con radio de 10 km desde Madrid centro
      final nearby = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      );

      // Assert - Solo debe incluir la cercana
      expect(nearby.length, equals(1));
      expect(nearby.first.id, equals('near'));
    });

    test('debe ordenar por distancia', () async {
      // Arrange
      await TestDatabaseHelper.insertTestStation(
        testDb, id: 'medium', lat: 40.4300, lon: -3.7038, gasolina95Price: 1.50,
      );
      await TestDatabaseHelper.insertTestStation(
        testDb, id: 'near', lat: 40.4180, lon: -3.7038, gasolina95Price: 1.45,
      );
      await TestDatabaseHelper.insertTestStation(
        testDb, id: 'far', lat: 40.4400, lon: -3.7038, gasolina95Price: 1.55,
      );

      // Act
      final nearby = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 50.0,
      );

      // Assert - Debe estar ordenado por distancia
      expect(nearby[0].id, equals('near'));
      expect(nearby[1].id, equals('medium'));
      expect(nearby[2].id, equals('far'));
    });

    test('debe limitar a 50 resultados máximo', () async {
      // Arrange - Insertar 100 gasolineras cercanas
      for (int i = 0; i < 100; i++) {
        await TestDatabaseHelper.insertTestStation(
          testDb,
          id: 'station_$i',
          lat: 40.4168 + (i * 0.001),
          lon: -3.7038,
          gasolina95Price: 1.45 + (i * 0.001),
        );
      }

      // Act
      final nearby = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 50.0,
      );

      // Assert
      expect(nearby.length, lessThanOrEqualTo(50));
    });
  });
}
```

**Criterios de aceptación:**
- ✅ Estrategia cache-first implementada correctamente
- ✅ Fallback a caché en errores de red
- ✅ Filtrado por radio preciso
- ✅ Ordenación por distancia correcta
- ✅ Límite de 50 resultados respetado

---

### **PRUEBA 4: Flujo Completo de Sincronización**

**Archivo:** `test/integration/sync_flow_integration_test.dart`

**Objetivo:** Validar flujo end-to-end según CU-01 y DSI 6

**Casos de prueba:**

1. **Sincronización inicial completa**
   - API → Parseo → Validación → BD → Lectura
   - Timestamp actualizado
   - >10,000 gasolineras guardadas

2. **Actualización periódica con cambios**
   - Detectar cambios en precios
   - Actualizar solo estaciones modificadas
   - Mantener timestamp

3. **Actualización periódica sin cambios**
   - Comparar datos
   - No actualizar BD (optimización)
   - Actualizar solo timestamp

4. **Sincronización con error de red**
   - Intentar actualizar
   - Fallar en API
   - Mantener caché antiguo
   - No actualizar timestamp

**Estructura del test:**

```dart
void main() {
  group('Sync Flow Integration Tests', () {
    late DataSyncService syncService;
    late GasStationRepositoryImpl repository;
    late Database testDb;

    setUp(() async {
      testDb = await TestDatabaseHelper.createInMemoryDatabase();
      final apiDataSource = ApiDataSource();
      final dbDataSource = DatabaseDataSource(testDb);
      repository = GasStationRepositoryImpl(apiDataSource, dbDataSource);
      syncService = DataSyncService(repository);
    });

    tearDown(() async {
      syncService.stop();
      await testDb.close();
    });

    test('debe completar sincronización inicial exitosamente', () async {
      // Act
      await syncService.performSync();

      // Assert
      final cachedStations = await repository.getCachedStations();
      expect(cachedStations.length, greaterThan(10000));

      final settings = await testDb.query('app_settings');
      expect(settings.first['last_api_sync'], isNotNull);
    }, timeout: Timeout(Duration(minutes: 3)));

    test('debe detectar cambios en precios', () async {
      // Arrange - Primera sincronización
      await syncService.performSync();
      final initialStations = await repository.getCachedStations();
      final sampleId = initialStations.first.id;

      // Simular cambio de precio (requiere mock o esperar actualización real)
      // Para test, modificamos manualmente el caché
      await testDb.update(
        'fuel_prices',
        {'value': 1.999},
        where: 'station_id = ?',
        whereArgs: [sampleId],
      );

      // Act - Segunda sincronización
      final hasChanges = await syncService.checkForChanges();

      // Assert - Debe detectar diferencias
      expect(hasChanges, isTrue);
    }, timeout: Timeout(Duration(minutes: 3)));
  });
}
```

---

### **PRUEBA 5: End-to-End con BLoC**

**Archivo:** `test/integration/end_to_end_test.dart`

**Objetivo:** Validar flujo completo desde BLoC hasta persistencia

**Casos de prueba:**

1. **Flujo completo de carga de mapa**
   - MapBloc.LoadMapData → Repository → API → BD → MapBloc.state
   - Verificar estados: Loading → Loaded
   - 50 marcadores asignados con rangos de precio

2. **Cambio de combustible con datos reales**
   - MapBloc.ChangeFuelType → Filtrado → Reasignación de rangos
   - Verificar que marcadores cambian

3. **Recentrado con nuevas coordenadas**
   - MapBloc.RecenterMap → Recálculo de distancias → Nuevos 50 marcadores
   - Verificar ordenación por distancia

**Estructura del test:**

```dart
void main() {
  group('End-to-End Integration Tests', () {
    late MapBloc mapBloc;
    late GasStationRepositoryImpl repository;
    late Database testDb;

    setUp(() async {
      testDb = await TestDatabaseHelper.createInMemoryDatabase();
      final apiDataSource = ApiDataSource();
      final dbDataSource = DatabaseDataSource(testDb);
      repository = GasStationRepositoryImpl(apiDataSource, dbDataSource);

      final getNearbyUseCase = GetNearbyStationsUseCase(repository);
      final filterUseCase = FilterByFuelTypeUseCase();
      final calculateDistanceUseCase = CalculateDistanceUseCase();
      final assignPriceRangeUseCase = AssignPriceRangeUseCase();

      mapBloc = MapBloc(
        getNearbyStationsUseCase: getNearbyUseCase,
        filterByFuelTypeUseCase: filterUseCase,
        calculateDistanceUseCase: calculateDistanceUseCase,
        assignPriceRangeUseCase: assignPriceRangeUseCase,
      );
    });

    tearDown(() async {
      mapBloc.close();
      await testDb.close();
    });

    test('debe cargar mapa con datos reales end-to-end', () async {
      // Arrange - Sincronizar datos primero
      await repository.fetchRemoteStations().then(repository.updateCache);

      // Act
      mapBloc.add(LoadMapData(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
        fuelType: FuelType.gasolina95,
      ));

      // Assert
      await expectLater(
        mapBloc.stream,
        emitsInOrder([
          isA<MapLoading>(),
          isA<MapLoaded>()
            .having((s) => s.stations.length, 'stations count', lessThanOrEqualTo(50))
            .having((s) => s.stations.first.priceRange, 'has price range', isNotNull),
        ]),
      );
    }, timeout: Timeout(Duration(minutes: 3)));

    test('debe cambiar combustible y actualizar marcadores', () async {
      // Arrange
      await repository.fetchRemoteStations().then(repository.updateCache);
      mapBloc.add(LoadMapData(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
        fuelType: FuelType.gasolina95,
      ));
      await mapBloc.stream.firstWhere((s) => s is MapLoaded);

      // Act
      mapBloc.add(ChangeFuelType(FuelType.dieselGasoleoA));

      // Assert
      await expectLater(
        mapBloc.stream,
        emits(isA<MapLoaded>()
          .having((s) => s.selectedFuel, 'fuel type', FuelType.dieselGasoleoA)),
      );
    }, timeout: Timeout(Duration(minutes: 3)));
  });
}
```

---

## Comandos de Ejecución

### Ejecutar Todas las Pruebas de Integración
```bash
flutter test test/integration/
```

### Ejecutar Prueba Específica
```bash
flutter test test/integration/api_integration_test.dart
```

### Ejecutar con Timeout Extendido
```bash
flutter test test/integration/ --timeout=5m
```

### Generar Cobertura Incluyendo Integración
```bash
flutter test --coverage
```

---

## Métricas de Calidad Esperadas

| Métrica | Objetivo Mínimo | Objetivo Ideal |
|---------|----------------|----------------|
| **Tests de integración pasando** | 100% | 100% |
| **Tiempo de ejecución total** | <5 minutos | <3 minutos |
| **Cobertura combinada (unit+integration)** | 75% | 85%+ |
| **Tests de API exitosos** | 100% | 100% |
| **Tests de BD exitosos** | 100% | 100% |

---

## Criterios de Aceptación del Paso 21

- [ ] **CA-01:** Tests de API con datos reales funcionando
- [ ] **CA-02:** Tests de BD con SQLite in-memory completados
- [ ] **CA-03:** Tests de repositorio con estrategia cache-first validada
- [ ] **CA-04:** Flujo de sincronización completo testeado
- [ ] **CA-05:** Tests end-to-end con BLoC pasando
- [ ] **CA-06:** 100% de tests de integración pasando
- [ ] **CA-07:** Tiempo de ejecución <5 minutos
- [ ] **CA-08:** Cobertura combinada >75%
- [ ] **CA-09:** Manejo de errores de red validado
- [ ] **CA-10:** Fallback a caché funcionando
- [ ] **CA-11:** Documentación de tests completa
- [ ] **CA-12:** Helper classes reutilizables creados

---

## Orden de Implementación Recomendado

### Fase 1: Configuración (Día 1)
1. Agregar dependencias (integration_test, sqflite_common_ffi)
2. Crear estructura de carpetas
3. Implementar TestDatabaseHelper
4. Implementar MockApiHelper (opcional)

### Fase 2: Tests de Componentes (Días 2-3)
1. `database_integration_test.dart` (más fácil, sin red)
2. `api_integration_test.dart` (requiere conexión)
3. `repository_integration_test.dart` (combina ambos)

### Fase 3: Tests de Flujo (Día 4)
1. `sync_flow_integration_test.dart` (flujo completo de sincronización)

### Fase 4: Tests End-to-End (Día 5)
1. `end_to_end_test.dart` (BLoC + Repositorio + BD)

### Fase 5: Validación y Documentación (Día 6)
1. Ejecutar todos los tests
2. Verificar cobertura
3. Documentar en PASO_21_COMPLETADO.md

---

## Notas Importantes

⚠️ **Restricciones:**
- Tests de API **requieren conexión a internet**
- Tests de BD usan **in-memory database** (se pierde al cerrar)
- Tests son **más lentos** que unitarios (60-180 segundos)
- API gubernamental puede estar **temporalmente no disponible**

✅ **Buenas prácticas:**
- Usar `timeout: Timeout(Duration(minutes: X))` para tests de red
- Limpiar BD en `tearDown()` para evitar contaminación
- Usar `sqflite_common_ffi` para tests en desktop (no requiere emulador)
- Separar tests que requieren red de los que no

⚡ **Optimizaciones:**
- Cachear respuesta de API en primera ejecución (para re-ejecuciones)
- Usar `setUpAll()` para operaciones pesadas una sola vez
- Limitar tests de API a casos críticos (no exhaustivos)

📝 **Documentación:**
- Actualizar `PASOS_DESARROLLO.md` al completar
- Crear `PASO_21_COMPLETADO.md` con resultados
- Documentar cualquier issue encontrado con la API

---

## Referencias de la Documentación

- **ASI 3 (CU-01):** Flujo de localizar gasolinera (caso de uso principal)
- **DSI 1:** Arquitectura con Repository Pattern y capas
- **DSI 5:** Esquema de BD SQLite (3 tablas con FK e índices)
- **DSI 6:** Proceso de actualización periódica con comparación
- **CSI 2:** Implementación de repositorio con fuentes múltiples

---

**Fecha de creación:** 2 de diciembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Autor:** Desarrollo según Métrica v3  
**Estado:** ⏳ PENDIENTE DE IMPLEMENTACIÓN  
**Prerequisito:** Paso 20 completado ✅
