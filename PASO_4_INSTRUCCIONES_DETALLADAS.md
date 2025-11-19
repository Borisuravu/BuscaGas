# PASO 4: CONFIGURAR BASE DE DATOS LOCAL - INSTRUCCIONES DETALLADAS

## Estado Actual del Proyecto

### ✅ Ya Implementado:
- `DatabaseDataSource` en `lib/data/datasources/local/database_datasource.dart` - **COMPLETAMENTE IMPLEMENTADO**
  - Esquema de base de datos SQLite con 3 tablas
  - Operaciones CRUD para gasolineras
  - Operaciones CRUD para precios
  - Operaciones de configuración
  - Búsqueda por ubicación geográfica
  - Inserción batch para optimización
  
- Modelos de datos:
  - `GasStationModel` con mappers a/desde entidad de dominio
  - `FuelPriceModel` con mappers a/desde entidad de dominio

### 🔴 Pendiente de Implementar:

1. **DatabaseService** (Wrapper/Facade del DatabaseDataSource)
2. **Integración con AppSettings** para persistencia en BD
3. **Pruebas y validación** del servicio de base de datos

---

## TAREA 1: Implementar DatabaseService

### Ubicación:
`lib/services/database_service.dart`

### Propósito:
Crear un servicio de alto nivel que actúe como facade del `DatabaseDataSource`, proporcionando una interfaz más simple y específica para el resto de la aplicación.

### Código Completo a Implementar:

```dart
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

/// Servicio de base de datos SQLite
/// 
/// Responsabilidades:
/// - Proporcionar interfaz simplificada para operaciones de BD
/// - Gestionar ciclo de vida de la base de datos
/// - Coordinar operaciones complejas entre tablas
/// - Manejar errores de base de datos
class DatabaseService {
  final DatabaseDataSource _dataSource = DatabaseDataSource();
  
  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  // ==================== INICIALIZACIÓN ====================
  
  /// Inicializar la base de datos
  /// Debe llamarse al inicio de la app (en SplashScreen o main.dart)
  Future<void> initialize() async {
    try {
      // Acceder a la base de datos para forzar su creación
      await _dataSource.database;
      print('✅ Base de datos inicializada correctamente');
    } catch (e) {
      print('❌ Error al inicializar base de datos: $e');
      rethrow;
    }
  }
  
  /// Verificar si la base de datos tiene datos
  Future<bool> hasData() async {
    try {
      return await _dataSource.hasData();
    } catch (e) {
      print('Error verificando datos: $e');
      return false;
    }
  }
  
  // ==================== GASOLINERAS ====================
  
  /// Guardar lista de gasolineras (reemplaza todo el caché)
  Future<void> saveStations(List<GasStation> stations) async {
    try {
      // Limpiar datos antiguos
      await _dataSource.clearAll();
      
      // Insertar nuevos datos en batch
      await _dataSource.insertBatch(stations);
      
      // Actualizar timestamp de sincronización
      await _dataSource.updateLastSync(DateTime.now());
      
      print('✅ ${stations.length} gasolineras guardadas en caché');
    } catch (e) {
      print('❌ Error guardando gasolineras: $e');
      rethrow;
    }
  }
  
  /// Obtener todas las gasolineras del caché
  Future<List<GasStation>> getAllStations() async {
    try {
      return await _dataSource.getAllStations();
    } catch (e) {
      print('Error obteniendo gasolineras: $e');
      return [];
    }
  }
  
  /// Obtener gasolineras cercanas a una ubicación
  Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final stations = await _dataSource.getStationsByLocation(
        centerLat: latitude,
        centerLon: longitude,
        radiusKm: radiusKm,
      );
      
      // Calcular y asignar distancia a cada gasolinera
      for (var station in stations) {
        station.distance = _calculateDistance(
          latitude,
          longitude,
          station.latitude,
          station.longitude,
        );
      }
      
      // Ordenar por distancia
      stations.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
      
      return stations;
    } catch (e) {
      print('Error obteniendo gasolineras cercanas: $e');
      return [];
    }
  }
  
  /// Agregar una sola gasolinera
  Future<void> addStation(GasStation station) async {
    try {
      await _dataSource.insertStation(station);
    } catch (e) {
      print('Error agregando gasolinera: $e');
      rethrow;
    }
  }
  
  /// Limpiar caché de gasolineras
  Future<void> clearCache() async {
    try {
      await _dataSource.clearAll();
      print('✅ Caché de gasolineras limpiado');
    } catch (e) {
      print('❌ Error limpiando caché: $e');
      rethrow;
    }
  }
  
  // ==================== PRECIOS ====================
  
  /// Actualizar precio de una gasolinera
  Future<void> updateStationPrice({
    required String stationId,
    required FuelPrice price,
  }) async {
    try {
      await _dataSource.updatePrice(stationId, price);
    } catch (e) {
      print('Error actualizando precio: $e');
      rethrow;
    }
  }
  
  // ==================== CONFIGURACIÓN ====================
  
  /// Obtener configuración de la app
  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      return await _dataSource.getSettings();
    } catch (e) {
      print('Error obteniendo configuración: $e');
      return null;
    }
  }
  
  /// Actualizar radio de búsqueda
  Future<void> updateSearchRadius(int radiusKm) async {
    try {
      await _dataSource.updateSettings({'search_radius': radiusKm});
    } catch (e) {
      print('Error actualizando radio de búsqueda: $e');
      rethrow;
    }
  }
  
  /// Actualizar combustible preferido
  Future<void> updatePreferredFuel(FuelType fuelType) async {
    try {
      await _dataSource.updateSettings({'preferred_fuel': fuelType.name});
    } catch (e) {
      print('Error actualizando combustible preferido: $e');
      rethrow;
    }
  }
  
  /// Actualizar modo oscuro
  Future<void> updateDarkMode(bool isDark) async {
    try {
      await _dataSource.updateSettings({'dark_mode': isDark ? 1 : 0});
    } catch (e) {
      print('Error actualizando modo oscuro: $e');
      rethrow;
    }
  }
  
  /// Obtener timestamp de última sincronización
  Future<DateTime?> getLastSyncTime() async {
    try {
      final settings = await _dataSource.getSettings();
      if (settings != null && settings['last_api_sync'] != null) {
        return DateTime.parse(settings['last_api_sync'] as String);
      }
      return null;
    } catch (e) {
      print('Error obteniendo timestamp de sincronización: $e');
      return null;
    }
  }
  
  // ==================== ESTADÍSTICAS ====================
  
  /// Obtener número de gasolineras en caché
  Future<int> getCachedStationCount() async {
    try {
      return await _dataSource.getStationCount();
    } catch (e) {
      print('Error obteniendo conteo: $e');
      return 0;
    }
  }
  
  /// Verificar si el caché está desactualizado
  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final lastSync = await getLastSyncTime();
      if (lastSync == null) return true;
      
      final age = DateTime.now().difference(lastSync);
      return age > maxAge;
    } catch (e) {
      print('Error verificando antigüedad del caché: $e');
      return true;
    }
  }
  
  // ==================== UTILIDADES ====================
  
  /// Calcular distancia entre dos puntos (fórmula de Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = (dLat / 2).sin() * (dLat / 2).sin() +
        _degreesToRadians(lat1).cos() *
            _degreesToRadians(lat2).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();
    
    double c = 2 * (a.sqrt()).atan2((1 - a).sqrt());
    
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * 3.14159265359 / 180;
  }
  
  /// Cerrar conexión a la base de datos
  Future<void> close() async {
    try {
      await _dataSource.close();
      print('✅ Base de datos cerrada');
    } catch (e) {
      print('❌ Error cerrando base de datos: $e');
    }
  }
}
```

