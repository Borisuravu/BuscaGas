# Paso 17: Implementar Actualización Automática de Datos

## Objetivo

Implementar un sistema de **actualización automática y periódica** de datos de gasolineras que funcione en segundo plano, comparando datos frescos de la API con la caché local y actualizando la interfaz sin interrumpir la experiencia del usuario.

---

## 1. Contexto y Requisitos

### 1.1. Requisito Funcional (RF-04)

**RF-04: Actualización de Datos**
- El sistema descargará datos de la API gubernamental al inicio
- Se ejecutará actualización automática periódica en segundo plano
- El usuario será informado durante las cargas

### 1.2. Subsistema Relacionado

**SS-02: Gestión de Datos de Combustible**
- Descarga desde API
- Parsing y validación
- **Actualización periódica** ← Foco del Paso 17
- Almacenamiento en caché

### 1.3. Diagrama de Flujo del Proceso

```
┌────────────────────────────────────────────┐
│ Timer Periódico: cada 30 minutos           │
└────────────────┬───────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────┐
│ ¿Hay Conexión a Internet?                  │
└────────┬──────────────────┬────────────────┘
         │ No               │ Sí
         ▼                  ▼
┌─────────────────┐  ┌──────────────────────┐
│ Cancelar Sync   │  │ Descargar Datos API  │
└─────────────────┘  └──────────┬───────────┘
                                │
                                ▼
                     ┌──────────────────────┐
                     │ ¿Descarga exitosa?   │
                     └──────┬────────┬──────┘
                            │ No     │ Sí
                            ▼        ▼
                   ┌──────────┐  ┌────────────────┐
                   │ Mantener │  │ Comparar con   │
                   │ Datos    │  │ Caché Actual   │
                   └──────────┘  └───────┬────────┘
                                         ▼
                                 ┌───────────────┐
                                 │ ¿Hay Cambios? │
                                 └───┬───────┬───┘
                                     │ No    │ Sí
                                     ▼       ▼
                            ┌─────────┐  ┌──────────────────┐
                            │ No      │  │ Actualizar DB    │
                            │ hacer   │  │ Recalcular       │
                            │ nada    │  │ Notificar UI     │
                            └─────────┘  └──────────────────┘
```

---

## 2. Especificaciones Técnicas

### 2.1. Estrategia de Actualización

**Foreground (Aplicación Activa):**
- Timer periódico cada **30 minutos**
- Dart `Timer.periodic()`
- Actualización silenciosa sin interrumpir usuario

**Background (Aplicación Inactiva):**
- WorkManager para Android (opcional para MVP)
- Permite sincronización incluso cuando app está cerrada
- No implementar en este paso (dejar para futuras versiones)

### 2.2. Componentes a Implementar

#### 2.2.1. DataSyncService

**Ubicación:** `lib/services/data_sync_service.dart`

**Responsabilidades:**
- Gestionar timer periódico
- Verificar conectividad a internet
- Descargar datos frescos de la API
- Comparar con caché local
- Actualizar base de datos si hay cambios
- Notificar a la UI sobre actualizaciones

**Dependencias:**
```dart
import 'dart:async';
import 'dart:math' show min;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/gas_station_repository.dart';
import '../domain/entities/gas_station.dart';
```

#### 2.2.2. Integración con MapScreen

**Ubicación:** `lib/presentation/screens/map_screen.dart`

**Modificaciones necesarias:**
- Inicializar DataSyncService en `initState()`
- Suscribirse a notificaciones de actualización
- Recargar marcadores cuando hay datos nuevos
- Detener timer en `dispose()`

---

## 3. Implementación Paso a Paso

### 3.1. Crear DataSyncService

**Archivo:** `lib/services/data_sync_service.dart`

