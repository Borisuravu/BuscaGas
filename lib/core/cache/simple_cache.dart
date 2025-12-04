import 'dart:async';

/// Entrada de caché con timestamp de expiración
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl; // Time To Live

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  /// Verifica si la entrada ha expirado
  bool get isExpired {
    final now = DateTime.now();
    final expirationTime = timestamp.add(ttl);
    return now.isAfter(expirationTime);
  }

  /// Tiempo restante hasta la expiración
  Duration get timeUntilExpiration {
    final now = DateTime.now();
    final expirationTime = timestamp.add(ttl);
    return expirationTime.difference(now);
  }
}

/// Caché simple en memoria con expiración automática.
///
/// Características:
/// - Almacena datos en memoria con tiempo de vida (TTL) configurable
/// - Expira automáticamente después del TTL
/// - Limpieza manual o automática de entradas expiradas
/// - Thread-safe para operaciones básicas
///
/// Uso:
/// ```dart
/// final cache = SimpleCache<List<GasStation>>(
///   ttl: Duration(minutes: 30),
/// );
///
/// // Guardar en caché
/// cache.put('nearby_stations', stations);
///
/// // Obtener del caché
/// final cached = cache.get('nearby_stations');
/// if (cached != null) {
///   print('Datos en caché válidos');
/// }
/// ```
class SimpleCache<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final Duration ttl;
  Timer? _cleanupTimer;

  /// Constructor
  ///
  /// [ttl] Tiempo de vida de las entradas en caché (por defecto: 30 minutos)
  /// [autoCleanup] Si es true, limpia entradas expiradas automáticamente
  /// [cleanupInterval] Intervalo de limpieza automática (por defecto: 5 minutos)
  SimpleCache({
    this.ttl = const Duration(minutes: 30),
    bool autoCleanup = true,
    Duration cleanupInterval = const Duration(minutes: 5),
  }) {
    if (autoCleanup) {
      _startAutoCleanup(cleanupInterval);
    }
  }

  /// Almacena un valor en el caché con la clave especificada
  ///
  /// [key] Clave única para identificar el valor
  /// [value] Valor a almacenar
  /// [customTtl] TTL personalizado para esta entrada (opcional)
  void put(String key, T value, {Duration? customTtl}) {
    _cache[key] = _CacheEntry<T>(
      data: value,
      timestamp: DateTime.now(),
      ttl: customTtl ?? ttl,
    );
  }

  /// Obtiene un valor del caché
  ///
  /// Retorna null si:
  /// - La clave no existe
  /// - La entrada ha expirado
  ///
  /// [key] Clave del valor a obtener
  T? get(String key) {
    final entry = _cache[key];

    // Si no existe, retornar null
    if (entry == null) return null;

    // Si expiró, eliminar y retornar null
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Verifica si existe una entrada válida para la clave
  ///
  /// [key] Clave a verificar
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Elimina una entrada del caché
  ///
  /// [key] Clave de la entrada a eliminar
  void remove(String key) {
    _cache.remove(key);
  }

  /// Limpia todas las entradas del caché
  void clear() {
    _cache.clear();
  }

  /// Limpia solo las entradas que han expirado
  ///
  /// Retorna el número de entradas eliminadas
  int removeExpired() {
    final keysToRemove = <String>[];

    _cache.forEach((key, entry) {
      if (entry.isExpired) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    return keysToRemove.length;
  }

  /// Obtiene el número total de entradas en caché
  int get size => _cache.length;

  /// Verifica si el caché está vacío
  bool get isEmpty => _cache.isEmpty;

  /// Verifica si el caché no está vacío
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Obtiene todas las claves almacenadas
  Iterable<String> get keys => _cache.keys;

  /// Obtiene información de debug sobre una entrada
  ///
  /// [key] Clave de la entrada
  Map<String, dynamic>? getEntryInfo(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    return {
      'key': key,
      'timestamp': entry.timestamp.toIso8601String(),
      'ttl': entry.ttl.inSeconds,
      'isExpired': entry.isExpired,
      'timeUntilExpiration': entry.isExpired
          ? 0
          : entry.timeUntilExpiration.inSeconds,
    };
  }

  /// Inicia la limpieza automática de entradas expiradas
  void _startAutoCleanup(Duration interval) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) {
      final removed = removeExpired();
      if (removed > 0) {
        // Solo para debugging, puedes comentar en producción
        // print('SimpleCache: Eliminadas $removed entradas expiradas');
      }
    });
  }

  /// Detiene la limpieza automática
  void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Libera recursos (debe llamarse al destruir el caché)
  void dispose() {
    stopAutoCleanup();
    clear();
  }
}