### Instrucciones de Implementación:

1. Abrir el archivo `lib/services/database_service.dart`
2. Eliminar todo el contenido actual (comentarios TODO)
3. Copiar y pegar el código completo de arriba
4. Guardar el archivo

---

## TAREA 2: Actualizar AppSettings para Usar Base de Datos

### Ubicación:
`lib/domain/entities/app_settings.dart`

### Objetivo:
Modificar `AppSettings` para que persista en la base de datos SQLite en lugar de solo en SharedPreferences.

### Cambios a Realizar:

**PASO 2.1: Importar DatabaseService**

Agregar al inicio del archivo (después de los imports existentes):

```dart
import 'package:buscagas/services/database_service.dart';
```

**PASO 2.2: Modificar método `load()`**

Reemplazar el método `load()` completo por:

```dart
static Future<AppSettings> load() async {
  try {
    final dbService = DatabaseService();
    final settings = await dbService.getAppSettings();
    
    if (settings != null) {
      // Cargar desde base de datos
      FuelType fuelType = FuelType.gasolina95;
      try {
        fuelType = FuelType.values.firstWhere(
          (e) => e.name == settings['preferred_fuel'],
        );
      } catch (_) {
        fuelType = FuelType.gasolina95;
      }
      
      return AppSettings(
        searchRadius: settings['search_radius'] as int? ?? 10,
        preferredFuel: fuelType,
        darkMode: (settings['dark_mode'] as int? ?? 0) == 1,
      );
    } else {
      // Si no hay datos en BD, devolver valores por defecto
      return AppSettings(
        searchRadius: 10,
        preferredFuel: FuelType.gasolina95,
        darkMode: false,
      );
    }
  } catch (e) {
    debugPrint('Error cargando configuración desde BD: $e');
    // Fallback a valores por defecto
    return AppSettings(
      searchRadius: 10,
      preferredFuel: FuelType.gasolina95,
      darkMode: false,
    );
  }
}
```

