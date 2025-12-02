import 'package:flutter/foundation.dart';

/// Monitor de rendimiento para medir tiempos de operaciones
/// 
/// Solo activo en debug mode para no afectar rendimiento en producción.
/// Permite medir tiempos de operaciones críticas y detectar cuellos de botella.
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  
  /// Iniciar medición de una operación
  /// 
  /// ```dart
  /// PerformanceMonitor.start('DatabaseQuery');
  /// ```
  static void start(String operation) {
    if (!kDebugMode) return;
    _timers[operation] = Stopwatch()..start();
  }
  
  /// Detener medición y loggear resultado
  /// 
  /// ```dart
  /// PerformanceMonitor.stop('DatabaseQuery');
  /// // Output: ⏱️ DatabaseQuery: 123ms
  /// ```
  static void stop(String operation) {
    if (!kDebugMode) return;
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      debugPrint('⏱️ $operation: ${timer.elapsedMilliseconds}ms');
      _timers.remove(operation);
    }
  }
  
  /// Medir función asíncrona completa
  /// 
  /// ```dart
  /// final result = await PerformanceMonitor.measure('API Call', () async {
  ///   return await apiService.fetchData();
  /// });
  /// ```
  static Future<T> measure<T>(String operation, Future<T> Function() fn) async {
    start(operation);
    try {
      return await fn();
    } finally {
      stop(operation);
    }
  }
  
  /// Medir función síncrona completa
  /// 
  /// ```dart
  /// final result = PerformanceMonitor.measureSync('Calculation', () {
  ///   return complexCalculation();
  /// });
  /// ```
  static T measureSync<T>(String operation, T Function() fn) {
    start(operation);
    try {
      return fn();
    } finally {
      stop(operation);
    }
  }
}
