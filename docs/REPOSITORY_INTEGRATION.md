# Integración del Repository Pattern en BuscaGas

## Descripción General

El **Repository Pattern** actúa como una capa intermedia entre los **casos de uso (UseCases)** de la capa de dominio y los **datasources** de la capa de datos. Su función principal es coordinar el acceso a múltiples fuentes de datos (API remota y base de datos local) con una interfaz limpia y consistente.

## Arquitectura del Proyecto

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │   BLoC     │  │   BLoC     │  │   BLoC     │            │
│  │   Home     │  │  Nearby    │  │   Search   │            │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘            │
│         │                │                │                  │
└─────────┼────────────────┼────────────────┼──────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                      CAPA DE DOMINIO                        │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  UseCase   │  │  UseCase   │  │  UseCase   │            │
│  │GetStations │  │GetNearby   │  │SyncStations│            │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘            │
│         │                │                │                  │
│         └────────────────┼────────────────┘                  │
│                          │                                   │
│              ┌───────────▼──────────────┐                    │
│              │ GasStationRepository     │ (Interface)        │
│              │  - fetchRemoteStations() │                    │
│              │  - getCachedStations()   │                    │
│              │  - updateCache()         │                    │
│              │  - getNearbyStations()   │                    │
│              └───────────┬──────────────┘                    │
└──────────────────────────┼───────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       CAPA DE DATOS                         │
│         ┌──────────────────────────────────┐                │
│         │ GasStationRepositoryImpl         │ (Concrete)     │
│         │  - _apiDataSource                │                │
│         │  - _databaseDataSource           │                │
│         └────────┬──────────────┬──────────┘                │
│                  │              │                            │
│      ┌───────────▼───┐    ┌────▼──────────────┐            │
│      │ ApiDataSource │    │ DatabaseDataSource │            │
│      │ (Remote)      │    │ (Local/SQLite)     │            │
│      └───────────────┘    └────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## 1. Integración con SyncService

### Función del SyncService

El `SyncService` orquesta la sincronización periódica de datos entre la API remota y la base de datos local. Utiliza el repositorio como su única interfaz de acceso a datos.

### Ejemplo de Integración

```dart
// lib/services/sync_service.dart

import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

class SyncService {
  final GasStationRepository _repository;
  
  SyncService({GasStationRepository? repository})
      : _repository = repository ?? GasStationRepositoryImpl(
          ApiDataSource(),
          DatabaseDataSource(),
        );
  
  /// Sincronización completa: API → Caché
  Future<void> syncGasStations() async {
    try {
      print('🔄 Iniciando sincronización...');
      
      // 1. Descargar datos frescos desde API
      final remoteStations = await _repository.fetchRemoteStations();
      print('📥 Descargadas ${remoteStations.length} gasolineras');
      
      // 2. Actualizar caché local
      await _repository.updateCache(remoteStations);
      print('💾 Caché actualizado');
      
      print('✅ Sincronización completada');
    } catch (e) {
      print('❌ Error en sincronización: $e');
      rethrow;
    }
  }
  
  /// Sincronización incremental (solo si caché está vacío)
  Future<void> syncIfNeeded() async {
    final cached = await _repository.getCachedStations();
    
    if (cached.isEmpty) {
      print('⚠️ Caché vacío, sincronizando...');
      await syncGasStations();
    } else {
      print('✅ Caché disponible (${cached.length} registros)');
    }
  }
  
  /// Sincronización programada en background
  Future<void> startPeriodicSync({Duration interval = const Duration(hours: 6)}) async {
    while (true) {
      await syncGasStations();
      await Future.delayed(interval);
    }
  }
}
```

### Flujo de Sincronización

```
Usuario abre app
       │
       ▼
SyncService.syncIfNeeded()
       │
       ▼
Repository.getCachedStations()
       │
       ├─── ¿Hay datos? ─── SÍ ─── Usar caché
       │
       └─── NO
              │
              ▼
       Repository.fetchRemoteStations()
              │
              ▼
       Repository.updateCache()
              │
              ▼
       Datos disponibles
```

