# Paso 23: Optimizar Rendimiento

## Contexto del Proyecto

**Proyecto:** BuscaGas - Localizador de Gasolineras Económicas en España  
**Fase:** FASE 8 - OPTIMIZACIÓN Y PULIDO  
**Paso:** 23 de 28  
**Documento base:** BuscaGas Documentacion V3 - Métrica v3  
**Prerequisitos:** Pasos 1-22 completados (app funcional con pruebas)

---

## Objetivo del Paso

Optimizar el rendimiento de la aplicación en tres áreas críticas:
1. **Tiempos de carga** - Reducir latencia en operaciones clave
2. **Consultas a base de datos** - Mejorar eficiencia de SQLite
3. **Consumo de batería** - Minimizar impacto energético

**Meta:** Cumplir con **RNF-01** (Requisito No Funcional de Rendimiento):
- Tiempo de carga inicial < 3 segundos
- Respuesta a interacciones < 500ms
- Usuario encuentra gasolinera más barata en < 10 segundos

---

## Estado Actual vs. Objetivos

### Métricas Actuales (Paso 12 - PASO_12_COMPLETADO.md)

| Métrica | Estado Actual | Objetivo | Estado |
|---------|---------------|----------|--------|
| Primera ejecución (descarga) | 15-25 seg | <20 seg | ⚠️ Mejorable |
| Siguientes ejecuciones (caché) | 2-3 seg | <3 seg | ✅ OK |
| Renderizado 50 marcadores | <500ms | <500ms | ✅ OK |
| Cambio de combustible | <200ms | <500ms | ✅ OK |
| Apertura de tarjeta | <100ms | <500ms | ✅ OK |
| Base de datos | 8-12 MB | <15 MB | ✅ OK |
| Memoria RAM | 80-120 MB | <150 MB | ✅ OK |
| Uso CPU (idle) | <15% | <20% | ✅ OK |
| Batería GPS | Normal | Optimizado | ⚠️ Mejorable |

### Áreas de Mejora Identificadas

1. **Primera carga (15-25s):** Reducir mediante:
   - Compresión de respuesta API (gzip)
   - Inserción batch optimizada en SQLite
   - Parseo paralelo de JSON

2. **Consumo de batería:** Reducir mediante:
   - GPS con `distanceFilter` (evitar actualizaciones innecesarias)
   - Sincronización condicional (solo WiFi en background)
   - Detener timer cuando app en background

3. **Consultas SQLite:** Mejorar mediante:
   - Índices compuestos
   - Query optimization
   - Prepared statements reutilizables

---

## Alcance de Optimizaciones

### ✅ INCLUIDO en Paso 23

1. **Optimización de Base de Datos**
   - Índices compuestos adicionales
   - Análisis de queries lentas
   - Vacuum y optimización de tamaño
   - Prepared statements cacheados

2. **Optimización de GPS**
   - Implementar `distanceFilter`
   - Reducir frecuencia de updates
   - Pausar GPS cuando no es necesario

3. **Optimización de Carga Inicial**
   - Inserción batch mejorada
   - Parseo paralelo de JSON con `compute()`
   - Compresión de respuesta HTTP

4. **Optimización de Sincronización**
   - Solo WiFi para actualizaciones en background
   - Detección de batería baja
   - Pausar timer cuando app invisible

5. **Optimización de Renderizado**
   - Lazy loading de marcadores
   - Caché de BitmapDescriptor
   - Debounce en filtros

### ❌ EXCLUIDO del Paso 23

- Optimizaciones de red (CDN, caché HTTP) - infraestructura externa
- Minificación de assets - parte del build de producción (Paso 26)
- Obfuscación de código - parte del build release (Paso 27)
- Análisis de memory leaks - requiere herramientas externas

---

## Especificaciones de Optimización por Componente

### **OPTIMIZACIÓN 1: Base de Datos SQLite**

#### Problema Actual
- Consulta de gasolineras por proximidad puede ser lenta con 11,000 registros
- Índice simple en `(latitude, longitude)` no es óptimo
- No hay estadísticas de rendimiento