**PASO 2.3: Modificar método `save()`**

Reemplazar el método `save()` completo por:

```dart
Future<void> save() async {
  try {
    final dbService = DatabaseService();
    
    // Guardar en base de datos
    await dbService.updateSearchRadius(searchRadius);
    await dbService.updatePreferredFuel(preferredFuel);
    await dbService.updateDarkMode(darkMode);
    
    debugPrint('✅ Configuración guardada en BD');
  } catch (e) {
    debugPrint('❌ Error guardando configuración en BD: $e');
  }
}
```

**NOTA:** Mantener el método `_loadFromSharedPreferences()` existente como fallback, pero ya no se usará activamente.

---

## TAREA 3: Inicializar Base de Datos en SplashScreen

### Ubicación:
`lib/presentation/screens/splash_screen.dart`

### Objetivo:
Asegurar que la base de datos se inicialice correctamente al inicio de la app.

### Cambios a Realizar:

**PASO 3.1: Importar DatabaseService**

Agregar al inicio del archivo:

```dart
import 'package:buscagas/services/database_service.dart';
```

**PASO 3.2: Modificar método `_initializeApp()`**

Buscar el método `_initializeApp()` y agregar la inicialización de BD después de la verificación de primera ejecución:

Localizar esta sección (aprox. línea 75):

```dart
Future<void> _initializeApp() async {
  try {
    // 1. Verificar si es primera ejecución
    final isFirstRun = await _isFirstRun();
```

Inmediatamente después del bloque del diálogo de tema, agregar:

```dart
// [Código existente del diálogo de tema...]

// NUEVO: Inicializar base de datos
try {
  final dbService = DatabaseService();
  await dbService.initialize();
  debugPrint('✅ Base de datos inicializada');
} catch (e) {
  debugPrint('❌ Error inicializando BD: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al inicializar base de datos')),
    );
  }
}

// 4. Carga inicial (opcional en este paso, se puede hacer en MapScreen)
await Future.delayed(const Duration(seconds: 1));
```

**Posición exacta:** Después de `await _setFirstRunComplete();` y antes de `await Future.delayed(const Duration(seconds: 1));`

---

## TAREA 4: Crear Archivo de Pruebas (Opcional pero Recomendado)

### Ubicación:
`test/services/database_service_test.dart`

### Propósito:
Verificar que el servicio de base de datos funciona correctamente.

### Código Completo:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/services/database_service.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DatabaseService Tests', () {
    late DatabaseService dbService;
    
    setUp(() async {
      dbService = DatabaseService();
      await dbService.initialize();
      await dbService.clearCache();
    });
    
    tearDown(() async {
      await dbService.clearCache();
    });
    
    test('Debe inicializar la base de datos sin errores', () async {
      await dbService.initialize();
      final hasData = await dbService.hasData();
      expect(hasData, false); // Debería estar vacía después de clearCache
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
      
      await dbService.saveStations(testStations);
      
      final retrieved = await dbService.getAllStations();
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
      
      await dbService.saveStations(testStations);
      
      final nearby = await dbService.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10,
      );
      
      expect(nearby.length, 1);
      expect(nearby[0].name, 'Cerca');
    });
    
    test('Debe actualizar configuración', () async {
      await dbService.updateSearchRadius(20);
      await dbService.updatePreferredFuel(FuelType.dieselGasoleoA);
      await dbService.updateDarkMode(true);
      
      final settings = await dbService.getAppSettings();
      expect(settings?['search_radius'], 20);
      expect(settings?['preferred_fuel'], 'dieselGasoleoA');
      expect(settings?['dark_mode'], 1);
    });
    
    test('Debe verificar caché desactualizado', () async {
      final isStale = await dbService.isCacheStale(
        maxAge: Duration(seconds: 1),
      );
      expect(isStale, true); // No hay datos, debería ser stale
      
      // Guardar datos
      await dbService.saveStations([
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
      
      final isStaleNow = await dbService.isCacheStale(
        maxAge: Duration(hours: 24),
      );
      expect(isStaleNow, false); // Acabamos de guardar, no debería ser stale
    });
  });
}
```

### Instrucciones para Pruebas:

1. Crear el directorio `test/services/` si no existe
2. Crear el archivo `database_service_test.dart`
3. Copiar el código de arriba
4. Ejecutar: `flutter test test/services/database_service_test.dart`

---

## TAREA 5: Actualizar Constantes (Opcional)

### Ubicación:
`lib/core/constants/app_constants.dart`

### Cambios Sugeridos:

Agregar constantes relacionadas con la base de datos:

```dart
// Configuración de caché
static const Duration cacheMaxAge = Duration(hours: 24);
static const Duration cacheStaleWarning = Duration(hours: 12);