## 2. Integración con BLoC (Business Logic Component)

### Ejemplo: Home BLoC

```dart
// lib/presentation/blocs/home/home_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

// ==================== EVENTS ====================

abstract class HomeEvent {}

class LoadStationsEvent extends HomeEvent {}
class RefreshStationsEvent extends HomeEvent {}

// ==================== STATES ====================

abstract class HomeState {}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<GasStation> stations;
  HomeLoaded(this.stations);
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// ==================== BLOC ====================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GasStationRepository _repository;
  
  HomeBloc(this._repository) : super(HomeInitial()) {
    on<LoadStationsEvent>(_onLoadStations);
    on<RefreshStationsEvent>(_onRefreshStations);
  }
  
  /// Cargar desde caché primero (modo offline-first)
  Future<void> _onLoadStations(
    LoadStationsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    try {
      // Intentar cargar desde caché
      final cachedStations = await _repository.getCachedStations();
      
      if (cachedStations.isNotEmpty) {
        emit(HomeLoaded(cachedStations));
      } else {
        // Si caché vacío, descargar de API
        final remoteStations = await _repository.fetchRemoteStations();
        await _repository.updateCache(remoteStations);
        emit(HomeLoaded(remoteStations));
      }
    } catch (e) {
      emit(HomeError('Error al cargar gasolineras: $e'));
    }
  }
  
  /// Refrescar forzando descarga desde API
  Future<void> _onRefreshStations(
    RefreshStationsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    try {
      final remoteStations = await _repository.fetchRemoteStations();
      await _repository.updateCache(remoteStations);
      emit(HomeLoaded(remoteStations));
    } catch (e) {
      emit(HomeError('Error al refrescar: $e'));
    }
  }
}
```

### Ejemplo: Nearby BLoC

```dart
// lib/presentation/blocs/nearby/nearby_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

// ==================== EVENTS ====================

abstract class NearbyEvent {}

class SearchNearbyEvent extends NearbyEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  
  SearchNearbyEvent({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
  });
}

// ==================== STATES ====================

abstract class NearbyState {}

class NearbyInitial extends NearbyState {}
class NearbyLoading extends NearbyState {}
class NearbyLoaded extends NearbyState {
  final List<GasStation> stations;
  final double radius;
  
  NearbyLoaded(this.stations, this.radius);
}
class NearbyError extends NearbyState {
  final String message;
  NearbyError(this.message);
}

// ==================== BLOC ====================

class NearbyBloc extends Bloc<NearbyEvent, NearbyState> {
  final GasStationRepository _repository;
  
  NearbyBloc(this._repository) : super(NearbyInitial()) {
    on<SearchNearbyEvent>(_onSearchNearby);
  }
  
  Future<void> _onSearchNearby(
    SearchNearbyEvent event,
    Emitter<NearbyState> emit,
  ) async {
    emit(NearbyLoading());
    
    try {
      final nearbyStations = await _repository.getNearbyStations(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      
      emit(NearbyLoaded(nearbyStations, event.radiusKm));
    } catch (e) {
      emit(NearbyError('Error al buscar gasolineras cercanas: $e'));
    }
  }
}
```

### Integración en Widget

```dart
// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscagas/presentation/blocs/home/home_bloc.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        GasStationRepositoryImpl(
          ApiDataSource(),
          DatabaseDataSource(),
        ),
      )..add(LoadStationsEvent()),
      child: Scaffold(
        appBar: AppBar(title: Text('BuscaGas')),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is HomeLoaded) {
              return ListView.builder(
                itemCount: state.stations.length,
                itemBuilder: (context, index) {
                  final station = state.stations[index];
                  return ListTile(
                    title: Text(station.name),
                    subtitle: Text(station.locality),
                  );
                },
              );
            } else if (state is HomeError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return Center(child: Text('Toca para cargar'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.read<HomeBloc>().add(RefreshStationsEvent());
          },
          child: Icon(Icons.refresh),
        ),
      ),
    );
  }
}
```

## 3. Integración con UseCases

### Ejemplo: GetNearbyStationsUseCase