```dart
import 'dart:async';
import 'dart:math' show min;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/gas_station_repository.dart';
import '../domain/entities/gas_station.dart';

/// Servicio de sincronización periódica de datos
/// 
/// Gestiona la actualización automática de datos de gasolineras
/// desde la API gubernamental cada 30 minutos
class DataSyncService {
  final GasStationRepository _repository;
  Timer? _syncTimer;
  
  /// Intervalo de sincronización: 30 minutos
  final Duration syncInterval = const Duration(minutes: 30);
  
  /// Callback para notificar a la UI sobre actualizaciones
  void Function()? onDataUpdated;
  
  /// Callback para notificar errores de sincronización
  void Function(String error)? onSyncError;
  
  DataSyncService(this._repository);
  
  /// Iniciar sincronización periódica
  void startPeriodicSync() {
    // Cancelar timer previo si existe
    _syncTimer?.cancel();
    
    // Crear nuevo timer periódico
    _syncTimer = Timer.periodic(syncInterval, (_) {
      performSync();
    });
    
    print('✅ Sincronización periódica iniciada (cada ${syncInterval.inMinutes} minutos)');
  }
  
  /// Detener sincronización periódica
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('🛑 Sincronización periódica detenida');
  }
  
  /// Ejecutar sincronización manual
  /// 
  /// Puede ser llamado manualmente o por el timer periódico
  Future<void> performSync() async {
    try {
      print('🔄 Iniciando sincronización...');
      
      // 1. Verificar conectividad
      if (!await _hasInternetConnection()) {
        print('⚠️  Sin conexión a internet, saltando sincronización');
        onSyncError?.call('Sin conexión a internet');
        return;
      }
      
      // 2. Descargar datos frescos de la API
      print('📥 Descargando datos frescos de la API...');
      List<GasStation> freshData = await _repository.fetchRemoteStations();
      print('✅ Descargados ${freshData.length} estaciones de la API');
      
      // 3. Obtener caché actual
      List<GasStation> cachedData = await _repository.getCachedStations();
      print('📦 Caché actual: ${cachedData.length} estaciones');
      
      // 4. Comparar datos
      if (_hasDataChanged(freshData, cachedData)) {
        print('🔄 Cambios detectados, actualizando caché...');
        
        // 5. Actualizar base de datos local
        await _repository.updateCache(freshData);
        
        // 6. Notificar a UI si está activa
        onDataUpdated?.call();
        
        print('✅ Sincronización completada exitosamente a las ${DateTime.now()}');
      } else {
        print('✓ No se detectaron cambios en los datos');
      }
      
    } catch (e) {
      print('❌ Error durante sincronización: $e');
      onSyncError?.call('Error al sincronizar: $e');
      // No interrumpir experiencia de usuario
    }
  }
  
  /// Verificar si hay conexión a internet
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('⚠️  Error al verificar conectividad: $e');
      return false; // Asumir sin conexión en caso de error
    }
  }
  
  /// Comparar datos frescos con caché para detectar cambios
  /// 
  /// Estrategia de comparación:
  /// - Si las listas tienen diferente longitud → cambio detectado
  /// - Comparar precios de las primeras 10 gasolineras como muestra
  bool _hasDataChanged(List<GasStation> fresh, List<GasStation> cached) {
    // Si hay diferencia en cantidad de estaciones
    if (fresh.length != cached.length) {
      print('📊 Cambio detectado: diferente cantidad de estaciones');
      return true;
    }
    
    // Si no hay datos para comparar
    if (fresh.isEmpty) return false;
    
    // Comparar precios de primeras 10 gasolineras como muestra
    int samplesToCompare = min(10, fresh.length);
    
    for (int i = 0; i < samplesToCompare; i++) {
      // Comparar precios de gasolina 95
      if (fresh[i].gasolina95Price != cached[i].gasolina95Price) {
        print('📊 Cambio detectado: precio de Gasolina 95 en estación $i');
        return true;
      }
      
      // Comparar precios de diésel
      if (fresh[i].dieselPrice != cached[i].dieselPrice) {
        print('📊 Cambio detectado: precio de Diésel en estación $i');
        return true;
      }
    }
    
    return false;
  }
  
  /// Liberar recursos
  void dispose() {
    stopPeriodicSync();
  }
}
```

### 3.2. Actualizar GasStationRepository

**Archivo:** `lib/data/repositories/gas_station_repository.dart`

Agregar método `updateCache()`:

```dart
/// Actualizar toda la caché con nuevos datos
/// 
/// Reemplaza todos los registros existentes con datos frescos
Future<void> updateCache(List<GasStation> stations);
```

**Archivo:** `lib/data/repositories/gas_station_repository_impl.dart`

Implementar método:

