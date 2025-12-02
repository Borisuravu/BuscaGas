import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/map_screen.dart';
import 'package:buscagas/services/database_service.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/main.dart' as main_app;

/// Pantalla de inicio (Splash Screen)
///
/// Responsabilidades:
/// - Mostrar logo de BuscaGas durante la carga inicial
/// - Detectar primera ejecución de la app
/// - Solicitar preferencia de tema (solo primera vez)
/// - Realizar carga inicial de datos
/// - Navegar a MapScreen automáticamente
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'Cargando datos...';
  double? _progress;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Verificar si es la primera ejecución de la app
  Future<bool> _isFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('first_run') ?? true;
    } catch (e) {
      debugPrint('Error verificando primera ejecución: $e');
      return true; // En caso de error, tratar como primera ejecución
    }
  }

  /// Marcar que la primera ejecución se ha completado
  Future<void> _setFirstRunComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_run', false);
    } catch (e) {
      debugPrint('Error guardando flag de primera ejecución: $e');
    }
  }

  /// Mostrar diálogo para seleccionar tema (claro/oscuro)
  Future<void> _showThemeDialog() async {
    final darkMode = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // No permitir cerrar tocando fuera
          builder: (context) => AlertDialog(
            title: const Text('Bienvenido a BuscaGas'),
            content: const Text('¿Prefieres tema claro u oscuro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('☀️ Claro'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('🌙 Oscuro'),
              ),
            ],
          ),
        ) ??
        false; // Default a false (claro) si se cierra de alguna forma

    try {
      // Guardar preferencia de tema
      final settings = await AppSettings.load();
      settings.darkMode = darkMode;
      await settings.save();

      // Recargar settings en la app principal para aplicar el tema
      main_app.appKey.currentState?.reloadSettings();
    } catch (e) {
      debugPrint('Error guardando preferencia de tema: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar configuración: $e')),
        );
      }
    }
  }

  /// Actualizar mensaje de estado en UI
  void _updateStatus(String message, {double? progress}) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _progress = progress;
      });
    }
  }

  /// Inicializar la aplicación
  Future<void> _initializeApp() async {
    try {
      // 1. Verificar si es primera ejecución
      _updateStatus('Iniciando aplicación...');
      final isFirstRun = await _isFirstRun();

      if (isFirstRun) {
        // Esperar un momento para que se vea el logo
        await Future.delayed(const Duration(milliseconds: 800));

        // 2. Mostrar diálogo de tema (solo primera vez)
        if (mounted) {
          await _showThemeDialog();
        }

        // 3. Marcar como completado
        await _setFirstRunComplete();
      }

      // 4. Inicializar base de datos
      _updateStatus('Inicializando base de datos...', progress: 0.2);
      try {
        final dbService = DatabaseService();
        await dbService.initialize();
        debugPrint('✅ Base de datos inicializada');
      } catch (e) {
        debugPrint('❌ Error inicializando BD: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al inicializar base de datos')),
          );
        }
      }

      // 5. Verificar y cargar datos de gasolineras
      await _loadGasStationsData();

      // 6. Navegar a MapScreen
      _updateStatus('Completado', progress: 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error en inicialización: $e');

      // En caso de error, intentar navegar de todos modos
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Esperar un poco para que se vea el mensaje
        await Future.delayed(const Duration(seconds: 2));

        // Intentar navegar
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MapScreen()),
          );
        }
      }
    }
  }

  /// Cargar datos de gasolineras desde API o caché
  Future<void> _loadGasStationsData() async {
    try {
      // Crear instancias necesarias
      final apiDataSource = ApiDataSource();
      final databaseDataSource = DatabaseDataSource();
      final repository = GasStationRepositoryImpl(
        apiDataSource,
        databaseDataSource,
      );

      // Verificar si hay datos en caché
      _updateStatus('Verificando caché local...', progress: 0.4);
      final cachedStations = await repository.getCachedStations();

      if (cachedStations.isEmpty) {
        // No hay caché, descargar desde API
        _updateStatus('Descargando gasolineras de España...', progress: 0.5);
        debugPrint('📡 Descargando datos desde API gubernamental...');

        try {
          final remoteStations = await repository.fetchRemoteStations();

          _updateStatus(
            'Guardando ${remoteStations.length} gasolineras...',
            progress: 0.8,
          );
          debugPrint(
              '💾 Guardando ${remoteStations.length} gasolineras en caché...');

          await repository.updateCache(remoteStations);

          _updateStatus(
            '✅ ${remoteStations.length} gasolineras listas',
            progress: 0.95,
          );
          debugPrint('✅ Datos guardados correctamente');

          // Pequeña pausa para que el usuario vea el mensaje de éxito
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('❌ Error descargando datos: $e');
          _updateStatus('Error descargando datos. Continuando...',
              progress: 0.9);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se pudieron descargar datos: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Esperar para que vea el error
          await Future.delayed(const Duration(seconds: 2));
        }
      } else {
        // Hay caché disponible
        _updateStatus(
          '✅ ${cachedStations.length} gasolineras en caché',
          progress: 0.95,
        );
        debugPrint(
            '✅ Usando caché local: ${cachedStations.length} gasolineras');
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      debugPrint('❌ Error cargando datos: $e');
      _updateStatus('Error cargando datos', progress: 0.9);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo (icono temporal de gasolinera)
            Icon(
              Icons.local_gas_station,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),

            // Nombre de la aplicación
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 40),

            // Indicador de carga (spinner o barra de progreso)
            if (_progress != null && _progress! > 0)
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            const SizedBox(height: 20),

            // Texto de carga
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
