# PASO 7: Implementar Casos de Uso

## Información extraída de la Documentación V3 para el Paso 7

---

## 🎯 OBJETIVO DEL PASO 7
- Implementar casos de uso en la capa de dominio
- Encapsular lógica de negocio independiente de frameworks
- Crear casos de uso específicos para obtener gasolineras cercanas, filtrar por combustible y calcular distancias
- Aplicar principio de responsabilidad única (Single Responsibility)
- Preparar base para BLoCs (Paso 8)

---

## 🧩 ¿QUÉ ES UN CASO DE USO?

Un **Caso de Uso (Use Case)** es una clase que encapsula una **única operación de lógica de negocio**.

### Características de los Casos de Uso:

1. **Una sola responsabilidad:** Cada caso de uso hace UNA cosa y la hace bien
2. **Independiente de UI:** No sabe nada de widgets, pantallas o estado
3. **Independiente de frameworks:** No depende de Flutter, solo de Dart puro
4. **Testeable:** Fácil de probar con tests unitarios
5. **Reutilizable:** Puede ser llamado desde múltiples BLoCs o servicios

### Estructura típica:

```dart
class MiCasoDeUso {
  final MiRepositorio repository;
  
  MiCasoDeUso(this.repository);
  
  Future<Resultado> call(Parametros parametros) async {
    // Lógica de negocio aquí
    return resultado;
  }
}
```

### Principio del método `call()`:

Usar el método `call()` permite invocar el caso de uso como si fuera una función:

```dart
// En lugar de:
final resultado = await miCasoDeUso.execute(params);

// Podemos hacer:
final resultado = await miCasoDeUso(params);
```

---

## 📋 CASOS DE USO A IMPLEMENTAR

Según la Documentación V3, necesitamos 3 casos de uso principales:

### 1. **GetNearbyStationsUseCase**
   - **Propósito:** Obtener gasolineras cercanas a una ubicación
   - **Input:** Latitud, longitud, radio en km
   - **Output:** Lista de `GasStation` ordenadas por distancia
   - **Lógica:** Delega en el repositorio

### 2. **FilterByFuelTypeUseCase**
   - **Propósito:** Filtrar gasolineras por tipo de combustible
   - **Input:** Lista de gasolineras, tipo de combustible
   - **Output:** Lista filtrada (solo con ese combustible)
   - **Lógica:** Filtra las que tienen precio para el combustible especificado

### 3. **CalculateDistanceUseCase**
   - **Propósito:** Calcular distancia entre dos coordenadas
   - **Input:** Dos pares de coordenadas (lat, lon)
   - **Output:** Distancia en kilómetros
   - **Lógica:** Fórmula de Haversine

---

## 📂 ESTRUCTURA DE ARCHIVOS

```
lib/
└── domain/
    └── usecases/
        ├── get_nearby_stations_usecase.dart
        ├── filter_by_fuel_type_usecase.dart
        └── calculate_distance_usecase.dart
```

---

## 📝 IMPLEMENTACIÓN COMPLETA

### 1. GetNearbyStationsUseCase

**Ubicación:** `lib/domain/usecases/get_nearby_stations_usecase.dart`

**Propósito:** Obtener gasolineras cercanas utilizando el repositorio.

```dart
/// Caso de uso: Obtener gasolineras cercanas a una ubicación
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';

class GetNearbyStationsUseCase {
  final GasStationRepository repository;
  
  /// Constructor con inyección de dependencias
  GetNearbyStationsUseCase(this.repository);
  
  /// Ejecutar caso de uso
  /// 
  /// Obtiene las estaciones de servicio cercanas a las coordenadas especificadas
  /// dentro del radio dado, ordenadas por distancia.
  /// 
  /// [latitude] Latitud de la ubicación del usuario
  /// [longitude] Longitud de la ubicación del usuario
  /// [radiusKm] Radio de búsqueda en kilómetros (5, 10, 20, 50)
  /// 
  /// Retorna lista de [GasStation] ordenadas por distancia (más cercanas primero)
  /// 
  /// Lanza [Exception] si hay error al obtener datos
  Future<List<GasStation>> call({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // Delegar en el repositorio
      final stations = await repository.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      
      return stations;
      
    } catch (e) {
      throw Exception('Error al obtener gasolineras cercanas: $e');
    }
  }
}
```

---

### 2. FilterByFuelTypeUseCase

**Ubicación:** `lib/domain/usecases/filter_by_fuel_type_usecase.dart`

**Propósito:** Filtrar lista de gasolineras para mostrar solo las que tienen un combustible específico.