```dart
@override
Future<void> updateCache(List<GasStation> stations) async {
  try {
    // 1. Limpiar tabla de gasolineras
    await _localDataSource.clearAllStations();
    
    // 2. Insertar nuevas gasolineras
    for (var station in stations) {
      await _localDataSource.insertStation(station);
    }
    
    // 3. Actualizar timestamp de última sincronización
    await _localDataSource.updateLastSyncTime(DateTime.now());
    
    print('✅ Caché actualizada con ${stations.length} estaciones');
  } catch (e) {
    print('❌ Error al actualizar caché: $e');
    rethrow;
  }
}
```

### 3.3. Actualizar DatabaseDataSource

**Archivo:** `lib/data/datasources/local/database_datasource.dart`

Agregar métodos:

```dart
/// Limpiar todas las gasolineras de la base de datos
Future<void> clearAllStations();

/// Actualizar timestamp de última sincronización
Future<void> updateLastSyncTime(DateTime timestamp);
```

**Implementación:**

```dart
/// Limpiar todas las gasolineras
Future<void> clearAllStations() async {
  final db = await database;
  await db.delete('gas_stations');
  print('🗑️  Todas las estaciones eliminadas de la caché');
}

/// Actualizar timestamp de última sincronización
Future<void> updateLastSyncTime(DateTime timestamp) async {
  final db = await database;
  await db.update(
    'app_settings',
    {'last_api_sync': timestamp.toIso8601String()},
    where: 'id = ?',
    whereArgs: [1],
  );
  print('⏰ Timestamp de sincronización actualizado: $timestamp');
}
```

### 3.4. Integrar con MapScreen

**Archivo:** `lib/presentation/screens/map_screen.dart`

**Modificaciones:**

```dart
import '../../services/data_sync_service.dart';

class _MapScreenState extends State<MapScreen> {
  // ... variables existentes ...
  
  late DataSyncService _dataSyncService;
  
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    
    // Inicializar servicio de sincronización
    _initializeDataSync();
  }
  
  /// Inicializar servicio de sincronización automática
  void _initializeDataSync() {
    // TODO: Inyectar repositorio real cuando esté disponible
    // Por ahora, el código está preparado para futura integración
    
    // _dataSyncService = DataSyncService(_repository);
    
    // // Configurar callbacks
    // _dataSyncService.onDataUpdated = _onDataSyncCompleted;
    // _dataSyncService.onSyncError = _onDataSyncError;
    
    // // Iniciar sincronización periódica
    // _dataSyncService.startPeriodicSync();
    
    print('🔄 Servicio de sincronización configurado (pendiente de repositorio)');
  }
  
  /// Callback cuando se completa la sincronización de datos
  void _onDataSyncCompleted() {
    if (!mounted) return;
    
    print('✅ Datos sincronizados, recargando marcadores...');
    
    // TODO: Recargar gasolineras desde caché actualizada
    // Esto se implementará en Paso 8 (BLoC)
    // context.read<MapBloc>().add(ReloadStations());
    
    // Mostrar notificación sutil (opcional)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Callback cuando hay error en sincronización
  void _onDataSyncError(String error) {
    if (!mounted) return;
    
    print('⚠️  Error de sincronización: $error');
    
    // No mostrar error al usuario si es solo falta de conexión
    // La app funciona con caché
  }
  
  @override
  void dispose() {
    // Detener sincronización al salir de la pantalla
    _dataSyncService.dispose();
    super.dispose();
  }
  
  // ... resto del código ...
}
```

---

## 4. Dependencias Necesarias

### 4.1. Actualizar pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existentes
  google_maps_flutter: ^2.5.0
  geolocator: ^10.0.0
  sqflite: ^2.3.0
  # ... otras dependencias existentes ...
  
  # NUEVA: Para verificar conectividad
  connectivity_plus: ^5.0.0
