import 'package:flutter/material.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/domain/entities/app_settings.dart';

/// Clase responsable de la inicialización de la aplicación.
///
/// Centraliza toda la lógica de inicialización y proporciona acceso
/// a servicios y repositorios de forma estática.
///
/// Uso:
/// ```dart
/// await AppInitializer.initialize();
/// final repository = AppInitializer.gasStationRepository;
/// ```
class AppInitializer {
  // Singleton pattern
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  // Estado de inicialización
  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Notificador para cambios de tema (reemplaza GlobalKey)
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

  // Servicios y repositorios
  late ApiDataSource _apiDataSource;
  late DatabaseDataSource _databaseDataSource;
  late GasStationRepositoryImpl _gasStationRepository;
  late AppSettings _settings;

  // Getters públicos para acceder a los servicios
  static ApiDataSource get apiDataSource => _instance._apiDataSource;
  static DatabaseDataSource get databaseDataSource => _instance._databaseDataSource;
  static GasStationRepositoryImpl get gasStationRepository => _instance._gasStationRepository;
  static AppSettings get settings => _instance._settings;

  /// Inicializa todos los servicios de la aplicación.
  ///
  /// Este método debe ser llamado una sola vez al inicio de la aplicación.
  /// Es seguro llamarlo múltiples veces; solo se ejecutará la primera vez.
  ///
  /// Retorna las configuraciones cargadas para uso inmediato en la UI.
  static Future<AppSettings> initialize() async {
    if (_instance._initialized) {
      debugPrint('⚠️ AppInitializer ya fue inicializado');
      return _instance._settings;
    }

    debugPrint('🚀 Iniciando AppInitializer...');

    try {
      // 1. Cargar configuraciones (rápido, ~50ms)
      _instance._settings = await AppSettings.load();
      themeModeNotifier.value = _instance._settings.darkMode ? ThemeMode.dark : ThemeMode.light;
      debugPrint('✅ Configuraciones cargadas');

      // 2. Inicializar datasources
      _instance._apiDataSource = ApiDataSource();
      _instance._databaseDataSource = DatabaseDataSource();
      debugPrint('✅ DataSources inicializados');

      // 3. Inicializar repositorio
      _instance._gasStationRepository = GasStationRepositoryImpl(
        _instance._apiDataSource,
        _instance._databaseDataSource,
      );
      debugPrint('✅ Repositorio inicializado');

      // 4. Verificar que la base de datos esté lista
      await _instance._databaseDataSource.hasData();
      debugPrint('✅ Base de datos verificada');

      _instance._initialized = true;
      debugPrint('🎉 AppInitializer completado exitosamente');

      return _instance._settings;
    } catch (e) {
      debugPrint('❌ Error en AppInitializer: $e');
      rethrow;
    }
  }

  /// Recarga las configuraciones de la aplicación.
  ///
  /// Útil cuando el usuario cambia configuraciones y necesitas
  /// actualizar el estado global.
  static Future<AppSettings> reloadSettings() async {
    _instance._settings = await AppSettings.load();
    themeModeNotifier.value = _instance._settings.darkMode ? ThemeMode.dark : ThemeMode.light;
    debugPrint('🔄 Configuraciones recargadas');
    return _instance._settings;
  }

  /// Resetea el inicializador (útil para testing).
  @visibleForTesting
  static void reset() {
    _instance._initialized = false;
    debugPrint('🔄 AppInitializer reseteado');
  }
}
