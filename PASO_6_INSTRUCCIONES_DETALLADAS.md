# PASO 6: IMPLEMENTAR REPOSITORIOS - INSTRUCCIONES DETALLADAS

## Estado Actual del Proyecto

### ✅ Ya Implementado:
- **`GasStationRepository`** (interfaz) en `lib/domain/repositories/gas_station_repository.dart` - ✅ COMPLETO
  - Define 4 métodos abstractos: `fetchRemoteStations()`, `getCachedStations()`, `updateCache()`, `getNearbyStations()`
  
- **`GasStationRepositoryImpl`** (implementación) en `lib/data/repositories/gas_station_repository_impl.dart` - ✅ COMPLETO
  - Implementa los 4 métodos de la interfaz
  - Inyección de dependencias: `ApiDataSource` y `DatabaseDataSource`
  - Conversión model → entity con `toDomain()`
  - Filtrado geográfico con `isWithinRadius()`
  - Ordenación por distancia con fórmula de Haversine
  
- **`SyncService`** en `lib/services/sync_service.dart` - ✅ PARCIALMENTE IMPLEMENTADO
  - Ya usa `GasStationRepository`
  - Sincronización periódica cada 30 minutos
  - Verificación de conectividad

### 🔴 Pendiente de Implementar:

1. **Tests unitarios del repositorio**
2. **Ejemplo de uso del repositorio**
3. **Documentación de integración**
4. **Validación completa del flujo**

---

## ANÁLISIS DE LO QUE FALTA

Después de analizar el código existente y la documentación Métrica V3, el **Paso 6 está prácticamente completo** en términos de código funcional. Sin embargo, faltan los siguientes elementos complementarios para considerarlo 100% terminado:

### 1. Tests Unitarios (Recomendado)
### 2. Ejemplo Ejecutable de Uso (Recomendado)
### 3. Script de Validación del Flujo Completo (Obligatorio)
### 4. Documentación de Integración (Opcional)

---

## TAREA 1: Crear Tests Unitarios del Repositorio

### Ubicación:
`test/repositories/gas_station_repository_test.dart`

### Propósito:
Validar que el repositorio funciona correctamente con datos mockeados, sin necesidad de conexión a internet o base de datos real.

### Código Completo:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/data/models/gas_station_model.dart';
import 'package:buscagas/data/models/fuel_price_model.dart';