```dart
/// Caso de uso: Filtrar gasolineras por tipo de combustible
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class FilterByFuelTypeUseCase {
  /// Ejecutar caso de uso
  /// 
  /// Filtra la lista de gasolineras para retornar solo aquellas que tienen
  /// precio disponible para el tipo de combustible especificado.
  /// 
  /// [stations] Lista completa de gasolineras
  /// [fuelType] Tipo de combustible a filtrar (gasolina95, dieselA)
  /// 
  /// Retorna lista filtrada de [GasStation] que tienen el combustible
  List<GasStation> call({
    required List<GasStation> stations,
    required FuelType fuelType,
  }) {
    // Filtrar estaciones que tienen precio para el combustible solicitado
    final filteredStations = stations.where((station) {
      final price = station.getPriceForFuel(fuelType);
      return price != null && price > 0;
    }).toList();
    
    return filteredStations;
  }
}
```

**Notas:**
- Este caso de uso NO es async (es síncrono) porque solo filtra en memoria
- No necesita constructor con dependencias (es stateless)
- Usa el método `getPriceForFuel()` de la entidad `GasStation`

---

### 3. CalculateDistanceUseCase

**Ubicación:** `lib/domain/usecases/calculate_distance_usecase.dart`

**Propósito:** Calcular distancia entre dos puntos geográficos usando la fórmula de Haversine.

```dart
/// Caso de uso: Calcular distancia entre dos coordenadas geográficas
library;

import 'dart:math';

class CalculateDistanceUseCase {
  /// Ejecutar caso de uso
  /// 
  /// Calcula la distancia en kilómetros entre dos puntos geográficos
  /// usando la fórmula de Haversine (considera curvatura de la Tierra).
  /// 
  /// [lat1] Latitud del punto 1
  /// [lon1] Longitud del punto 1
  /// [lat2] Latitud del punto 2
  /// [lon2] Longitud del punto 2
  /// 
  /// Retorna distancia en kilómetros
  double call({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Radio de la Tierra en kilómetros
    const double earthRadiusKm = 6371.0;
    
    // Convertir grados a radianes
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    // Fórmula de Haversine
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
        cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Distancia = radio * ángulo
    final distance = earthRadiusKm * c;
    
    return distance;
  }
  
  /// Convertir grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
```

**Notas:**
- Implementa la **fórmula de Haversine** para cálculos precisos
- Es síncrono (no usa `async`)
- No tiene dependencias externas (puro Dart)
- Usa `dart:math` para funciones trigonométricas

---

## 🔄 FLUJO DE USO EN LA APLICACIÓN

### Secuencia de llamadas desde BLoC:

```
Usuario abre app
    ↓
MapBloc recibe evento LoadMapData
    ↓
1. Obtener ubicación GPS (LocationService)
    ↓
2. Llamar GetNearbyStationsUseCase
    ↓
    Repository.getNearbyStations()
    ↓
    DatabaseDataSource (caché local)
    ↓
Lista de GasStation (todas cercanas)
    ↓
3. Llamar FilterByFuelTypeUseCase
    ↓
Lista filtrada por combustible
    ↓
4. Para cada estación: CalculateDistanceUseCase
    ↓
Estaciones con campo distance calculado
    ↓
5. Clasificar por rango de precio (PriceRangeCalculator)
    ↓
MapBloc emite nuevo estado MapLoaded
    ↓
MapScreen reconstruye UI con marcadores
```

---

## 🧪 EJEMPLO DE USO DESDE UN BLoC

```dart
// En MapBloc
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetNearbyStationsUseCase getNearbyStations;
  final FilterByFuelTypeUseCase filterByFuelType;
  final CalculateDistanceUseCase calculateDistance;
  
  MapBloc({
    required this.getNearbyStations,
    required this.filterByFuelType,
    required this.calculateDistance,
  }) : super(MapInitial()) {
    on<LoadMapData>(_onLoadMapData);
  }
  
  Future<void> _onLoadMapData(
    LoadMapData event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());
    
    try {
      // 1. Obtener gasolineras cercanas
      List<GasStation> stations = await getNearbyStations(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      
      // 2. Filtrar por tipo de combustible
      stations = filterByFuelType(
        stations: stations,
        fuelType: event.fuelType,
      );
      
      // 3. Calcular distancias para cada estación
      for (var station in stations) {
        station.distance = calculateDistance(
          lat1: event.latitude,
          lon1: event.longitude,
          lat2: station.latitude,
          lon2: station.longitude,
        );
      }
      
      // 4. Emitir estado con datos
      emit(MapLoaded(stations: stations));
      
    } catch (e) {
      emit(MapError(message: 'Error al cargar gasolineras: $e'));
    }
  }
}
```