#### Solución

**1.1. Índices Compuestos**

Archivo: `lib/data/datasources/local/database_datasource.dart`

```dart
// En el método onCreate, después de CREATE TABLE gas_stations

// Índice compuesto para consultas geográficas + combustible
await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_geo_fuel 
  ON fuel_prices(fuel_type, station_id)
''');

// Índice para optimizar ORDER BY distance (aproximado)
await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_lat_lon 
  ON gas_stations(latitude DESC, longitude DESC)
''');

// Índice para caché timestamp
await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_cached_at 
  ON gas_stations(cached_at DESC)
''');
```

**1.2. Query Optimization**

Archivo: `lib/services/database_service.dart`

Reemplazar la consulta actual de `getNearbyStations` con una optimizada:

```dart
Future<List<GasStation>> getNearbyStations({
  required double latitude,
  required double longitude,
  required double radiusKm,
  FuelType? fuelType,
}) async {
  try {
    final db = await _dataSource.database;
    
    // 1. Calcular bounding box (mucho más rápido que Haversine en todos)
    final latDelta = radiusKm / 111.0; // Aprox. 111 km por grado
    final lonDelta = radiusKm / (111.0 * cos(latitude * pi / 180));
    
    final minLat = latitude - latDelta;
    final maxLat = latitude + latDelta;
    final minLon = longitude - lonDelta;
    final maxLon = longitude + lonDelta;
    
    // 2. Query con bounding box (usa índices)
    String query = '''
      SELECT DISTINCT s.*, p.fuel_type, p.price, p.updated_at
      FROM gas_stations s
      INNER JOIN fuel_prices p ON s.id = p.station_id
      WHERE s.latitude BETWEEN ? AND ?
        AND s.longitude BETWEEN ? AND ?
    ''';
    
    List<dynamic> args = [minLat, maxLat, minLon, maxLon];
    
    // 3. Filtrar por combustible si se especifica
    if (fuelType != null) {
      query += ' AND p.fuel_type = ?';
      args.add(fuelType.toString().split('.').last);
    }
    
    // 4. Ejecutar query
    final results = await db.rawQuery(query, args);
    
    // 5. Convertir resultados
    Map<String, GasStation> stationsMap = {};
    
    for (var row in results) {
      final stationId = row['id'] as String;
      
      if (!stationsMap.containsKey(stationId)) {
        stationsMap[stationId] = GasStation(
          id: stationId,
          name: row['name'] as String,
          latitude: row['latitude'] as double,
          longitude: row['longitude'] as double,
          address: row['address'] as String? ?? '',
          locality: row['locality'] as String? ?? '',
          operator: row['operator'] as String? ?? '',
          prices: [],
        );
      }
      
      // Agregar precio
      stationsMap[stationId]!.prices.add(
        FuelPrice(
          fuelType: _parseFuelType(row['fuel_type'] as String),
          value: row['price'] as double,
          updatedAt: DateTime.parse(row['updated_at'] as String),
        ),
      );
    }
    
    // 6. Calcular distancias reales solo para candidatos (no 11,000)
    List<GasStation> stations = stationsMap.values.toList();
    for (var station in stations) {
      station.distance = _calculateDistance(
        latitude,
        longitude,
        station.latitude,
        station.longitude,
      );
    }
    
    // 7. Filtrar por radio exacto y ordenar
    stations = stations.where((s) => s.distance! <= radiusKm).toList();
    stations.sort((a, b) => a.distance!.compareTo(b.distance!));
    
    return stations;
  } catch (e) {
    debugPrint('Error getNearbyStations: $e');
    rethrow;
  }
}
```

**Beneficios:**
- ✅ Bounding box reduce candidatos de 11,000 a ~500 (98% menos)
- ✅ Haversine solo se calcula para candidatos (20x más rápido)
- ✅ Índices compuestos aceleran JOIN (5x más rápido)
- **Estimado:** Consulta de 500ms → 100ms (5x mejora)

