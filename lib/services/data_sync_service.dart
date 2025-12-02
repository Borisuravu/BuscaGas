/// Servicio de sincronización periódica de datos
/// 
/// Gestiona la actualización automática de datos de gasolineras
/// desde la API gubernamental cada 30 minutos
library;

import 'dart:async';
import 'dart:math' show min;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/repositories/gas_station_repository_impl.dart';
import '../domain/entities/gas_station.dart';

class DataSyncService {
  final GasStationRepositoryImpl _repository;
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
      return connectivityResult.first != ConnectivityResult.none;
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
      // Obtener precios de gasolina 95
      final freshGasolina95 = fresh[i].prices
          .where((p) => p.fuelType.name == 'gasolina95')
          .map((p) => p.value)
          .firstOrNull;
      
      final cachedGasolina95 = cached[i].prices
          .where((p) => p.fuelType.name == 'gasolina95')
          .map((p) => p.value)
          .firstOrNull;
      
      // Comparar precios de gasolina 95
      if (freshGasolina95 != cachedGasolina95) {
        print('📊 Cambio detectado: precio de Gasolina 95 en estación $i');
        return true;
      }
      
      // Obtener precios de diésel
      final freshDiesel = fresh[i].prices
          .where((p) => p.fuelType.name == 'diesel')
          .map((p) => p.value)
          .firstOrNull;
      
      final cachedDiesel = cached[i].prices
          .where((p) => p.fuelType.name == 'diesel')
          .map((p) => p.value)
          .firstOrNull;
      
      // Comparar precios de diésel
      if (freshDiesel != cachedDiesel) {
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