---

## 🔗 DEPENDENCIAS CON OTROS COMPONENTES

### Componentes que los Casos de Uso UTILIZAN:

1. **GasStationRepository** (Paso 6) - Ya implementado ✅
   - `getNearbyStations()` usado por GetNearbyStationsUseCase

2. **GasStation** (Paso 3) - Ya implementado ✅
   - `getPriceForFuel()` usado por FilterByFuelTypeUseCase

3. **FuelType** (Paso 3) - Ya implementado ✅
   - Enum usado en FilterByFuelTypeUseCase

### Componentes que USARÁN los Casos de Uso:

1. **MapBloc** (Paso 8) - Próximo
   - Coordinará los 3 casos de uso
   - Emitirá estados basados en resultados

2. **SettingsBloc** (Paso 8) - Próximo
   - Puede usar GetNearbyStationsUseCase cuando cambie el radio

3. **DataSyncService** (Paso 9) - Futuro
   - Puede usar GetNearbyStationsUseCase

---

## 🛡️ MANEJO DE ERRORES

### Estrategia de errores en Casos de Uso:

1. **GetNearbyStationsUseCase:**
   ```dart
   try {
     final stations = await repository.getNearbyStations(...);
     return stations;
   } catch (e) {
     throw Exception('Error al obtener gasolineras cercanas: $e');
   }
   ```
   - Captura errores del repositorio
   - Re-lanza con mensaje descriptivo
   - El BLoC manejará el error

2. **FilterByFuelTypeUseCase:**
   ```dart
   // No lanza excepciones, solo retorna lista vacía si no hay resultados
   final filteredStations = stations.where((station) {
     final price = station.getPriceForFuel(fuelType);
     return price != null && price > 0;
   }).toList();
   ```
   - Operación segura sin excepciones
   - Retorna lista vacía si no hay coincidencias

3. **CalculateDistanceUseCase:**
   ```dart
   // Cálculo matemático puro, no lanza excepciones
   // Siempre retorna un double válido
   final distance = earthRadiusKm * c;
   return distance;
   ```
   - Cálculo matemático determinista
   - No hay operaciones que puedan fallar

---

## ✅ CHECKLIST PASO 7

### Archivos a crear:

1. ✅ `lib/domain/usecases/get_nearby_stations_usecase.dart`
   - Clase `GetNearbyStationsUseCase`
   - Constructor con `GasStationRepository`
   - Método `call()` asíncrono
   - Parámetros: latitude, longitude, radiusKm
   - Retorna `Future<List<GasStation>>`

2. ✅ `lib/domain/usecases/filter_by_fuel_type_usecase.dart`
   - Clase `FilterByFuelTypeUseCase`
   - Método `call()` síncrono
   - Parámetros: stations, fuelType
   - Retorna `List<GasStation>` filtrada

3. ✅ `lib/domain/usecases/calculate_distance_usecase.dart`
   - Clase `CalculateDistanceUseCase`
   - Método `call()` síncrono
   - Parámetros: lat1, lon1, lat2, lon2
   - Retorna `double` (distancia en km)
   - Implementa fórmula de Haversine
   - Método auxiliar `_degreesToRadians()`

### Verificaciones:

1. ✅ Crear directorio `lib/domain/usecases/` si no existe

2. ✅ Verificar imports necesarios:
   - `package:buscagas/domain/entities/gas_station.dart`
   - `package:buscagas/domain/entities/fuel_type.dart`
   - `package:buscagas/domain/repositories/gas_station_repository.dart`
   - `dart:math` (solo para CalculateDistanceUseCase)

3. ✅ Ejecutar `flutter analyze` sin errores

4. ✅ (Opcional) Crear pruebas unitarias:
   ```dart
   test('GetNearbyStationsUseCase debe retornar lista de gasolineras', () async {
     final mockRepository = MockGasStationRepository();
     final useCase = GetNearbyStationsUseCase(mockRepository);
     
     when(mockRepository.getNearbyStations(
       latitude: any,
       longitude: any,
       radiusKm: any,
     )).thenAnswer((_) async => mockStations);
     
     final result = await useCase(
       latitude: 40.4,
       longitude: -3.7,
       radiusKm: 10,
     );
     
     expect(result, mockStations);
   });
   ```

---

## 🎯 CRITERIOS DE ÉXITO DEL PASO 7

**El Paso 7 está completo cuando:**