**1.3. Vacuum Periódico**

Archivo: `lib/services/database_service.dart`

Agregar método de mantenimiento:

```dart
/// Optimizar base de datos (ejecutar semanalmente)
Future<void> optimizeDatabase() async {
  try {
    final db = await _dataSource.database;
    
    // VACUUM: Reconstruye BD, elimina fragmentación
    await db.execute('VACUUM');
    
    // ANALYZE: Actualiza estadísticas para query optimizer
    await db.execute('ANALYZE');
    
    debugPrint('✅ Base de datos optimizada');
  } catch (e) {
    debugPrint('Error optimizando BD: $e');
  }
}
```

Ejecutar automáticamente:

```dart
// En DataSyncService._performSync()
// Después de actualizar caché exitosamente

// Optimizar BD una vez por semana
final lastOptimization = await _getLastOptimizationTime();
if (lastOptimization == null || 
    DateTime.now().difference(lastOptimization).inDays >= 7) {
  await _databaseService.optimizeDatabase();
  await _saveLastOptimizationTime();
}
```

**1.4. Análisis de Rendimiento**

Archivo: `lib/core/utils/performance_monitor.dart` (NUEVO)

```dart
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  /// Iniciar medición
  static void start(String operation) {
    if (!kDebugMode) return;
    _timers[operation] = Stopwatch()..start();
  }
  
  /// Detener medición y loggear
  static void stop(String operation) {
    if (!kDebugMode) return;
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      debugPrint('⏱️ $operation: ${timer.elapsedMilliseconds}ms');
      _timers.remove(operation);
    }
  }
  
  /// Medir función
  static Future<T> measure<T>(String operation, Future<T> Function() fn) async {
    start(operation);
    try {
      return await fn();
    } finally {
      stop(operation);
    }
  }
}
```

Uso en DatabaseService:

```dart
Future<List<GasStation>> getNearbyStations(...) async {
  return PerformanceMonitor.measure('getNearbyStations', () async {
    // ... código existente
  });
}
```

**Criterios de aceptación:**
- [ ] Índices compuestos creados correctamente
- [ ] Query optimizada con bounding box implementada
- [ ] Consulta getNearbyStations <200ms (antes 500ms)
- [ ] VACUUM ejecutado automáticamente cada semana
- [ ] Logs de performance en debug mode

---

### **OPTIMIZACIÓN 2: GPS y Geolocalización**

#### Problema Actual
- GPS solicita actualizaciones continuas (consume batería)
- No hay `distanceFilter` (actualiza incluso con movimientos mínimos)
- GPS activo incluso cuando no se necesita

#### Solución

**2.1. Configurar distanceFilter**

Archivo: `lib/services/location_service.dart`

Actualizar configuración de LocationSettings:

```dart
static const LocationSettings _locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 50, // Solo actualizar si se mueve >50 metros
  timeLimit: Duration(seconds: 30), // Timeout
);

/// Obtener ubicación actual con configuración optimizada
Future<Position?> getCurrentLocation() async {
  try {
    PerformanceMonitor.start('GPS');
    
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint('⏱️ Timeout GPS');
        throw TimeoutException('GPS timeout');
      },
    );
    
    PerformanceMonitor.stop('GPS');
    return position;
  } catch (e) {
    debugPrint('❌ Error GPS: $e');
    return null;
  }
}
```

**2.2. Stream de Posición Optimizado**

Agregar método para tracking continuo (cuando sea necesario):

```dart
/// Stream de posición con filtro de distancia
Stream<Position> getPositionStream({int distanceFilterMeters = 100}) {
  return Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.medium, // Reducir a medium en stream
      distanceFilter: distanceFilterMeters,
      timeLimit: Duration(seconds: 60),
    ),
  );
}

/// Pausar actualizaciones de GPS
void pauseLocationUpdates() {
  // Cancelar subscripciones activas si las hay
  _positionStreamSubscription?.cancel();
  debugPrint('📍 GPS pausado');
}

/// Reanudar actualizaciones de GPS
void resumeLocationUpdates() {
  // Reactivar stream si es necesario
  debugPrint('📍 GPS reanudado');
}
```

