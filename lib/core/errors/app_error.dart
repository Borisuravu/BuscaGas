import 'package:equatable/equatable.dart';

/// Tipos de errores en la aplicación
enum ErrorType {
  /// Error de red (sin conexión, timeout, etc.)
  network,

  /// Error de permisos (ubicación, almacenamiento, etc.)
  permission,

  /// Error de datos (parsing, validación, etc.)
  data,

  /// Error del servidor/API
  server,

  /// Error de base de datos local
  database,

  /// Error desconocido
  unknown,
}

/// Clase centralizada para manejar errores en la aplicación.
///
/// Proporciona una forma consistente de representar errores en toda la app,
/// facilitando el manejo y la presentación de mensajes al usuario.
///
/// Uso:
/// ```dart
/// throw AppError.network(
///   message: 'No se pudo conectar al servidor',
///   originalError: e,
/// );
/// ```
class AppError extends Equatable implements Exception {
  /// Tipo de error
  final ErrorType type;

  /// Mensaje descriptivo del error
  final String message;

  /// Error original (opcional)
  final dynamic originalError;

  /// Stack trace del error (opcional)
  final StackTrace? stackTrace;

  /// Indica si el error es recuperable
  final bool isRecoverable;

  const AppError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
    this.isRecoverable = true,
  });

  /// Factory: Error de red
  factory AppError.network({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: ErrorType.network,
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory: Error de permisos
  factory AppError.permission({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: ErrorType.permission,
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory: Error de datos
  factory AppError.data({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: ErrorType.data,
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
      isRecoverable: false,
    );
  }

  /// Factory: Error del servidor
  factory AppError.server({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: ErrorType.server,
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory: Error de base de datos
  factory AppError.database({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: ErrorType.database,
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory: Error desconocido
  factory AppError.unknown({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      type: ErrorType.unknown,
      message: message,
      originalError: originalError,
      stackTrace: stackTrace,
      isRecoverable: false,
    );
  }

  /// Obtiene un mensaje amigable para mostrar al usuario
  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'Sin conexión a internet. Verifica tu conexión e intenta nuevamente.';
      case ErrorType.permission:
        return 'Se necesitan permisos adicionales. Por favor, otórganlos en la configuración.';
      case ErrorType.data:
        return 'Los datos recibidos no son válidos. Intenta actualizar.';
      case ErrorType.server:
        return 'El servidor no está disponible. Intenta más tarde.';
      case ErrorType.database:
        return 'Error al acceder a los datos locales.';
      case ErrorType.unknown:
        return message;
    }
  }

  /// Obtiene un icono representativo del error (emoji)
  String get icon {
    switch (type) {
      case ErrorType.network:
        return '📡';
      case ErrorType.permission:
        return '🔒';
      case ErrorType.data:
        return '📋';
      case ErrorType.server:
        return '🖥️';
      case ErrorType.database:
        return '💾';
      case ErrorType.unknown:
        return '⚠️';
    }
  }

  @override
  List<Object?> get props => [type, message, originalError];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('AppError(');
    buffer.write('type: $type, ');
    buffer.write('message: $message');
    if (originalError != null) {
      buffer.write(', originalError: $originalError');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
