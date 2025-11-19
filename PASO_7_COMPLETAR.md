# PASO 7: COMPLETAR - Casos de Uso Pendientes

## 📊 ANÁLISIS DEL ESTADO ACTUAL

### ✅ Casos de Uso YA Implementados

1. **GetNearbyStationsUseCase** ✅
   - Archivo: `lib/domain/usecases/get_nearby_stations.dart`
   - Estado: COMPLETO
   - Funcionalidad: Obtiene gasolineras cercanas usando el repositorio

2. **FilterByFuelTypeUseCase** ✅
   - Archivo: `lib/domain/usecases/filter_by_fuel_type.dart`
   - Estado: COMPLETO
   - Funcionalidad: Filtra gasolineras por tipo de combustible

3. **CalculateDistanceUseCase** ✅
   - Archivo: `lib/domain/usecases/calculate_distance.dart`
   - Estado: COMPLETO
   - Funcionalidad: Calcula distancia entre coordenadas con Haversine

### ❌ Componentes PENDIENTES según Documentación V3

#### 1. ❌ **AssignPriceRangeUseCase** - NO EXISTE
   - **Mencionado en:** DSI 6 - Diseño de Procesos (línea 1339-1372)
   - **Funcionalidad:** Clasificar gasolineras en rangos de precio (low/medium/high) usando percentiles
   - **Necesario para:** Asignar colores a marcadores en el mapa (verde/amarillo/rojo)

#### 2. ❌ **SyncStationsUseCase** - NO EXISTE
   - **Mencionado en:** docs/REPOSITORY_INTEGRATION.md
   - **Funcionalidad:** Sincronizar datos desde API a caché local
   - **Necesario para:** Actualización periódica de datos

#### 3. ❌ **Tests Unitarios** - NO EXISTEN
   - **Ubicación esperada:** `test/usecases/`
   - **Archivos necesarios:**
     - `test/usecases/get_nearby_stations_test.dart`
     - `test/usecases/filter_by_fuel_type_test.dart`
     - `test/usecases/calculate_distance_test.dart`
     - `test/usecases/assign_price_range_test.dart`
     - `test/usecases/sync_stations_test.dart`

---

## 📝 INSTRUCCIONES DETALLADAS PARA COMPLETAR PASO 7

---

## TAREA 1: Implementar AssignPriceRangeUseCase

### Contexto
Este caso de uso clasifica gasolineras en 3 rangos de precio (bajo, medio, alto) usando percentiles. Es CRÍTICO para el sistema de colores de los marcadores en el mapa.

### Ubicación
**Archivo:** `lib/domain/usecases/assign_price_range.dart`

### Código Completo

```dart
/// Caso de uso: Asignar rangos de precio a gasolineras
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/price_range.dart';

/// Clasificador de gasolineras por rangos de precio
/// 
/// Utiliza percentiles para dividir las gasolineras en 3 grupos:
/// - PriceRange.low: 33% más baratas (verde)
/// - PriceRange.medium: 33% intermedias (amarillo/naranja)
/// - PriceRange.high: 33% más caras (rojo)
class AssignPriceRangeUseCase {
  /// Ejecutar caso de uso
  /// 
  /// Modifica IN-PLACE el campo priceRange de cada GasStation
  /// 
  /// [stations] Lista de gasolineras a clasificar (se modifica)
  /// [fuelType] Tipo de combustible para calcular rangos
  /// 
  /// Algoritmo:
  /// 1. Extraer todos los precios válidos del combustible especificado
  /// 2. Ordenar precios de menor a mayor
  /// 3. Calcular percentiles 33 y 66
  /// 4. Asignar PriceRange.low si precio <= p33
  /// 5. Asignar PriceRange.medium si p33 < precio <= p66
  /// 6. Asignar PriceRange.high si precio > p66
  void call({
    required List<GasStation> stations,
    required FuelType fuelType,
  }) {
    // 1. Extraer todos los precios válidos para el combustible
    List<double> prices = stations
        .map((station) => station.getPriceForFuel(fuelType))
        .whereType<double>() // Filtrar nulls
        .where((price) => price > 0) // Filtrar precios inválidos
        .toList();
    
    // Si no hay precios, no hay nada que clasificar
    if (prices.isEmpty) {
      // Asignar null a todas las estaciones
      for (var station in stations) {
        station.priceRange = null;
      }
      return;
    }
    
    // Si solo hay 1 o 2 precios, todos son "medium"
    if (prices.length <= 2) {
      for (var station in stations) {
        final price = station.getPriceForFuel(fuelType);
        if (price != null && price > 0) {
          station.priceRange = PriceRange.medium;
        } else {
          station.priceRange = null;
        }
      }
      return;
    }
    
    // 2. Ordenar precios de menor a mayor
    prices.sort();
    
    // 3. Calcular percentiles 33 y 66
    final int count = prices.length;
    final int p33Index = (count * 0.33).floor();
    final int p66Index = (count * 0.66).floor();
    
    final double p33 = prices[p33Index];
    final double p66 = prices[p66Index];
    
    // 4. Asignar rangos a cada estación
    for (var station in stations) {
      final double? price = station.getPriceForFuel(fuelType);
      
      if (price == null || price <= 0) {
        station.priceRange = null;
        continue;
      }
      
      if (price <= p33) {
        station.priceRange = PriceRange.low; // Verde (barato)
      } else if (price <= p66) {
        station.priceRange = PriceRange.medium; // Naranja (medio)
      } else {
        station.priceRange = PriceRange.high; // Rojo (caro)
      }
    }
  }
}
```

