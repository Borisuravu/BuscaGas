import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/map_screen.dart';
import 'package:buscagas/services/database_service.dart';
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
    ) ?? false; // Default a false (claro) si se cierra de alguna forma
    
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

  /// Inicializar la aplicación
  Future<void> _initializeApp() async {
    try {
      // 1. Verificar si es primera ejecución
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
      
      // 5. Carga inicial (opcional en este paso)
      // En este punto se podría cargar caché, verificar permisos, etc.
      // Por ahora solo esperamos para mostrar el logo
      await Future.delayed(const Duration(seconds: 1));
      
      // 6. Navegar a MapScreen
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
            
            // Indicador de carga (spinner)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Texto de carga
            Text(
              'Cargando datos...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