```

### 4.2. Instalar Dependencia

```bash
flutter pub get
```

---

## 5. Casos de Uso

### 5.1. CU-17A: Sincronización Automática Exitosa

**Precondiciones:**
- Aplicación ejecutándose en foreground
- Timer periódico activo (30 minutos)
- Conexión a internet disponible

**Flujo Principal:**
1. Timer dispara evento de sincronización
2. Sistema verifica conectividad → OK
3. Sistema descarga datos de API → 1500 estaciones
4. Sistema compara con caché → Cambios detectados
5. Sistema actualiza base de datos local
6. Sistema notifica a MapScreen
7. MapScreen recarga marcadores (futuro Paso 8)
8. Usuario ve SnackBar: "Datos actualizados"

**Postcondiciones:**
- Caché local actualizada con datos frescos
- `last_api_sync` timestamp actualizado
- Marcadores reflejan precios más recientes

### 5.2. CU-17B: Sin Conexión a Internet

**Precondiciones:**
- Timer activo
- Sin conexión a internet

**Flujo Principal:**
1. Timer dispara evento
2. Sistema verifica conectividad → Sin conexión
3. Sistema cancela sincronización
4. Sistema imprime en log: "Sin conexión, saltando sync"
5. Usuario continúa usando datos de caché

**Postcondiciones:**
- Caché sin cambios
- Usuario no interrumpido

### 5.3. CU-17C: Sin Cambios en Datos

**Precondiciones:**
- Timer activo
- Conexión disponible
- API devuelve mismos datos

**Flujo Principal:**
1. Timer dispara evento
2. Sistema descarga datos
3. Sistema compara con caché → Sin cambios
4. Sistema imprime: "No se detectaron cambios"
5. No se actualiza DB
6. No se notifica a usuario

**Postcondiciones:**
- Caché intacta
- Timestamp de sync NO actualizado

---

## 6. Criterios de Aceptación

### 6.1. Funcionales

| Criterio | Descripción | Verificación |
|----------|-------------|--------------|
| **FA-01** | Timer se activa cada 30 minutos | Logs muestran "Iniciando sincronización" cada 30 min |
| **FA-02** | Verifica conectividad antes de descargar | Si no hay internet, cancela sync |
| **FA-03** | Descarga datos de API gubernamental | Datos frescos obtenidos de endpoint oficial |
| **FA-04** | Compara datos nuevos con caché | Detecta cambios en cantidad o precios |
| **FA-05** | Actualiza DB solo si hay cambios | `updateCache()` llamado solo con cambios |
| **FA-06** | Notifica a UI tras actualización | Callback `onDataUpdated()` ejecutado |
| **FA-07** | No interrumpe usuario en errores | Errores logeados pero no mostrados |
| **FA-08** | Timer se detiene en `dispose()` | Recurso liberado al salir de MapScreen |

### 6.2. No Funcionales

| Criterio | Descripción | Valor Objetivo |
|----------|-------------|----------------|
| **NFA-01** | Sincronización silenciosa | Sin bloqueo de UI |
| **NFA-02** | Tiempo de sincronización | < 5 segundos (red normal) |
| **NFA-03** | Consumo de batería | Mínimo (solo cada 30 min) |
| **NFA-04** | Consumo de datos | ~500KB por sync (JSON API) |
| **NFA-05** | Tolerancia a errores | No crashea si API falla |

---

## 7. Pruebas

### 7.1. Pruebas Unitarias

**Archivo:** `test/services/data_sync_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:buscagas/services/data_sync_service.dart';
import 'package:buscagas/data/repositories/gas_station_repository.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