### Explicación del Algoritmo

1. **Extracción de precios:**
   - Recorre todas las gasolineras
   - Obtiene el precio del combustible especificado (gasolina95 o dieselA)
   - Filtra valores nulos e inválidos

2. **Cálculo de percentiles:**
   - Ordena los precios de menor a mayor
   - p33 = precio en posición 33% (separa el tercio más barato)
   - p66 = precio en posición 66% (separa el tercio más caro)

3. **Clasificación:**
   - `precio <= p33` → **PriceRange.low** (verde)
   - `p33 < precio <= p66` → **PriceRange.medium** (naranja)
   - `precio > p66` → **PriceRange.high** (rojo)

### Ejemplo de Uso

```dart
// En MapBloc después de obtener gasolineras cercanas

final assignPriceRange = AssignPriceRangeUseCase();

// Lista de 150 gasolineras con precios variados
List<GasStation> stations = [...];
FuelType selectedFuel = FuelType.gasolina95;

// Clasificar gasolineras (modifica in-place)
assignPriceRange(
  stations: stations,
  fuelType: selectedFuel,
);

// Ahora cada station tiene su priceRange asignado
for (var station in stations) {
  print('${station.name}: ${station.priceRange}');
  // Output: "Repsol Madrid: PriceRange.low"
}
```

---

## TAREA 2: Implementar SyncStationsUseCase

### Contexto
Este caso de uso coordina la sincronización completa de datos: descarga desde API y actualización de caché local.

### Ubicación
**Archivo:** `lib/domain/usecases/sync_stations.dart`

### Código Completo

```dart
/// Caso de uso: Sincronizar estaciones desde API a caché local
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';

/// Sincronización completa de datos de gasolineras
/// 
/// Coordina el proceso de:
/// 1. Descargar datos frescos desde la API gubernamental
/// 2. Actualizar la caché local con los nuevos datos
/// 3. Retornar la cantidad de gasolineras sincronizadas
class SyncStationsUseCase {
  final GasStationRepository repository;
  
  /// Constructor con inyección de dependencias
  SyncStationsUseCase(this.repository);
  
  /// Ejecutar sincronización completa
  /// 
  /// Retorna el número de gasolineras sincronizadas
  /// 
  /// Lanza [Exception] si hay error de red o de base de datos
  Future<int> call() async {
    try {
      // 1. Descargar datos frescos desde API remota
      final remoteStations = await repository.fetchRemoteStations();
      
      if (remoteStations.isEmpty) {
        throw Exception('La API no retornó gasolineras');
      }
      
      // 2. Actualizar caché local (borra datos antiguos e inserta nuevos)
      await repository.updateCache(remoteStations);
      
      // 3. Retornar cantidad sincronizada
      return remoteStations.length;
      
    } catch (e) {
      throw Exception('Error al sincronizar gasolineras: $e');
    }
  }
}
```

### Ejemplo de Uso

```dart
// En SyncService o en un BLoC

final syncStations = SyncStationsUseCase(repository);

try {
  final count = await syncStations();
  print('✅ Sincronizadas $count gasolineras');
} catch (e) {
  print('❌ Error: $e');
}
```

---

## TAREA 3: Crear Tests Unitarios

### Contexto
Los tests unitarios son ESENCIALES para garantizar que los casos de uso funcionan correctamente de forma aislada.

### Estructura de Directorios

```
test/
└── usecases/
    ├── get_nearby_stations_test.dart
    ├── filter_by_fuel_type_test.dart
    ├── calculate_distance_test.dart
    ├── assign_price_range_test.dart
    └── sync_stations_test.dart
```

---

### TEST 1: get_nearby_stations_test.dart