**2.3. Detección de Background**

Archivo: `lib/presentation/screens/map_screen.dart`

Usar `WidgetsBindingObserver` para detectar estado de app:

```dart
class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App en background
        debugPrint('🔄 App en background - pausar GPS');
        _locationService.pauseLocationUpdates();
        _syncService.stop(); // Detener timer de sincronización
        break;
        
      case AppLifecycleState.resumed:
        // App en foreground
        debugPrint('✅ App en foreground - reanudar GPS');
        _locationService.resumeLocationUpdates();
        _syncService.start(); // Reanudar sincronización
        break;
        
      default:
        break;
    }
  }
}
```

**Beneficios:**
- ✅ 50 metros distanceFilter reduce actualizaciones GPS en 80%
- ✅ GPS pausado en background ahorra ~30% batería
- ✅ Accuracy medium en stream vs high reduce consumo en 20%
- **Estimado:** Consumo batería GPS -40%

**Criterios de aceptación:**
- [ ] `distanceFilter: 50` configurado en LocationSettings
- [ ] GPS se pausa cuando app va a background
- [ ] GPS se reanuda cuando app vuelve a foreground
- [ ] Stream de posición usa accuracy medium
- [ ] Timeout de 30s en getCurrentLocation

---

### **OPTIMIZACIÓN 3: Sincronización de Datos**

#### Problema Actual
- Timer activo incluso cuando app en background
- Sincronización usa datos móviles (costoso/lento)
- No detecta batería baja

#### Solución

**3.1. Solo WiFi en Background**

Archivo: `lib/services/data_sync_service.dart`

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

class DataSyncService {
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();
  bool _isInForeground = true;
  
  // ... código existente ...
  
  Future<void> _performSync() async {
    try {
      // 1. Verificar estado de la app
      if (!_isInForeground) {
        debugPrint('🔄 App en background - verificar WiFi');
        
        // Solo sincronizar en WiFi cuando está en background
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.wifi) {
          debugPrint('⚠️ No hay WiFi - cancelar sync en background');
          return;
        }
      }
      
      // 2. Verificar batería
      final batteryLevel = await _battery.batteryLevel;
      if (batteryLevel < 20) {
        debugPrint('🔋 Batería baja ($batteryLevel%) - cancelar sync');
        return;
      }
      
      // 3. Verificar conectividad
      if (!await _hasInternetConnection()) {
        debugPrint('📡 Sin conexión - cancelar sync');
        return;
      }
      
      // 4. Realizar sincronización
      PerformanceMonitor.start('Sync');
      
      final freshData = await _repository.fetchRemoteStations();
      
      if (_hasDataChanged(freshData, cachedData)) {
        await _repository.updateCache(freshData);
        _notifyDataUpdated?.call();
        debugPrint('✅ Sync completado: ${freshData.length} estaciones');
      } else {
        debugPrint('ℹ️ Sin cambios en datos');
      }
      
      PerformanceMonitor.stop('Sync');
      
    } catch (e) {
      debugPrint('❌ Error sync: $e');
      _onSyncError?.call(e.toString());
    }
  }
  
  /// Notificar cambio de estado de app
  void setForegroundState(bool isForeground) {
    _isInForeground = isForeground;
    debugPrint('📱 App ${isForeground ? "foreground" : "background"}');
  }
}
```

**3.2. Actualizar MapScreen**

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.paused:
      _syncService.setForegroundState(false);
      break;
      
    case AppLifecycleState.resumed:
      _syncService.setForegroundState(true);
      break;
      
    default:
      break;
  }
}
```

**3.3. Agregar Dependencia**

`pubspec.yaml`:

```yaml
dependencies:
  battery_plus: ^6.0.0  # Detección de nivel de batería
  # connectivity_plus: ^7.0.0  # Ya agregada en Paso 17
```

