# PASO 6: Implementar Repositorios

## Información extraída de la Documentación V3 para el Paso 6

---

## 🎯 OBJETIVO DEL PASO 6
- Crear interfaces de repositorios en la capa de dominio
- Implementar repositorios concretos en la capa de datos
- Combinar fuentes de datos locales (DatabaseDataSource) y remotas (ApiDataSource)
- Implementar lógica de caché inteligente
- Proporcionar métodos para obtener estaciones cercanas por ubicación y radio

---

## 🏗️ PATRÓN ARQUITECTÓNICO: REPOSITORY PATTERN

### ¿Qué es el Repository Pattern?

El **Repository Pattern** actúa como una capa de abstracción entre la lógica de negocio y las fuentes de datos. Sus ventajas son:

1. **Abstracción**: La lógica de negocio no sabe de dónde vienen los datos (API, BD local, caché)
2. **Testabilidad**: Fácil de mockear en pruebas unitarias
3. **Flexibilidad**: Cambiar fuente de datos sin modificar casos de uso
4. **Single Source of Truth**: Centraliza acceso a datos

### Arquitectura de Capas

```
┌─────────────────────────────────────────────┐
│         CAPA DE PRESENTACIÓN                │
│              (BLoC/Widgets)                 │
└─────────────────┬───────────────────────────┘
                  │ usa
                  ▼
┌─────────────────────────────────────────────┐
│        CAPA DE LÓGICA DE NEGOCIO            │
│           (Casos de Uso)                    │
└─────────────────┬───────────────────────────┘
                  │ usa interfaz
                  ▼
┌─────────────────────────────────────────────┐
│          CAPA DE DOMINIO                    │
│   GasStationRepository (INTERFAZ)           │
└─────────────────┬───────────────────────────┘
                  │ implementa
                  ▼
┌─────────────────────────────────────────────┐
│           CAPA DE DATOS                     │
│   GasStationRepositoryImpl                  │
│         (IMPLEMENTACIÓN)                    │
└──────┬──────────────────────┬───────────────┘
       │                      │
       ▼                      ▼
┌──────────────┐      ┌──────────────────┐
│ ApiDataSource│      │DatabaseDataSource│
│  (Remoto)    │      │     (Local)      │
└──────────────┘      └──────────────────┘
```

---

## 📂 ESTRUCTURA DE ARCHIVOS

### Archivos a crear:

```
lib/
├── domain/
│   └── repositories/
│       └── gas_station_repository.dart    ← INTERFAZ (abstracción)
│
└── data/
    └── repositories/
        └── gas_station_repository_impl.dart ← IMPLEMENTACIÓN (concreta)
```

---

## 📝 IMPLEMENTACIÓN COMPLETA

### 1. Interfaz del Repositorio (Capa de Dominio)

**Ubicación:** `lib/domain/repositories/gas_station_repository.dart`

**Propósito:** Definir el contrato (interfaz) que deben cumplir todas las implementaciones del repositorio.

```dart
/// Repositorio abstracto para gestión de gasolineras
/// Define el contrato que debe cumplir cualquier implementación
library;

import 'package:buscagas/domain/entities/gas_station.dart';

abstract class GasStationRepository {
  /// Obtener todas las estaciones desde la API remota
  /// 
  /// Lanza [Exception] si hay error de red o parseo
  Future<List<GasStation>> fetchRemoteStations();
  
  /// Obtener todas las estaciones almacenadas en caché local
  /// 
  /// Retorna lista vacía si no hay datos en caché
  Future<List<GasStation>> getCachedStations();
  
  /// Actualizar caché local con nuevos datos
  /// 
  /// Borra todos los datos antiguos y guarda los nuevos
  /// [stations] Lista de estaciones a guardar en caché
  Future<void> updateCache(List<GasStation> stations);
  
  /// Obtener estaciones cercanas a una ubicación específica
  /// 
  /// Filtra estaciones en caché dentro del radio especificado
  /// [latitude] Latitud de la ubicación del usuario
  /// [longitude] Longitud de la ubicación del usuario
  /// [radiusKm] Radio de búsqueda en kilómetros (5, 10, 20, 50)
  /// 
  /// Retorna lista de estaciones dentro del radio, ordenadas por distancia
  Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}
```