**Ubicación:** `test/usecases/get_nearby_stations_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/usecases/get_nearby_stations.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

// Generar mock con build_runner
@GenerateMocks([GasStationRepository])
import 'get_nearby_stations_test.mocks.dart';

void main() {
  group('GetNearbyStationsUseCase', () {
    late GetNearbyStationsUseCase useCase;
    late MockGasStationRepository mockRepository;
    
    setUp(() {
      mockRepository = MockGasStationRepository();
      useCase = GetNearbyStationsUseCase(mockRepository);
    });
    
    test('debe retornar lista de gasolineras cercanas', () async {
      // Arrange
      final mockStations = [
        GasStation(
          id: '1',
          name: 'Repsol Madrid',
          latitude: 40.4168,
          longitude: -3.7038,
          address: 'Calle Mayor 1',
          locality: 'Madrid',
          operator: 'Repsol',
        ),
      ];
      
      when(mockRepository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      )).thenAnswer((_) async => mockStations);
      
      // Act
      final result = await useCase(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      );
      
      // Assert
      expect(result, mockStations);
      expect(result.length, 1);
      expect(result.first.name, 'Repsol Madrid');
      
      verify(mockRepository.getNearbyStations(
        latitude: 40.4168,
        longitude: -3.7038,
        radiusKm: 10.0,
      )).called(1);
    });
    
    test('debe lanzar excepción si el repositorio falla', () async {
      // Arrange
      when(mockRepository.getNearbyStations(
        latitude: any,
        longitude: any,
        radiusKm: any,
      )).thenThrow(Exception('Error de red'));
      
      // Act & Assert
      expect(
        () => useCase(latitude: 40.4168, longitude: -3.7038, radiusKm: 10.0),
        throwsException,
      );
    });
  });
}
```

---

### TEST 2: filter_by_fuel_type_test.dart

**Ubicación:** `test/usecases/filter_by_fuel_type_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/filter_by_fuel_type.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';

void main() {
  group('FilterByFuelTypeUseCase', () {
    late FilterByFuelTypeUseCase useCase;
    
    setUp(() {
      useCase = FilterByFuelTypeUseCase();
    });
    
    test('debe filtrar gasolineras que tienen gasolina95', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Con Gasolina',
          latitude: 40.4168,
          longitude: -3.7038,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.45,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStation(
          id: '2',
          name: 'Solo Diesel',
          latitude: 41.3851,
          longitude: 2.1734,
          prices: [
            FuelPrice(
              fuelType: FuelType.dieselGasoleoA,
              value: 1.38,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];
      
      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert
      expect(result.length, 1);
      expect(result.first.name, 'Con Gasolina');
    });
    
    test('debe retornar lista vacía si ninguna tiene el combustible', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Sin Precios',
          latitude: 40.4168,
          longitude: -3.7038,
          prices: [],
        ),
      ];
      
      // Act
      final result = useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert
      expect(result, isEmpty);
    });
  });
}
```

---

### TEST 3: calculate_distance_test.dart

**Ubicación:** `test/usecases/calculate_distance_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/calculate_distance.dart';

void main() {
  group('CalculateDistanceUseCase', () {
    late CalculateDistanceUseCase useCase;
    
    setUp(() {
      useCase = CalculateDistanceUseCase();
    });
    
    test('debe calcular distancia entre Madrid y Barcelona', () {
      // Arrange: Coordenadas reales
      const madridLat = 40.4168;
      const madridLon = -3.7038;
      const barcelonaLat = 41.3851;
      const barcelonaLon = 2.1734;
      
      // Act
      final distance = useCase(
        lat1: madridLat,
        lon1: madridLon,
        lat2: barcelonaLat,
        lon2: barcelonaLon,
      );
      
      // Assert: La distancia real es ~504 km
      expect(distance, greaterThan(500));
      expect(distance, lessThan(510));
    });
    
    test('debe retornar 0 para la misma ubicación', () {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;
      
      // Act
      final distance = useCase(
        lat1: lat,
        lon1: lon,
        lat2: lat,
        lon2: lon,
      );
      
      // Assert
      expect(distance, 0.0);
    });
    
    test('debe calcular distancia pequeña correctamente', () {
      // Arrange: Dos puntos muy cercanos (~1 km)
      const lat1 = 40.4168;
      const lon1 = -3.7038;
      const lat2 = 40.4268; // ~1 km al norte
      const lon2 = -3.7038;
      
      // Act
      final distance = useCase(
        lat1: lat1,
        lon1: lon1,
        lat2: lat2,
        lon2: lon2,
      );
      
      // Assert
      expect(distance, greaterThan(0.9));
      expect(distance, lessThan(1.2));
    });
  });
}
```