// Límites de base de datos
static const int maxCachedStations = 10000;
static const int batchInsertSize = 100;
```

Esto es opcional, ya que las constantes actuales son suficientes.

---

## CHECKLIST DE IMPLEMENTACIÓN

### Obligatorio:
- [ ] Implementar `DatabaseService` completo
- [ ] Actualizar `AppSettings.load()` para usar BD
- [ ] Actualizar `AppSettings.save()` para usar BD
- [ ] Inicializar BD en `SplashScreen._initializeApp()`
- [ ] Probar la app manualmente (verificar que no crashea)

### Recomendado:
- [ ] Crear y ejecutar tests de `DatabaseService`
- [ ] Verificar que la configuración se persiste correctamente
- [ ] Verificar que los datos se guardan y recuperan correctamente
- [ ] Actualizar constantes si es necesario

### Validación:
- [ ] La app inicia sin errores
- [ ] El tema se guarda y recupera correctamente
- [ ] La configuración persiste entre reinicios de la app
- [ ] No hay errores en la consola relacionados con BD

---

## CÓMO PROBAR QUE FUNCIONA

### Prueba Manual 1: Persistencia de Tema

1. Ejecutar la app
2. Ir a configuración (cuando se implemente)
3. Cambiar el tema a oscuro
4. Cerrar la app completamente
5. Volver a abrir
6. **Resultado esperado:** El tema oscuro se mantiene

### Prueba Manual 2: Base de Datos

1. Ejecutar la app
2. Verificar en los logs (Debug Console) que aparece:
   - `✅ Base de datos inicializada correctamente`
   - `✅ Configuración guardada en BD`
3. **Resultado esperado:** No hay errores de base de datos

### Prueba Manual 3: Conteo de Gasolineras (Para después del Paso 5)

Después de implementar la API:

```dart
// En algún lugar de prueba (ej. MapScreen):
final dbService = DatabaseService();
final count = await dbService.getCachedStationCount();
print('Gasolineras en caché: $count');
```

---

## ERRORES COMUNES Y SOLUCIONES

### Error: "MissingPluginException"
**Causa:** El plugin sqflite no está instalado correctamente.
**Solución:** 
```bash
flutter pub get
flutter clean
flutter pub get
```

### Error: "Database is locked"
**Causa:** Intentar acceder desde múltiples instancias.
**Solución:** Usar siempre el singleton `DatabaseService()`.

### Error: "No such table: gas_stations"
**Causa:** La base de datos no se inicializó correctamente.
**Solución:** Llamar a `dbService.initialize()` al inicio.

### Error: "UNIQUE constraint failed"
**Causa:** Intentar insertar gasolinera con ID duplicado.
**Solución:** Usar `saveStations()` que limpia antes de insertar, o manejar conflictos.

---

## NOTAS IMPORTANTES

1. **Singleton Pattern:** `DatabaseService` usa singleton, siempre obtener instancia con `DatabaseService()`.

2. **Rendimiento:** Las operaciones de BD son asíncronas. Siempre usar `await`.

3. **Errores:** Todos los métodos tienen manejo de errores con `try-catch`. Los errores se imprimen en consola.

4. **Caché:** La base de datos actúa como caché local. Se debe sincronizar con la API periódicamente.

5. **Distancias:** El cálculo de distancia usa la fórmula de Haversine, precisa para distancias cortas.

6. **Configuración:** La tabla `app_settings` es un singleton (solo una fila con id=1).

---

## PRÓXIMOS PASOS (Paso 5)

Una vez completado el Paso 4, el siguiente paso será:

**Paso 5: Integrar API Gubernamental**
- Crear `ApiDataSource` en `lib/data/datasources/remote/api_datasource.dart`
- Implementar cliente HTTP
- Parsear respuestas JSON de la API
- Gestionar errores de red
- Conectar con `DatabaseService` para cachear datos

---

**Fecha de creación:** 19 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Paso:** 4 - Base de Datos Local (Instrucciones Detalladas)  
**Metodología:** Métrica v3