```dart
// lib/domain/usecases/get_nearby_stations_usecase.dart

import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

/// Caso de uso: Obtener gasolineras cercanas a una ubicación
class GetNearbyStationsUseCase {
  final GasStationRepository _repository;
  
  GetNearbyStationsUseCase(this._repository);
  
  /// Ejecutar caso de uso
  /// 
  /// [latitude] Latitud del usuario
  /// [longitude] Longitud del usuario
  /// [radiusKm] Radio de búsqueda en kilómetros (default: 10 km)
  /// 
  /// Returns lista de gasolineras ordenadas por distancia
  Future<List<GasStation>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    // Validaciones de entrada
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitud inválida: $latitude');
    }
    
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitud inválida: $longitude');
    }
    
    if (radiusKm <= 0) {
      throw ArgumentError('Radio debe ser positivo: $radiusKm');
    }
    
    // Delegar al repositorio
    return await _repository.getNearbyStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
```

### Ejemplo: SyncStationsUseCase

```dart
// lib/domain/usecases/sync_stations_usecase.dart

import 'package:buscagas/domain/repositories/gas_station_repository.dart';

/// Caso de uso: Sincronizar gasolineras desde API a caché local
class SyncStationsUseCase {
  final GasStationRepository _repository;
  
  SyncStationsUseCase(this._repository);
  
  /// Ejecutar sincronización completa
  Future<int> call() async {
    // 1. Descargar desde API
    final remoteStations = await _repository.fetchRemoteStations();
    
    // 2. Actualizar caché
    await _repository.updateCache(remoteStations);
    
    // 3. Retornar cantidad sincronizada
    return remoteStations.length;
  }
}
```

### Integración de UseCases en BLoC

```dart
// lib/presentation/blocs/nearby/nearby_bloc.dart (versión con UseCases)

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscagas/domain/usecases/get_nearby_stations_usecase.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

class NearbyBloc extends Bloc<NearbyEvent, NearbyState> {
  final GetNearbyStationsUseCase _getNearbyStationsUseCase;
  
  NearbyBloc(this._getNearbyStationsUseCase) : super(NearbyInitial()) {
    on<SearchNearbyEvent>(_onSearchNearby);
  }
  
  Future<void> _onSearchNearby(
    SearchNearbyEvent event,
    Emitter<NearbyState> emit,
  ) async {
    emit(NearbyLoading());
    
    try {
      final nearbyStations = await _getNearbyStationsUseCase(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      
      emit(NearbyLoaded(nearbyStations, event.radiusKm));
    } catch (e) {
      emit(NearbyError('Error: $e'));
    }
  }
}
```

## 4. Inyección de Dependencias

### Opción 1: Constructor Injection (Actual)

```dart
// lib/main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos
  final dbService = DatabaseService();
  await dbService.initialize();
  
  // Crear datasources
  final apiDataSource = ApiDataSource();
  final databaseDataSource = DatabaseDataSource();
  
  // Crear repositorio
  final repository = GasStationRepositoryImpl(
    apiDataSource,
    databaseDataSource,
  );
  
  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final GasStationRepository repository;
  
  const MyApp({required this.repository, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => HomeBloc(repository),
        child: HomeScreen(),
      ),
    );
  }
}
```

### Opción 2: get_it (Service Locator)

```yaml
# pubspec.yaml
dependencies:
  get_it: ^7.6.0
```

```dart
// lib/core/di/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/usecases/get_nearby_stations_usecase.dart';
import 'package:buscagas/presentation/blocs/home/home_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // DataSources
  getIt.registerLazySingleton(() => ApiDataSource());
  getIt.registerLazySingleton(() => DatabaseDataSource());
  
  // Repositories
  getIt.registerLazySingleton<GasStationRepository>(
    () => GasStationRepositoryImpl(
      getIt<ApiDataSource>(),
      getIt<DatabaseDataSource>(),
    ),
  );
  
  // UseCases
  getIt.registerLazySingleton(
    () => GetNearbyStationsUseCase(getIt<GasStationRepository>()),
  );
  
  // BLoCs
  getIt.registerFactory(() => HomeBloc(getIt<GasStationRepository>()));
}
```