Ejecutar:
```bash
flutter pub add battery_plus
flutter pub get
```

**Beneficios:**
- ✅ Solo WiFi en background ahorra datos móviles
- ✅ Detección de batería baja previene descargas
- ✅ Sincronización inteligente reduce consumo
- **Estimado:** Consumo datos móviles -70%, batería -25%

**Criterios de aceptación:**
- [ ] Sincronización solo WiFi cuando app en background
- [ ] No sincroniza si batería <20%
- [ ] Timer detenido cuando app en background
- [ ] Dependencia battery_plus agregada
- [ ] Logs indican razón de cancelación de sync

---

### **OPTIMIZACIÓN 4: Parseo y Carga Inicial**

#### Problema Actual
- Parseo de 11,000 gasolineras bloquea UI thread (15-20s)
- Inserción batch podría ser más rápida
- Sin compresión en respuesta HTTP

#### Solución

**4.1. Parseo Paralelo con compute()**

Archivo: `lib/data/datasources/remote/api_datasource.dart`

```dart
import 'package:flutter/foundation.dart';

// Función top-level para compute()
List<GasStation> _parseGasStationsInBackground(Map<String, dynamic> json) {
  final List<dynamic> estaciones = json['ListaEESSPrecio'] ?? [];
  
  return estaciones.map((e) {
    return ApiGasStationDTO.fromJson(e).toDomain();
  }).toList();
}

class ApiDataSource {
  
  Future<List<GasStation>> fetchStations() async {
    try {
      PerformanceMonitor.start('API Download');
      
      // 1. Descargar JSON
      final response = await _client.get(
        Uri.parse(ApiConstants.baseUrl),
        headers: {
          'Accept-Encoding': 'gzip', // Solicitar compresión
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('API timeout'),
      );
      
      PerformanceMonitor.stop('API Download');
      
      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode}');
      }
      
      // 2. Decodificar JSON
      PerformanceMonitor.start('JSON Parse');
      final Map<String, dynamic> jsonData = json.decode(response.body);
      PerformanceMonitor.stop('JSON Parse');
      
      // 3. Parsear en background thread (NO BLOQUEA UI)
      PerformanceMonitor.start('Background Parse');
      final stations = await compute(_parseGasStationsInBackground, jsonData);
      PerformanceMonitor.stop('Background Parse');
      
      debugPrint('✅ ${stations.length} estaciones descargadas');
      return stations;
      
    } catch (e) {
      debugPrint('❌ Error API: $e');
      rethrow;
    }
  }
}
```

**4.2. Inserción Batch Optimizada**

Archivo: `lib/data/datasources/local/database_datasource.dart`

```dart
Future<void> saveStationsBatch(List<GasStation> stations) async {
  final db = await database;
  
  PerformanceMonitor.start('Batch Insert');
  
  // Usar transacción con batch (mucho más rápido)
  await db.transaction((txn) async {
    // Crear batch para estaciones
    var stationBatch = txn.batch();
    
    for (var station in stations) {
      stationBatch.insert(
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
      
      // Commit cada 500 estaciones (evitar OOM)
      if (stationBatch.length >= 500) {
        await stationBatch.commit(noResult: true);
        stationBatch = txn.batch();
      }
    }
    
    // Commit restantes
    if (stationBatch.length > 0) {
      await stationBatch.commit(noResult: true);
    }
    
    // Crear batch para precios (separado para mejor rendimiento)
    var priceBatch = txn.batch();
    
    for (var station in stations) {
      for (var price in station.prices) {
        priceBatch.insert(
          'fuel_prices',
          {
            'station_id': station.id,
            'fuel_type': price.fuelType.toString().split('.').last,
            'price': price.value,
            'updated_at': price.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        
        if (priceBatch.length >= 500) {
          await priceBatch.commit(noResult: true);
          priceBatch = txn.batch();
        }
      }
    }
    
    if (priceBatch.length > 0) {
      await priceBatch.commit(noResult: true);
    }
  });
  
  PerformanceMonitor.stop('Batch Insert');
  debugPrint('✅ Batch insert completado');
}
```

