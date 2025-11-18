import 'package:flutter/material.dart';
import 'package:buscagas/core/theme/app_theme.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/splash_screen.dart';
import 'package:buscagas/presentation/screens/map_screen.dart';
import 'package:buscagas/presentation/screens/settings_screen.dart';

/// Key global para acceder al estado de la app desde cualquier lugar
/// 
/// Nota: Este GlobalKey permite que otros widgets (como SplashScreen)
/// puedan notificar a la app principal para recargar settings
final GlobalKey<BuscaGasAppState> appKey = GlobalKey<BuscaGasAppState>();

/// Punto de entrada de la aplicación BuscaGas
void main() {
  runApp(BuscaGasApp(key: appKey));
}

/// Widget raíz de la aplicación
class BuscaGasApp extends StatefulWidget {
  const BuscaGasApp({super.key});

  @override
  BuscaGasAppState createState() => BuscaGasAppState();
}

class BuscaGasAppState extends State<BuscaGasApp> {
  AppSettings? _settings;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
    });
  }
  
  /// Método público para recargar settings desde otros widgets
  void reloadSettings() {
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Configuración de temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settings?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
      
      // TODO: Implement - Configurar rutas de navegación
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/map': (context) => const MapScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