---

### 2. Implementación del Repositorio (Capa de Datos)

**Ubicación:** `lib/data/repositories/gas_station_repository_impl.dart`

**Propósito:** Implementación concreta que coordina ApiDataSource y DatabaseDataSource.

```dart
/// Implementación concreta del repositorio de gasolineras
/// Combina fuentes de datos remotas (API) y locales (SQLite)
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

class GasStationRepositoryImpl implements GasStationRepository {
  final ApiDataSource _apiDataSource;
  final DatabaseDataSource _databaseDataSource;
  
  /// Constructor con inyección de dependencias
  /// 
  /// [_apiDataSource] Fuente de datos remota (API gubernamental)
  /// [_databaseDataSource] Fuente de datos local (SQLite)
  GasStationRepositoryImpl(
    this._apiDataSource,
    this._databaseDataSource,
  );
  
  @override
  Future<List<GasStation>> fetchRemoteStations() async {
    try {
      // 1. Descargar modelos desde API
      final gasStationModels = await _apiDataSource.fetchAllStations();
      
      // 2. Convertir modelos a entidades de dominio
      final gasStations = gasStationModels
          .map((model) => model.toDomain())
          .toList();
      
      return gasStations;
      
    } on ApiException {
      // Re-lanzar excepciones de API para que capa superior las maneje
      rethrow;
    } catch (e) {
      throw Exception('Error al obtener estaciones remotas: $e');
    }
  }
  
  @override
  Future<List<GasStation>> getCachedStations() async {
    try {
      // Obtener todas las estaciones de la base de datos local
      return await _databaseDataSource.getAllStations();
    } catch (e) {
      throw Exception('Error al obtener estaciones en caché: $e');
    }
  }
  
  @override
  Future<void> updateCache(List<GasStation> stations) async {
    try {
      // 1. Borrar todos los datos antiguos
      await _databaseDataSource.clearAllStations();
      
      // 2. Insertar nuevos datos en batch (más eficiente)
      await _databaseDataSource.insertStationsBatch(stations);
      
      // 3. Actualizar timestamp de última sincronización
      await _databaseDataSource.updateLastSyncTimestamp(DateTime.now());
      
    } catch (e) {
      throw Exception('Error al actualizar caché: $e');
    }
  }
  
  @override
  Future<List<GasStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // 1. Obtener todas las estaciones del caché
      final allStations = await getCachedStations();
      
      // 2. Filtrar estaciones dentro del radio especificado
      final nearbyStations = allStations.where((station) {
        return station.isWithinRadius(latitude, longitude, radiusKm);
      }).toList();
      
      // 3. Ordenar por distancia (las más cercanas primero)
      nearbyStations.sort((a, b) {
        final distanceA = a.calculateDistance(latitude, longitude);
        final distanceB = b.calculateDistance(latitude, longitude);
        return distanceA.compareTo(distanceB);
      });
      
      return nearbyStations;
      
    } catch (e) {
      throw Exception('Error al obtener estaciones cercanas: $e');
    }
  }
}
```

---

## 🔄 FLUJO DE DATOS COMPLETO

### Escenario 1: Primera carga (sin caché)

```
Usuario abre app
    ↓
Caso de Uso solicita datos
    ↓
Repository.fetchRemoteStations()
    ↓
ApiDataSource descarga JSON
    ↓
Convierte models → entities
    ↓
Repository.updateCache(entities)
    ↓
DatabaseDataSource guarda en SQLite
    ↓
Retorna entities a Caso de Uso
    ↓
BLoC actualiza estado
    ↓
UI muestra marcadores en mapa
```

