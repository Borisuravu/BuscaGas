/// Servicio de sincronización periódica de datos
///
/// Gestiona la actualización automática de datos de gasolineras
/// desde la API gubernamental cada 30 minutos
library;

import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import '../data/repositories/gas_station_repository_impl.dart';
import '../domain/entities/gas_station.dart';
import '../core/utils/performance_monitor.dart';
import '../data/datasources/local/database_datasource.dart';

class DataSyncService {
  final GasStationRepositoryImpl _repository;
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();
  final DatabaseDataSource _databaseDataSource = DatabaseDataSource();
  Timer? _syncTimer;
  bool _isInForeground = true;

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

    debugPrint(
        '✅ Sincronización periódica iniciada (cada ${syncInterval.inMinutes} minutos)');
  }

  /// Detener sincronización periódica
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('🛑 Sincronización periódica detenida');
  }

  /// Método alias para compatibilidad
  void start() => startPeriodicSync();

  /// Método alias para compatibilidad
  void stop() => stopPeriodicSync();

  /// Notificar cambio de estado de app (foreground/background)
  void setForegroundState(bool isForeground) {
    _isInForeground = isForeground;
    debugPrint('📱 App ${isForeground ? "foreground" : "background"}');
  }

  /// Ejecutar sincronización manual
  ///
  /// Puede ser llamado manualmente o por el timer periódico
  Future<void> performSync() async {
    try {
      debugPrint('🔄 Iniciando sincronización...');

      // 1. Verificar estado de la app y conectividad
      if (!_isInForeground) {
        debugPrint('🔄 App en background - verificar WiFi');

        // Solo sincronizar en WiFi cuando está en background
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult.first != ConnectivityResult.wifi) {
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

      // 3. Verificar conectividad general
      if (!await _hasInternetConnection()) {
        debugPrint('📡 Sin conexión - cancelar sync');
        onSyncError?.call('Sin conexión a internet');
        return;
      }

      // 4. Realizar sincronización
      await PerformanceMonitor.measure('Sync', () async {
        // Descargar datos frescos de la API
        debugPrint('📥 Descargando datos frescos de la API...');
        List<GasStation> freshData = await _repository.fetchRemoteStations();
        debugPrint('✅ Descargados ${freshData.length} estaciones de la API');

        // Obtener caché actual
        List<GasStation> cachedData = await _repository.getCachedStations();
        debugPrint('📦 Caché actual: ${cachedData.length} estaciones');

        // Comparar datos
        if (_hasDataChanged(freshData, cachedData)) {
          debugPrint('🔄 Cambios detectados, actualizando caché...');

          // Actualizar base de datos local
          await _repository.updateCache(freshData);

          // Notificar a UI si está activa
          onDataUpdated?.call();

          debugPrint(
              '✅ Sync completado: ${freshData.length} estaciones a las ${DateTime.now()}');
        } else {
          debugPrint('ℹ️ Sin cambios en datos');
        }

        // 5. Optimizar BD semanalmente (comentado ya que DatabaseDataSource no tiene estos métodos)
        // TODO: Implementar optimización de BD en DatabaseDataSource si es necesario
        /*
        final lastOptimization =
            await _databaseDataSource.getLastOptimizationTime();
        if (lastOptimization == null ||
            DateTime.now().difference(lastOptimization).inDays >= 7) {
          debugPrint('🔧 Optimizando base de datos (semanal)...');
          await _databaseDataSource.optimizeDatabase();
          await _databaseDataSource.updateLastOptimizationTime();
        }
        */
      });
    } catch (e) {
      debugPrint('❌ Error sync: $e');
      onSyncError?.call('Error al sincronizar: $e');
      // No interrumpir experiencia de usuario
    }
  }

  /// Verificar si hay conexión a internet
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      debugPrint('⚠️  Error al verificar conectividad: $e');
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
      debugPrint('📊 Cambio detectado: diferente cantidad de estaciones');
      return true;
    }

    // Si no hay datos para comparar
    if (fresh.isEmpty) return false;

    // Comparar precios de primeras 10 gasolineras como muestra
    int samplesToCompare = min(10, fresh.length);

    for (int i = 0; i < samplesToCompare; i++) {
      // Obtener precios de gasolina 95
      final freshGasolina95 = fresh[i]
          .prices
          .where((p) => p.fuelType.name == 'gasolina95')
          .map((p) => p.value)
          .firstOrNull;

      final cachedGasolina95 = cached[i]
          .prices
          .where((p) => p.fuelType.name == 'gasolina95')
          .map((p) => p.value)
          .firstOrNull;

      // Comparar precios de gasolina 95
      if (freshGasolina95 != cachedGasolina95) {
        debugPrint('📊 Cambio detectado: precio de Gasolina 95 en estación $i');
        return true;
      }

      // Obtener precios de diésel
      final freshDiesel = fresh[i]
          .prices
          .where((p) => p.fuelType.name == 'diesel')
          .map((p) => p.value)
          .firstOrNull;

      final cachedDiesel = cached[i]
          .prices
          .where((p) => p.fuelType.name == 'diesel')
          .map((p) => p.value)
          .firstOrNull;

      // Comparar precios de diésel
      if (freshDiesel != cachedDiesel) {
        debugPrint('📊 Cambio detectado: precio de Diésel en estación $i');
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
