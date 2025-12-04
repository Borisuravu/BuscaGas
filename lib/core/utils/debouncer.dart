import 'dart:async';

/// Debouncer para evitar ejecuciones repetidas de funciones
/// 
/// Útil para optimizar búsquedas, filtros y eventos que se disparan
/// con alta frecuencia (como onChanged de TextField o movimiento de mapa).
/// 
/// Ejemplo de uso:
/// ```dart
/// final debouncer = Debouncer(delay: Duration(milliseconds: 500));
/// 
/// TextField(
///   onChanged: (value) {
///     debouncer.run(() {
///       // Esta función solo se ejecuta después de 500ms de inactividad
///       searchProducts(value);
///     });
///   },
/// );
/// ```
class Debouncer {
  /// Duración del delay antes de ejecutar la acción
  final Duration delay;

  /// Timer interno para controlar el delay
  Timer? _timer;

  /// Constructor
  /// 
  /// [delay] - Tiempo de espera antes de ejecutar la acción
  Debouncer({
    this.delay = const Duration(milliseconds: 500),
  });

  /// Ejecuta la acción después del delay configurado
  /// 
  /// Si se llama múltiples veces, cancela las ejecuciones anteriores
  /// y reinicia el temporizador.
  /// 
  /// [action] - Función a ejecutar después del delay
  void run(VoidCallback action) {
    // Cancelar el timer anterior si existe
    _timer?.cancel();

    // Crear un nuevo timer
    _timer = Timer(delay, action);
  }

  /// Cancela cualquier acción pendiente
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Ejecuta la acción inmediatamente y cancela cualquier timer pendiente
  void runImmediately(VoidCallback action) {
    cancel();
    action();
  }

  /// Verifica si hay una acción pendiente
  bool get isActive => _timer?.isActive ?? false;

  /// Libera recursos cuando ya no se necesita el debouncer
  void dispose() {
    cancel();
  }
}

/// Tipo de callback sin parámetros
typedef VoidCallback = void Function();
