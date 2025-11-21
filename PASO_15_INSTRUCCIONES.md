# PASO 15: Implementar Cálculo de Rangos de Precio

**Fecha de creación:** 21 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3

---

## ÍNDICE

1. [Contexto y Objetivos](#contexto-y-objetivos)
2. [Fundamento Teórico](#fundamento-teórico)
3. [Especificaciones Técnicas](#especificaciones-técnicas)
4. [Implementación Detallada](#implementación-detallada)
5. [Integración con Componentes Existentes](#integración-con-componentes-existentes)
6. [Pruebas y Validación](#pruebas-y-validación)

---

## CONTEXTO Y OBJETIVOS

### Descripción General
El Paso 15 consiste en la implementación del **algoritmo de clasificación por percentiles** para determinar rangos de precio (bajo, medio, alto) y la **asignación de colores a marcadores** según estos rangos.

### Objetivos Específicos
1. Implementar algoritmo de clasificación por percentiles (33% y 66%)
2. Asignar rangos de precio a gasolineras (low, medium, high)
3. Crear utilidad reutilizable `PriceRangeCalculator`
4. Integrar con entidad `PriceRange` existente
5. Garantizar actualización de colores en marcadores del mapa

### Referencia Arquitectónica
- **Capa:** Lógica de Negocio (Domain Layer)
- **Subsistema:** SS-04 (Filtrado y Búsqueda)
- **Ubicación:** `lib/core/utils/` o `lib/domain/usecases/`

### Requisitos Relacionados
- **RF-02:** Visualización en Mapa - Los marcadores usarán código de color según rango de precios
- **RNF-02:** Usabilidad - El usuario debe encontrar la gasolinera más barata en menos de 10 segundos
- **RNF-04:** Precisión - Los datos deben coincidir exactamente con la fuente oficial

---

## FUNDAMENTO TEÓRICO

### Clasificación por Percentiles

Los **percentiles** dividen un conjunto ordenado de datos en 100 partes iguales. En este proyecto usamos dos percentiles clave:

- **Percentil 33 (P33):** El 33% de los precios más bajos
- **Percentil 66 (P66):** El 66% de los precios más bajos

**Criterio de clasificación:**
```
Precio ≤ P33    → Rango BAJO (verde)
P33 < Precio ≤ P66 → Rango MEDIO (naranja/amarillo)
Precio > P66    → Rango ALTO (rojo)
```

### Fórmula de Cálculo de Percentiles

Para calcular un percentil en una lista ordenada:

```
índice = (n * p / 100).floor()
```

Donde:
- `n` = número total de elementos
- `p` = percentil deseado (33 o 66)
- `.floor()` = redondeo hacia abajo

**Ejemplo:**
Si tenemos 100 gasolineras ordenadas por precio:
- P33 = elemento en posición 33
- P66 = elemento en posición 66

### Ventajas del Método de Percentiles

1. **Adaptativo:** Se ajusta automáticamente a la distribución de precios actual
2. **Justo:** Siempre habrá aproximadamente 33% en cada rango
3. **Robusto:** No se ve afectado por valores extremos (outliers)
4. **Simple:** Fácil de calcular y entender

---

## ESPECIFICACIONES TÉCNICAS

### Algoritmo Completo (DSI 6)

Según la documentación Métrica V3, sección DSI 6 - Diseño de Procesos:

```dart
class PriceRangeCalculator {
  static void assignPriceRanges(
    List<GasStation> stations,
    FuelType fuelType
  ) {
    // 1. Extraer todos los precios válidos
    List<double> prices = stations
        .map((s) => s.getPriceForFuel(fuelType))
        .whereType<double>()
        .toList();
    
    if (prices.isEmpty) return;
    
    // 2. Calcular percentiles
    prices.sort();
    int count = prices.length;
    
    double p33 = prices[(count * 0.33).floor()];
    double p66 = prices[(count * 0.66).floor()];
    
    // 3. Asignar rangos
    for (var station in stations) {
      double? price = station.getPriceForFuel(fuelType);
      if (price == null) continue;
      
      if (price <= p33) {
        station.priceRange = PriceRange.low;
      } else if (price <= p66) {
        station.priceRange = PriceRange.medium;
      } else {
        station.priceRange = PriceRange.high;
      }
    }
  }
}
```

### Entidad PriceRange (Ya Implementada)

Según DSI 4 - Diseño de Clases:

```dart
enum PriceRange {
  low,    // verde
  medium, // amarillo
  high;   // rojo
  
  Color get color {
    switch (this) {
      case PriceRange.low:
        return Colors.green;
      case PriceRange.medium:
        return Colors.orange;
      case PriceRange.high:
        return Colors.red;
    }
  }
}
```

**Ubicación esperada:** `lib/domain/entities/price_range.dart` o integrado en `gas_station.dart`

### Propiedad en GasStation

La clase `GasStation` debe tener la propiedad:

```dart
PriceRange? priceRange; // bajo, medio, alto
```

Esta propiedad se asigna **dinámicamente** después de obtener las gasolineras y antes de mostrarlas en el mapa.

---

## IMPLEMENTACIÓN DETALLADA

### Paso 1: Crear PriceRangeCalculator

**Ubicación:** `lib/core/utils/price_range_calculator.dart`

**Implementación completa:**

```dart
import '../domain/entities/gas_station.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/price_range.dart';

/// Calculadora de rangos de precio utilizando percentiles.
/// 
/// Clasifica gasolineras en tres rangos (bajo, medio, alto) basándose
/// en la distribución de precios del combustible seleccionado.
/// 
/// Criterio:
/// - Rango BAJO: precio ≤ percentil 33
/// - Rango MEDIO: percentil 33 < precio ≤ percentil 66
/// - Rango ALTO: precio > percentil 66
class PriceRangeCalculator {
  /// Asigna rangos de precio a una lista de gasolineras.
  /// 
  /// Este método modifica directamente la propiedad `priceRange` de cada
  /// gasolinera en la lista proporcionada.
  /// 
  /// [stations] Lista de gasolineras a clasificar
  /// [fuelType] Tipo de combustible para comparar precios
  /// 
  /// Si la lista está vacía o no hay precios válidos, no realiza ninguna acción.
  static void assignPriceRanges(
    List<GasStation> stations,
    FuelType fuelType,
  ) {
    // 1. Extraer todos los precios válidos para el tipo de combustible
    final List<double> prices = stations
        .map((station) => station.getPriceForFuel(fuelType))
        .whereType<double>() // Filtra valores null
        .toList();
    
    // Si no hay precios, no se puede calcular rangos
    if (prices.isEmpty) return;
    
    // 2. Ordenar precios de menor a mayor
    prices.sort();
    final int count = prices.length;
    
    // 3. Calcular percentiles 33 y 66
    final double p33 = prices[(count * 0.33).floor()];
    final double p66 = prices[(count * 0.66).floor()];
    
    // 4. Asignar rango a cada gasolinera
    for (final station in stations) {
      final double? price = station.getPriceForFuel(fuelType);
      
      // Si la gasolinera no tiene precio para este combustible, saltar
      if (price == null) continue;
      
      // Clasificar según percentiles
      if (price <= p33) {
        station.priceRange = PriceRange.low;
      } else if (price <= p66) {
        station.priceRange = PriceRange.medium;
      } else {
        station.priceRange = PriceRange.high;
      }
    }
  }
  
  /// Calcula estadísticas de distribución de precios.
  /// 
  /// Útil para debugging y análisis.
  /// 
  /// Retorna un mapa con:
  /// - 'min': precio mínimo
  /// - 'max': precio máximo
  /// - 'p33': percentil 33
  /// - 'p66': percentil 66
  /// - 'count': número de gasolineras
  static Map<String, dynamic> calculateStatistics(
    List<GasStation> stations,
    FuelType fuelType,
  ) {
    final List<double> prices = stations
        .map((station) => station.getPriceForFuel(fuelType))
        .whereType<double>()
        .toList();
    
    if (prices.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'p33': 0.0,
        'p66': 0.0,
        'count': 0,
      };
    }
    
    prices.sort();
    final int count = prices.length;
    
    return {
      'min': prices.first,
      'max': prices.last,
      'p33': prices[(count * 0.33).floor()],
      'p66': prices[(count * 0.66).floor()],
      'count': count,
    };
  }
  
  /// Cuenta cuántas gasolineras hay en cada rango.
  /// 
  /// Retorna un mapa con las claves 'low', 'medium', 'high' y sus conteos.
  static Map<String, int> countByRange(List<GasStation> stations) {
    final Map<String, int> counts = {
      'low': 0,
      'medium': 0,
      'high': 0,
    };
    
    for (final station in stations) {
      if (station.priceRange == null) continue;
      
      switch (station.priceRange!) {
        case PriceRange.low:
          counts['low'] = counts['low']! + 1;
          break;
        case PriceRange.medium:
          counts['medium'] = counts['medium']! + 1;
          break;
        case PriceRange.high:
          counts['high'] = counts['high']! + 1;
          break;
      }
    }
    
    return counts;
  }
}
```

### Paso 2: Verificar Entidad PriceRange

**Ubicación esperada:** `lib/domain/entities/price_range.dart`

Si no existe, crear el archivo con:

```dart
import 'package:flutter/material.dart';

/// Rango de precio de combustible.
/// 
/// Clasifica los precios en tres categorías:
/// - low: precios bajos (verde)
/// - medium: precios medios (naranja)
/// - high: precios altos (rojo)
enum PriceRange {
  /// Rango de precio bajo (≤ percentil 33)
  low,
  
  /// Rango de precio medio (percentil 33 < precio ≤ percentil 66)
  medium,
  
  /// Rango de precio alto (> percentil 66)
  high;
  
  /// Color asociado al rango de precio.
  /// 
  /// Utilizado para colorear marcadores en el mapa.
  Color get color {
    switch (this) {
      case PriceRange.low:
        return Colors.green;
      case PriceRange.medium:
        return Colors.orange;
      case PriceRange.high:
        return Colors.red;
    }
  }
  
  /// Nombre legible del rango.
  String get displayName {
    switch (this) {
      case PriceRange.low:
        return 'Precio Bajo';
      case PriceRange.medium:
        return 'Precio Medio';
      case PriceRange.high:
        return 'Precio Alto';
    }
  }
}
```

### Paso 3: Actualizar GasStation (Si es Necesario)

**Ubicación:** `lib/domain/entities/gas_station.dart`

Asegurarse de que la clase tiene:

```dart
class GasStation {
  // ... otras propiedades ...
  
  /// Rango de precio asignado dinámicamente.
  /// 
  /// Se calcula usando PriceRangeCalculator basado en percentiles.
  PriceRange? priceRange;
  
  // ... resto del código ...
}
```

---

## INTEGRACIÓN CON COMPONENTES EXISTENTES

### Integración en MapBloc o Use Case

El cálculo de rangos debe ejecutarse **después de obtener las gasolineras** y **antes de emitir el estado al UI**.

#### Opción A: Integración en MapBloc

**Ubicación:** `lib/presentation/blocs/map/map_bloc.dart` (si existe)

```dart
Future<void> _onLoadMapData(LoadMapData event, Emitter<MapState> emit) async {
  emit(MapLoading());
  
  try {
    // 1. Obtener gasolineras cercanas
    final stations = await _getNearbyStations(
      latitude: event.latitude,
      longitude: event.longitude,
      radiusKm: _settings.searchRadius.toDouble(),
    );
    
    // 2. Filtrar por tipo de combustible
    final filteredStations = stations
        .where((s) => s.getPriceForFuel(_settings.preferredFuel) != null)
        .toList();
    
    // 3. CALCULAR RANGOS DE PRECIO
    PriceRangeCalculator.assignPriceRanges(
      filteredStations,
      _settings.preferredFuel,
    );
    
    // 4. Emitir estado con rangos asignados
    emit(MapLoaded(
      stations: filteredStations,
      currentFuel: _settings.preferredFuel,
    ));
  } catch (e) {
    emit(MapError(message: e.toString()));
  }
}
```

#### Opción B: Integración en Use Case

**Ubicación:** `lib/domain/usecases/get_nearby_stations.dart`

```dart
class GetNearbyStationsUseCase {
  final GasStationRepository _repository;
  
  GetNearbyStationsUseCase(this._repository);
  
  Future<List<GasStation>> call({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required FuelType fuelType,
  }) async {
    // 1. Obtener gasolineras cercanas
    final stations = await _repository.getNearbyStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    
    // 2. Filtrar por combustible
    final filteredStations = stations
        .where((s) => s.getPriceForFuel(fuelType) != null)
        .toList();
    
    // 3. CALCULAR RANGOS DE PRECIO
    PriceRangeCalculator.assignPriceRanges(filteredStations, fuelType);
    
    // 4. Ordenar por precio (opcional)
    filteredStations.sort((a, b) {
      final priceA = a.getPriceForFuel(fuelType) ?? double.infinity;
      final priceB = b.getPriceForFuel(fuelType) ?? double.infinity;
      return priceA.compareTo(priceB);
    });
    
    return filteredStations;
  }
}
```

### Integración con Widgets

Los widgets `GasStationMarker` y `StationInfoCard` ya están preparados para usar `priceRange`:

```dart
// En gas_station_marker.dart (ya implementado)
Color markerColor = station.priceRange?.color ?? Colors.grey;
```

```dart
// En station_info_card.dart (ya implementado)
color: station.priceRange?.color,
```

No se requieren cambios en los widgets si ya usan `station.priceRange?.color`.

### Flujo Completo en el Sistema

```
Usuario abre app
    ↓
SplashScreen carga
    ↓
MapScreen se inicializa
    ↓
MapBloc.LoadMapData (con ubicación GPS)
    ↓
GetNearbyStationsUseCase ejecuta
    ↓
1. Repository obtiene gasolineras de cache/API
2. Se filtran por combustible seleccionado
3. PriceRangeCalculator.assignPriceRanges() ← PASO 15
4. Se asigna priceRange a cada GasStation
    ↓
MapBloc emite MapLoaded con stations
    ↓
MapScreen reconstruye UI
    ↓
Widgets leen station.priceRange.color
    ↓
Marcadores se muestran con colores correctos
```

---

## PRUEBAS Y VALIDACIÓN

### Pruebas Unitarias

**Ubicación:** `test/core/utils/price_range_calculator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/core/utils/price_range_calculator.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/price_range.dart';

void main() {
  group('PriceRangeCalculator', () {
    test('debe asignar rangos correctamente con 9 gasolineras', () {
      // Arrange: 9 gasolineras con precios: 1.00, 1.10, 1.20, ..., 1.80
      final stations = List.generate(9, (i) {
        return GasStation(
          id: 'station_$i',
          name: 'Station $i',
          latitude: 40.0,
          longitude: -3.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.00 + (i * 0.10),
              updatedAt: DateTime.now(),
            ),
          ],
        );
      });

      // Act
      PriceRangeCalculator.assignPriceRanges(stations, FuelType.gasolina95);

      // Assert
      // Con 9 elementos: P33 = posición 2 (1.20), P66 = posición 5 (1.50)
      // Low: 1.00, 1.10, 1.20 (3 elementos)
      expect(stations[0].priceRange, PriceRange.low);
      expect(stations[1].priceRange, PriceRange.low);
      expect(stations[2].priceRange, PriceRange.low);
      
      // Medium: 1.30, 1.40, 1.50 (3 elementos)
      expect(stations[3].priceRange, PriceRange.medium);
      expect(stations[4].priceRange, PriceRange.medium);
      expect(stations[5].priceRange, PriceRange.medium);
      
      // High: 1.60, 1.70, 1.80 (3 elementos)
      expect(stations[6].priceRange, PriceRange.high);
      expect(stations[7].priceRange, PriceRange.high);
      expect(stations[8].priceRange, PriceRange.high);
    });

    test('debe manejar lista vacía sin errores', () {
      // Arrange
      final stations = <GasStation>[];

      // Act & Assert (no debe lanzar excepción)
      expect(
        () => PriceRangeCalculator.assignPriceRanges(stations, FuelType.gasolina95),
        returnsNormally,
      );
    });

    test('debe ignorar gasolineras sin precio para el combustible', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Con Precio',
          latitude: 40.0,
          longitude: -3.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.50,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        GasStation(
          id: '2',
          name: 'Sin Precio',
          latitude: 40.0,
          longitude: -3.0,
          prices: [], // Sin precios
        ),
      ];

      // Act
      PriceRangeCalculator.assignPriceRanges(stations, FuelType.gasolina95);

      // Assert
      expect(stations[0].priceRange, isNotNull);
      expect(stations[1].priceRange, isNull); // No se asigna rango
    });

    test('debe calcular estadísticas correctamente', () {
      // Arrange
      final stations = [
        _createStation('1', 1.30),
        _createStation('2', 1.40),
        _createStation('3', 1.50),
      ];

      // Act
      final stats = PriceRangeCalculator.calculateStatistics(
        stations,
        FuelType.gasolina95,
      );

      // Assert
      expect(stats['min'], 1.30);
      expect(stats['max'], 1.50);
      expect(stats['count'], 3);
      expect(stats['p33'], closeTo(1.30, 0.01));
      expect(stats['p66'], closeTo(1.40, 0.01));
    });

    test('debe contar gasolineras por rango', () {
      // Arrange
      final stations = [
        _createStation('1', 1.00)..priceRange = PriceRange.low,
        _createStation('2', 1.10)..priceRange = PriceRange.low,
        _createStation('3', 1.50)..priceRange = PriceRange.medium,
        _createStation('4', 1.80)..priceRange = PriceRange.high,
      ];

      // Act
      final counts = PriceRangeCalculator.countByRange(stations);

      // Assert
      expect(counts['low'], 2);
      expect(counts['medium'], 1);
      expect(counts['high'], 1);
    });
  });
}

// Helper para crear gasolineras de prueba
GasStation _createStation(String id, double price) {
  return GasStation(
    id: id,
    name: 'Station $id',
    latitude: 40.0,
    longitude: -3.0,
    prices: [
      FuelPrice(
        fuelType: FuelType.gasolina95,
        value: price,
        updatedAt: DateTime.now(),
      ),
    ],
  );
}
```

### Pruebas de Integración

**Ubicación:** `test/integration/price_range_integration_test.dart`

```dart
void main() {
  group('Integración: PriceRangeCalculator con Use Case', () {
    test('el use case debe retornar gasolineras con rangos asignados', () async {
      // Arrange
      final mockRepo = MockGasStationRepository();
      final useCase = GetNearbyStationsUseCase(mockRepo);
      
      final mockStations = [
        _createStation('1', 1.30),
        _createStation('2', 1.40),
        _createStation('3', 1.50),
      ];
      
      when(mockRepo.getNearbyStations(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        radiusKm: anyNamed('radiusKm'),
      )).thenAnswer((_) async => mockStations);

      // Act
      final result = await useCase(
        latitude: 40.0,
        longitude: -3.0,
        radiusKm: 10.0,
        fuelType: FuelType.gasolina95,
      );

      // Assert
      expect(result.length, 3);
      expect(result.every((s) => s.priceRange != null), true);
      expect(result[0].priceRange, PriceRange.low);
      expect(result[2].priceRange, PriceRange.high);
    });
  });
}
```

### Validación Visual

**Checklist de Validación:**

- [ ] **Marcadores en Mapa:**
  - [ ] Gasolineras con precios bajos tienen marcador verde
  - [ ] Gasolineras con precios medios tienen marcador naranja
  - [ ] Gasolineras con precios altos tienen marcador rojo
  - [ ] Aproximadamente 33% de marcadores de cada color

- [ ] **Consistencia de Datos:**
  - [ ] El color del marcador coincide con el precio mostrado
  - [ ] Al cambiar de combustible, los colores se recalculan
  - [ ] Gasolineras sin precio no tienen color asignado (gris)

- [ ] **Rendimiento:**
  - [ ] El cálculo de rangos se ejecuta en < 100ms
  - [ ] No hay lag al cargar el mapa
  - [ ] Los rangos se actualizan inmediatamente al filtrar

### Validación con Datos Reales

**Proceso de validación:**

1. Ejecutar app con datos reales de la API
2. Observar distribución de colores en el mapa
3. Verificar que aproximadamente 1/3 de gasolineras sean verdes
4. Verificar que aproximadamente 1/3 sean naranjas
5. Verificar que aproximadamente 1/3 sean rojas
6. Comprobar que los precios verdes son los más bajos
7. Comprobar que los precios rojos son los más altos

**Comando de debug para estadísticas:**

```dart
final stats = PriceRangeCalculator.calculateStatistics(stations, FuelType.gasolina95);
print('Estadísticas de precio:');
print('  Mínimo: ${stats['min']} €/L');
print('  Máximo: ${stats['max']} €/L');
print('  P33: ${stats['p33']} €/L');
print('  P66: ${stats['p66']} €/L');
print('  Total: ${stats['count']} gasolineras');

final counts = PriceRangeCalculator.countByRange(stations);
print('Distribución:');
print('  Verde (bajo): ${counts['low']}');
print('  Naranja (medio): ${counts['medium']}');
print('  Rojo (alto): ${counts['high']}');
```

---

## CRITERIOS DE ACEPTACIÓN

### Funcionales
1. ✅ PriceRangeCalculator está implementado en `lib/core/utils/`
2. ✅ El algoritmo usa percentiles 33 y 66 correctamente
3. ✅ Los rangos se asignan a la propiedad `priceRange` de GasStation
4. ✅ La integración funciona en MapBloc o Use Case
5. ✅ Los marcadores en el mapa muestran los colores correctos
6. ✅ Al cambiar tipo de combustible, los rangos se recalculan
7. ✅ Gasolineras sin precio no causan errores

### No Funcionales
1. ✅ El cálculo completo tarda menos de 100ms con 1000 gasolineras
2. ✅ El código está documentado con comentarios inline
3. ✅ No hay errores de compilación
4. ✅ No hay warnings de flutter analyze
5. ✅ La distribución de rangos es equilibrada (~33% cada uno)

### Cobertura de Pruebas
1. ✅ Al menos 5 pruebas unitarias para PriceRangeCalculator
2. ✅ Pruebas cubren casos: lista vacía, lista con elementos, precios null
3. ✅ Prueba de integración con Use Case
4. ✅ Todas las pruebas pasan exitosamente

---

## ESTRUCTURA DE ARCHIVOS

Después de implementar el Paso 15:

```
lib/
├── core/
│   └── utils/
│       ├── distance_calculator.dart (existente)
│       └── price_range_calculator.dart ← NUEVO
├── domain/
│   ├── entities/
│   │   ├── gas_station.dart (actualizado si es necesario)
│   │   ├── fuel_type.dart (existente)
│   │   ├── fuel_price.dart (existente)
│   │   └── price_range.dart ← NUEVO (si no existe)
│   └── usecases/
│       └── get_nearby_stations.dart (actualizado con cálculo de rangos)
└── presentation/
    └── blocs/
        └── map/
            └── map_bloc.dart (actualizado con cálculo de rangos)

test/
├── core/
│   └── utils/
│       └── price_range_calculator_test.dart ← NUEVO
└── integration/
    └── price_range_integration_test.dart ← NUEVO
```

---

## COMANDOS DE DESARROLLO

### Crear archivos:

```powershell
# Crear directorio si no existe
New-Item -ItemType Directory -Force -Path "lib/core/utils"

# Crear archivo principal
New-Item -ItemType File -Path "lib/core/utils/price_range_calculator.dart"

# Crear archivos de pruebas
New-Item -ItemType Directory -Force -Path "test/core/utils"
New-Item -ItemType File -Path "test/core/utils/price_range_calculator_test.dart"
```

### Ejecutar pruebas:

```powershell
# Ejecutar pruebas unitarias específicas
flutter test test/core/utils/price_range_calculator_test.dart

# Ejecutar todas las pruebas
flutter test

# Ejecutar con cobertura
flutter test --coverage
```

### Validar código:

```powershell
# Analizar código
flutter analyze lib/core/utils/price_range_calculator.dart

# Formatear código
flutter format lib/core/utils/
```

---

## NOTAS ADICIONALES

### Consideraciones de Rendimiento

**Complejidad temporal:**
- Extracción de precios: O(n)
- Ordenación: O(n log n)
- Asignación de rangos: O(n)
- **Total: O(n log n)**

Con 1000 gasolineras, el tiempo de ejecución típico es < 50ms.

### Manejo de Casos Especiales

**Caso 1: Todos los precios iguales**
```dart
// Ejemplo: [1.50, 1.50, 1.50, 1.50]
// P33 = 1.50, P66 = 1.50
// Resultado: Todos en rango "low" (precio <= p33)
```

**Caso 2: Solo 1 gasolinera**
```dart
// P33 y P66 serán el mismo valor
// La gasolinera única será clasificada como "low"
```

**Caso 3: Gasolineras sin precio**
```dart
// Se ignoran en el cálculo de percentiles
// Su priceRange permanece null
// Los widgets deben manejar null con color gris
```

### Alternativas al Algoritmo de Percentiles

**Otras opciones consideradas (no implementadas):**

1. **Rangos fijos:** Definir umbrales absolutos (ej: < 1.40, 1.40-1.50, > 1.50)
   - Desventaja: No se adapta a cambios de mercado

2. **Media y desviación estándar:** Usar μ - σ y μ + σ como límites
   - Desventaja: Sensible a valores extremos

3. **Cuartiles:** Usar Q1, Q2, Q3 (percentiles 25, 50, 75)
   - Ventaja: Más granular
   - Desventaja: Solo tenemos 3 colores

**Conclusión:** Los percentiles 33/66 son la mejor opción para 3 rangos equilibrados.

### Extensibilidad Futura

El diseño permite fácilmente:

1. **Agregar más rangos:**
```dart
enum PriceRange {
  veryLow,  // P25
  low,      // P50
  medium,   // P75
  high,     // P90
  veryHigh  // > P90
}
```

2. **Algoritmos personalizables:**
```dart
static void assignPriceRangesCustom(
  List<GasStation> stations,
  FuelType fuelType,
  {double lowThreshold = 0.33, double highThreshold = 0.66}
) {
  // Implementación flexible
}
```

3. **Caché de percentiles:**
```dart
// Almacenar P33 y P66 en SharedPreferences para comparaciones históricas
```

---

## REFERENCIAS

### Documentación Métrica V3
- **DSI 4:** Diseño de Clases - Clase GasStation y enum PriceRange
- **DSI 6:** Diseño de Procesos - Algoritmo PriceRangeCalculator
- **ASI 1:** Capa de Lógica de Negocio - Clasificación por rangos de precio
- **ASI 6:** Proceso Principal - "Clasificar por rangos de precio (percentiles)"
- **RF-02:** Visualización en Mapa - Código de color según rango de precios

### Entidades Relacionadas
- `lib/domain/entities/gas_station.dart`
- `lib/domain/entities/price_range.dart`
- `lib/domain/entities/fuel_type.dart`
- `lib/domain/entities/fuel_price.dart`

### Componentes que Usan Rangos
- `lib/presentation/widgets/gas_station_marker.dart`
- `lib/presentation/widgets/station_info_card.dart`
- `lib/domain/usecases/get_nearby_stations.dart`
- `lib/presentation/blocs/map/map_bloc.dart`

---

## CHECKLIST DE FINALIZACIÓN

Antes de considerar el Paso 15 como completado:

- [ ] `PriceRangeCalculator` implementado en `lib/core/utils/`
- [ ] Método `assignPriceRanges()` funciona correctamente
- [ ] Métodos auxiliares `calculateStatistics()` y `countByRange()` implementados
- [ ] `PriceRange` enum existe con getter `color`
- [ ] Propiedad `priceRange` añadida a `GasStation`
- [ ] Integración en MapBloc o Use Case completada
- [ ] Pruebas unitarias implementadas (mínimo 5 tests)
- [ ] Prueba de integración completada
- [ ] No hay errores de compilación (`flutter analyze`)
- [ ] Todas las pruebas pasan (`flutter test`)
- [ ] Validación visual: colores de marcadores correctos
- [ ] Validación con datos reales: distribución ~33% cada rango
- [ ] Documentación inline completa
- [ ] Archivo PASO_15_COMPLETADO.md creado
- [ ] PASOS_DESARROLLO.md actualizado

---

**FIN DEL DOCUMENTO**
