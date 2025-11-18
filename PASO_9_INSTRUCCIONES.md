# PASO 9: Implementación de Servicios del Sistema

## Proyecto: BuscaGas - Localizador de Gasolineras Económicas en España

---

## ÍNDICE

1. [Objetivo del Paso 9](#objetivo-del-paso-9)
2. [Contexto Arquitectónico](#contexto-arquitectónico)
3. [Servicios a Implementar](#servicios-a-implementar)
4. [Estructura de Archivos](#estructura-de-archivos)
5. [Dependencias Necesarias](#dependencias-necesarias)
6. [Implementación LocationService](#implementación-locationservice)
7. [Implementación SyncService](#implementación-syncservice)
8. [Integración con Componentes Existentes](#integración-con-componentes-existentes)
9. [Verificación y Pruebas](#verificación-y-pruebas)
10. [Checklist de Implementación](#checklist-de-implementación)

---

## OBJETIVO DEL PASO 9

### Descripción General
Implementar los servicios del sistema que proporcionan funcionalidades de infraestructura para la aplicación: geolocalización GPS y sincronización periódica de datos.

### Objetivos Específicos

1. **LocationService** - Servicio de Geolocalización:
   - Gestión de permisos de ubicación
   - Obtención de coordenadas GPS actuales
   - Verificación de disponibilidad de servicios de ubicación
   - Manejo de errores de GPS
   - Stream de actualizaciones de ubicación (opcional)

2. **SyncService** - Servicio de Sincronización Periódica:
   - Timer periódico cada 30 minutos en foreground
   - Actualización automática de datos desde API
   - Comparación con caché local
   - Notificación de cambios a la UI
   - Gestión de errores de red

### Requisitos Previos Completados
- ✅ Paso 5: Integración con API gubernamental (ApiDataSource)
- ✅ Paso 6: Repositorios implementados (GasStationRepository)
- ✅ Paso 7: Casos de uso implementados
- ✅ Paso 8: BLoCs para gestión de estado

---

## CONTEXTO ARQUITECTÓNICO

### Ubicación en Clean Architecture

```
┌───────────────────────────────────────────────────────────┐
│                   CAPA DE PRESENTACIÓN                    │
│  ┌─────────────────────────────────────────────────────┐  │
│  │          BLoCs (MapBloc, SettingsBloc)             │  │
│  └──────────────────┬──────────────────────────────────┘  │
└─────────────────────┼──────────────────────────────────────┘
                      │ usa servicios
                      ▼
┌───────────────────────────────────────────────────────────┐
│                   SERVICIOS DEL SISTEMA                   │  ◄── ESTAMOS AQUÍ
│  ┌─────────────────────────────────────────────────────┐  │
│  │  LocationService    │    SyncService                │  │
│  │  - GPS              │    - Timer periódico          │  │
│  │  - Permisos         │    - Actualización automática │  │
│  │  - Verificación     │    - Comparación de datos     │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
                      │ utiliza
                      ▼
┌───────────────────────────────────────────────────────────┐
│                   CAPA DE DOMINIO                         │
│  ┌─────────────────────────────────────────────────────┐  │
│  │             GasStationRepository                    │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### Responsabilidades de los Servicios

**LocationService (SS-01: Gestión de Ubicación):**
- Solicitar y verificar permisos de ubicación
- Obtener coordenadas GPS actuales con precisión configurable
- Comprobar disponibilidad de servicios de ubicación
- Manejar errores de GPS (servicio deshabilitado, timeout, etc.)
- Proporcionar ubicación predeterminada si es necesario

**SyncService (SS-02: Gestión de Datos - Actualización Periódica):**
- Ejecutar sincronización periódica cada 30 minutos
- Verificar conectividad antes de sincronizar
- Descargar datos frescos desde la API
- Comparar con datos en caché
- Actualizar base de datos si hay cambios
- Notificar a la UI sobre actualizaciones
- Registrar timestamp de última sincronización

---

## SERVICIOS A IMPLEMENTAR

### 1. LocationService - Detalles Técnicos

**Funcionalidades:**
- `Future<Position> getCurrentPosition()` - Obtener ubicación actual
- `Future<bool> checkLocationPermission()` - Verificar permisos
- `Future<bool> requestLocationPermission()` - Solicitar permisos
- `Future<bool> isLocationServiceEnabled()` - Verificar si GPS está activo
- `Stream<Position>? getLocationStream()` - (Opcional) Stream de ubicaciones

**Configuración:**
- Precisión: `LocationAccuracy.high` (±10-100m)
- Timeout: 10 segundos
- Manejo de permisos: `denied`, `deniedForever`, `whileInUse`, `always`

**Casos de Error:**
- GPS deshabilitado → Mostrar mensaje para activar
- Permisos denegados → Solicitar nuevamente
- Permisos denegados permanentemente → Abrir configuración del sistema
- Timeout → Usar última ubicación conocida o ubicación predeterminada

### 2. SyncService - Detalles Técnicos

**Funcionalidades:**
- `void startPeriodicSync()` - Iniciar sincronización periódica
- `void stopPeriodicSync()` - Detener sincronización
- `Future<void> performSync()` - Ejecutar sincronización manual
- `bool get isSyncing` - Verificar si está sincronizando
- `DateTime? get lastSyncTime` - Obtener timestamp de última sincronización

**Configuración:**
- Intervalo: 30 minutos (configurable)
- Verificación de conectividad antes de sincronizar
- Comparación de datos: primeras 10 gasolineras
- Actualización silenciosa sin interrumpir al usuario

**Proceso de Sincronización:**
```
1. Verificar conectividad a internet
   └─ Si no hay → Cancelar sincronización
   
2. Descargar datos frescos desde API
   └─ Si falla → Log error, mantener datos actuales
   
3. Obtener datos de caché local
   
4. Comparar datos (cantidad y precios)
   └─ Si no hay cambios → Log "No changes", terminar
   
5. Actualizar base de datos local
   
6. Actualizar timestamp de sincronización
   
7. Notificar a UI (opcional, mediante callback)
```

---

## ESTRUCTURA DE ARCHIVOS

### Directorios a Crear

```
lib/
└── services/
    ├── location_service.dart
    └── sync_service.dart
```

### Descripción de Archivos

| Archivo | Propósito | Dependencias Principales |
|---------|-----------|--------------------------|
| `location_service.dart` | Gestión de GPS y permisos de ubicación | geolocator, permission_handler |
| `sync_service.dart` | Sincronización periódica con API | dart:async (Timer), GasStationRepository |

---

## DEPENDENCIAS NECESARIAS

### Verificar en `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Location (ya instaladas)
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  
  # Networking (ya instalada)
  http: ^1.1.0
  
  # Storage (ya instalada)
  shared_preferences: ^2.2.2
```

**Nota:** Todas las dependencias necesarias ya están instaladas desde pasos anteriores.

---

## IMPLEMENTACIÓN LOCATIONSERVICE

### Archivo: `lib/services/location_service.dart`

```dart
import 'package:geolocator/geolocator.dart';

/// Servicio para gestionar la geolocalización del usuario
/// 
/// Responsabilidades:
/// - Verificar y solicitar permisos de ubicación
/// - Obtener coordenadas GPS actuales
/// - Verificar disponibilidad de servicios de ubicación
/// - Manejar errores de GPS
class LocationService {
  // Configuración de precisión de ubicación
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100, // Actualizar cada 100 metros
  );
  
  /// Obtener la posición actual del usuario
  /// 
  /// Lanza [LocationServiceDisabledException] si GPS está deshabilitado
  /// Lanza [PermissionDeniedException] si no hay permisos
  /// Lanza [TimeoutException] si tarda más de 10 segundos
  Future<Position> getCurrentPosition() async {
    // 1. Verificar si el servicio de ubicación está habilitado
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }
    
    // 2. Verificar permisos
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      // Intentar solicitar permisos
      bool granted = await requestLocationPermission();
      if (!granted) {
        throw PermissionDeniedException('Permisos de ubicación denegados');
      }
    }
    
    // 3. Obtener posición actual
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return position;
    } catch (e) {
      // Si falla, intentar obtener última ubicación conocida
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      
      // Si no hay última ubicación, lanzar excepción
      rethrow;
    }
  }
  
  /// Verificar si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Verificar si la aplicación tiene permisos de ubicación
  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
  
  /// Solicitar permisos de ubicación al usuario
  /// 
  /// Retorna true si se concedieron los permisos
  /// Retorna false si se denegaron
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    // Si ya están concedidos, retornar true
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }
    
    // Si están denegados permanentemente, no se puede solicitar
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    // Solicitar permisos
    permission = await Geolocator.requestPermission();
    
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
  
  /// Abrir la configuración de la aplicación para que el usuario
  /// pueda habilitar los permisos manualmente
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
  
  /// Abrir la configuración de la aplicación
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
  
  /// Obtener un stream de actualizaciones de posición
  /// 
  /// Útil para seguimiento en tiempo real (opcional para MVP)
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    );
  }
  
  /// Calcular la distancia entre dos puntos en metros
  /// 
  /// Útil para verificar si el usuario se ha movido significativamente
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
  
  /// Obtener una posición predeterminada (Madrid centro)
  /// 
  /// Usar solo como fallback cuando no se puede obtener ubicación real
  Position getDefaultPosition() {
    return Position(
      latitude: 40.416775,
      longitude: -3.703790,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}
```

---

## IMPLEMENTACIÓN SYNCSERVICE

### Archivo: `lib/services/sync_service.dart`

```dart
import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../domain/repositories/gas_station_repository.dart';
import '../domain/entities/gas_station.dart';
import '../domain/entities/app_settings.dart';

/// Servicio para sincronización periódica de datos con la API
/// 
/// Responsabilidades:
/// - Ejecutar sincronización periódica cada 30 minutos
/// - Verificar conectividad antes de sincronizar
/// - Actualizar caché local con datos frescos
/// - Notificar cambios a listeners
class SyncService {
  final GasStationRepository _repository;
  final AppSettings _settings;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  // Callbacks para notificar eventos
  Function(bool success)? onSyncComplete;
  Function(String error)? onSyncError;
  Function()? onDataUpdated;
  
  /// Intervalo de sincronización (30 minutos)
  final Duration syncInterval = const Duration(minutes: 30);
  
  SyncService({
    required GasStationRepository repository,
    required AppSettings settings,
  })  : _repository = repository,
        _settings = settings;
  
  /// Indicador de si está sincronizando actualmente
  bool get isSyncing => _isSyncing;
  
  /// Timestamp de la última sincronización exitosa
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Iniciar sincronización periódica
  /// 
  /// Ejecuta una sincronización inmediata y luego programa
  /// sincronizaciones cada 30 minutos
  void startPeriodicSync() {
    // Cancelar timer anterior si existe
    stopPeriodicSync();
    
    // Ejecutar sincronización inicial
    performSync();
    
    // Programar sincronizaciones periódicas
    _syncTimer = Timer.periodic(syncInterval, (_) {
      performSync();
    });
    
    print('[SyncService] Sincronización periódica iniciada (intervalo: ${syncInterval.inMinutes} min)');
  }
  
  /// Detener sincronización periódica
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('[SyncService] Sincronización periódica detenida');
  }
  
  /// Ejecutar sincronización manual
  /// 
  /// Puede ser llamado por el usuario o automáticamente por el timer
  Future<void> performSync() async {
    // Evitar sincronizaciones simultáneas
    if (_isSyncing) {
      print('[SyncService] Sincronización ya en progreso, ignorando');
      return;
    }
    
    _isSyncing = true;
    print('[SyncService] Iniciando sincronización...');
    
    try {
      // 1. Verificar conectividad
      bool hasConnection = await _hasInternetConnection();
      if (!hasConnection) {
        print('[SyncService] Sin conexión a internet, cancelando sincronización');
        onSyncError?.call('Sin conexión a internet');
        _isSyncing = false;
        return;
      }
      
      // 2. Descargar datos frescos desde la API
      print('[SyncService] Descargando datos frescos desde API...');
      List<GasStation> freshData = await _repository.fetchRemoteStations();
      print('[SyncService] Descargados ${freshData.length} registros');
      
      // 3. Obtener datos de caché
      List<GasStation> cachedData = await _repository.getCachedStations();
      print('[SyncService] Caché actual: ${cachedData.length} registros');
      
      // 4. Comparar datos
      bool hasChanges = _hasDataChanged(freshData, cachedData);
      
      if (hasChanges) {
        print('[SyncService] Cambios detectados, actualizando caché...');
        
        // 5. Actualizar base de datos local
        await _repository.updateCache(freshData);
        
        // 6. Actualizar timestamp de sincronización
        _lastSyncTime = DateTime.now();
        _settings.lastUpdateTimestamp = _lastSyncTime;
        await _settings.save();
        
        print('[SyncService] Caché actualizada exitosamente');
        
        // 7. Notificar que hay datos nuevos
        onDataUpdated?.call();
      } else {
        print('[SyncService] No se detectaron cambios en los datos');
        _lastSyncTime = DateTime.now();
      }
      
      // Notificar sincronización exitosa
      onSyncComplete?.call(true);
      print('[SyncService] Sincronización completada exitosamente a las ${DateTime.now()}');
      
    } catch (e) {
      print('[SyncService] Error durante sincronización: $e');
      onSyncError?.call(e.toString());
      onSyncComplete?.call(false);
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Verificar si hay conexión a internet
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // Verificar si hay algún tipo de conexión
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('[SyncService] Error verificando conectividad: $e');
      return false;
    }
  }
  
  /// Comparar datos frescos con caché para detectar cambios
  /// 
  /// Estrategia: Comparar cantidad de registros y precios de las
  /// primeras 10 gasolineras como muestra representativa
  bool _hasDataChanged(List<GasStation> fresh, List<GasStation> cached) {
    // Comparar cantidad de registros
    if (fresh.length != cached.length) {
      print('[SyncService] Cambio detectado: diferente cantidad de registros');
      return true;
    }
    
    if (fresh.isEmpty) {
      return false;
    }
    
    // Comparar precios de muestra (primeras 10 gasolineras)
    int sampleSize = min(10, fresh.length);
    
    for (int i = 0; i < sampleSize; i++) {
      // Comparar cantidad de precios
      if (fresh[i].prices.length != cached[i].prices.length) {
        print('[SyncService] Cambio detectado en precios de estación ${fresh[i].id}');
        return true;
      }
      
      // Comparar valores de precios
      for (int j = 0; j < fresh[i].prices.length; j++) {
        if (fresh[i].prices[j].value != cached[i].prices[j].value) {
          print('[SyncService] Cambio detectado en precio de combustible');
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Limpiar recursos al destruir el servicio
  void dispose() {
    stopPeriodicSync();
  }
}
```

**Nota:** Necesitarás agregar la dependencia `connectivity_plus` al `pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: ^5.0.2
```

---

## INTEGRACIÓN CON COMPONENTES EXISTENTES

### 1. Integración con MapBloc

El `MapBloc` debe usar `LocationService` para obtener la ubicación del usuario:

```dart
// En lib/presentation/blocs/map/map_bloc.dart

import '../../../services/location_service.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final GetNearbyStationsUseCase _getNearbyStations;
  final FilterByFuelTypeUseCase _filterByFuelType;
  final CalculateDistanceUseCase _calculateDistance;
  final AppSettings _settings;
  final LocationService _locationService; // ← NUEVO
  
  MapBloc({
    required GetNearbyStationsUseCase getNearbyStations,
    required FilterByFuelTypeUseCase filterByFuelType,
    required CalculateDistanceUseCase calculateDistance,
    required AppSettings settings,
    required LocationService locationService, // ← NUEVO
  })  : _getNearbyStations = getNearbyStations,
        _filterByFuelType = filterByFuelType,
        _calculateDistance = calculateDistance,
        _settings = settings,
        _locationService = locationService, // ← NUEVO
        super(const MapInitial()) {
    // ... resto del código
  }
  
  // Modificar _onRecenterMap para usar LocationService
  Future<void> _onRecenterMap(
    RecenterMap event,
    Emitter<MapState> emit,
  ) async {
    try {
      // Usar el servicio de ubicación
      Position position = await _locationService.getCurrentPosition();
      
      // Recargar datos con nueva ubicación
      add(LoadMapData(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } on LocationServiceDisabledException {
      emit(const MapError(message: 'Servicio de ubicación deshabilitado'));
    } on PermissionDeniedException {
      emit(const MapLocationPermissionDenied());
    } catch (e) {
      emit(MapError(message: 'Error al obtener ubicación: ${e.toString()}'));
    }
  }
}
```

### 2. Inicialización en main.dart

Crear instancias de los servicios e inyectarlas:

```dart
// En lib/main.dart

import 'services/location_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar configuración
  final appSettings = await AppSettings.load();
  
  // Crear servicios
  final locationService = LocationService();
  
  // Crear repositorio (ya existe)
  final gasStationRepository = GasStationRepositoryImpl(
    apiDataSource,
    databaseDataSource,
  );
  
  // Crear servicio de sincronización
  final syncService = SyncService(
    repository: gasStationRepository,
    settings: appSettings,
  );
  
  // Configurar callbacks del servicio de sincronización
  syncService.onDataUpdated = () {
    print('Datos actualizados, refrescar UI si es necesario');
    // Aquí podrías disparar un evento al BLoC para refrescar
  };
  
  syncService.onSyncError = (error) {
    print('Error de sincronización: $error');
  };
  
  // Iniciar sincronización periódica
  syncService.startPeriodicSync();
  
  // Crear casos de uso
  final getNearbyStationsUseCase = GetNearbyStationsUseCase(gasStationRepository);
  final filterByFuelTypeUseCase = FilterByFuelTypeUseCase();
  final calculateDistanceUseCase = CalculateDistanceUseCase();
  
  // Crear BLoC con servicios inyectados
  final mapBloc = MapBloc(
    getNearbyStations: getNearbyStationsUseCase,
    filterByFuelType: filterByFuelTypeUseCase,
    calculateDistance: calculateDistanceUseCase,
    settings: appSettings,
    locationService: locationService, // ← INYECTAR
  );
  
  runApp(MyApp(
    mapBloc: mapBloc,
    syncService: syncService,
  ));
}
```

### 3. Uso en Pantalla de Inicio

Solicitar permisos de ubicación durante la carga inicial:

```dart
// En lib/presentation/screens/splash_screen.dart

class _SplashScreenState extends State<SplashScreen> {
  final LocationService _locationService = LocationService();
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // 1. Verificar permisos de ubicación
      bool hasPermission = await _locationService.checkLocationPermission();
      
      if (!hasPermission) {
        // Solicitar permisos
        bool granted = await _locationService.requestLocationPermission();
        
        if (!granted) {
          // Mostrar diálogo explicativo
          _showPermissionDialog();
          return;
        }
      }
      
      // 2. Obtener ubicación inicial
      Position position = await _locationService.getCurrentPosition();
      
      // 3. Navegar a pantalla principal
      Navigator.pushReplacementNamed(
        context,
        '/map',
        arguments: position,
      );
      
    } catch (e) {
      // Manejar errores
      _showErrorDialog(e.toString());
    }
  }
}
```

---

## VERIFICACIÓN Y PRUEBAS

### 1. Pruebas Unitarias de LocationService

```dart
// test/services/location_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';

void main() {
  late LocationService locationService;
  
  setUp(() {
    locationService = LocationService();
  });
  
  group('LocationService', () {
    test('getCurrentPosition retorna posición válida', () async {
      // Este test requiere mock de Geolocator
      // En un entorno real, se necesitaría mockito para simular
      
      // Verificar que retorna Position
      expect(locationService.getCurrentPosition(), isA<Future<Position>>());
    });
    
    test('getDefaultPosition retorna Madrid centro', () {
      final defaultPos = locationService.getDefaultPosition();
      
      expect(defaultPos.latitude, closeTo(40.416775, 0.0001));
      expect(defaultPos.longitude, closeTo(-3.703790, 0.0001));
    });
    
    test('calculateDistance calcula correctamente', () {
      // Madrid centro a Barcelona centro ≈ 504 km
      double distance = locationService.calculateDistance(
        40.416775, -3.703790, // Madrid
        41.385064, 2.173404,  // Barcelona
      );
      
      // Verificar que está en el rango esperado (504 km ≈ 504000 metros)
      expect(distance, greaterThan(500000));
      expect(distance, lessThan(510000));
    });
  });
}
```

### 2. Pruebas Unitarias de SyncService

```dart
// test/services/sync_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  late SyncService syncService;
  late MockGasStationRepository mockRepository;
  late MockAppSettings mockSettings;
  
  setUp(() {
    mockRepository = MockGasStationRepository();
    mockSettings = MockAppSettings();
    
    syncService = SyncService(
      repository: mockRepository,
      settings: mockSettings,
    );
  });
  
  tearDown(() {
    syncService.dispose();
  });
  
  group('SyncService', () {
    test('startPeriodicSync inicia el timer', () {
      syncService.startPeriodicSync();
      
      // Verificar que se ha iniciado
      expect(syncService.isSyncing, isFalse);
    });
    
    test('stopPeriodicSync detiene el timer', () {
      syncService.startPeriodicSync();
      syncService.stopPeriodicSync();
      
      // Verificar que se ha detenido
      expect(syncService.isSyncing, isFalse);
    });
    
    test('performSync actualiza caché cuando hay cambios', () async {
      // Simular datos frescos
      final freshData = [
        GasStation(
          id: '1',
          name: 'Test',
          latitude: 40.4,
          longitude: -3.7,
          prices: [],
        ),
      ];
      
      when(mockRepository.fetchRemoteStations())
          .thenAnswer((_) async => freshData);
      
      when(mockRepository.getCachedStations())
          .thenAnswer((_) async => []);
      
      // Ejecutar sincronización
      await syncService.performSync();
      
      // Verificar que se llamó updateCache
      verify(mockRepository.updateCache(freshData)).called(1);
    });
  });
}
```

### 3. Pruebas de Integración

```dart
// test/integration/services_integration_test.dart

void main() {
  test('LocationService y SyncService trabajan juntos', () async {
    final locationService = LocationService();
    final syncService = SyncService(
      repository: realRepository,
      settings: realSettings,
    );
    
    // 1. Obtener ubicación
    Position position = await locationService.getCurrentPosition();
    expect(position.latitude, isNotNull);
    
    // 2. Sincronizar datos
    await syncService.performSync();
    expect(syncService.lastSyncTime, isNotNull);
    
    // 3. Limpiar
    syncService.dispose();
  });
}
```

### 4. Comandos de Verificación

```bash
# Agregar dependencia de conectividad
flutter pub add connectivity_plus

# Verificar compilación sin errores
flutter analyze

# Ejecutar pruebas unitarias
flutter test

# Ejecutar en dispositivo real (necesario para GPS)
flutter run
```

### 5. Checklist de Verificación Manual

**LocationService:**
- [ ] Solicita permisos de ubicación correctamente
- [ ] Obtiene ubicación GPS con precisión adecuada
- [ ] Maneja el caso de GPS deshabilitado
- [ ] Maneja el caso de permisos denegados
- [ ] Retorna ubicación predeterminada como fallback
- [ ] Calcula distancias correctamente

**SyncService:**
- [ ] Inicia sincronización periódica cada 30 minutos
- [ ] Verifica conectividad antes de sincronizar
- [ ] Descarga datos desde la API correctamente
- [ ] Compara datos frescos con caché
- [ ] Actualiza base de datos cuando hay cambios
- [ ] No actualiza cuando no hay cambios
- [ ] Registra timestamp de última sincronización
- [ ] Ejecuta callbacks de notificación

---

## CHECKLIST DE IMPLEMENTACIÓN

### Tareas Principales

- [ ] **1. Agregar dependencia connectivity_plus**
  ```bash
  flutter pub add connectivity_plus
  ```

- [ ] **2. Implementar LocationService**
  - [ ] Crear archivo `lib/services/location_service.dart`
  - [ ] Implementar `getCurrentPosition()`
  - [ ] Implementar `checkLocationPermission()`
  - [ ] Implementar `requestLocationPermission()`
  - [ ] Implementar `isLocationServiceEnabled()`
  - [ ] Implementar `getDefaultPosition()`
  - [ ] Implementar `calculateDistance()`
  - [ ] Documentar todos los métodos con comentarios Dart

- [ ] **3. Implementar SyncService**
  - [ ] Crear archivo `lib/services/sync_service.dart`
  - [ ] Implementar `startPeriodicSync()`
  - [ ] Implementar `stopPeriodicSync()`
  - [ ] Implementar `performSync()`
  - [ ] Implementar `_hasInternetConnection()`
  - [ ] Implementar `_hasDataChanged()`
  - [ ] Implementar callbacks (onSyncComplete, onSyncError, onDataUpdated)
  - [ ] Documentar todos los métodos

- [ ] **4. Integrar con MapBloc**
  - [ ] Inyectar LocationService en MapBloc
  - [ ] Modificar `_onRecenterMap` para usar LocationService
  - [ ] Manejar excepciones de LocationService

- [ ] **5. Integrar con main.dart**
  - [ ] Crear instancias de servicios
  - [ ] Configurar callbacks de SyncService
  - [ ] Iniciar sincronización periódica
  - [ ] Inyectar servicios en BLoCs

- [ ] **6. Actualizar Splash Screen**
  - [ ] Solicitar permisos de ubicación en carga inicial
  - [ ] Manejar caso de permisos denegados
  - [ ] Obtener ubicación inicial

- [ ] **7. Escribir pruebas**
  - [ ] Tests unitarios de LocationService (mínimo 3)
  - [ ] Tests unitarios de SyncService (mínimo 3)
  - [ ] Test de integración (opcional)

- [ ] **8. Verificar compilación**
  - [ ] Ejecutar `flutter analyze` sin errores
  - [ ] Ejecutar `flutter test` exitosamente
  - [ ] Probar en dispositivo real (GPS)

### Criterios de Aceptación

✅ **Paso 9 completado cuando:**
1. LocationService implementado con gestión completa de permisos
2. SyncService implementado con sincronización periódica funcional
3. Servicios integrados con MapBloc y main.dart
4. Permisos de ubicación se solicitan en primera ejecución
5. Sincronización se ejecuta cada 30 minutos automáticamente
6. Manejo adecuado de errores de GPS y red
7. Pruebas unitarias pasan exitosamente
8. `flutter analyze` no muestra errores
9. Código documentado con comentarios Dart
10. Probado en dispositivo real con GPS

---

## NOTAS IMPORTANTES

### Mejores Prácticas

**LocationService:**
1. **Siempre verificar permisos antes de obtener ubicación**
2. **Proporcionar mensajes claros al usuario** cuando faltan permisos
3. **Usar timeout** para evitar bloqueos indefinidos
4. **Tener fallback** con ubicación predeterminada
5. **Considerar batería** - no solicitar actualizaciones muy frecuentes

**SyncService:**
1. **Verificar conectividad antes de sincronizar** para ahorrar batería
2. **No interrumpir al usuario** - sincronización silenciosa
3. **Comparar datos antes de actualizar** para evitar escrituras innecesarias
4. **Registrar timestamp** de última sincronización
5. **Manejar errores gracefully** - no crashear la app

### Errores Comunes a Evitar

❌ **No hacer:**
- Solicitar permisos sin explicación al usuario
- Bloquear la UI esperando GPS indefinidamente
- Sincronizar sin verificar conectividad
- Actualizar DB en cada sincronización sin verificar cambios
- Olvidar detener timers al cerrar la app

✅ **Hacer:**
- Explicar por qué se necesitan permisos
- Usar timeouts y fallbacks
- Verificar conectividad antes de operaciones de red
- Comparar datos antes de actualizar
- Limpiar recursos en dispose()

### Consideraciones de Batería

**Optimizaciones:**
- Usar `distanceFilter` para reducir actualizaciones GPS
- Sincronizar solo cuando hay conectividad WiFi (opcional)
- Aumentar intervalo de sincronización si batería baja
- Detener sincronización cuando app está en background

### Permisos en Android

Agregar al `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Recursos Adicionales

- [Documentación Geolocator](https://pub.dev/packages/geolocator)
- [Documentación Connectivity Plus](https://pub.dev/packages/connectivity_plus)
- [Flutter Location Best Practices](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options#location)

---

**Fecha de creación:** 18 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3  
**Paso:** 9 de 28