---

### TEST 4: assign_price_range_test.dart

**Ubicación:** `test/usecases/assign_price_range_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/assign_price_range.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/price_range.dart';

void main() {
  group('AssignPriceRangeUseCase', () {
    late AssignPriceRangeUseCase useCase;
    
    setUp(() {
      useCase = AssignPriceRangeUseCase();
    });
    
    test('debe asignar rangos correctamente a 9 gasolineras', () {
      // Arrange: 9 gasolineras con precios uniformemente distribuidos
      final stations = List.generate(9, (i) {
        return GasStation(
          id: '$i',
          name: 'Gasolinera $i',
          latitude: 40.0,
          longitude: -3.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.40 + (i * 0.05), // 1.40, 1.45, 1.50, ..., 1.80
              updatedAt: DateTime.now(),
            ),
          ],
        );
      });
      
      // Act
      useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert: Verificar distribución de rangos
      final lowCount = stations.where((s) => s.priceRange == PriceRange.low).length;
      final mediumCount = stations.where((s) => s.priceRange == PriceRange.medium).length;
      final highCount = stations.where((s) => s.priceRange == PriceRange.high).length;
      
      expect(lowCount, 3); // 33%
      expect(mediumCount, 3); // 33%
      expect(highCount, 3); // 33%
      
      // Verificar que las 3 primeras son "low"
      expect(stations[0].priceRange, PriceRange.low);
      expect(stations[1].priceRange, PriceRange.low);
      expect(stations[2].priceRange, PriceRange.low);
    });
    
    test('debe asignar null si no hay precios', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Sin Precios',
          latitude: 40.0,
          longitude: -3.0,
          prices: [],
        ),
      ];
      
      // Act
      useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert
      expect(stations.first.priceRange, isNull);
    });
    
    test('debe asignar medium si solo hay 1 precio', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Única',
          latitude: 40.0,
          longitude: -3.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.45,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];
      
      // Act
      useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert
      expect(stations.first.priceRange, PriceRange.medium);
    });
  });
}
```

---

### TEST 5: sync_stations_test.dart

**Ubicación:** `test/usecases/sync_stations_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/usecases/sync_stations.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

@GenerateMocks([GasStationRepository])
import 'sync_stations_test.mocks.dart';

void main() {
  group('SyncStationsUseCase', () {
    late SyncStationsUseCase useCase;
    late MockGasStationRepository mockRepository;
    
    setUp(() {
      mockRepository = MockGasStationRepository();
      useCase = SyncStationsUseCase(mockRepository);
    });
    
    test('debe sincronizar gasolineras correctamente', () async {
      // Arrange
      final mockStations = List.generate(100, (i) => GasStation(
        id: '$i',
        name: 'Gasolinera $i',
        latitude: 40.0,
        longitude: -3.0,
      ));
      
      when(mockRepository.fetchRemoteStations())
          .thenAnswer((_) async => mockStations);
      when(mockRepository.updateCache(any))
          .thenAnswer((_) async => {});
      
      // Act
      final count = await useCase();
      
      // Assert
      expect(count, 100);
      verify(mockRepository.fetchRemoteStations()).called(1);
      verify(mockRepository.updateCache(mockStations)).called(1);
    });
    
    test('debe lanzar excepción si API retorna lista vacía', () async {
      // Arrange
      when(mockRepository.fetchRemoteStations())
          .thenAnswer((_) async => []);
      
      // Act & Assert
      expect(() => useCase(), throwsException);
    });
    
    test('debe lanzar excepción si falla la descarga', () async {
      // Arrange
      when(mockRepository.fetchRemoteStations())
          .thenThrow(Exception('Error de red'));
      
      // Act & Assert
      expect(() => useCase(), throwsException);
    });
  });
}
```

---

## TAREA 4: Generar Mocks y Ejecutar Tests

### Paso 4.1: Generar archivos de mocks

Ejecutar en terminal:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Esto generará:
- `test/usecases/get_nearby_stations_test.mocks.dart`
- `test/usecases/sync_stations_test.mocks.dart`

### Paso 4.2: Ejecutar todos los tests

```bash
flutter test test/usecases/
```

**Resultado esperado:**
```
✅ 14 tests pasados
⏱️ Tiempo: < 5 segundos
```

---

## TAREA 5: Validar Completitud del Paso 7

### Checklist de Validación

Ejecutar cada comando y verificar resultado:

#### 1. Análisis estático
```bash
flutter analyze
```
**Esperado:** `No issues found!`

#### 2. Verificar estructura de archivos