### Escenario 2: Carga con caché disponible

```
Usuario abre app
    ↓
Caso de Uso solicita datos
    ↓
Repository.getCachedStations()
    ↓
DatabaseDataSource lee SQLite
    ↓
Retorna entities inmediatamente
    ↓
UI muestra datos (rápido)
    ↓
[En paralelo] Sincronización background
    ↓
Repository.fetchRemoteStations()
    ↓
Si hay cambios → Repository.updateCache()
    ↓
Notifica UI para refrescar
```

### Escenario 3: Búsqueda por proximidad

```
Usuario en coordenadas (40.4168, -3.7038)
Radio configurado: 10 km
    ↓
Caso de Uso solicita cercanas
    ↓
Repository.getNearbyStations(40.4168, -3.7038, 10)
    ↓
Obtiene TODAS de caché local (rápido)
    ↓
Filtra con isWithinRadius() (Haversine)
    ↓
Ordena por distancia (sort)
    ↓
Retorna solo las que cumplen criterio
    ↓
UI muestra solo marcadores cercanos
```

---

## 🧠 LÓGICA DE CACHÉ INTELIGENTE

### Estrategia de caché implementada:

1. **Offline-first:**
   - Siempre intenta cargar desde caché primero
   - Si falla, intenta API remota
   - Si ambos fallan, muestra error

2. **Actualización periódica:**
   - Timer cada 30 minutos descarga datos frescos
   - Compara con caché actual
   - Solo actualiza si hay cambios (ahorro de batería/datos)

3. **Fallback automático:**
   - Sin conexión → usa caché
   - Caché vacío → fuerza descarga
   - Error de parseo → mantiene caché antiguo

### Implementación del servicio de sincronización (referencia):

```dart
// Esto se implementará en Paso 9 (Servicios del Sistema)
// Aquí solo como referencia de cómo se usará el repositorio

class DataSyncService {
  final GasStationRepository _repository;
  Timer? _syncTimer;
  
  void startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 30), (_) {
      _performSync();
    });
  }
  
  Future<void> _performSync() async {
    try {
      // 1. Verificar conectividad
      if (!await _hasInternetConnection()) {
        return; // Sin internet, no sincronizar
      }
      
      // 2. Descargar datos frescos
      List<GasStation> freshData = await _repository.fetchRemoteStations();
      
      // 3. Comparar con caché
      List<GasStation> cachedData = await _repository.getCachedStations();
      
      if (_hasDataChanged(freshData, cachedData)) {
        // 4. Actualizar base de datos local
        await _repository.updateCache(freshData);
        
        // 5. Notificar a UI
        print('✅ Datos sincronizados: ${DateTime.now()}');
      } else {
        print('ℹ️ Sin cambios detectados');
      }
      
    } catch (e) {
      print('❌ Error de sincronización: $e');
      // No interrumpir experiencia de usuario
    }
  }
  
  bool _hasDataChanged(List<GasStation> fresh, List<GasStation> cached) {
    if (fresh.length != cached.length) return true;
    
    // Comparar precios de primeras 10 gasolineras (muestra representativa)
    for (int i = 0; i < min(10, fresh.length); i++) {
      if (fresh[i].prices != cached[i].prices) {
        return true;
      }
    }
    return false;
  }
}
```

---

## 🧪 EJEMPLO DE USO DEL REPOSITORIO

### En un caso de uso:

```dart
// lib/domain/usecases/get_nearby_stations.dart
class GetNearbyStationsUseCase {
  final GasStationRepository repository;
  
  GetNearbyStationsUseCase(this.repository);
  
  Future<List<GasStation>> call({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    // El caso de uso no sabe si los datos vienen de API o caché
    // Solo llama al repositorio
    return await repository.getNearbyStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
```

### En un BLoC:

