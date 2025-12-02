# Paso 20: Escribir Pruebas Unitarias

## Contexto del Proyecto

**Proyecto:** BuscaGas - Localizador de Gasolineras Económicas en España  
**Fase:** FASE 7 - PRUEBAS  
**Paso:** 20 de 28  
**Documento base:** BuscaGas Documentacion V3 - Métrica v3

---

## Objetivo del Paso

Implementar pruebas unitarias exhaustivas para garantizar la calidad, robustez y mantenibilidad del código de BuscaGas, validando el comportamiento de los componentes de lógica de negocio de forma aislada.

---

## Alcance de las Pruebas Unitarias

Según la documentación Métrica v3 (sección ASI 8 - Matriz de Trazabilidad) y la arquitectura definida (DSI 1), las pruebas unitarias deben cubrir:

### 1. **Casos de Uso (Domain/UseCases)**
- `get_nearby_stations.dart` - Obtener gasolineras cercanas
- `filter_by_fuel_type.dart` - Filtrar por tipo de combustible
- `calculate_distance.dart` - Cálculo de distancias (Haversine)
- `assign_price_range.dart` - Asignación de rangos de precio

### 2. **Utilidades del Core (Core/Utils)**
- `distance_calculator.dart` - Algoritmo de distancia geográfica
- `price_range_calculator.dart` - Clasificación por percentiles
- `price_formatter.dart` - Formateo de precios en euros
- `api_validator.dart` - Validación de datos de API

### 3. **Entidades de Dominio (Domain/Entities)**
- `gas_station.dart` - Modelo de gasolinera
- `fuel_price.dart` - Modelo de precio de combustible
- `app_settings.dart` - Configuración de la aplicación

### 4. **Repositorios (Data/Repositories)**
- `gas_station_repository_impl.dart` - Implementación del repositorio
- Lógica de combinación de fuentes locales y remotas
- Gestión de caché

---

## Requisitos Previos

### Dependencias Necesarias

Verificar que `pubspec.yaml` incluya:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  test: ^1.24.0
```

Si faltan, agregar y ejecutar:
```bash
flutter pub add --dev mockito build_runner
flutter pub get
```

### Estructura de Carpetas

Asegurar que existe la estructura:
```
test/
├── core/
│   └── utils/
│       ├── distance_calculator_test.dart
│       ├── price_range_calculator_test.dart
│       └── price_formatter_test.dart
├── domain/
│   ├── entities/
│   │   ├── gas_station_test.dart
│   │   └── app_settings_test.dart
│   └── usecases/
│       ├── get_nearby_stations_test.dart
│       ├── filter_by_fuel_type_test.dart
│       ├── calculate_distance_test.dart
│       └── assign_price_range_test.dart
└── data/
    └── repositories/
        └── gas_station_repository_impl_test.dart