- ✅ Los 3 casos de uso están implementados en `domain/usecases/`
- ✅ GetNearbyStationsUseCase delega correctamente en el repositorio
- ✅ FilterByFuelTypeUseCase filtra correctamente por tipo de combustible
- ✅ CalculateDistanceUseCase implementa correctamente Haversine
- ✅ Todos los casos de uso usan el método `call()` para ser invocables
- ✅ Inyección de dependencias implementada donde sea necesario
- ✅ Manejo de errores apropiado en operaciones asíncronas
- ✅ Código documentado con comentarios Dart
- ✅ `flutter analyze` sin errores
- ✅ (Opcional) Tests unitarios pasando

---

## 🔍 NOTAS IMPORTANTES

### Principios aplicados:

1. **Single Responsibility:**
   - Cada caso de uso tiene UNA responsabilidad clara
   - GetNearbyStations → Obtener cercanas
   - FilterByFuelType → Filtrar por combustible
   - CalculateDistance → Calcular distancia

2. **Dependency Inversion:**
   - GetNearbyStationsUseCase depende de la interfaz `GasStationRepository`
   - No depende de la implementación concreta

3. **Clean Architecture:**
   - Casos de uso en capa de dominio
   - No dependen de frameworks (puro Dart)
   - No conocen detalles de UI o infraestructura

4. **Testabilidad:**
   - Fácil de testear con mocks
   - Sin dependencias complejas
   - Comportamiento predecible

### Ventajas de usar el método `call()`:

```dart
// Sin call() - menos intuitivo
final stations = await useCase.execute(lat: 40, lon: -3, radius: 10);

// Con call() - más limpio
final stations = await useCase(lat: 40, lon: -3, radius: 10);
```

### ¿Por qué separar FilterByFuelType?

Aunque podría estar en GetNearbyStations, separarlo permite:
- Reutilización desde múltiples BLoCs
- Filtrado dinámico sin re-consultar repositorio
- Testing independiente
- Cambio de filtro sin nueva búsqueda

### Fórmula de Haversine:

La fórmula implementada en CalculateDistanceUseCase es la más precisa para:
- Distancias cortas y medias (< 1000 km)
- Considera la curvatura de la Tierra
- Margen de error < 0.5% para nuestro caso de uso
- Más precisa que Pythagoras para coordenadas geográficas

---

## 🧮 PSEUDOCÓDIGO DE FLUJO COMPLETO

```
// En MapBloc cuando se carga el mapa

1. Usuario abre app
   ↓
2. LocationService.getCurrentPosition()
   → Obtiene (40.4168, -3.7038)
   ↓
3. GetNearbyStationsUseCase(lat: 40.4168, lon: -3.7038, radius: 10)
   ↓
   Repository.getNearbyStations(...)
   ↓
   DatabaseDataSource.getAllStations() → 5000 gasolineras
   ↓
   Filtrar isWithinRadius(10 km)
   ↓
   Ordenar por distancia
   ↓
   → Retorna 150 gasolineras cercanas
   ↓
4. FilterByFuelTypeUseCase(stations: 150, fuelType: gasolina95)
   ↓
   Filtrar stations.where(getPriceForFuel(gasolina95) != null)
   ↓
   → Retorna 120 gasolineras (30 no tienen gasolina95)
   ↓
5. Para cada estación:
   CalculateDistanceUseCase(
     lat1: 40.4168, lon1: -3.7038,
     lat2: station.lat, lon2: station.lon
   )
   ↓
   Haversine formula
   ↓
   station.distance = 2.5 km
   ↓
6. MapBloc.emit(MapLoaded(stations: 120))
   ↓
7. UI reconstruye con 120 marcadores
```

---

## 🚀 PRÓXIMOS PASOS

Después del Paso 7, el Paso 8 implementará:
- **BLoCs** que coordinen los casos de uso
- `MapBloc` para gestión de estado del mapa
- `SettingsBloc` para configuración
- Eventos y Estados para cada BLoC
- Integración con Flutter Bloc package

---

## 📚 REFERENCIAS DE LA DOCUMENTACIÓN V3

- **DSI 3:** Diseño de Casos de Uso Reales (líneas 915-979)
- **DSI 8:** Estructura de Directorios - usecases (líneas 1534-1537)
- **CSI 2:** Generación del Código de Componentes
- **CSI 3:** Ejecución de Pruebas Unitarias (líneas 1924-1948)

---

**Fecha de creación:** 17 de noviembre de 2025  
**Basado en:** BuscaGas Documentacion V3 (Métrica v3)  
**Sección:** DSI 3 - Casos de Uso, DSI 4 - Diseño de Clases, CSI 2 - Construcción