```dart
// presentation/blocs/map/map_bloc.dart
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetNearbyStationsUseCase _getNearbyStations;
  
  Future<void> _onLoadMapData(LoadMapData event, Emitter<MapState> emit) async {
    emit(MapLoading());
    
    try {
      // Llamar al caso de uso (que usa el repositorio)
      final stations = await _getNearbyStations(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: 10.0,
      );
      
      emit(MapLoaded(stations: stations));
      
    } catch (e) {
      emit(MapError(message: 'Error al cargar gasolineras: $e'));
    }
  }
}
```

---

## 🔗 DEPENDENCIAS CON OTROS COMPONENTES

### Componentes que el repositorio UTILIZA:

1. **ApiDataSource** (Paso 5) - Ya implementado ✅
   - `fetchAllStations()` → Descarga datos de API

2. **DatabaseDataSource** (Paso 4) - Ya implementado ✅
   - `getAllStations()` → Lee caché
   - `clearAllStations()` → Borra caché
   - `insertStationsBatch()` → Guarda en lote
   - `updateLastSyncTimestamp()` → Marca última sync

3. **GasStationModel** (Paso 3) - Ya implementado ✅
   - `toDomain()` → Convierte model a entity

4. **GasStation Entity** (Paso 3) - Ya implementado ✅
   - `isWithinRadius()` → Verifica distancia
   - `calculateDistance()` → Calcula km

### Componentes que USARÁN el repositorio:

1. **Casos de Uso** (Paso 7) - Próximo paso
   - `GetNearbyStationsUseCase`
   - `FilterByFuelTypeUseCase`

2. **BLoCs** (Paso 8)
   - `MapBloc`
   - `SettingsBloc`

3. **Servicios** (Paso 9)
   - `DataSyncService`

---

## 🛡️ MANEJO DE ERRORES

### Estrategia de errores del repositorio:

1. **Errores de API:**
   ```dart
   try {
     final data = await _apiDataSource.fetchAllStations();
   } on ApiException {
     rethrow; // Dejar que capa superior maneje
   }
   ```

2. **Errores de Base de Datos:**
   ```dart
   try {
     await _databaseDataSource.getAllStations();
   } catch (e) {
     throw Exception('Error al obtener caché: $e');
   }
   ```

3. **Errors de conversión:**
   ```dart
   try {
     final entities = models.map((m) => m.toDomain()).toList();
   } catch (e) {
     throw Exception('Error al convertir modelos: $e');
   }
   ```

### Ejemplo de manejo en capa superior (BLoC):

```dart
try {
  // Intentar obtener de caché primero
  final cachedStations = await repository.getCachedStations();
  
  if (cachedStations.isNotEmpty) {
    emit(MapLoaded(stations: cachedStations));
  }
  
  // Luego actualizar desde API en background
  try {
    final freshStations = await repository.fetchRemoteStations();
    await repository.updateCache(freshStations);
    emit(MapLoaded(stations: freshStations));
  } on ApiException catch (e) {
    // Sin internet, mantener caché
    print('Sin conexión, usando caché: ${e.userFriendlyMessage}');
  }
  
} catch (e) {
  emit(MapError(message: 'Error al cargar datos'));
}
```

---

## ✅ CHECKLIST PASO 6

### Archivos a crear:

1. ✅ `lib/domain/repositories/gas_station_repository.dart`
   - Clase abstracta `GasStationRepository`
   - Método `fetchRemoteStations()`
   - Método `getCachedStations()`
   - Método `updateCache()`
   - Método `getNearbyStations()`

2. ✅ `lib/data/repositories/gas_station_repository_impl.dart`
   - Clase `GasStationRepositoryImpl implements GasStationRepository`
   - Inyección de `ApiDataSource` y `DatabaseDataSource`
   - Implementación de todos los métodos de la interfaz
   - Conversión model → entity con `toDomain()`
   - Lógica de filtrado por radio geográfico
   - Ordenación por distancia

### Verificaciones:

