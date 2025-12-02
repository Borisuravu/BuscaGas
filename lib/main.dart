import 'package:flutter/material.dart';
import 'package:buscagas/core/theme/app_theme.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/splash_screen.dart';
import 'package:buscagas/presentation/screens/map_screen.dart';
import 'package:buscagas/presentation/screens/settings_screen.dart';

/// Key global para acceder al estado de la app desde cualquier lugar
final GlobalKey<BuscaGasAppState> appKey = GlobalKey<BuscaGasAppState>();

/// Punto de entrada de la aplicación BuscaGas
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo cargar configuración (rápido, ~50ms)
  final settings = await AppSettings.load();

  // TODO: Resto de inicialización se hará en SplashScreen de forma asíncrona
  runApp(
    BuscaGasApp(
      key: appKey,
      initialSettings: settings,
    ),
  );
}

/// Widget raíz de la aplicación
class BuscaGasApp extends StatefulWidget {
  final AppSettings initialSettings;

  const BuscaGasApp({
    super.key,
    required this.initialSettings,
  });

  @override
  BuscaGasAppState createState() => BuscaGasAppState();
}

class BuscaGasAppState extends State<BuscaGasApp> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Método público para recargar settings desde otros widgets
  Future<void> reloadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Configuración de temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,

      // Configurar rutas de navegación
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/map': (context) => const MapScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
