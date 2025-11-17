import 'package:flutter/material.dart';

/// Tema de la aplicación (claro y oscuro)
class AppTheme {
  // TODO: Implement - Configurar temas claro y oscuro
  
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    useMaterial3: true,
  );
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    useMaterial3: true,
  );
}