@GenerateMocks([GasStationRepository])
void main() {
  group('DataSyncService', () {
    late DataSyncService service;
    late MockGasStationRepository mockRepository;
    
    setUp(() {
      mockRepository = MockGasStationRepository();
      service = DataSyncService(mockRepository);
    });
    
    tearDown(() {
      service.dispose();
    });
    
    test('debe iniciar timer periódico', () {
      service.startPeriodicSync();
      expect(service._syncTimer, isNotNull);
      expect(service._syncTimer!.isActive, isTrue);
    });
    
    test('debe detener timer correctamente', () {
      service.startPeriodicSync();
      service.stopPeriodicSync();
      expect(service._syncTimer, isNull);
    });
    
    test('debe detectar cambios cuando hay diferente cantidad de estaciones', () {
      final fresh = [
        GasStation(id: '1', name: 'Test 1', /* ... */),
        GasStation(id: '2', name: 'Test 2', /* ... */),
      ];
      
      final cached = [
        GasStation(id: '1', name: 'Test 1', /* ... */),
      ];
      
      expect(service._hasDataChanged(fresh, cached), isTrue);
    });
    
    test('debe detectar cambios en precios', () {
      final fresh = [
        GasStation(id: '1', gasolina95Price: 1.50, /* ... */),
      ];
      
      final cached = [
        GasStation(id: '1', gasolina95Price: 1.45, /* ... */),
      ];
      
      expect(service._hasDataChanged(fresh, cached), isTrue);
    });
    
    test('NO debe detectar cambios si datos son idénticos', () {
      final station = GasStation(
        id: '1',
        gasolina95Price: 1.50,
        dieselPrice: 1.35,
        /* ... */
      );
      
      expect(service._hasDataChanged([station], [station]), isFalse);
    });
  });
}
```

### 7.2. Pruebas Manuales

**Checklist de Validación:**

- [ ] **Sincronización Inicial**
  - Abrir MapScreen
  - Verificar en logs: "Sincronización periódica iniciada"
  - Confirmar timer activo

- [ ] **Sincronización Periódica**
  - Mantener app abierta 30 minutos
  - Verificar logs cada 30 min: "Iniciando sincronización"
  - Confirmar descarga de datos

- [ ] **Sin Conexión**
  - Activar modo avión
  - Esperar 30 minutos
  - Verificar log: "Sin conexión a internet, saltando sync"
  - No debe haber error visible

- [ ] **Con Cambios**
  - Simular cambio en API (modificar DB manualmente)
  - Esperar sincronización
  - Verificar: "Cambios detectados, actualizando caché"
  - Verificar SnackBar: "Datos actualizados"

- [ ] **Sin Cambios**
  - Esperar sincronización sin modificar datos
  - Verificar log: "No se detectaron cambios"
  - No debe haber SnackBar

- [ ] **Detención de Timer**
  - Navegar a SettingsScreen
  - Volver a MapScreen
  - Verificar en logs que timer se reinicia correctamente

- [ ] **Dispose**
  - Cerrar app completamente
  - Verificar log: "Sincronización periódica detenida"

---

## 8. Integración con Pasos Previos

### 8.1. Depende de:

✅ **Paso 4: Base de datos local**
- Métodos CRUD para estaciones
- Tabla `app_settings` con `last_api_sync`

✅ **Paso 5: API gubernamental**
- Cliente HTTP funcional
- Parser de JSON/XML

✅ **Paso 6: Repositorios**
- `GasStationRepository` con métodos:
  - `fetchRemoteStations()`
  - `getCachedStations()`
  - `updateCache()` (nuevo en este paso)

### 8.2. Prepara para:

⏳ **Paso 8: BLoC (Gestión de Estado)**
- Evento `DataSyncCompleted` para actualizar UI
- Estado `DataSyncing` para mostrar indicador
- Recarga automática de marcadores tras sync

⏳ **Paso 20: Pruebas Unitarias**
- Tests de sincronización con mocks
- Tests de comparación de datos

---

## 9. Notas Técnicas

### 9.1. Limitaciones del MVP

**WorkManager NO incluido:**
- Sincronización solo funciona con app abierta
- Background sync requiere WorkManager (Android) o BackgroundFetch (iOS)
- Dejar para versión 2.0

**Sincronización Básica:**
- Comparación simple de precios (primeras 10 estaciones)
- No usa hashes ni checksums
- Suficiente para MVP

### 9.2. Optimizaciones Futuras

**Comparación Eficiente:**
```dart
// Versión futura: usar hash de datos
String _calculateDataHash(List<GasStation> stations) {
  final dataString = stations.map((s) => '${s.id}-${s.gasolina95Price}').join(',');
  return dataString.hashCode.toString();
}
```

**Sincronización Incremental:**
```dart
// Solo descargar estaciones modificadas (requiere API con timestamps)
Future<List<GasStation>> fetchUpdatedSince(DateTime lastSync);
```

**Indicador Visual:**
```dart
// Mostrar icono de sync en AppBar durante actualización
class MapScreen extends StatefulWidget {
  bool _isSyncing = false;
  