```bash
# Windows PowerShell
Get-ChildItem -Path lib\domain\usecases\ -Recurse -File
Get-ChildItem -Path test\usecases\ -Recurse -File
```

**Esperado:**
```
lib/domain/usecases/
├── assign_price_range.dart          ✅ NUEVO
├── calculate_distance.dart          ✅ EXISTE
├── filter_by_fuel_type.dart         ✅ EXISTE
├── get_nearby_stations.dart         ✅ EXISTE
└── sync_stations.dart               ✅ NUEVO

test/usecases/
├── assign_price_range_test.dart     ✅ NUEVO
├── calculate_distance_test.dart     ✅ NUEVO
├── filter_by_fuel_type_test.dart    ✅ NUEVO
├── get_nearby_stations_test.dart    ✅ NUEVO
├── get_nearby_stations_test.mocks.dart (generado)
├── sync_stations_test.dart          ✅ NUEVO
└── sync_stations_test.mocks.dart    (generado)
```

#### 3. Ejecutar tests específicos

```bash
# Test individual
flutter test test/usecases/assign_price_range_test.dart

# Todos los tests de casos de uso
flutter test test/usecases/

# Todos los tests del proyecto
flutter test
```

**Esperado:** Todos los tests pasan ✅

---

## 📊 RESUMEN EJECUTIVO

### Estado Final del Paso 7

| Componente | Estado Inicial | Acción Requerida | Estado Final |
|------------|----------------|------------------|--------------|
| GetNearbyStationsUseCase | ✅ Completo | Ninguna | ✅ Completo |
| FilterByFuelTypeUseCase | ✅ Completo | Ninguna | ✅ Completo |
| CalculateDistanceUseCase | ✅ Completo | Ninguna | ✅ Completo |
| **AssignPriceRangeUseCase** | ❌ **Falta** | **Crear** | ✅ Completo |
| **SyncStationsUseCase** | ❌ **Falta** | **Crear** | ✅ Completo |
| Tests Unitarios | ❌ **Faltan** | **Crear 5 archivos** | ✅ Completo |

### Archivos a Crear (7 archivos nuevos)

1. `lib/domain/usecases/assign_price_range.dart` (80 líneas)
2. `lib/domain/usecases/sync_stations.dart` (35 líneas)
3. `test/usecases/get_nearby_stations_test.dart` (70 líneas)
4. `test/usecases/filter_by_fuel_type_test.dart` (75 líneas)
5. `test/usecases/calculate_distance_test.dart` (70 líneas)
6. `test/usecases/assign_price_range_test.dart` (120 líneas)
7. `test/usecases/sync_stations_test.dart` (75 líneas)

**Total:** ~525 líneas de código nuevo

### Tiempo Estimado

- Tarea 1 (AssignPriceRange): 20 minutos
- Tarea 2 (SyncStations): 10 minutos
- Tarea 3 (Tests): 60 minutos
- Tarea 4 (Validación): 10 minutos

**Total estimado:** 100 minutos (~1.5 horas)

---

## 🎯 CRITERIOS DE ÉXITO

El Paso 7 estará **100% COMPLETO** cuando:

- ✅ Los 5 casos de uso están implementados
- ✅ AssignPriceRangeUseCase clasifica correctamente por percentiles
- ✅ SyncStationsUseCase coordina API y caché
- ✅ Todos los tests unitarios pasan (14+ tests)
- ✅ `flutter analyze` sin errores
- ✅ Cobertura de tests > 90% en casos de uso
- ✅ Documentación en cada archivo (comentarios Dart)

---

## 🔗 INTEGRACIÓN CON OTROS PASOS

### Dependencias (ya completados)
- ✅ Paso 3: Entidades (GasStation, FuelPrice, FuelType, PriceRange)
- ✅ Paso 6: Repositorio (GasStationRepository)

### Próximo Paso
- ⏭️ **Paso 8:** Los casos de uso se inyectarán en los BLoCs
  - MapBloc usará: GetNearbyStations, FilterByFuelType, AssignPriceRange
  - SyncBloc usará: SyncStations

---

## 📚 REFERENCIAS

- **Documentación V3:**
  - DSI 6 - Diseño de Procesos (línea 1339-1372): PriceRangeCalculator
  - ASI 3 - Análisis de Casos de Uso (línea 187-262): Flujos de negocio

- **Archivos del Proyecto:**
  - `lib/domain/entities/gas_station.dart` - Entidad con campo priceRange
  - `lib/domain/entities/price_range.dart` - Enum con colores
  - `lib/domain/repositories/gas_station_repository.dart` - Interface

---

**Fecha de Creación:** 19 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3  
**Paso:** 7 - Casos de Uso (Completar Pendientes)