```

---

## Especificaciones de Pruebas por Componente

### **PRUEBA 1: CalculateDistanceUseCase**

**Archivo:** `test/domain/usecases/calculate_distance_test.dart`

**Objetivo:** Validar el cálculo de distancias usando la fórmula de Haversine

**Casos de prueba obligatorios:**

1. **Distancia conocida entre coordenadas reales**
   - Madrid (40.4168, -3.7038) a Barcelona (41.3851, 2.1734)
   - Resultado esperado: ~504 km (±5 km de tolerancia)

2. **Mismo punto (distancia cero)**
   - Coordenadas idénticas
   - Resultado esperado: 0.0 km

3. **Distancias cortas (<1 km)**
   - Validar precisión en rangos urbanos
   - Ejemplo: 500 metros entre dos puntos

4. **Coordenadas en hemisferios opuestos**
   - Validar cálculo con longitudes negativas/positivas

**Criterios de aceptación:**
- ✅ Precisión del ±2% en distancias >10 km
- ✅ Precisión del ±50 metros en distancias <1 km
- ✅ Manejo correcto de coordenadas límite (±90° lat, ±180° lon)

---

### **PRUEBA 2: PriceRangeCalculator**

**Archivo:** `test/core/utils/price_range_calculator_test.dart`

**Objetivo:** Validar clasificación de precios por percentiles

**Casos de prueba según documentación (DSI 6):**

1. **Distribución normal de precios**
   - Lista: [1.40, 1.42, 1.45, 1.48, 1.50, 1.52, 1.55, 1.58, 1.60]
   - Validar que ~33% están en cada rango (low/medium/high)

2. **Todos los precios iguales**
   - Lista: [1.50, 1.50, 1.50, 1.50]
   - Resultado esperado: Todos en `PriceRange.medium`

3. **Lista vacía**
   - Entrada: []
   - Comportamiento: Retornar lista vacía sin error

4. **Un solo elemento**
   - Entrada: [1.45]
   - Resultado esperado: `PriceRange.medium`

5. **Cálculo de percentiles P33 y P66**
   - Validar interpolación lineal según algoritmo DSI 6

**Criterios de aceptación:**
- ✅ P33 calculado con precisión ±0.01€
- ✅ P66 calculado con precisión ±0.01€
- ✅ Distribución uniforme (~33% en cada rango)
- ✅ Sin excepciones en casos edge

---

### **PRUEBA 3: GetNearbyStationsUseCase**

**Archivo:** `test/domain/usecases/get_nearby_stations_test.dart`

**Objetivo:** Validar obtención y filtrado de gasolineras cercanas

**Casos de prueba según CU-01 (ASI 3):**

1. **Filtrado por radio de búsqueda**
   - Radio: 10 km
   - Verificar que solo se incluyan estaciones dentro del radio

2. **Ordenación por distancia**
   - Validar que la lista esté ordenada de menor a mayor distancia

3. **Límite de resultados**
   - Máximo 50 gasolineras (según PASO_12_COMPLETADO.md - FASE 3)
   - Verificar que se devuelven las 50 más cercanas

4. **Sin gasolineras en el radio**
   - Radio muy pequeño (ej: 0.1 km)
   - Resultado esperado: Lista vacía

**Mock necesario:**
```dart
@GenerateMocks([GasStationRepository])
```

**Criterios de aceptación:**
- ✅ Filtrado correcto por radio
- ✅ Ordenación ascendente por distancia
- ✅ Límite de 50 respetado
- ✅ Llamada al repositorio ejecutada exactamente 1 vez

---

### **PRUEBA 4: FilterByFuelTypeUseCase**

**Archivo:** `test/domain/usecases/filter_by_fuel_type_test.dart`

**Objetivo:** Validar filtrado de gasolineras por tipo de combustible

**Casos de prueba:**

1. **Filtrar por Gasolina 95**
   - Entrada: 10 gasolineras (5 con Gasolina 95, 5 sin)
   - Resultado esperado: 5 gasolineras

2. **Filtrar por Diésel Gasóleo A**
   - Similar al anterior

3. **Gasolinera con múltiples combustibles**
   - Validar que se incluye si tiene el combustible solicitado

4. **Gasolinera sin ningún precio**
   - Debe ser excluida del resultado

**Criterios de aceptación:**
- ✅ Filtrado exacto según `FuelType` enum
- ✅ Sin resultados duplicados
- ✅ Sin excepciones con listas vacías

---

### **PRUEBA 5: AssignPriceRangeUseCase**

**Archivo:** `test/domain/usecases/assign_price_range_test.dart`

**Objetivo:** Validar asignación de rangos de precio a gasolineras

**Casos de prueba:**

1. **Asignación básica**
   - 9 gasolineras con precios variados
   - Verificar que cada una tiene `priceRange` asignado

2. **Respeto de percentiles**
   - Los 3 precios más bajos deben tener `PriceRange.low`
   - Los 3 intermedios deben tener `PriceRange.medium`
   - Los 3 más altos deben tener `PriceRange.high`

3. **Sin gasolineras con el combustible seleccionado**
   - Resultado: Todas con `PriceRange.medium` (valor por defecto)

**Criterios de aceptación:**
- ✅ Distribución uniforme de rangos
- ✅ Coherencia con `PriceRangeCalculator`
- ✅ Inmutabilidad de entidades originales

---

### **PRUEBA 6: GasStation Entity**

**Archivo:** `test/domain/entities/gas_station_test.dart`

**Objetivo:** Validar comportamiento de la entidad `GasStation`

**Casos de prueba:**

1. **Creación de instancia válida**
   - Con todos los campos requeridos
   - Verificar que no lanza excepciones

2. **Método `copyWith()`**
   - Validar que crea nueva instancia con campos modificados
   - Verificar inmutabilidad del original

3. **Método `calcularDistancia()` (según ASI 4)**
   - Validar integración con `CalculateDistanceUseCase`

4. **Igualdad (`==`) y `hashCode`**
   - Dos gasolineras con mismo ID deben ser iguales
   - `hashCode` debe ser consistente

**Criterios de aceptación:**
- ✅ Inmutabilidad garantizada
- ✅ Métodos helper funcionan correctamente
- ✅ Validación de campos obligatorios

---

### **PRUEBA 7: AppSettings Entity**

**Archivo:** `test/domain/entities/app_settings_test.dart`

**Objetivo:** Validar configuración de usuario y persistencia

**Casos de prueba según ASI 4:**

1. **Valores por defecto**
   - Radio: 10 km
   - Combustible: gasolina95
   - Tema: false (claro)

2. **Método `save()`**
   - Mock de SharedPreferences
   - Verificar que se persisten todos los campos

3. **Método `load()`**
   - Cargar desde SharedPreferences mockeado
   - Validar reconstrucción correcta

4. **Validación de rangos**
   - Radio solo puede ser 5, 10, 20, 50 km
   - Combustible solo valores del enum `FuelType`

**Criterios de aceptación:**
- ✅ Persistencia correcta
- ✅ Validación de valores permitidos
- ✅ Manejo de errores en load/save

---

### **PRUEBA 8: GasStationRepositoryImpl**

**Archivo:** `test/data/repositories/gas_station_repository_impl_test.dart`

**Objetivo:** Validar lógica de combinación de fuentes de datos

**Casos de prueba según DSI 1 (Repository Pattern):**

1. **Caché disponible y reciente**
   - Mock: DatabaseDataSource retorna datos
   - Resultado: No se llama a ApiDataSource

2. **Caché vacío**
   - Mock: DatabaseDataSource retorna lista vacía
   - Verificar: Se llama a ApiDataSource
   - Verificar: Datos guardados en caché

3. **Error en API**
   - ApiDataSource lanza excepción
   - Verificar: Se intenta usar caché antiguo

4. **Método `updateCache()`**
   - Validar que borra datos antiguos
   - Validar que inserta nuevos datos
   - Validar timestamp de sincronización

**Mocks necesarios:**
```dart
@GenerateMocks([ApiDataSource, DatabaseDataSource])
```

**Criterios de aceptación:**
- ✅ Estrategia cache-first implementada
- ✅ Fallback a caché en caso de error de red
- ✅ Actualización correcta del timestamp
- ✅ Manejo robusto de excepciones

---

## Estructura de un Test Unitario Modelo

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/domain/usecases/calculate_distance.dart';

// Generar mocks si es necesario
// @GenerateMocks([DependenciaX])

void main() {
  group('CalculateDistanceUseCase', () {
    late CalculateDistanceUseCase useCase;

    setUp(() {
      useCase = CalculateDistanceUseCase();
    });

    test('debe calcular distancia Madrid-Barcelona correctamente', () {
      // Arrange
      const madridLat = 40.4168;
      const madridLon = -3.7038;
      const barcelonaLat = 41.3851;
      const barcelonaLon = 2.1734;

      // Act
      final distance = useCase.execute(
        madridLat, madridLon,
        barcelonaLat, barcelonaLon,
      );

      // Assert
      expect(distance, greaterThan(500));
      expect(distance, lessThan(510));
    });

    test('debe retornar 0 para el mismo punto', () {
      // Arrange
      const lat = 40.4168;
      const lon = -3.7038;

      // Act
      final distance = useCase.execute(lat, lon, lat, lon);

      // Assert
      expect(distance, equals(0.0));
    });

    // Más tests...
  });
}
```

