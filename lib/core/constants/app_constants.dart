/// Constantes generales de la aplicación
class AppConstants {
  // TODO: Implement - Definir constantes de la aplicación

  // Nombre de la aplicación
  static const String appName = 'BuscaGas';

  // Radios de búsqueda disponibles (en km)
  static const List<int> searchRadii = [5, 10, 20, 50];
  static const int defaultSearchRadius = 10;

  // Configuración de base de datos
  static const String databaseName = 'buscagas.db';
  static const int databaseVersion = 1;

  // SharedPreferences keys
  static const String keyFirstRun = 'first_run';
  static const String keySearchRadius = 'search_radius';
  static const String keyPreferredFuel = 'preferred_fuel';
  static const String keyDarkMode = 'dark_mode';
  static const String keyLastSync = 'last_api_sync';

  // Sincronización
  static const Duration syncInterval = Duration(minutes: 30);

  // Configuración de API
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Validación de datos
  static const double minValidLat = 35.0;
  static const double maxValidLat = 44.0;
  static const double minValidLon = -10.0;
  static const double maxValidLon = 5.0;
  static const double minValidPrice = 0.5;
  static const double maxValidPrice = 3.0;

  // Mensajes de error para usuario
  static const String errorNoInternet = 'Sin conexión a internet';
  static const String errorServerDown = 'Servidor no disponible';
  static const String errorTimeout = 'La petición tardó demasiado';
  static const String errorUnknown = 'Error inesperado';
}
