import 'package:flutter/material.dart';
import 'package:buscagas/core/theme/app_theme.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/presentation/screens/splash_screen.dart';
import 'package:buscagas/presentation/screens/map_screen.dart';
import 'package:buscagas/presentation/screens/settings_screen.dart';

/// Punto de entrada de la aplicación BuscaGas
void main() {
  runApp(const BuscaGasApp());
}

/// Widget raíz de la aplicación
class BuscaGasApp extends StatelessWidget {
  const BuscaGasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // TODO: Implement - Configurar temas claro y oscuro
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Por defecto, cambiar según preferencias
      
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