**Beneficios:**
- ✅ `compute()` evita bloqueo de UI (app responde durante carga)
- ✅ gzip reduce tamaño de descarga en ~60% (500KB → 200KB)
- ✅ Batch optimizado reduce inserción de 10s → 3s
- **Estimado:** Primera carga 15-25s → 8-12s (50% mejora)

**Criterios de aceptación:**
- [ ] Parseo se ejecuta en background con compute()
- [ ] UI no se congela durante parseo
- [ ] Header Accept-Encoding: gzip en requests
- [ ] Batch insert con commits cada 500 registros
- [ ] Primera carga <15 segundos

---

### **OPTIMIZACIÓN 5: Renderizado de Marcadores**

#### Problema Actual
- BitmapDescriptor se crea para cada marcador (ineficiente)
- No hay lazy loading de marcadores distantes
- Cambio de combustible reconstruye todos los marcadores

#### Solución

**5.1. Caché de BitmapDescriptor**

Archivo: `lib/presentation/screens/map_screen.dart`

```dart
class _MapScreenState extends State<MapScreen> {
  // Caché de iconos de marcadores
  final Map<PriceRange, BitmapDescriptor> _markerIcons = {};
  bool _iconsInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeMarkerIcons();
  }
  
  Future<void> _initializeMarkerIcons() async {
    // Crear iconos una sola vez
    _markerIcons[PriceRange.low] = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/marker_green.png',
    );
    
    _markerIcons[PriceRange.medium] = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/marker_orange.png',
    );
    
    _markerIcons[PriceRange.high] = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/marker_red.png',
    );
    
    setState(() {
      _iconsInitialized = true;
    });
    
    debugPrint('✅ Iconos de marcadores cacheados');
  }
  
  Set<Marker> _buildMarkers(List<GasStation> stations, FuelType fuelType) {
    if (!_iconsInitialized) return {};
    
    return stations.map((station) {
      // Usar icono cacheado
      final icon = _markerIcons[station.priceRange] ?? 
                    BitmapDescriptor.defaultMarker;
      
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        icon: icon,
        // ... resto del código
      );
    }).toSet();
  }
}
```

**5.2. Debounce en Filtros**

Archivo: `lib/presentation/widgets/fuel_selector.dart`

```dart
import 'dart:async';

class FuelSelector extends StatefulWidget {
  final FuelType selectedFuel;
  final Function(FuelType) onFuelChanged;
  final Duration debounceDuration;
  
  const FuelSelector({
    Key? key,
    required this.selectedFuel,
    required this.onFuelChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  }) : super(key: key);
  
  @override
  State<FuelSelector> createState() => _FuelSelectorState();
}

class _FuelSelectorState extends State<FuelSelector> {
  Timer? _debounceTimer;
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  void _onFuelTapped(FuelType fuelType) {
    // Cancelar timer anterior
    _debounceTimer?.cancel();
    
    // Actualizar UI inmediatamente (feedback visual)
    setState(() {
      // Opcional: variable local para UI
    });
    
    // Ejecutar callback con debounce
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onFuelChanged(fuelType);
    });
  }
  
  // ... resto del widget
}
```

**5.3. Lazy Loading de Marcadores Lejanos**

Archivo: `lib/presentation/blocs/map/map_bloc.dart`

