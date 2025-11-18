# PASO 8: Implementación de Gestión de Estado con BLoC

## Proyecto: BuscaGas - Localizador de Gasolineras Económicas en España

---

## ÍNDICE

1. [Objetivo del Paso 8](#objetivo-del-paso-8)
2. [Contexto Arquitectónico](#contexto-arquitectónico)
3. [Patrón BLoC](#patrón-bloc)
4. [Estructura de Archivos](#estructura-de-archivos)
5. [Dependencias Necesarias](#dependencias-necesarias)
6. [Implementación MapBloc](#implementación-mapbloc)
7. [Implementación SettingsBloc](#implementación-settingsbloc)
8. [Integración con Casos de Uso](#integración-con-casos-de-uso)
9. [Ejemplos de Uso](#ejemplos-de-uso)
10. [Verificación y Pruebas](#verificación-y-pruebas)
11. [Checklist de Implementación](#checklist-de-implementación)

---

## OBJETIVO DEL PASO 8

### Descripción General
Implementar la capa de gestión de estado utilizando el patrón BLoC (Business Logic Component) para las pantallas principales de la aplicación: mapa y configuración.

### Objetivos Específicos
1. Crear **MapBloc** para gestionar el estado de la pantalla principal:
   - Carga de datos de gasolineras
   - Filtrado por tipo de combustible
   - Recentrado del mapa
   - Selección de marcadores
   - Clasificación por rangos de precio

2. Crear **SettingsBloc** para gestionar la configuración:
   - Cambio de radio de búsqueda
   - Selección de combustible preferido
   - Alternancia de tema claro/oscuro
   - Persistencia de preferencias

3. Definir todos los **eventos** y **estados** necesarios para cada BLoC

4. Integrar los BLoCs con los casos de uso implementados en el Paso 7

### Requisitos Previos Completados
- ✅ Paso 5: Integración con API gubernamental
- ✅ Paso 6: Repositorios implementados
- ✅ Paso 7: Casos de uso implementados

---

## CONTEXTO ARQUITECTÓNICO

### Ubicación en Clean Architecture

```
┌───────────────────────────────────────────────────────────┐
│                   CAPA DE PRESENTACIÓN                    │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                    SCREENS                          │  │
│  │  (map_screen.dart, settings_screen.dart)            │  │
│  └──────────────────┬──────────────────────────────────┘  │
│                     │ consume                             │
│                     ▼                                      │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              BLoC (ESTE PASO)                       │  │◄── ESTAMOS AQUÍ
│  │  ┌──────────────┐        ┌──────────────┐          │  │
│  │  │   MapBloc    │        │ SettingsBloc │          │  │
│  │  │- events      │        │- events      │          │  │
│  │  │- states      │        │- states      │          │  │
│  │  └──────────────┘        └──────────────┘          │  │
│  └──────────────────┬──────────────────────────────────┘  │
└─────────────────────┼──────────────────────────────────────┘
                      │ llama
                      ▼
┌───────────────────────────────────────────────────────────┐
│                   CAPA DE DOMINIO                         │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                   USE CASES                         │  │
│  │  - GetNearbyStationsUseCase                         │  │
│  │  - FilterByFuelTypeUseCase                          │  │
│  │  - CalculateDistanceUseCase                         │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### Responsabilidades del BLoC

**MapBloc:**
- Gestionar el estado del mapa (cargando, cargado, error)
- Coordinar la obtención de gasolineras cercanas
- Aplicar filtros por combustible
- Calcular distancias y clasificar por precio
- Recentrar el mapa en la ubicación actual
- Gestionar selección de marcadores

**SettingsBloc:**
- Gestionar el estado de configuración
- Modificar radio de búsqueda
- Cambiar combustible preferido
- Alternar modo claro/oscuro
- Persistir cambios en SharedPreferences

---

## PATRÓN BLoC

### Conceptos Fundamentales

El patrón BLoC separa la lógica de negocio de la UI mediante flujos de datos:

```
┌─────────────┐        eventos        ┌──────────┐
│     UI      │──────────────────────►│   BLoC   │
│  (Widget)   │                        │          │
│             │◄───────────────────────│(Lógica)  │
└─────────────┘       estados          └──────────┘
```

### Componentes Clave

1. **Events (Eventos):**
   - Acciones del usuario o del sistema
   - Inmutables (usar `Equatable`)
   - Describen "qué pasó"

2. **States (Estados):**
   - Representan el estado de la UI en un momento dado
   - Inmutables (usar `Equatable`)
   - Describen "cómo está la UI"

3. **BLoC:**
   - Recibe eventos
   - Ejecuta lógica de negocio (llamando casos de uso)
   - Emite nuevos estados

### Ventajas del Patrón BLoC

- ✅ Separación clara de responsabilidades
- ✅ Testeable (pruebas unitarias simples)
- ✅ Reutilizable
- ✅ Estado predecible
- ✅ Ideal para Flutter/Dart (uso de Streams)

---

## ESTRUCTURA DE ARCHIVOS

### Directorios a Crear

```
lib/
└── presentation/
    └── blocs/
        ├── map/
        │   ├── map_bloc.dart
        │   ├── map_event.dart
        │   └── map_state.dart
        └── settings/
            ├── settings_bloc.dart
            ├── settings_event.dart
            └── settings_state.dart
```

### Descripción de Archivos

| Archivo | Propósito |
|---------|-----------|
| `map_event.dart` | Define todos los eventos que puede recibir MapBloc |
| `map_state.dart` | Define todos los estados posibles del mapa |
| `map_bloc.dart` | Implementa la lógica de gestión de estado del mapa |
| `settings_event.dart` | Define eventos de configuración |
| `settings_state.dart` | Define estados de configuración |
| `settings_bloc.dart` | Implementa lógica de configuración |

---

## DEPENDENCIAS NECESARIAS

### Verificar en `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # Utilities
  equatable: ^2.0.5
  
  # Location (ya instalado)
  geolocator: ^10.1.0
  
  # Storage (ya instalado)
  shared_preferences: ^2.2.2
```

### Instalar si es necesario

```bash
flutter pub add flutter_bloc
flutter pub add equatable
```

---

## IMPLEMENTACIÓN MAPBLOC

### 1. Map Events (`lib/presentation/blocs/map/map_event.dart`)

```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/entities/fuel_price.dart';

/// Clase base para todos los eventos del mapa
abstract class MapEvent extends Equatable {
  const MapEvent();
  
  @override
  List<Object?> get props => [];
}

/// Evento: Cargar datos del mapa con ubicación específica
class LoadMapData extends MapEvent {
  final double latitude;
  final double longitude;
  
  const LoadMapData({
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [latitude, longitude];
}

/// Evento: Cambiar tipo de combustible seleccionado
class ChangeFuelType extends MapEvent {
  final FuelType fuelType;
  
  const ChangeFuelType({required this.fuelType});
  
  @override
  List<Object?> get props => [fuelType];
}

/// Evento: Recentrar mapa en ubicación actual
class RecenterMap extends MapEvent {
  const RecenterMap();
}

/// Evento: Actualizar datos desde la API
class RefreshMapData extends MapEvent {
  const RefreshMapData();
}

/// Evento: Seleccionar una gasolinera en el mapa
class SelectStation extends MapEvent {
  final GasStation? station; // null para deseleccionar
  
  const SelectStation({this.station});
  
  @override
  List<Object?> get props => [station];
}

/// Evento: Cambiar radio de búsqueda (cuando se modifica desde configuración)
class ChangeSearchRadius extends MapEvent {
  final int radiusKm;
  
  const ChangeSearchRadius({required this.radiusKm});
  
  @override
  List<Object?> get props => [radiusKm];
}
```

### 2. Map States (`lib/presentation/blocs/map/map_state.dart`)

```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/entities/fuel_price.dart';

/// Clase base para todos los estados del mapa
abstract class MapState extends Equatable {
  const MapState();
  
  @override
  List<Object?> get props => [];
}

/// Estado: Carga inicial del mapa
class MapInitial extends MapState {
  const MapInitial();
}

/// Estado: Cargando datos (mostrar spinner)
class MapLoading extends MapState {
  const MapLoading();
}

/// Estado: Datos cargados exitosamente
class MapLoaded extends MapState {
  final List<GasStation> stations;
  final FuelType currentFuelType;
  final double currentLatitude;
  final double currentLongitude;
  final int searchRadiusKm;
  final GasStation? selectedStation;
  
  const MapLoaded({
    required this.stations,
    required this.currentFuelType,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.searchRadiusKm,
    this.selectedStation,
  });
  
  @override
  List<Object?> get props => [
    stations,
    currentFuelType,
    currentLatitude,
    currentLongitude,
    searchRadiusKm,
    selectedStation,
  ];
  
  /// Método helper para crear una copia con cambios
  MapLoaded copyWith({
    List<GasStation>? stations,
    FuelType? currentFuelType,
    double? currentLatitude,
    double? currentLongitude,
    int? searchRadiusKm,
    GasStation? selectedStation,
    bool clearSelection = false,
  }) {
    return MapLoaded(
      stations: stations ?? this.stations,
      currentFuelType: currentFuelType ?? this.currentFuelType,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      selectedStation: clearSelection ? null : (selectedStation ?? this.selectedStation),
    );
  }
}

/// Estado: Error al cargar datos
class MapError extends MapState {
  final String message;
  
  const MapError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

/// Estado: Sin permisos de ubicación
class MapLocationPermissionDenied extends MapState {
  const MapLocationPermissionDenied();
}
```

### 3. Map BLoC (`lib/presentation/blocs/map/map_bloc.dart`)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/usecases/get_nearby_stations.dart';
import '../../../domain/usecases/filter_by_fuel_type.dart';
import '../../../domain/usecases/calculate_distance.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/entities/fuel_price.dart';
import 'map_event.dart';
import 'map_state.dart';

/// BLoC para gestionar el estado del mapa principal
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetNearbyStationsUseCase _getNearbyStations;
  final FilterByFuelTypeUseCase _filterByFuelType;
  final CalculateDistanceUseCase _calculateDistance;
  final AppSettings _settings;
  
  MapBloc({
    required GetNearbyStationsUseCase getNearbyStations,
    required FilterByFuelTypeUseCase filterByFuelType,
    required CalculateDistanceUseCase calculateDistance,
    required AppSettings settings,
  })  : _getNearbyStations = getNearbyStations,
        _filterByFuelType = filterByFuelType,
        _calculateDistance = calculateDistance,
        _settings = settings,
        super(const MapInitial()) {
    // Registrar handlers para cada evento
    on<LoadMapData>(_onLoadMapData);
    on<ChangeFuelType>(_onChangeFuelType);
    on<RecenterMap>(_onRecenterMap);
    on<RefreshMapData>(_onRefreshMapData);
    on<SelectStation>(_onSelectStation);
    on<ChangeSearchRadius>(_onChangeSearchRadius);
  }
  
  /// Handler: Cargar datos del mapa
  Future<void> _onLoadMapData(
    LoadMapData event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());
    
    try {
      // 1. Obtener gasolineras cercanas
      List<GasStation> stations = await _getNearbyStations.call(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: _settings.searchRadius.toDouble(),
      );
      
      // 2. Filtrar por combustible preferido
      stations = _filterByFuelType.call(
        stations: stations,
        fuelType: _settings.preferredFuel,
      );
      
      // 3. Calcular distancias
      for (var station in stations) {
        station.distance = _calculateDistance.call(
          event.latitude,
          event.longitude,
          station.latitude,
          station.longitude,
        );
      }
      
      // 4. Ordenar por distancia
      stations.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
      
      // 5. Clasificar por rangos de precio
      _assignPriceRanges(stations, _settings.preferredFuel);
      
      // 6. Emitir estado cargado
      emit(MapLoaded(
        stations: stations,
        currentFuelType: _settings.preferredFuel,
        currentLatitude: event.latitude,
        currentLongitude: event.longitude,
        searchRadiusKm: _settings.searchRadius,
      ));
    } catch (e) {
      emit(MapError(message: 'Error al cargar datos: ${e.toString()}'));
    }
  }
  
  /// Handler: Cambiar tipo de combustible
  Future<void> _onChangeFuelType(
    ChangeFuelType event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) return;
    
    final currentState = state as MapLoaded;
    
    try {
      // 1. Volver a filtrar con nuevo tipo de combustible
      List<GasStation> filteredStations = _filterByFuelType.call(
        stations: currentState.stations,
        fuelType: event.fuelType,
      );
      
      // 2. Reclasificar por rangos de precio
      _assignPriceRanges(filteredStations, event.fuelType);
      
      // 3. Emitir nuevo estado
      emit(currentState.copyWith(
        stations: filteredStations,
        currentFuelType: event.fuelType,
        clearSelection: true,
      ));
    } catch (e) {
      emit(MapError(message: 'Error al cambiar combustible: ${e.toString()}'));
    }
  }
  
  /// Handler: Recentrar mapa
  Future<void> _onRecenterMap(
    RecenterMap event,
    Emitter<MapState> emit,
  ) async {
    try {
      // 1. Verificar permisos
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        emit(const MapLocationPermissionDenied());
        return;
      }
      
      // 2. Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // 3. Recargar datos con nueva ubicación
      add(LoadMapData(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      emit(MapError(message: 'Error al obtener ubicación: ${e.toString()}'));
    }
  }
  
  /// Handler: Actualizar datos
  Future<void> _onRefreshMapData(
    RefreshMapData event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) return;
    
    final currentState = state as MapLoaded;
    
    // Recargar con ubicación actual
    add(LoadMapData(
      latitude: currentState.currentLatitude,
      longitude: currentState.currentLongitude,
    ));
  }
  
  /// Handler: Seleccionar gasolinera
  void _onSelectStation(
    SelectStation event,
    Emitter<MapState> emit,
  ) {
    if (state is! MapLoaded) return;
    
    final currentState = state as MapLoaded;
    
    emit(currentState.copyWith(
      selectedStation: event.station,
    ));
  }
  
  /// Handler: Cambiar radio de búsqueda
  Future<void> _onChangeSearchRadius(
    ChangeSearchRadius event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) return;
    
    final currentState = state as MapLoaded;
    
    // Actualizar configuración
    _settings.searchRadius = event.radiusKm;
    await _settings.save();
    
    // Recargar datos con nuevo radio
    add(LoadMapData(
      latitude: currentState.currentLatitude,
      longitude: currentState.currentLongitude,
    ));
  }
  
  /// Método auxiliar: Verificar permisos de ubicación
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
  
  /// Método auxiliar: Clasificar gasolineras por rango de precio
  void _assignPriceRanges(List<GasStation> stations, FuelType fuelType) {
    // 1. Extraer precios válidos
    List<double> prices = stations
        .map((s) => s.getPriceForFuel(fuelType))
        .whereType<double>()
        .toList();
    
    if (prices.isEmpty) return;
    
    // 2. Calcular percentiles (33% y 66%)
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

---

## IMPLEMENTACIÓN SETTINGSBLOC

### 1. Settings Events (`lib/presentation/blocs/settings/settings_event.dart`)

```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/fuel_price.dart';

/// Clase base para eventos de configuración
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  
  @override
  List<Object?> get props => [];
}

/// Evento: Cargar configuración guardada
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Evento: Cambiar radio de búsqueda
class ChangeSearchRadius extends SettingsEvent {
  final int radiusKm; // 5, 10, 20, 50
  
  const ChangeSearchRadius({required this.radiusKm});
  
  @override
  List<Object?> get props => [radiusKm];
}

/// Evento: Cambiar combustible preferido
class ChangePreferredFuel extends SettingsEvent {
  final FuelType fuelType;
  
  const ChangePreferredFuel({required this.fuelType});
  
  @override
  List<Object?> get props => [fuelType];
}

/// Evento: Alternar modo oscuro
class ToggleDarkMode extends SettingsEvent {
  final bool isDarkMode;
  
  const ToggleDarkMode({required this.isDarkMode});
  
  @override
  List<Object?> get props => [isDarkMode];
}

/// Evento: Restaurar valores por defecto
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
```

### 2. Settings States (`lib/presentation/blocs/settings/settings_state.dart`)

```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/fuel_price.dart';

/// Clase base para estados de configuración
abstract class SettingsState extends Equatable {
  const SettingsState();
  
  @override
  List<Object?> get props => [];
}

/// Estado: Configuración inicial (cargando)
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Estado: Configuración cargada
class SettingsLoaded extends SettingsState {
  final int searchRadiusKm;
  final FuelType preferredFuel;
  final bool isDarkMode;
  final DateTime? lastSyncTimestamp;
  
  const SettingsLoaded({
    required this.searchRadiusKm,
    required this.preferredFuel,
    required this.isDarkMode,
    this.lastSyncTimestamp,
  });
  
  @override
  List<Object?> get props => [
    searchRadiusKm,
    preferredFuel,
    isDarkMode,
    lastSyncTimestamp,
  ];
  
  /// Método helper para crear copia con cambios
  SettingsLoaded copyWith({
    int? searchRadiusKm,
    FuelType? preferredFuel,
    bool? isDarkMode,
    DateTime? lastSyncTimestamp,
  }) {
    return SettingsLoaded(
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      preferredFuel: preferredFuel ?? this.preferredFuel,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
    );
  }
}

/// Estado: Error al cargar/guardar configuración
class SettingsError extends SettingsState {
  final String message;
  
  const SettingsError({required this.message});
  
  @override
  List<Object?> get props => [message];
}
```

### 3. Settings BLoC (`lib/presentation/blocs/settings/settings_bloc.dart`)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/fuel_price.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC para gestionar el estado de configuración
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AppSettings _settings;
  
  SettingsBloc({required AppSettings settings})
      : _settings = settings,
        super(const SettingsInitial()) {
    // Registrar handlers
    on<LoadSettings>(_onLoadSettings);
    on<ChangeSearchRadius>(_onChangeSearchRadius);
    on<ChangePreferredFuel>(_onChangePreferredFuel);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ResetSettings>(_onResetSettings);
  }
  
  /// Handler: Cargar configuración
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Cargar desde SharedPreferences
      await _settings.load();
      
      emit(SettingsLoaded(
        searchRadiusKm: _settings.searchRadius,
        preferredFuel: _settings.preferredFuel,
        isDarkMode: _settings.darkMode,
        lastSyncTimestamp: _settings.lastUpdateTimestamp,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Error al cargar configuración: ${e.toString()}'));
    }
  }
  
  /// Handler: Cambiar radio de búsqueda
  Future<void> _onChangeSearchRadius(
    ChangeSearchRadius event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      // Actualizar configuración
      _settings.searchRadius = event.radiusKm;
      await _settings.save();
      
      // Emitir nuevo estado
      emit(currentState.copyWith(searchRadiusKm: event.radiusKm));
    } catch (e) {
      emit(SettingsError(message: 'Error al cambiar radio: ${e.toString()}'));
    }
  }
  
  /// Handler: Cambiar combustible preferido
  Future<void> _onChangePreferredFuel(
    ChangePreferredFuel event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      // Actualizar configuración
      _settings.preferredFuel = event.fuelType;
      await _settings.save();
      
      // Emitir nuevo estado
      emit(currentState.copyWith(preferredFuel: event.fuelType));
    } catch (e) {
      emit(SettingsError(message: 'Error al cambiar combustible: ${e.toString()}'));
    }
  }
  
  /// Handler: Alternar modo oscuro
  Future<void> _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      // Actualizar configuración
      _settings.darkMode = event.isDarkMode;
      await _settings.save();
      
      // Emitir nuevo estado
      emit(currentState.copyWith(isDarkMode: event.isDarkMode));
    } catch (e) {
      emit(SettingsError(message: 'Error al cambiar tema: ${e.toString()}'));
    }
  }
  
  /// Handler: Restaurar valores por defecto
  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Valores por defecto
      _settings.searchRadius = 10;
      _settings.preferredFuel = FuelType.gasolina95;
      _settings.darkMode = false;
      await _settings.save();
      
      emit(SettingsLoaded(
        searchRadiusKm: 10,
        preferredFuel: FuelType.gasolina95,
        isDarkMode: false,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Error al restaurar configuración: ${e.toString()}'));
    }
  }
}
```

---

## INTEGRACIÓN CON CASOS DE USO

### Diagrama de Flujo

```
┌─────────────────┐
│  Usuario toca   │
│  en el mapa     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Widget dispara evento:             │
│  add(LoadMapData(lat, lon))         │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  MapBloc recibe LoadMapData         │
│  Handler: _onLoadMapData()          │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  1. Emite: MapLoading               │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  2. Llama: GetNearbyStationsUseCase │
│     → Repository → API/DB            │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  3. Llama: FilterByFuelTypeUseCase  │
│     (filtra por combustible)         │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  4. Llama: CalculateDistanceUseCase │
│     (para cada gasolinera)           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  5. Ordena por distancia            │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  6. Clasifica por precio            │
│     (_assignPriceRanges)             │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  7. Emite: MapLoaded                │
│     (con lista de gasolineras)       │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Widget reconstruye con BlocBuilder │
│  Muestra marcadores en el mapa      │
└─────────────────────────────────────┘
```

### Inyección de Dependencias

Los BLoCs necesitan recibir las instancias de casos de uso. Ejemplo de cómo instanciarlos:

```dart
// En main.dart o donde se configure la app
final getNearbyStationsUseCase = GetNearbyStationsUseCase(gasStationRepository);
final filterByFuelTypeUseCase = FilterByFuelTypeUseCase();
final calculateDistanceUseCase = CalculateDistanceUseCase();
final appSettings = await AppSettings.load();

final mapBloc = MapBloc(
  getNearbyStations: getNearbyStationsUseCase,
  filterByFuelType: filterByFuelTypeUseCase,
  calculateDistance: calculateDistanceUseCase,
  settings: appSettings,
);

final settingsBloc = SettingsBloc(
  settings: appSettings,
);
```

---

## EJEMPLOS DE USO

### Ejemplo 1: Uso de MapBloc en Widget

```dart
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapBloc(
        getNearbyStations: context.read<GetNearbyStationsUseCase>(),
        filterByFuelType: context.read<FilterByFuelTypeUseCase>(),
        calculateDistance: context.read<CalculateDistanceUseCase>(),
        settings: context.read<AppSettings>(),
      )..add(LoadMapData(latitude: 40.4, longitude: -3.7)),
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (state is MapError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          
          if (state is MapLoaded) {
            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(state.currentLatitude, state.currentLongitude),
                zoom: 13,
              ),
              markers: _buildMarkers(state.stations, state.currentFuelType),
            );
          }
          
          return SizedBox();
        },
      ),
    );
  }
}
```

### Ejemplo 2: Cambiar Combustible

```dart
// En un widget selector de combustible
SegmentedButton<FuelType>(
  segments: [
    ButtonSegment(
      value: FuelType.gasolina95,
      label: Text('Gasolina 95'),
    ),
    ButtonSegment(
      value: FuelType.dieselGasoleoA,
      label: Text('Diésel'),
    ),
  ],
  selected: {selectedFuel},
  onSelectionChanged: (Set<FuelType> selection) {
    context.read<MapBloc>().add(
      ChangeFuelType(fuelType: selection.first),
    );
  },
)
```

### Ejemplo 3: Recentrar Mapa

```dart
FloatingActionButton(
  onPressed: () {
    context.read<MapBloc>().add(const RecenterMap());
  },
  child: Icon(Icons.my_location),
)
```

### Ejemplo 4: Uso de SettingsBloc

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is SettingsLoaded) {
          return ListView(
            children: [
              // Radio de búsqueda
              ListTile(
                title: Text('Radio de búsqueda'),
                subtitle: Text('${state.searchRadiusKm} km'),
              ),
              RadioListTile(
                title: Text('5 km'),
                value: 5,
                groupValue: state.searchRadiusKm,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    ChangeSearchRadius(radiusKm: value!),
                  );
                },
              ),
              // Modo oscuro
              SwitchListTile(
                title: Text('Modo oscuro'),
                value: state.isDarkMode,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    ToggleDarkMode(isDarkMode: value),
                  );
                },
              ),
            ],
          );
        }
        return SizedBox();
      },
    );
  }
}
```

---

## VERIFICACIÓN Y PRUEBAS

### 1. Pruebas Unitarias de BLoC

#### Test de MapBloc

```dart
// test/presentation/blocs/map/map_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  late MapBloc mapBloc;
  late MockGetNearbyStationsUseCase mockGetNearbyStations;
  late MockFilterByFuelTypeUseCase mockFilterByFuelType;
  late MockCalculateDistanceUseCase mockCalculateDistance;
  late MockAppSettings mockSettings;
  
  setUp(() {
    mockGetNearbyStations = MockGetNearbyStationsUseCase();
    mockFilterByFuelType = MockFilterByFuelTypeUseCase();
    mockCalculateDistance = MockCalculateDistanceUseCase();
    mockSettings = MockAppSettings();
    
    when(mockSettings.searchRadius).thenReturn(10);
    when(mockSettings.preferredFuel).thenReturn(FuelType.gasolina95);
    
    mapBloc = MapBloc(
      getNearbyStations: mockGetNearbyStations,
      filterByFuelType: mockFilterByFuelType,
      calculateDistance: mockCalculateDistance,
      settings: mockSettings,
    );
  });
  
  tearDown(() {
    mapBloc.close();
  });
  
  group('MapBloc', () {
    test('estado inicial es MapInitial', () {
      expect(mapBloc.state, equals(const MapInitial()));
    });
    
    blocTest<MapBloc, MapState>(
      'emite [MapLoading, MapLoaded] cuando LoadMapData es exitoso',
      build: () {
        when(mockGetNearbyStations.call(
          latitude: any,
          longitude: any,
          radiusKm: any,
        )).thenAnswer((_) async => [
          GasStation(
            id: '1',
            name: 'Test',
            latitude: 40.4,
            longitude: -3.7,
            prices: [
              FuelPrice(
                fuelType: FuelType.gasolina95,
                value: 1.45,
                updatedAt: DateTime.now(),
              ),
            ],
          ),
        ]);
        
        when(mockFilterByFuelType.call(
          stations: any,
          fuelType: any,
        )).thenReturn([/* lista filtrada */]);
        
        when(mockCalculateDistance.call(any, any, any, any))
            .thenReturn(1.5);
        
        return mapBloc;
      },
      act: (bloc) => bloc.add(const LoadMapData(
        latitude: 40.4,
        longitude: -3.7,
      )),
      expect: () => [
        isA<MapLoading>(),
        isA<MapLoaded>(),
      ],
    );
    
    blocTest<MapBloc, MapState>(
      'emite MapError cuando falla la carga',
      build: () {
        when(mockGetNearbyStations.call(
          latitude: any,
          longitude: any,
          radiusKm: any,
        )).thenThrow(Exception('Error de red'));
        
        return mapBloc;
      },
      act: (bloc) => bloc.add(const LoadMapData(
        latitude: 40.4,
        longitude: -3.7,
      )),
      expect: () => [
        isA<MapLoading>(),
        isA<MapError>(),
      ],
    );
  });
}
```

#### Test de SettingsBloc

```dart
// test/presentation/blocs/settings/settings_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  late SettingsBloc settingsBloc;
  late MockAppSettings mockSettings;
  
  setUp(() {
    mockSettings = MockAppSettings();
    
    when(mockSettings.searchRadius).thenReturn(10);
    when(mockSettings.preferredFuel).thenReturn(FuelType.gasolina95);
    when(mockSettings.darkMode).thenReturn(false);
    
    settingsBloc = SettingsBloc(settings: mockSettings);
  });
  
  tearDown(() {
    settingsBloc.close();
  });
  
  group('SettingsBloc', () {
    blocTest<SettingsBloc, SettingsState>(
      'emite SettingsLoaded cuando se carga configuración',
      build: () => settingsBloc,
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        isA<SettingsLoaded>(),
      ],
      verify: (_) {
        verify(mockSettings.load()).called(1);
      },
    );
    
    blocTest<SettingsBloc, SettingsState>(
      'actualiza radio de búsqueda correctamente',
      build: () => settingsBloc,
      seed: () => const SettingsLoaded(
        searchRadiusKm: 10,
        preferredFuel: FuelType.gasolina95,
        isDarkMode: false,
      ),
      act: (bloc) => bloc.add(const ChangeSearchRadius(radiusKm: 20)),
      expect: () => [
        const SettingsLoaded(
          searchRadiusKm: 20,
          preferredFuel: FuelType.gasolina95,
          isDarkMode: false,
        ),
      ],
      verify: (_) {
        verify(mockSettings.save()).called(1);
      },
    );
  });
}
```

### 2. Comandos de Verificación

```bash
# Verificar compilación sin errores
flutter analyze

# Ejecutar pruebas unitarias
flutter test

# Verificar cobertura de pruebas
flutter test --coverage
```

### 3. Checklist de Verificación Manual

- [ ] MapBloc emite MapLoading al iniciar carga
- [ ] MapBloc emite MapLoaded con lista de gasolineras
- [ ] MapBloc emite MapError cuando falla la conexión
- [ ] ChangeFuelType actualiza marcadores correctamente
- [ ] RecenterMap obtiene nueva ubicación GPS
- [ ] SelectStation actualiza selectedStation en estado
- [ ] SettingsBloc persiste cambios en SharedPreferences
- [ ] ToggleDarkMode cambia tema de la aplicación
- [ ] ChangeSearchRadius recarga datos con nuevo radio

---

## CHECKLIST DE IMPLEMENTACIÓN

### Tareas Principales

- [ ] **1. Crear estructura de directorios**
  - [ ] `lib/presentation/blocs/map/`
  - [ ] `lib/presentation/blocs/settings/`

- [ ] **2. Implementar MapBloc**
  - [ ] Crear `map_event.dart` con todos los eventos
  - [ ] Crear `map_state.dart` con todos los estados
  - [ ] Crear `map_bloc.dart` con lógica de negocio
  - [ ] Implementar `_onLoadMapData()`
  - [ ] Implementar `_onChangeFuelType()`
  - [ ] Implementar `_onRecenterMap()`
  - [ ] Implementar `_onRefreshMapData()`
  - [ ] Implementar `_onSelectStation()`
  - [ ] Implementar `_onChangeSearchRadius()`
  - [ ] Implementar `_assignPriceRanges()`

- [ ] **3. Implementar SettingsBloc**
  - [ ] Crear `settings_event.dart` con eventos
  - [ ] Crear `settings_state.dart` con estados
  - [ ] Crear `settings_bloc.dart` con lógica
  - [ ] Implementar `_onLoadSettings()`
  - [ ] Implementar `_onChangeSearchRadius()`
  - [ ] Implementar `_onChangePreferredFuel()`
  - [ ] Implementar `_onToggleDarkMode()`
  - [ ] Implementar `_onResetSettings()`

- [ ] **4. Escribir pruebas unitarias**
  - [ ] Tests de MapBloc (mínimo 3 casos)
  - [ ] Tests de SettingsBloc (mínimo 3 casos)

- [ ] **5. Verificar compilación**
  - [ ] Ejecutar `flutter analyze` sin errores
  - [ ] Ejecutar `flutter test` con éxito

### Criterios de Aceptación

✅ **Paso 8 completado cuando:**
1. Todos los archivos de BLoCs están creados
2. MapBloc gestiona correctamente 6 eventos diferentes
3. SettingsBloc gestiona correctamente 5 eventos diferentes
4. Todos los estados están definidos con `Equatable`
5. BLoCs integran correctamente los casos de uso del Paso 7
6. Pruebas unitarias pasan exitosamente
7. `flutter analyze` no muestra errores
8. Código está documentado con comentarios Dart

---

## NOTAS IMPORTANTES

### Mejores Prácticas BLoC

1. **Un BLoC por pantalla principal** (MapBloc para mapa, SettingsBloc para configuración)
2. **Estados inmutables** usando `Equatable` para comparaciones eficientes
3. **Eventos descriptivos** con nombres que indiquen la acción del usuario
4. **Handlers async** para operaciones asíncronas
5. **No llamar emit después de close()** del BLoC

### Errores Comunes a Evitar

❌ **No hacer:**
- Lógica de UI dentro del BLoC
- Modificar estado directamente (siempre emitir nuevo estado)
- Usar BLoC para almacenamiento persistente (usar repositorios)
- Crear demasiados eventos/estados innecesarios

✅ **Hacer:**
- Separar lógica de negocio de UI
- Usar casos de uso para operaciones complejas
- Emitir estados inmutables
- Testear cada handler independientemente

### Recursos Adicionales

- [Documentación oficial flutter_bloc](https://bloclibrary.dev/)
- [Patrón BLoC explicado](https://www.didierboelens.com/2018/08/reactive-programming-streams-bloc/)
- [Bloc Testing Guide](https://bloclibrary.dev/#/testing)

---

**Fecha de creación:** 18 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3  
**Paso:** 8 de 28