  Widget _buildSyncIndicator() {
    if (!_isSyncing) return SizedBox.shrink();
    
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
```

### 9.3. Consideraciones de Rendimiento

**Timer en Foreground:**
- Solo activo cuando MapScreen está visible
- Se detiene al navegar a otras pantallas
- Se reinicia al volver a MapScreen

**Consumo de Recursos:**
- Timer: ~0% CPU (solo despierta cada 30 min)
- Descarga API: ~500KB datos (una vez cada 30 min)
- Escritura DB: ~2-3 segundos (SQLite)

---

## 10. Checklist de Implementación

### Fase 1: Estructura Base
- [ ] Crear `lib/services/data_sync_service.dart`
- [ ] Implementar clase `DataSyncService`
- [ ] Implementar método `startPeriodicSync()`
- [ ] Implementar método `stopPeriodicSync()`
- [ ] Implementar método `performSync()`
- [ ] Implementar método `_hasInternetConnection()`
- [ ] Implementar método `_hasDataChanged()`

### Fase 2: Repositorio
- [ ] Agregar método `updateCache()` a interfaz
- [ ] Implementar `updateCache()` en `GasStationRepositoryImpl`
- [ ] Agregar `clearAllStations()` a `DatabaseDataSource`
- [ ] Agregar `updateLastSyncTime()` a `DatabaseDataSource`

### Fase 3: Integración MapScreen
- [ ] Importar `DataSyncService`
- [ ] Crear instancia `_dataSyncService`
- [ ] Inicializar en `initState()`
- [ ] Implementar `_onDataSyncCompleted()`
- [ ] Implementar `_onDataSyncError()`
- [ ] Detener timer en `dispose()`

### Fase 4: Dependencias
- [ ] Agregar `connectivity_plus: ^5.0.0` a `pubspec.yaml`
- [ ] Ejecutar `flutter pub get`

### Fase 5: Pruebas
- [ ] Crear archivo de tests unitarios
- [ ] Implementar tests de timer
- [ ] Implementar tests de comparación de datos
- [ ] Ejecutar `flutter test`
- [ ] Validar con pruebas manuales

### Fase 6: Validación
- [ ] Ejecutar `flutter analyze` → 0 errores
- [ ] Probar sincronización con conexión
- [ ] Probar sincronización sin conexión
- [ ] Probar detección de cambios
- [ ] Verificar logs de sincronización
- [ ] Confirmar timer se detiene en dispose

---

## 11. Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Análisis estático
flutter analyze lib/services/data_sync_service.dart

# Pruebas unitarias
flutter test test/services/data_sync_service_test.dart

# Ejecutar app y observar logs
flutter run
# En otra terminal:
adb logcat | grep -i "sincronización\|sync"

# Simular sin conexión (adb)
adb shell svc wifi disable
adb shell svc data disable

# Restaurar conexión
adb shell svc wifi enable
adb shell svc data enable
```

---

## 12. Referencias

### Documentación Métrica v3

- **DSI 6:** Diseño de Procesos - Actualización Periódica de Datos
- **RF-04:** Actualización de Datos
- **SS-02:** Gestión de Datos de Combustible
- **Diagrama de Flujo:** Proceso de Actualización de Datos

### Código de Referencia

- Líneas 1270-1334 de Documentación V3: Implementación de `DataSyncService`
- Líneas 600-670: Diagrama de flujo del proceso de actualización

### Paquetes Dart

- **connectivity_plus:** https://pub.dev/packages/connectivity_plus
- **Timer:** https://api.dart.dev/stable/dart-async/Timer-class.html

---

## 13. Resumen Ejecutivo

### ¿Qué se implementa?

Sistema de **actualización automática** que descarga datos de la API cada 30 minutos, compara con caché, y actualiza la base de datos solo si hay cambios.

### ¿Por qué es importante?

- Garantiza que usuarios vean **precios actualizados**
- Funciona **en segundo plano** sin interrumpir
- Optimiza uso de recursos (solo actualiza si hay cambios)
- Preparación para BLoC (Paso 8)

### ¿Cuándo se ejecuta?

- Automáticamente cada **30 minutos** con app abierta
- Manualmente con `performSync()` (futuro)
- Se detiene al cerrar MapScreen

### ¿Qué pasa si no hay internet?

- Sincronización se cancela silenciosamente
- Usuario continúa usando **datos de caché**
- No se muestra error

### Próximos pasos

Tras completar Paso 17, continuar con **Paso 8 (BLoC)** para integrar eventos de sincronización y actualización automática de marcadores en el mapa.

---

**Fecha de creación:** 1 de diciembre de 2025  
**Paso:** 17 de 28  
**Estado:** Pendiente de implementación  
**Prerequisitos:** Pasos 4, 5, 6 completados  
**Siguiente:** Paso 8 (BLoC) o Paso 18 (Permisos Android)
