# Guía de Refactorización y Optimización - BuscaGas

**Versión:** 1.0 - Simplificada  
**Fecha:** 3 de diciembre de 2025

---

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Problemas Actuales](#problemas-actuales)
3. [Refactorizaciones Principales](#refactorizaciones-principales)
4. [Optimizaciones Simples](#optimizaciones-simples)
5. [Testing Básico](#testing-básico)
6. [Checklist de Implementación](#checklist-de-implementación)

---

## 🎯 Introducción

Esta guía te ayudará a mejorar el proyecto **BuscaGas** de forma práctica y sin complicaciones excesivas.

### Objetivos Principales

- ✅ Eliminar código duplicado
- ✅ Simplificar la estructura de dependencias
- ✅ Mejorar el rendimiento básico
- ✅ Añadir tests esenciales
- ✅ Mantener el código limpio y mantenible

---

## 🔍 Problemas Actuales

### Lo que hay que arreglar

#### 🔴 Prioritarios (Hacer primero)

1. **Servicios duplicados**
   - `api_service.dart` hace lo mismo que `ApiDataSource`
   - `database_service.dart` hace lo mismo que `DatabaseDataSource`
   - `sync_service.dart` duplica `data_sync_service.dart`
   - **Solución**: Eliminar los duplicados y usar solo uno

2. **Carpeta `examples/` en producción**
   - No debe estar en el código final
   - **Solución**: Eliminar o mover a proyecto aparte

3. **Mucha lógica en `main.dart`**
   - 50+ líneas de inicialización
   - **Solución**: Mover a clase `AppInitializer`

#### 🟡 Importantes (Hacer después)

4. **GlobalKey en main.dart**
   - Anti-patrón difícil de mantener
   - **Solución**: Usar BLoC para comunicación

5. **Falta manejo de errores consistente**
   - Cada parte maneja errores diferente
   - **Solución**: Crear clase `AppError` simple

---

## 🔧 Refactorizaciones Principales

### 1. Limpiar Servicios Duplicados (30 min)

**Problema**: Tenemos dos servicios que hacen lo mismo.

**Solución Simple**:

```bash
# Eliminar archivos duplicados
Remove-Item lib\services\api_service.dart
Remove-Item lib\services\database_service.dart
Remove-Item lib\services\sync_service.dart
Remove-Item -Recurse lib\examples
```

Luego actualizar los imports donde se usaban:
- `api_service.dart` → `data/datasources/remote/api_datasource.dart`
- `database_service.dart` → `data/datasources/local/database_datasource.dart`
- `sync_service.dart` → `services/data_sync_service.dart`

---

### 2. Simplificar main.dart (45 min)

**Antes** (muy largo):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 50+ líneas de inicialización...
  final settings = await AppSettings.load();
  final apiDataSource = ApiDataSource();
  // ... muchas más líneas
  
  runApp(BuscaGasApp(/* muchos parámetros */));
}
```

**Después** (simple y limpio):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Todo en una clase
  await AppInitializer.initialize();
  
  runApp(const BuscaGasApp());
}
```

**Crear archivo**: `lib/core/app_initializer.dart`

```dart
class AppInitializer {
  static Future<void> initialize() async {
    // Cargar configuración
    final settings = await AppSettings.load();
    _settings = settings;
    
    // Inicializar base de datos
    _database = DatabaseService();
    await _database.initialize();
    
    // Crear datasources
    _apiDataSource = ApiDataSource();
    _databaseDataSource = DatabaseDataSource();
    
    // Crear repositorio
    _repository = GasStationRepositoryImpl(
      _apiDataSource,
      _databaseDataSource,
    );
    
    // Crear servicios
    _locationService = LocationService();
    _syncService = DataSyncService(_repository);
  }
  
  // Getters simples
  static AppSettings get settings => _settings;
  static LocationService get locationService => _locationService;
  static GasStationRepository get repository => _repository;
  static DataSyncService get syncService => _syncService;
  
  // Variables privadas
  static late AppSettings _settings;
  static late LocationService _locationService;
  static late GasStationRepository _repository;
  static late DataSyncService _syncService;
  static late DatabaseService _database;
  static late ApiDataSource _apiDataSource;
  static late DatabaseDataSource _databaseDataSource;
}
```

**Uso en la app**:
```dart
// En cualquier lugar
final settings = AppInitializer.settings;
final repository = AppInitializer.repository;
```

---

### 3. Eliminar GlobalKey Anti-patrón (20 min)

**Antes**:
```dart
final GlobalKey<BuscaGasAppState> appKey = GlobalKey<BuscaGasAppState>();

void main() {
  runApp(BuscaGasApp(key: appKey));
}

// En otra parte
appKey.currentState?.reloadSettings();
```

**Después** (usando BLoC):
```dart
// En SettingsScreen después de guardar
context.read<SettingsBloc>().add(ReloadSettings());

// El BLoC notifica a todos los listeners
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  Future<void> _onReloadSettings(...) async {
    final newSettings = await AppSettings.load();
    emit(SettingsLoaded(newSettings));
  }
}
```

---

### 4. Manejo de Errores Simple (30 min)

**Crear**: `lib/core/errors/app_error.dart`

```dart
/// Clase simple para manejar errores en toda la app
class AppError {
  final String message;
  final String? detail;
  final ErrorType type;
  
  AppError({
    required this.message,
    this.detail,
    this.type = ErrorType.general,
  });
  
  // Factory constructors para casos comunes
  factory AppError.network() => AppError(
    message: 'Sin conexión a internet',
    type: ErrorType.network,
  );
  
  factory AppError.location() => AppError(
    message: 'No se pudo obtener tu ubicación',
    type: ErrorType.location,
  );
  
  factory AppError.noData() => AppError(
    message: 'No hay datos disponibles',
    type: ErrorType.noData,
  );
  
  @override
  String toString() => detail != null ? '$message: $detail' : message;
}

enum ErrorType {
  general,
  network,
  location,
  noData,
  permission,
}
```

**Uso**:
```dart
// En lugar de lanzar excepciones
try {
  final stations = await repository.fetchRemoteStations();
} catch (e) {
  final error = AppError(
    message: 'Error al cargar gasolineras',
    detail: e.toString(),
    type: ErrorType.network,
  );
  emit(MapError(error));
}
```

---

### 5. Simplificar BLoCs (45 min)

**Problema**: MapBloc tiene lógica de negocio dentro.

**Antes**:
```dart
class MapBloc {
  void _assignPriceRanges(List<GasStation> stations, FuelType fuelType) {
    // 30 líneas de lógica compleja...
    List<double> prices = stations.map(...).toList();
    prices.sort();
    // etc.
  }
}
```

**Después** (lógica en caso de uso):
```dart
class MapBloc {
  final AssignPriceRangeUseCase _assignPriceRange;
  
  Future<void> _onLoadMapData(...) async {
    // BLoC solo orquesta
    final stations = await _getNearbyStations.call(...);
    final rankedStations = _assignPriceRange.call(stations, fuelType);
    emit(MapLoaded(stations: rankedStations));
  }
}

// La lógica está en el caso de uso
class AssignPriceRangeUseCase {
  List<GasStation> call(List<GasStation> stations, FuelType fuelType) {
    // Toda la lógica aquí
    // ...
    return stations;
  }
}
```

---

## 🚀 Optimizaciones Simples

### 1. Limitar Marcadores en Mapa (15 min)

**Problema**: Mostrar 500 marcadores hace que el mapa vaya lento.

**Solución**:
```dart
// En MapBloc, después de obtener estaciones
if (stations.length > 50) {
  stations = stations.sublist(0, 50); // Solo las 50 más cercanas
}
```

Ya está implementado, solo verifica que funcione.

---

### 2. Caché Simple (20 min)

**Crear**: `lib/core/cache/simple_cache.dart`

```dart
/// Caché en memoria muy simple
class SimpleCache<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final Duration defaultTTL;
  
  SimpleCache({this.defaultTTL = const Duration(minutes: 30)});
  
  void put(String key, T value) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(defaultTTL),
    );
  }
  
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }
  
  void clear() => _cache.clear();
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry({required this.value, required this.expiresAt});
}
```

**Uso**:
```dart
// En el repositorio
final _cache = SimpleCache<List<GasStation>>();

Future<List<GasStation>> getNearbyStations(...) async {
  final cacheKey = 'stations_${latitude}_${longitude}_$radiusKm';
  
  // Buscar en caché primero
  final cached = _cache.get(cacheKey);
  if (cached != null) return cached;
  
  // Si no está en caché, obtener de BD
  final stations = await _databaseDataSource.getAllStations();
  _cache.put(cacheKey, stations);
  
  return stations;
}
```

---

### 3. Debouncing en Búsqueda (15 min)

**Crear**: `lib/core/utils/debouncer.dart`

```dart
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({this.delay = const Duration(milliseconds: 500)});
  
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  void dispose() => _timer?.cancel();
}
```

**Uso en búsqueda**:
```dart
class _SearchBarState extends State<SearchBar> {
  final _debouncer = Debouncer();
  
  void _onSearchChanged(String query) {
    _debouncer(() {
      // Solo se ejecuta 500ms después de que el usuario deja de escribir
      context.read<MapBloc>().add(SearchStations(query));
    });
  }
  
  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
```

---

## 🧪 Testing Básico

### Mejorar Lints (10 min)

**Actualizar**: `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Estilo básico
    - prefer_single_quotes
    - prefer_const_constructors
    - avoid_print
    
    # Errores comunes
    - cancel_subscriptions
    - close_sinks
    
    # Buenas prácticas
    - always_declare_return_types
    - avoid_init_to_null
    - prefer_final_fields
    - unnecessary_this
```

---

### Tests Esenciales (1 hora)

**Prioridad**: Tests de casos de uso (más importantes)

```dart
// test/domain/usecases/get_nearby_stations_test.dart
void main() {
  late GetNearbyStationsUseCase useCase;
  late MockGasStationRepository mockRepository;
  
  setUp(() {
    mockRepository = MockGasStationRepository();
    useCase = GetNearbyStationsUseCase(mockRepository);
  });
  
  test('debe retornar lista de estaciones cercanas', () async {
    // Arrange
    final mockStations = [createMockStation()];
    when(mockRepository.getNearbyStations(
      latitude: 40.0,
      longitude: -3.0,
      radiusKm: 10.0,
    )).thenAnswer((_) async => mockStations);
    
    // Act
    final result = await useCase.call(40.0, -3.0, 10.0);
    
    // Assert
    expect(result, mockStations);
    verify(mockRepository.getNearbyStations(
      latitude: 40.0,
      longitude: -3.0,
      radiusKm: 10.0,
    )).called(1);
  });
}
```

**Tests mínimos recomendados**:
- ✅ 1 test por cada caso de uso (5 tests)
- ✅ 1 test para el repositorio (2 tests)
- ✅ 1 test de widget importante (2 tests)

Total: ~9 tests básicos pero efectivos.

---

## ✅ Checklist de Implementación

### Día 1: Limpieza (2-3 horas)

- [ ] **Eliminar duplicados**
  - [ ] Borrar `api_service.dart`
  - [ ] Borrar `database_service.dart`
  - [ ] Borrar `sync_service.dart`
  - [ ] Borrar carpeta `examples/`
  - [ ] Actualizar imports

- [ ] **Simplificar main.dart**
  - [ ] Crear `AppInitializer`
  - [ ] Mover lógica a initializer
  - [ ] Simplificar `main()`

---

### Día 2: Mejoras (2-3 horas)

- [ ] **Manejo de errores**
  - [ ] Crear `AppError`
  - [ ] Actualizar BLoCs para usar `AppError`

- [ ] **Eliminar GlobalKey**
  - [ ] Usar BLoC para comunicación
  - [ ] Quitar `appKey` de main.dart

- [ ] **Simplificar BLoCs**
  - [ ] Mover lógica de `_assignPriceRanges` a caso de uso
  - [ ] Limpiar otros métodos privados complejos

---

### Día 3: Optimizaciones (2 horas)

- [ ] **Caché simple**
  - [ ] Crear `SimpleCache`
  - [ ] Usar en repositorio

- [ ] **Debouncing**
  - [ ] Crear `Debouncer`
  - [ ] Aplicar en búsqueda

- [ ] **Verificar límite de marcadores**
  - [ ] Confirmar que solo muestra 50 marcadores

---

### Día 4: Testing (2 horas)

- [ ] **Configurar lints**
  - [ ] Actualizar `analysis_options.yaml`
  - [ ] Corregir warnings

- [ ] **Tests básicos**
  - [ ] 5 tests de casos de uso
  - [ ] 2 tests de repositorio
  - [ ] 2 tests de widgets

- [ ] **Ejecutar tests**
  - [ ] `flutter test`
  - [ ] Verificar que todos pasen

---

### Día 5: Documentación (1 hora)

- [ ] **Actualizar README**
  - [ ] Descripción del proyecto
  - [ ] Instrucciones de instalación
  - [ ] Estructura básica

- [ ] **Comentarios en código**
  - [ ] Documentar clases principales
  - [ ] Explicar lógica compleja

---

## 📊 Resultado Esperado

### Antes
- ⚠️ 71 archivos .dart
- ⚠️ Servicios duplicados
- ⚠️ main.dart con 50+ líneas
- ⚠️ Lógica en BLoCs

### Después
- ✅ ~65 archivos .dart (eliminamos ~6)
- ✅ Sin duplicaciones
- ✅ main.dart con 10 líneas
- ✅ BLoCs simples y limpios
- ✅ Caché y optimizaciones básicas
- ✅ 9+ tests esenciales

**Tiempo total estimado**: 9-11 horas (1-2 semanas a tiempo parcial)

---

## 💡 Consejos Finales

1. **Hacer cambios pequeños**: Un archivo a la vez
2. **Probar después de cada cambio**: `flutter run` para verificar
3. **No sobre-optimizar**: Solo lo necesario
4. **Tests simples pero efectivos**: Mejor 10 tests buenos que 100 malos
5. **Documentar lo importante**: No cada línea, solo lo no obvio

---

**Mantén el código simple, limpio y funcional** 🚀