---

## Comandos de Ejecución

### Generar Mocks (si usa Mockito)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Ejecutar Todas las Pruebas
```bash
flutter test
```

### Ejecutar Pruebas de un Archivo Específico
```bash
flutter test test/domain/usecases/calculate_distance_test.dart
```

### Ejecutar con Cobertura de Código
```bash
flutter test --coverage
```

### Ver Reporte de Cobertura (requiere lcov)
```bash
genhtml coverage/lcov.info -o coverage/html
# Abrir coverage/html/index.html en navegador
```

---

## Métricas de Calidad Esperadas

Según las mejores prácticas de Métrica v3 y desarrollo Flutter:

| Métrica | Objetivo Mínimo | Objetivo Ideal |
|---------|----------------|----------------|
| **Cobertura de Código** | 70% | 85%+ |
| **Cobertura de Casos de Uso** | 100% | 100% |
| **Cobertura de Utilidades** | 90% | 100% |
| **Pruebas que pasan** | 100% | 100% |
| **Tiempo de ejecución** | <10 segundos | <5 segundos |

---

## Criterios de Aceptación del Paso 20

- [ ] **CA-01:** Todas las pruebas unitarias implementadas según especificación
- [ ] **CA-02:** Cobertura de código ≥70% en módulos críticos (domain, core/utils)
- [ ] **CA-03:** 100% de las pruebas pasan exitosamente
- [ ] **CA-04:** Mocks configurados correctamente para dependencias externas
- [ ] **CA-05:** Documentación inline de cada test (qué valida y por qué)
- [ ] **CA-06:** Uso de `setUp()` y `tearDown()` para inicialización/limpieza
- [ ] **CA-07:** Nomenclatura clara: `test/ruta/espeja/lib/ruta`
- [ ] **CA-08:** Grupos lógicos con `group()` para organizar tests relacionados
- [ ] **CA-09:** Assertions específicas (`expect()` con matchers adecuados)
- [ ] **CA-10:** Sin dependencias de tiempo real, red o sistema de archivos
- [ ] **CA-11:** Ejecución rápida (<10 segundos total)
- [ ] **CA-12:** Integración en pipeline CI/CD (opcional pero recomendado)