```dart
void _onLoadMapData(LoadMapData event, Emitter<MapState> emit) async {
  emit(MapLoading());
  
  try {
    // ... código existente hasta obtener stations ...
    
    // 5. Lazy loading: Solo marcadores dentro de viewport + buffer
    final visibleStations = _filterVisibleStations(
      stations,
      event.latitude,
      event.longitude,
      event.radiusKm,
    );
    
    // 6. Limitar a 50 más cercanos
    if (visibleStations.length > 50) {
      visibleStations = visibleStations.sublist(0, 50);
    }
    
    emit(MapLoaded(
      stations: visibleStations,
      allStations: stations, // Guardar para futuro lazy load
      selectedFuel: event.fuelType,
    ));
  } catch (e) {
    emit(MapError(e.toString()));
  }
}

List<GasStation> _filterVisibleStations(
  List<GasStation> allStations,
  double centerLat,
  double centerLon,
  double radiusKm,
) {
  // Solo retornar estaciones dentro del radio visible
  return allStations
      .where((s) => s.distance != null && s.distance! <= radiusKm)
      .toList();
}
```

**Beneficios:**
- ✅ Caché de iconos evita crear BitmapDescriptor repetidamente
- ✅ Debounce reduce eventos de cambio de filtro
- ✅ Lazy loading reduce marcadores fuera de vista
- **Estimado:** Renderizado 500ms → 200ms (60% mejora)

**Criterios de aceptación:**
- [ ] BitmapDescriptor cacheados al iniciar
- [ ] Solo se crean iconos una vez
- [ ] Debounce de 300ms en FuelSelector
- [ ] Lazy loading implementado (solo marcadores visibles)
- [ ] Renderizado <200ms

---

## Orden de Implementación Recomendado

### Día 1: Base de Datos
1. ✅ Agregar índices compuestos
2. ✅ Implementar query optimizada con bounding box
3. ✅ Agregar VACUUM periódico
4. ✅ Implementar PerformanceMonitor
5. ✅ Medir tiempos de consulta

### Día 2: GPS y Batería
1. ✅ Configurar distanceFilter en LocationSettings
2. ✅ Implementar pauseLocationUpdates/resume
3. ✅ Agregar WidgetsBindingObserver a MapScreen
4. ✅ Probar pausa/reanudación de GPS

### Día 3: Sincronización
1. ✅ Agregar dependencia battery_plus
2. ✅ Implementar detección de WiFi/batería en sync
3. ✅ Actualizar setForegroundState
4. ✅ Probar sincronización condicional

### Día 4: Parseo y Carga
1. ✅ Implementar parseo con compute()
2. ✅ Agregar header Accept-Encoding: gzip
3. ✅ Optimizar batch insert (commits cada 500)
4. ✅ Medir tiempos de primera carga

### Día 5: Renderizado
1. ✅ Implementar caché de BitmapDescriptor
2. ✅ Agregar debounce a FuelSelector
3. ✅ Implementar lazy loading de marcadores
4. ✅ Medir tiempos de renderizado

### Día 6: Validación y Documentación
1. ✅ Ejecutar tests de rendimiento
2. ✅ Medir métricas antes/después
3. ✅ Documentar en PASO_23_COMPLETADO.md
4. ✅ Actualizar PASOS_DESARROLLO.md

---

## Comandos de Validación

### Agregar Dependencias
```bash
flutter pub add battery_plus
flutter pub get
```

### Ejecutar Análisis Estático
```bash
flutter analyze
```

### Medir Rendimiento en Dispositivo Real
```bash
flutter run --profile
# Abrir DevTools para análisis de performance
flutter pub global activate devtools
flutter pub global run devtools
```

### Generar Reporte de Rendimiento
```bash
flutter run --profile --trace-startup
```

---

## Métricas de Éxito

### Antes de Optimización (Paso 12)

| Métrica | Valor Actual |
|---------|--------------|
| Primera carga | 15-25 seg |
| Query getNearbyStations | ~500ms |
| Renderizado 50 marcadores | ~500ms |
| Cambio de combustible | ~200ms |
| Consumo batería GPS | Alto |
| Sincronización en background | Siempre |

### Después de Optimización (Objetivos)

| Métrica | Valor Objetivo | Mejora |
|---------|----------------|--------|
| Primera carga | <15 seg | -33% |
| Query getNearbyStations | <150ms | -70% |
| Renderizado 50 marcadores | <200ms | -60% |
| Cambio de combustible | <100ms | -50% |
| Consumo batería GPS | Reducido 40% | -40% |
| Sincronización en background | Solo WiFi | -70% datos |

