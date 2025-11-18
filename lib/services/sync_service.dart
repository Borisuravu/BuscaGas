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
      return connectivityResult.first != ConnectivityResult.none;
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