---

## Orden de Implementación Recomendado

1. **Fase 1 - Utilidades básicas (1-2 días)**
   - `distance_calculator_test.dart`
   - `price_range_calculator_test.dart`
   - `price_formatter_test.dart`

2. **Fase 2 - Entidades (1 día)**
   - `gas_station_test.dart`
   - `app_settings_test.dart`

3. **Fase 3 - Casos de uso (2-3 días)**
   - `calculate_distance_test.dart`
   - `filter_by_fuel_type_test.dart`
   - `get_nearby_stations_test.dart`
   - `assign_price_range_test.dart`

4. **Fase 4 - Repositorio (1-2 días)**
   - `gas_station_repository_impl_test.dart` (más complejo, requiere mocks)

---

## Notas Importantes

⚠️ **Restricciones:**
- No usar datos reales de la API en pruebas unitarias
- Mockear todas las dependencias externas (API, base de datos, GPS)
- Las pruebas deben ser deterministas (mismo input → mismo output siempre)

✅ **Buenas prácticas:**
- Seguir patrón AAA (Arrange-Act-Assert)
- Un test, una responsabilidad
- Nombres descriptivos: `debe_hacer_X_cuando_Y`
- Usar `const` para valores de prueba cuando sea posible
- Documentar casos edge y por qué se prueban

📝 **Documentación:**
- Actualizar `PASOS_DESARROLLO.md` al completar
- Crear `PASO_20_COMPLETADO.md` con resultados y capturas de cobertura
- Anotar cualquier bug encontrado durante las pruebas

---

## Referencias de la Documentación

- **ASI 3:** Análisis de Casos de Uso → Base para pruebas funcionales
- **ASI 4:** Análisis de Clases → Especificaciones de entidades
- **DSI 1:** Arquitectura del Sistema → Componentes a probar
- **DSI 4:** Diseño de Clases → Contratos de métodos
- **DSI 6:** Diseño de Procesos → Algoritmos a validar

---

**Fecha de creación:** 2 de diciembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Autor:** Desarrollo según Métrica v3  
**Estado:** ⏳ PENDIENTE DE IMPLEMENTACIÓN