1. ✅ Crear directorios si no existen:
   - `lib/domain/repositories/`
   - `lib/data/repositories/`

2. ✅ Verificar imports necesarios:
   - `package:buscagas/domain/entities/gas_station.dart`
   - `package:buscagas/data/datasources/remote/api_datasource.dart`
   - `package:buscagas/data/datasources/local/database_datasource.dart`

3. ✅ Ejecutar `flutter analyze` sin errores

4. ✅ (Opcional) Crear prueba básica:
   ```dart
   test('debe obtener estaciones desde API y guardar en caché', () async {
     final mockApi = MockApiDataSource();
     final mockDb = MockDatabaseDataSource();
     final repo = GasStationRepositoryImpl(mockApi, mockDb);
     
     final stations = await repo.fetchRemoteStations();
     
     expect(stations, isNotEmpty);
   });
   ```

---

## 🎯 CRITERIOS DE ÉXITO DEL PASO 6

**El Paso 6 está completo cuando:**

- ✅ Interfaz `GasStationRepository` creada en `domain/repositories/`
- ✅ Implementación `GasStationRepositoryImpl` creada en `data/repositories/`
- ✅ Todos los métodos implementados correctamente
- ✅ Inyección de dependencias configurada (ApiDataSource + DatabaseDataSource)
- ✅ Conversión model → entity funciona con `toDomain()`
- ✅ Filtrado geográfico implementado con `isWithinRadius()`
- ✅ Ordenación por distancia funciona correctamente
- ✅ Manejo de errores apropiado en cada método
- ✅ `flutter analyze` sin errores
- ✅ Código documentado con comentarios Dart

---

## 🔍 NOTAS IMPORTANTES

### Principios aplicados:

1. **Separation of Concerns:**
   - Interfaz en `domain/` (reglas de negocio)
   - Implementación en `data/` (detalles técnicos)

2. **Dependency Inversion:**
   - Casos de uso dependen de interfaz, no de implementación
   - Fácil de cambiar implementación sin romper lógica

3. **Single Responsibility:**
   - Repositorio solo coordina fuentes de datos
   - No contiene lógica de negocio compleja

4. **Testabilidad:**
   - Inyección de dependencias permite mocks
   - Interfaz facilita pruebas unitarias

### Conversión Model → Entity:

El método `toDomain()` ya implementado en `GasStationModel` (Paso 3):
```dart
// En GasStationModel
GasStation toDomain() {
  return GasStation(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    address: address,
    locality: locality,
    operator: operator,
    prices: prices.map((p) => p.toDomain()).toList(),
  );
}
```

### Cálculo de distancias:

El método `isWithinRadius()` ya implementado en `GasStation` entity (Paso 3):
```dart
// En GasStation
bool isWithinRadius(double lat, double lon, double radiusKm) {
  final distance = calculateDistance(lat, lon);
  return distance <= radiusKm;
}

double calculateDistance(double lat, double lon) {
  // Fórmula de Haversine
  const double earthRadiusKm = 6371.0;
  // ... implementación completa en Paso 3
}
```

### Rendimiento:

- **Batch insert:** Insertar todas las estaciones en una transacción (más rápido)
- **Filtrado en memoria:** Filtrar por radio después de cargar (miles de registros)
- **Ordenación:** Solo ordenar estaciones cercanas, no todas

---

## 🚀 PRÓXIMOS PASOS

Después del Paso 6, el Paso 7 implementará:
- **Casos de Uso** que usen el repositorio
- `GetNearbyStationsUseCase`
- `FilterByFuelTypeUseCase`
- `CalculateDistanceUseCase`
- Lógica de negocio independiente de UI y datos

---

**Fecha de creación:** 17 de noviembre de 2025  
**Basado en:** BuscaGas Documentacion V3 (Métrica v3)  
**Sección:** DSI 1 - Arquitectura, DSI 2 - Módulos, CSI 2 - Construcción Repositorios