## 5. Manejo de Errores

### Estrategia de Manejo de Errores

```dart
// lib/data/repositories/gas_station_repository_impl.dart

class GasStationRepositoryImpl implements GasStationRepository {
  // ...
  
  @override
  Future<List<GasStation>> fetchRemoteStations() async {
    try {
      final models = await _apiDataSource.fetchGasStations();
      return models.map((model) => model.toEntity()).toList();
    } on NetworkException catch (e) {
      // Error de red (timeout, sin conexión)
      throw RepositoryException(
        'Error de red: ${e.message}',
        cause: e,
      );
    } on ApiException catch (e) {
      // Error de API (500, 404, etc.)
      throw RepositoryException(
        'Error de API: ${e.message}',
        cause: e,
      );
    } catch (e) {
      // Cualquier otro error
      throw RepositoryException(
        'Error desconocido al descargar datos',
        cause: e,
      );
    }
  }
  
  @override
  Future<List<GasStation>> getCachedStations() async {
    try {
      final models = await _databaseDataSource.getAllStations();
      return models.map((model) => model.toEntity()).toList();
    } on DatabaseException catch (e) {
      throw RepositoryException(
        'Error de base de datos: ${e.message}',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException(
        'Error desconocido al leer caché',
        cause: e,
      );
    }
  }
}

// Excepciones personalizadas
class RepositoryException implements Exception {
  final String message;
  final dynamic cause;
  
  RepositoryException(this.message, {this.cause});
  
  @override
  String toString() => 'RepositoryException: $message';
}
```

## 6. Testing

### Unit Tests del Repositorio

Ver archivo: `test/repositories/gas_station_repository_test.dart`

### Integration Tests

```dart
// integration_test/repository_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Repository Integration Tests', () {
    late GasStationRepositoryImpl repository;
    
    setUpAll(() {
      repository = GasStationRepositoryImpl(
        ApiDataSource(),
        DatabaseDataSource(),
      );
    });
    
    testWidgets('Full sync flow', (tester) async {
      // 1. Fetch remote
      final remote = await repository.fetchRemoteStations();
      expect(remote, isNotEmpty);
      
      // 2. Update cache
      await repository.updateCache(remote);
      
      // 3. Get cached
      final cached = await repository.getCachedStations();
      expect(cached.length, equals(remote.length));
    });
  });
}
```

## 7. Diagramas de Secuencia

### Sincronización Completa

```
Usuario  │  BLoC  │  UseCase  │  Repository  │  DataSource
   │         │         │            │              │
   │ Tap     │         │            │              │
   ├────────>│         │            │              │
   │         │ Execute │            │              │
   │         ├────────>│            │              │
   │         │         │ Fetch      │              │
   │         │         ├───────────>│              │
   │         │         │            │ API Request  │
   │         │         │            ├─────────────>│
   │         │         │            │<─────────────┤
   │         │         │            │ JSON Response│
   │         │         │<───────────┤              │
   │         │         │ Entities   │              │
   │         │         │            │              │
   │         │         │ Update     │              │
   │         │         ├───────────>│              │
   │         │         │            │ Save to DB   │
   │         │         │            ├─────────────>│
   │         │         │            │<─────────────┤
   │         │         │<───────────┤              │
   │         │<────────┤            │              │
   │<────────┤ Updated │            │              │
   │ UI      │ State   │            │              │
```

## Resumen de Beneficios

1. **Separación de Responsabilidades**: BLoC maneja UI, Repository maneja datos
2. **Testabilidad**: Fácil mocear el repositorio en tests
3. **Flexibilidad**: Cambiar implementación sin afectar BLoC
4. **Caché Automático**: Repository decide cuándo usar API vs caché
5. **Manejo Centralizado de Errores**: Un solo punto de control
6. **Clean Architecture**: Dependencias apuntan hacia el dominio

---

**Autor:** BuscaGas Team  
**Fecha:** Paso 6 - Repository Pattern Implementation  
**Versión:** 1.0