// Generar mocks con mockito
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
    
    test('fetchRemoteStations debe descargar y convertir datos de la API', () async {
      // Arrange: Preparar datos mock
      final mockModels = [
        GasStationModel(
          id: '1',
          name: 'Repsol Madrid',
          latitude: 40.4168,
          longitude: -3.7038,
          address: 'Calle Mayor 1',
          locality: 'Madrid',
          operator: 'Repsol',
          prices: [
            FuelPriceModel(
              fuelType: 'gasolina95',
              price: 1.459,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStationModel(
          id: '2',
          name: 'Cepsa Barcelona',
          latitude: 41.3851,
          longitude: 2.1734,
          address: 'Rambla Catalunya 10',
          locality: 'Barcelona',
          operator: 'Cepsa',
          prices: [
            FuelPriceModel(
              fuelType: 'dieselGasoleoA',
              price: 1.389,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];
      
      when(mockApiDataSource.fetchAllStations())
          .thenAnswer((_) async => mockModels);
      
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
      when(mockApiDataSource.fetchAllStations())
          .thenThrow(ApiException('Error de red', type: ApiErrorType.noConnection));
      
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
    
    test('getCachedStations debe retornar lista vacía si no hay caché', () async {
      // Arrange
      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => []);
      
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
      
      when(mockDatabaseDataSource.clearAll())
          .thenAnswer((_) async => {});
      when(mockDatabaseDataSource.insertBatch(any))
          .thenAnswer((_) async => {});
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
        // Estación muy cerca (Madrid centro: 40.4168, -3.7038)
        GasStation(
          id: '1',
          name: 'Cerca',
          latitude: 40.4200, // ~350m de distancia
          longitude: -3.7050,
          address: 'Cerca',
          locality: 'Madrid',
          operator: 'Test',
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              price: 1.50,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        // Estación lejos (fuera del radio de 5 km)
        GasStation(
          id: '2',
          name: 'Lejos',
          latitude: 40.5000, // ~10 km de distancia
          longitude: -3.8000,
          address: 'Lejos',
          locality: 'Madrid',
          operator: 'Test',
          prices: [],
        ),
        // Estación medio (dentro de 5 km)
        GasStation(
          id: '3',
          name: 'Medio',
          latitude: 40.4500, // ~4 km de distancia
          longitude: -3.7200,
          address: 'Medio',
          locality: 'Madrid',
          operator: 'Test',
          prices: [],
        ),
      ];
      
      when(mockDatabaseDataSource.getAllStations())
          .thenAnswer((_) async => allStations);
      
      // Act: Buscar con radio de 5 km
      final result = await repository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 5.0,
      );
      
      // Assert
      expect(result.length, 2); // Solo 'Cerca' y 'Medio', no 'Lejos'
      expect(result[0].name, 'Cerca'); // Primera porque está más cerca
      expect(result[1].name, 'Medio');
    });
    
    test('getNearbyStations debe retornar lista vacía si no hay estaciones cercanas', () async {
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
      final mockModels = [
        GasStationModel(
          id: '1',
          name: 'Estación 1',
          latitude: 40.4200,
          longitude: -3.7050,
          address: 'Calle 1',
          locality: 'Madrid',
          operator: 'Repsol',
          prices: [],
        ),
        GasStationModel(
          id: '2',
          name: 'Estación 2',
          latitude: 40.4500,
          longitude: -3.7200,
          address: 'Calle 2',
          locality: 'Madrid',
          operator: 'Cepsa',
          prices: [],
        ),
      ];
      
      when(mockApiDataSource.fetchAllStations())
          .thenAnswer((_) async => mockModels);
      when(mockDatabaseDataSource.clearAll())
          .thenAnswer((_) async => {});
      when(mockDatabaseDataSource.insertBatch(any))
          .thenAnswer((_) async => {});
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
      expect(nearbyStations.length, 2);
      expect(nearbyStations[0].name, 'Estación 1'); // Más cerca
    });
  });
}
```

### Instrucciones de Implementación:

1. Crear el directorio `test/repositories/` si no existe
2. Crear el archivo `gas_station_repository_test.dart`
3. Copiar el código completo
4. Ejecutar generación de mocks:
   ```bash
   flutter pub run build_runner build
   ```
5. Ejecutar tests:
   ```bash
   flutter test test/repositories/gas_station_repository_test.dart
   ```

**Nota:** Si `build_runner` no está instalado, agregar a `pubspec.yaml`:
```yaml
dev_dependencies:
  build_runner: ^2.4.6
  mockito: ^5.4.2
```

---

## TAREA 2: Crear Ejemplo de Uso del Repositorio

### Ubicación:
`lib/examples/repository_usage_example.dart`

### Propósito:
Demostrar cómo usar el repositorio en diferentes escenarios del mundo real.

### Código Completo:

```dart
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

/// EJEMPLOS DE USO DEL REPOSITORY PATTERN
/// 
/// Este archivo muestra cómo usar GasStationRepository
/// en diferentes escenarios de la aplicación

class RepositoryUsageExamples {
  
  /// Ejemplo 1: Inicialización del repositorio con inyección de dependencias
  static GasStationRepository createRepository() {
    final apiDataSource = ApiDataSource();
    final databaseDataSource = DatabaseDataSource();
    
    return GasStationRepositoryImpl(
      apiDataSource,
      databaseDataSource,
    );
  }
  
  /// Ejemplo 2: Carga inicial de datos (primera vez que se abre la app)
  static Future<void> example1InitialLoad() async {
    print('\n=== EJEMPLO 1: Carga Inicial ===\n');
    
    final repository = createRepository();
    
    try {
      // 1. Intentar obtener datos desde API
      print('📥 Descargando datos desde API...');
      final stations = await repository.fetchRemoteStations();
      print('✅ Descargadas ${stations.length} gasolineras');
      
      // 2. Guardar en caché para uso offline
      print('💾 Guardando en caché local...');
      await repository.updateCache(stations);
      print('✅ Caché actualizado');
      
      // 3. Mostrar primeras 3 estaciones
      print('\n📋 Primeras 3 gasolineras:');
      for (var station in stations.take(3)) {
        print('  - ${station.name} (${station.locality})');
        print('    ${station.latitude}, ${station.longitude}');
      }
      
    } catch (e) {
      print('❌ Error en carga inicial: $e');
    }
  }
  
  /// Ejemplo 2: Obtener gasolineras cercanas a ubicación del usuario
  static Future<void> example2GetNearby() async {
    print('\n=== EJEMPLO 2: Gasolineras Cercanas ===\n');
    
    final repository = createRepository();
    
    try {
      // Coordenadas de Madrid centro
      const double userLat = 40.4168;
      const double userLon = -3.7038;
      const double radiusKm = 10.0;
      
      print('📍 Ubicación del usuario: $userLat, $userLon');
      print('🔍 Buscando en radio de $radiusKm km...');
      
      final nearbyStations = await repository.getNearbyStations(
        latitude: userLat,
        longitude: userLon,
        radiusKm: radiusKm,
      );
      
      print('✅ Encontradas ${nearbyStations.length} gasolineras cercanas');
      
      // Mostrar las 5 más cercanas
      print('\n📋 5 gasolineras más cercanas:');
      for (var i = 0; i < nearbyStations.take(5).length; i++) {
        final station = nearbyStations[i];
        final distance = station.calculateDistance(userLat, userLon);
        print('  ${i + 1}. ${station.name}');
        print('     Distancia: ${distance.toStringAsFixed(2)} km');
        print('     Dirección: ${station.address}');
      }
      
    } catch (e) {
      print('❌ Error al buscar cercanas: $e');
    }
  }
  
  /// Ejemplo 3: Estrategia de caché primero (Cache-First)
  /// Cargar desde caché inmediatamente, actualizar en background
  static Future<void> example3CacheFirst() async {
    print('\n=== EJEMPLO 3: Estrategia Cache-First ===\n');
    
    final repository = createRepository();
    
    try {
      // PASO 1: Cargar desde caché inmediatamente (rápido)
      print('📂 Cargando desde caché...');
      final cachedStations = await repository.getCachedStations();
      
      if (cachedStations.isNotEmpty) {
        print('✅ Mostrando ${cachedStations.length} gasolineras en caché');
        print('   (Usuario ve datos inmediatamente)');
      } else {
        print('⚠️ Caché vacío, mostrando pantalla de carga');
      }
      
      // PASO 2: Actualizar desde API en background (lento)
      print('\n🌐 Actualizando desde API en background...');
      try {
        final freshStations = await repository.fetchRemoteStations();
        await repository.updateCache(freshStations);
        print('✅ Caché actualizado con ${freshStations.length} gasolineras');
        print('   (UI se actualiza con datos frescos)');
      } catch (e) {
        print('⚠️ Error al actualizar, manteniendo caché: $e');
        print('   (Usuario sigue viendo datos antiguos)');
      }
      
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  /// Ejemplo 4: Estrategia de red primero (Network-First)
  /// Intentar API, si falla usar caché
  static Future<void> example4NetworkFirst() async {
    print('\n=== EJEMPLO 4: Estrategia Network-First ===\n');
    
    final repository = createRepository();
    
    try {
      // PASO 1: Intentar obtener datos frescos desde API
      print('🌐 Intentando descargar desde API...');
      
      try {
        final freshStations = await repository.fetchRemoteStations();
        await repository.updateCache(freshStations);
        
        print('✅ Datos frescos: ${freshStations.length} gasolineras');
        print('   (Usuario ve datos actualizados)');
        
      } catch (apiError) {
        // PASO 2: Si falla API, usar caché como fallback
        print('⚠️ API no disponible: $apiError');
        print('📂 Intentando cargar desde caché...');
        
        final cachedStations = await repository.getCachedStations();
        
        if (cachedStations.isNotEmpty) {
          print('✅ Usando caché: ${cachedStations.length} gasolineras');
          print('   (Usuario ve datos antiguos pero funcionales)');
        } else {
          print('❌ No hay datos en caché');
          print('   (Mostrar mensaje: "Sin conexión y sin datos")');
        }
      }
      
    } catch (e) {
      print('❌ Error crítico: $e');
    }
  }
  
  /// Ejemplo 5: Sincronización periódica (usado por SyncService)
  static Future<void> example5PeriodicSync() async {
    print('\n=== EJEMPLO 5: Sincronización Periódica ===\n');
    
    final repository = createRepository();
    
    try {
      // Simular sincronización periódica cada X minutos
      print('⏰ Ejecutando sincronización automática...');
      
      // 1. Obtener datos frescos
      final freshStations = await repository.fetchRemoteStations();
      
      // 2. Obtener datos actuales en caché
      final cachedStations = await repository.getCachedStations();
      
      // 3. Comparar si hay cambios
      final hasChanges = freshStations.length != cachedStations.length;
      
      if (hasChanges) {
        print('🔄 Detectados cambios, actualizando caché...');
        await repository.updateCache(freshStations);
        print('✅ Caché actualizado');
        print('   (Notificar UI: "Datos actualizados")');
      } else {
        print('✅ Datos sin cambios, caché vigente');
        print('   (No se notifica al usuario)');
      }
      
    } catch (e) {
      print('⚠️ Sincronización fallida: $e');
      print('   (Reintentar en próximo ciclo)');
    }
  }
  
  /// Ejemplo 6: Búsqueda con diferentes radios
  static Future<void> example6DifferentRadii() async {
    print('\n=== EJEMPLO 6: Búsqueda con Diferentes Radios ===\n');
    
    final repository = createRepository();
    
    const double userLat = 40.4168;
    const double userLon = -3.7038;
    
    final radii = [5, 10, 20, 50]; // Radios configurables en AppSettings
    
    print('📍 Ubicación: $userLat, $userLon\n');
    
    for (var radius in radii) {
      try {
        final stations = await repository.getNearbyStations(
          latitude: userLat,
          longitude: userLon,
          radiusKm: radius.toDouble(),
        );
        
        print('📏 Radio: $radius km → ${stations.length} gasolineras');
        
      } catch (e) {
        print('📏 Radio: $radius km → Error: $e');
      }
    }
  }
}

/// Función principal para ejecutar ejemplos
void main() async {
  print('╔════════════════════════════════════════════╗');
  print('║  EJEMPLOS DE USO DE REPOSITORY PATTERN    ║');
  print('╚════════════════════════════════════════════╝');
  
  // Descomentar el ejemplo que quieras ejecutar:
  
  // await RepositoryUsageExamples.example1InitialLoad();
  // await RepositoryUsageExamples.example2GetNearby();
  // await RepositoryUsageExamples.example3CacheFirst();
  // await RepositoryUsageExamples.example4NetworkFirst();
  // await RepositoryUsageExamples.example5PeriodicSync();
  await RepositoryUsageExamples.example6DifferentRadii();
  
  print('\n✅ Ejemplos completados');
}
```

### Instrucciones de Implementación:

1. Crear el archivo `lib/examples/repository_usage_example.dart`
2. Copiar el código completo
3. Guardar el archivo

**Para ejecutar los ejemplos:**

```bash
# Ejecutar un ejemplo específico
dart run lib/examples/repository_usage_example.dart
```

**Nota:** Necesitas conexión a internet activa para ejemplos que usan la API real.

---

## TAREA 3: Crear Script de Validación del Flujo Completo

### Ubicación:
`scripts/validate_repository.dart`

### Propósito:
Script ejecutable que valida que todo el flujo del repositorio funciona correctamente de principio a fin.

### Código Completo:

```dart
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/services/database_service.dart';

/// SCRIPT DE VALIDACIÓN DEL PASO 6
/// 
/// Verifica que el repositorio funcione correctamente
/// en el flujo completo: API → Caché → Filtrado → Ordenación

Future<void> main() async {
  print('╔════════════════════════════════════════════╗');
  print('║   VALIDACIÓN DEL PASO 6: REPOSITORIOS     ║');
  print('╚════════════════════════════════════════════╝\n');
  
  bool allTestsPassed = true;
  
  // ==================== TEST 1: Inicializar DB ====================
  
  print('📝 TEST 1: Inicializar base de datos');
  try {
    final dbService = DatabaseService();
    await dbService.initialize();
    print('✅ Base de datos inicializada correctamente\n');
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 2: Crear Repositorio ====================
  
  print('📝 TEST 2: Crear instancia de repositorio');
  late GasStationRepositoryImpl repository;
  
  try {
    final apiDataSource = ApiDataSource();
    final databaseDataSource = DatabaseDataSource();
    
    repository = GasStationRepositoryImpl(
      apiDataSource,
      databaseDataSource,
    );
    
    print('✅ Repositorio creado con inyección de dependencias\n');
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
    return;
  }
  
  // ==================== TEST 3: Fetch Remote ====================
  
  print('📝 TEST 3: Descargar desde API remota');
  print('   ⏳ Esto puede tardar 15-30 segundos...');
  
  try {
    final remoteStations = await repository.fetchRemoteStations();
    
    if (remoteStations.isEmpty) {
      print('❌ FALLÓ: API retornó lista vacía\n');
      allTestsPassed = false;
    } else {
      print('✅ Descargadas ${remoteStations.length} gasolineras');
      print('   Primera: ${remoteStations.first.name}');
      print('   Coordenadas: ${remoteStations.first.latitude}, ${remoteStations.first.longitude}\n');
    }
    
  } catch (e) {
    print('❌ FALLÓ: $e');
    print('   (Verifica conexión a internet)\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 4: Update Cache ====================
  
  print('📝 TEST 4: Actualizar caché local');
  
  try {
    final freshData = await repository.fetchRemoteStations();
    await repository.updateCache(freshData);
    
    print('✅ Caché actualizado con ${freshData.length} registros\n');
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 5: Get Cached ====================
  
  print('📝 TEST 5: Obtener desde caché local');
  
  try {
    final cachedStations = await repository.getCachedStations();
    
    if (cachedStations.isEmpty) {
      print('❌ FALLÓ: Caché está vacío después de updateCache()\n');
      allTestsPassed = false;
    } else {
      print('✅ Recuperadas ${cachedStations.length} gasolineras desde caché');
      print('   Primera: ${cachedStations.first.name}\n');
    }
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 6: Get Nearby (Madrid) ====================
  
  print('📝 TEST 6: Filtrar gasolineras cercanas (Madrid)');
  
  try {
    // Coordenadas de Madrid centro
    const double madridLat = 40.4168;
    const double madridLon = -3.7038;
    const double radius = 10.0;
    
    print('   📍 Ubicación: $madridLat, $madridLon');
    print('   📏 Radio: $radius km');
    
    final nearbyStations = await repository.getNearbyStations(
      latitude: madridLat,
      longitude: madridLon,
      radiusKm: radius,
    );
    
    if (nearbyStations.isEmpty) {
      print('⚠️  ADVERTENCIA: No hay gasolineras en radio de $radius km');
      print('   (Puede ser normal si no hay estaciones en esa zona)\n');
    } else {
      print('✅ Encontradas ${nearbyStations.length} gasolineras cercanas');
      
      // Verificar que están ordenadas por distancia
      print('   🔍 Verificando ordenación por distancia:');
      
      for (var i = 0; i < nearbyStations.take(3).length; i++) {
        final station = nearbyStations[i];
        final distance = station.calculateDistance(madridLat, madridLon);
        print('      ${i + 1}. ${station.name}');
        print('         Distancia: ${distance.toStringAsFixed(2)} km');
      }
      
      // Verificar que el orden es correcto
      bool properlyOrdered = true;
      for (var i = 0; i < nearbyStations.length - 1; i++) {
        final dist1 = nearbyStations[i].calculateDistance(madridLat, madridLon);
        final dist2 = nearbyStations[i + 1].calculateDistance(madridLat, madridLon);
        if (dist1 > dist2) {
          properlyOrdered = false;
          break;
        }
      }
      
      if (properlyOrdered) {
        print('\n✅ Ordenación correcta: distancias ascendentes\n');
      } else {
        print('\n❌ FALLÓ: Ordenación incorrecta\n');
        allTestsPassed = false;
      }
    }
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 7: Get Nearby (Barcelona) ====================
  
  print('📝 TEST 7: Filtrar gasolineras cercanas (Barcelona)');
  
  try {
    const double barcelonaLat = 41.3851;
    const double barcelonaLon = 2.1734;
    const double radius = 5.0;
    
    print('   📍 Ubicación: $barcelonaLat, $barcelonaLon');
    print('   📏 Radio: $radius km');
    
    final nearbyStations = await repository.getNearbyStations(
      latitude: barcelonaLat,
      longitude: barcelonaLon,
      radiusKm: radius,
    );
    
    print('✅ Encontradas ${nearbyStations.length} gasolineras en Barcelona\n');
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 8: Diferentes radios ====================
  
  print('📝 TEST 8: Probar diferentes radios de búsqueda');
  
  try {
    const double testLat = 40.4168;
    const double testLon = -3.7038;
    
    final radii = [5, 10, 20, 50];
    int previousCount = 0;
    
    for (var radius in radii) {
      final stations = await repository.getNearbyStations(
        latitude: testLat,
        longitude: testLon,
        radiusKm: radius.toDouble(),
      );
      
      print('   📏 Radio $radius km: ${stations.length} gasolineras');
      
      // Verificar que a mayor radio, más gasolineras (o igual)
      if (stations.length < previousCount) {
        print('❌ FALLÓ: Radio mayor tiene menos gasolineras\n');
        allTestsPassed = false;
        break;
      }
      
      previousCount = stations.length;
    }
    
    print('✅ Radios funcionan correctamente\n');
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== RESUMEN FINAL ====================
  
  print('╔════════════════════════════════════════════╗');
  print('║            RESUMEN DE VALIDACIÓN          ║');
  print('╚════════════════════════════════════════════╝\n');
  
  if (allTestsPassed) {
    print('🎉 ¡TODOS LOS TESTS PASARON!');
    print('✅ El Paso 6 está completamente funcional');
    print('\nComponentes validados:');
    print('  ✅ Inicialización de base de datos');
    print('  ✅ Creación de repositorio');
    print('  ✅ Descarga desde API');
    print('  ✅ Actualización de caché');
    print('  ✅ Lectura desde caché');
    print('  ✅ Filtrado geográfico');
    print('  ✅ Ordenación por distancia');
    print('  ✅ Múltiples radios de búsqueda');
  } else {
    print('❌ ALGUNOS TESTS FALLARON');
    print('⚠️  Revisa los errores arriba');
    print('\nAcciones sugeridas:');
    print('  1. Verifica conexión a internet');
    print('  2. Revisa permisos de base de datos');
    print('  3. Ejecuta flutter clean && flutter pub get');
    print('  4. Revisa logs de errores');
  }
  
  print('\n' + '=' * 48);
}
```

### Instrucciones de Implementación:

1. Crear el directorio `scripts/` en la raíz del proyecto
2. Crear el archivo `validate_repository.dart`
3. Copiar el código completo
4. Ejecutar el script:

```bash
dart run scripts/validate_repository.dart
```

**Requisitos:**
- Conexión a internet activa
- Permisos de escritura en el dispositivo
- Base de datos SQLite funcional

---

## TAREA 4: Crear Documentación de Integración (Opcional)

### Ubicación:
`docs/REPOSITORY_INTEGRATION.md`

### Propósito:
Documentar cómo el repositorio se integra con el resto del sistema.

### Contenido:

```markdown
# Integración del Repository Pattern en BuscaGas

## Descripción General

El `GasStationRepository` es el componente central de la capa de datos que coordina el acceso a:
- **Fuente remota**: API del gobierno español
- **Fuente local**: Base de datos SQLite

## Arquitectura de Integración

```
┌─────────────────────────────────────┐
│     CAPA DE PRESENTACIÓN            │
│        (MapScreen, UI)              │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│    CAPA DE LÓGICA DE NEGOCIO        │
│      (MapBloc, UseCases)            │
└─────────────┬───────────────────────┘
              │
              ▼ usa interfaz
┌─────────────────────────────────────┐
│       CAPA DE DOMINIO               │
│  GasStationRepository (INTERFAZ)    │
└─────────────┬───────────────────────┘
              │
              ▼ implementa
┌─────────────────────────────────────┐
│       CAPA DE DATOS                 │
│  GasStationRepositoryImpl           │
└──────┬──────────────────┬───────────┘
       │                  │
       ▼                  ▼
┌─────────────┐   ┌────────────────┐
│ApiDataSource│   │DatabaseDataSource│
└─────────────┘   └────────────────┘
```

## Componentes que Usan el Repositorio

### 1. SyncService

**Ubicación:** `lib/services/sync_service.dart`

**Uso:**
```dart
class SyncService {
  final GasStationRepository _repository;
  
  Future<void> performSync() async {
    // Descargar datos frescos
    final fresh = await _repository.fetchRemoteStations();
    
    // Actualizar caché
    await _repository.updateCache(fresh);
  }
}
```

### 2. MapBloc (Próximo Paso 8)

**Uso previsto:**
```dart
class MapBloc extends Bloc<MapEvent, MapState> {
  final GasStationRepository _repository;
  
  Future<void> _onLoadMap(LoadMap event) async {
    // Obtener gasolineras cercanas
    final nearby = await _repository.getNearbyStations(
      latitude: event.lat,
      longitude: event.lon,
      radiusKm: 10.0,
    );
    
    emit(MapLoaded(stations: nearby));
  }
}
```

### 3. GetNearbyStationsUseCase (Próximo Paso 7)

**Uso previsto:**
```dart
class GetNearbyStationsUseCase {
  final GasStationRepository repository;
  
  Future<List<GasStation>> call({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    return repository.getNearbyStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
```

## Estrategias de Caché

### Cache-First (Recomendado para pantalla principal)

```dart
// 1. Cargar desde caché inmediatamente
final cached = await repository.getCachedStations();
emit(MapLoaded(stations: cached));

// 2. Actualizar en background
try {
  final fresh = await repository.fetchRemoteStations();
  await repository.updateCache(fresh);
  emit(MapLoaded(stations: fresh));
} catch (e) {
  // Mantener caché si falla API
}
```

### Network-First (Recomendado para sincronización manual)

```dart
try {
  // 1. Intentar API primero
  final fresh = await repository.fetchRemoteStations();
  await repository.updateCache(fresh);
  emit(MapLoaded(stations: fresh));
} catch (e) {
  // 2. Fallback a caché
  final cached = await repository.getCachedStations();
  emit(MapLoaded(stations: cached));
}
```

## Manejo de Errores

### Errores de API

```dart
try {
  await repository.fetchRemoteStations();
} on ApiException catch (e) {
  switch (e.type) {
    case ApiErrorType.noConnection:
      // Sin internet
      break;
    case ApiErrorType.timeout:
      // Timeout
      break;
    // ... otros casos
  }
}
```

### Errores de Base de Datos

```dart
try {
  await repository.getCachedStations();
} catch (e) {
  // Error de BD local
  print('Error de BD: $e');
}
```

## Testing

### Crear Mocks

```dart
class MockGasStationRepository extends Mock 
    implements GasStationRepository {}

test('should load nearby stations', () async {
  final mockRepo = MockGasStationRepository();
  
  when(mockRepo.getNearbyStations(
    latitude: any,
    longitude: any,
    radiusKm: any,
  )).thenAnswer((_) async => mockStations);
  
  // Usar mock en test
});
```

## Mejores Prácticas

1. **Siempre usar la interfaz** `GasStationRepository`, nunca la implementación directamente
2. **Inyectar dependencias** en constructores (facilita testing)
3. **Manejar errores** apropiadamente en cada capa
4. **Usar caché** para mejorar experiencia offline
5. **Actualizar caché** periódicamente en background

## Troubleshooting

### Problema: "No hay gasolineras cercanas"

**Causa:** Radio demasiado pequeño o ubicación remota

**Solución:**
- Aumentar radio de búsqueda
- Verificar coordenadas del usuario
- Verificar que hay datos en caché

### Problema: "Error al actualizar caché"

**Causa:** Permisos de escritura o BD corrupta

**Solución:**
- Verificar permisos de almacenamiento
- Borrar y recrear base de datos
- Ejecutar `flutter clean`

---

**Última actualización:** 19 de noviembre de 2025  
**Versión:** BuscaGas v1.0.0
```

### Instrucciones de Implementación:

1. Crear el directorio `docs/` si no existe
2. Crear el archivo `REPOSITORY_INTEGRATION.md`
3. Copiar el contenido completo
4. Guardar el archivo

---

## CHECKLIST DE IMPLEMENTACIÓN DEL PASO 6

### Código Funcional (Ya implementado ✅):

- [x] `lib/domain/repositories/gas_station_repository.dart` - Interfaz
- [x] `lib/data/repositories/gas_station_repository_impl.dart` - Implementación
- [x] Inyección de `ApiDataSource` y `DatabaseDataSource`
- [x] Método `fetchRemoteStations()` implementado
- [x] Método `getCachedStations()` implementado
- [x] Método `updateCache()` implementado
- [x] Método `getNearbyStations()` implementado
- [x] Filtrado geográfico con `isWithinRadius()`
- [x] Ordenación por distancia con Haversine
- [x] Conversión model → entity con `toDomain()`

### Tests y Validación (Pendiente):

- [ ] `test/repositories/gas_station_repository_test.dart` - Tests unitarios
- [ ] Generar mocks con `build_runner`
- [ ] Ejecutar tests con `flutter test`

### Ejemplos y Documentación (Pendiente):

- [ ] `lib/examples/repository_usage_example.dart` - Ejemplos de uso
- [ ] `scripts/validate_repository.dart` - Script de validación
- [ ] `docs/REPOSITORY_INTEGRATION.md` - Documentación de integración

### Verificaciones Finales:

- [ ] `flutter analyze` sin errores
- [ ] Ejecutar script de validación
- [ ] Tests unitarios pasando
- [ ] Ejemplos ejecutables funcionan

---

## CÓMO VALIDAR QUE EL PASO 6 ESTÁ COMPLETO

### Validación Rápida (5 minutos):

```bash
# 1. Verificar que no hay errores
flutter analyze

# 2. Ejecutar script de validación
dart run scripts/validate_repository.dart

# 3. Verificar salida esperada:
#    ✅ 8 tests pasados
#    ✅ Descarga desde API funciona
#    ✅ Caché funciona
#    ✅ Filtrado geográfico funciona
```

### Validación Completa (15 minutos):

```bash
# 1. Ejecutar todos los tests
flutter test test/repositories/gas_station_repository_test.dart

# 2. Ejecutar ejemplos
dart run lib/examples/repository_usage_example.dart

# 3. Verificar integración con SyncService
# (Ejecutar app y verificar que sincroniza datos)
```

---

## PRÓXIMOS PASOS

Una vez completado el Paso 6, el siguiente paso será:

**PASO 7: Implementar Casos de Uso**
- Crear `GetNearbyStationsUseCase`
- Crear `FilterByFuelTypeUseCase`
- Crear `CalculateDistanceUseCase`
- Lógica de negocio independiente de UI y datos
- Usar el repositorio que acabamos de implementar

---

**Fecha de creación:** 19 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Paso:** 6 - Implementar Repositorios (Instrucciones Detalladas)  
**Metodología:** Métrica v3