---

## Criterios de Aceptación del Paso 23

### Funcionales
- [ ] **CA-01:** Índices compuestos creados en SQLite
- [ ] **CA-02:** Query optimizada con bounding box implementada
- [ ] **CA-03:** VACUUM ejecutado automáticamente cada semana
- [ ] **CA-04:** GPS con distanceFilter: 50 metros
- [ ] **CA-05:** GPS pausado en background
- [ ] **CA-06:** Sincronización solo WiFi en background
- [ ] **CA-07:** No sincroniza si batería <20%
- [ ] **CA-08:** Parseo en background con compute()
- [ ] **CA-09:** BitmapDescriptor cacheados
- [ ] **CA-10:** Debounce de 300ms en filtros

### No Funcionales
- [ ] **CA-11:** Primera carga <15 segundos
- [ ] **CA-12:** Query getNearbyStations <150ms
- [ ] **CA-13:** Renderizado marcadores <200ms
- [ ] **CA-14:** Cambio de combustible <100ms
- [ ] **CA-15:** Consumo batería GPS reducido en 40%
- [ ] **CA-16:** Sincronización en background -70% datos
- [ ] **CA-17:** Logs de performance en debug mode
- [ ] **CA-18:** flutter analyze sin errores

---

## Herramientas de Medición

### 1. Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Uso:**
- Performance tab: Medir framerate, reconstrucciones de widgets
- Memory tab: Detectar memory leaks
- Network tab: Analizar tamaño de requests

### 2. Android Profiler (Android Studio)
- CPU Profiler: Identificar métodos lentos
- Memory Profiler: Analizar uso de RAM
- Network Profiler: Medir consumo de datos

### 3. PerformanceMonitor (Custom)
```dart
// En cualquier parte del código
PerformanceMonitor.start('OperationName');
// ... operación
PerformanceMonitor.stop('OperationName');
// Output: ⏱️ OperationName: 123ms
```

---

## Notas Importantes

⚠️ **Restricciones:**
- Optimizaciones de parseo requieren función top-level (no método de clase)
- BitmapDescriptor debe crearse en main thread (no en compute)
- VACUUM bloquea BD temporalmente (ejecutar fuera de horas pico)
- battery_plus requiere permisos adicionales en iOS (no afecta Android)

✅ **Buenas prácticas:**
- Medir ANTES y DESPUÉS de cada optimización
- Usar PerformanceMonitor en debug, desactivar en release
- Documentar por qué se hace cada optimización
- Probar en dispositivos de gama baja (más crítico)
- No optimizar prematuramente - medir primero

⚡ **Trade-offs:**
- Bounding box reduce precisión en zonas polares (aceptable en España)
- distanceFilter 50m puede no actualizar en movimientos lentos (aceptable)
- Solo WiFi en background puede retrasar sync (aceptable)
- Caché de iconos usa ~1MB RAM (aceptable)

📝 **Documentación:**
- Actualizar PASOS_DESARROLLO.md al completar
- Crear PASO_23_COMPLETADO.md con métricas antes/después
- Documentar cualquier trade-off tomado
- Incluir screenshots de DevTools (opcional)

---

## Referencias de la Documentación

- **RNF-01:** Requisito No Funcional de Rendimiento (tiempo carga <3s, interacción <500ms)
- **DSI 5:** Diseño de BD SQLite con índices
- **DSI 6:** Proceso de actualización periódica
- **PASO_12_COMPLETADO.md:** Métricas actuales de rendimiento
- **PASO_9_INSTRUCCIONES.md:** Mejores prácticas de LocationService

---

**Fecha de creación:** 2 de diciembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Autor:** Desarrollo según Métrica v3  
**Estado:** ⏳ PENDIENTE DE IMPLEMENTACIÓN  
**Prerequisito:** Pasos 1-22 completados ✅  
**Estimación:** 6 días de desarrollo + validación
