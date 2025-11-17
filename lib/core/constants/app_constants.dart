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
}
