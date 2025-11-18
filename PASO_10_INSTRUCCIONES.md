# PASO 10: Configuración de Temas y Estilos

## Proyecto: BuscaGas - Localizador de Gasolineras Económicas en España

---

## ÍNDICE

1. [Objetivo del Paso 10](#objetivo-del-paso-10)
2. [Contexto Arquitectónico](#contexto-arquitectónico)
3. [Requisitos de Diseño](#requisitos-de-diseño)
4. [Estructura de Archivos](#estructura-de-archivos)
5. [Implementación de Colores](#implementación-de-colores)
6. [Implementación de Temas](#implementación-de-temas)
7. [Integración con Configuración de Usuario](#integración-con-configuración-de-usuario)
8. [Verificación y Pruebas](#verificación-y-pruebas)
9. [Checklist de Implementación](#checklist-de-implementación)

---

## OBJETIVO DEL PASO 10

### Descripción General
Implementar el sistema de temas visuales (claro y oscuro) con paleta de colores específica para la aplicación, garantizando accesibilidad y coherencia visual en toda la interfaz.

### Objetivos Específicos

1. **Definir Paleta de Colores**:
   - Colores para rangos de precios (verde, amarillo, rojo)
   - Colores primarios y secundarios de la aplicación
   - Variantes para modo claro y oscuro
   - Colores de estado (error, éxito, advertencia, info)

2. **Implementar Temas Flutter**:
   - ThemeData para modo claro
   - ThemeData para modo oscuro
   - Configuración de tipografía legible
   - Estilos de componentes (AppBar, Cards, Buttons)

3. **Gestión Dinámica de Temas**:
   - Alternar entre modo claro/oscuro
   - Persistir preferencia de usuario
   - Aplicar tema globalmente en la aplicación

### Requisitos Previos Completados
- ✅ Paso 3: Entidades implementadas (AppSettings con campo darkMode)
- ✅ Paso 9: Servicios implementados (almacenamiento de preferencias)

---

## CONTEXTO ARQUITECTÓNICO

### Ubicación en Clean Architecture

```
┌───────────────────────────────────────────────────────────┐
│                   CAPA DE PRESENTACIÓN                    │
│  ┌─────────────────────────────────────────────────────┐  │  ◄── ESTAMOS AQUÍ
│  │          MaterialApp (ThemeData)                    │  │
│  │          - lightTheme                               │  │
│  │          - darkTheme                                │  │
│  │          - themeMode (light/dark/system)            │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
                      │ usa
                      ▼
┌───────────────────────────────────────────────────────────┐
│                        CORE                               │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  theme/                                             │  │
│  │  - app_theme.dart (ThemeData configurations)        │  │
│  │  - colors.dart (Color constants)                    │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
                      │ persiste preferencia
                      ▼
┌───────────────────────────────────────────────────────────┐
│                   DOMINIO (ENTIDADES)                     │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  AppSettings                                        │  │
│  │  - bool darkMode                                    │  │
│  │  - save() / load()                                  │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### Responsabilidades del Sistema de Temas

**Paleta de Colores (`colors.dart`):**
- Definir constantes de color para toda la aplicación
- Colores para rangos de precios (bajo, medio, alto)
- Colores primarios y de acento
- Colores de estado y feedback
- Variantes para ambos modos (claro/oscuro)

**Configuración de Temas (`app_theme.dart`):**
- Crear ThemeData para modo claro
- Crear ThemeData para modo oscuro
- Configurar tipografía Material Design 3
- Definir estilos de componentes (AppBar, Card, Button, etc.)
- Garantizar contraste adecuado para accesibilidad

**Integración con MaterialApp:**
- Aplicar temas globalmente
- Responder a cambios de preferencia del usuario
- Transiciones suaves entre temas

---

## REQUISITOS DE DISEÑO

### Requisitos Funcionales

**RF-06: Configuración (Extracto)**
- Alternancia entre modo claro/oscuro
- Preferencia debe persistir entre sesiones
- Aplicación inmediata al cambiar

**RF-07: Experiencia Inicial**
- Solicitud de preferencia de tema claro/oscuro (solo primera ejecución)

### Requisitos No Funcionales

**RNF-02: Usabilidad**
- Interfaz minimalista y clara
- Tipografía legible con precios destacados
- Precios en negrita y tamaño mayor

**RNF-06: Accesibilidad**
- Contraste adecuado en ambos modos (claro/oscuro)
- Tamaño de texto legible sin zoom
- Cumplir con WCAG 2.1 nivel AA mínimo

### Especificaciones de Diseño

**Paleta de Colores - Rangos de Precio:**
- **Verde (Precio Bajo)**: `#4CAF50` / `#66BB6A` (modo oscuro)
- **Amarillo/Naranja (Precio Medio)**: `#FF9800` / `#FFA726` (modo oscuro)
- **Rojo (Precio Alto)**: `#F44336` / `#EF5350` (modo oscuro)

**Colores Primarios:**
- **Primary (Azul)**: `#1976D2` / `#42A5F5` (modo oscuro)
- **Secondary (Verde)**: `#388E3C` / `#66BB6A` (modo oscuro)

**Tipografía:**
- Familia: Roboto (Material Design default)
- Tamaños:
  - Título grande: 24px
  - Título pantalla: 20px
  - Cuerpo: 16px
  - Precios: 20px (bold)
  - Subtítulos: 14px

**Contraste:**
- Ratio mínimo 4.5:1 para texto normal
- Ratio mínimo 3:1 para texto grande (>18px)

---

## ESTRUCTURA DE ARCHIVOS

### Directorios a Crear

```
lib/
└── core/
    └── theme/
        ├── app_theme.dart
        └── colors.dart
```

### Descripción de Archivos

| Archivo | Propósito | Contenido |
|---------|-----------|-----------|
| `colors.dart` | Constantes de color | Paleta completa de colores, rangos de precios, estados |
| `app_theme.dart` | Configuración de temas | ThemeData para modos claro y oscuro, tipografía, componentes |

---

## IMPLEMENTACIÓN DE COLORES

### Archivo: `lib/core/theme/colors.dart`

```dart
import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación BuscaGas
/// 
/// Define colores para:
/// - Rangos de precios (bajo, medio, alto)
/// - Colores primarios y de acento
/// - Estados de la aplicación
/// - Variantes para modo claro y oscuro
class AppColors {
  // Prevenir instanciación
  AppColors._();
  
  // ============================================================
  // RANGOS DE PRECIO
  // ============================================================
  
  /// Color para precios bajos (verde)
  static const Color priceLowLight = Color(0xFF4CAF50);
  static const Color priceLowDark = Color(0xFF66BB6A);
  
  /// Color para precios medios (naranja)
  static const Color priceMediumLight = Color(0xFFFF9800);
  static const Color priceMediumDark = Color(0xFFFFA726);
  
  /// Color para precios altos (rojo)
  static const Color priceHighLight = Color(0xFFF44336);
  static const Color priceHighDark = Color(0xFFEF5350);
  
  // ============================================================
  // COLORES PRIMARIOS
  // ============================================================
  
  /// Color primario de la aplicación (azul)
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF42A5F5);
  
  /// Color secundario de la aplicación (verde)
  static const Color secondaryLight = Color(0xFF388E3C);
  static const Color secondaryDark = Color(0xFF66BB6A);
  
  /// Color de acento (para botones flotantes, etc.)
  static const Color accentLight = Color(0xFF2196F3);
  static const Color accentDark = Color(0xFF64B5F6);
  
  // ============================================================
  // FONDOS Y SUPERFICIES
  // ============================================================
  
  /// Color de fondo principal
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  
  /// Color de superficie (cards, dialogs)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  /// Color de superficie elevada (app bar, etc.)
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark = Color(0xFF2C2C2C);
  
  // ============================================================
  // TEXTOS
  // ============================================================
  
  /// Color de texto principal
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  
  /// Color de texto secundario
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  /// Color de texto deshabilitado
  static const Color textDisabledLight = Color(0xFFBDBDBD);
  static const Color textDisabledDark = Color(0xFF616161);
  
  // ============================================================
  // ESTADOS
  // ============================================================
  
  /// Color para estados de error
  static const Color errorLight = Color(0xFFD32F2F);
  static const Color errorDark = Color(0xFFEF5350);
  
  /// Color para estados de éxito
  static const Color successLight = Color(0xFF388E3C);
  static const Color successDark = Color(0xFF66BB6A);
  
  /// Color para advertencias
  static const Color warningLight = Color(0xFFF57C00);
  static const Color warningDark = Color(0xFFFFB74D);
  
  /// Color para información
  static const Color infoLight = Color(0xFF1976D2);
  static const Color infoDark = Color(0xFF42A5F5);
  
  // ============================================================
  // DIVISORES Y BORDES
  // ============================================================
  
  /// Color de divisores
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);
  
  /// Color de bordes
  static const Color borderLight = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF616161);
  
  // ============================================================
  // OVERLAY Y SOMBRAS
  // ============================================================
  
  /// Color de overlay (diálogos, bottom sheets)
  static const Color overlayLight = Color(0x99000000);
  static const Color overlayDark = Color(0xCC000000);
  
  /// Color de sombra
  static const Color shadowLight = Color(0x1F000000);
  static const Color shadowDark = Color(0x3F000000);
  
  // ============================================================
  // MARCADORES DE MAPA
  // ============================================================
  
  /// Color de ubicación del usuario en el mapa
  static const Color userLocationMarker = Color(0xFF2196F3);
  
  /// Color de marcador seleccionado
  static const Color markerSelectedLight = Color(0xFF1565C0);
  static const Color markerSelectedDark = Color(0xFF42A5F5);
}
```

---

## IMPLEMENTACIÓN DE TEMAS

### Archivo: `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

/// Configuración de temas de la aplicación BuscaGas
/// 
/// Proporciona:
/// - Tema claro (light theme)
/// - Tema oscuro (dark theme)
/// - Tipografía consistente
/// - Estilos de componentes
class AppTheme {
  // Prevenir instanciación
  AppTheme._();
  
  // ============================================================
  // TEMA CLARO
  // ============================================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      // Configuración de brillo
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Paleta de colores
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceLight,
        background: AppColors.backgroundLight,
        error: AppColors.errorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onBackground: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),
      
      // Fondo de scaffold
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceElevatedLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 2,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryLight,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: AppColors.surfaceLight,
        elevation: 4,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(8),
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones flotantes
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentLight,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.errorLight),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Divisores
      dividerTheme: DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      
      // Iconos
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryLight,
        size: 24,
      ),
      
      // Tipografía
      textTheme: _buildTextTheme(AppColors.textPrimaryLight),
      
      // Diálogos
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 8,
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primaryLight,
        disabledColor: AppColors.dividerLight,
        labelStyle: TextStyle(color: AppColors.textPrimaryLight),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // ============================================================
  // TEMA OSCURO
  // ============================================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      // Configuración de brillo
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Paleta de colores
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundDark,
        error: AppColors.errorDark,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimaryDark,
        onBackground: AppColors.textPrimaryDark,
        onError: Colors.black,
      ),
      
      // Fondo de scaffold
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceElevatedDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 2,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimaryDark,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 4,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(8),
      ),
      
      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Botones flotantes
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentDark,
        foregroundColor: Colors.black,
        elevation: 6,
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.errorDark),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Divisores
      dividerTheme: DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      
      // Iconos
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryDark,
        size: 24,
      ),
      
      // Tipografía
      textTheme: _buildTextTheme(AppColors.textPrimaryDark),
      
      // Diálogos
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 8,
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primaryDark,
        disabledColor: AppColors.dividerDark,
        labelStyle: TextStyle(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: TextStyle(color: Colors.black),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // ============================================================
  // TIPOGRAFÍA
  // ============================================================
  
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Títulos grandes
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: 0,
      ),
      
      // Encabezados
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      
      // Títulos
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),
      
      // Cuerpo de texto
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textColor,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      
      // Etiquetas
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }
  
  // ============================================================
  // ESTILOS PERSONALIZADOS
  // ============================================================
  
  /// Estilo para precios destacados
  static TextStyle priceTextStyle(BuildContext context, {bool isDark = false}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      letterSpacing: 0.15,
    );
  }
  
  /// Estilo para distancias
  static TextStyle distanceTextStyle(BuildContext context, {bool isDark = false}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      letterSpacing: 0.25,
    );
  }
  
  /// Estilo para nombres de gasolineras
  static TextStyle stationNameTextStyle(BuildContext context, {bool isDark = false}) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      letterSpacing: 0.15,
    );
  }
}
```

---

## INTEGRACIÓN CON CONFIGURACIÓN DE USUARIO

### Modificar `main.dart` para Aplicar Temas

```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/app_settings.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar configuración de usuario
  final appSettings = await AppSettings.load();
  
  runApp(MyApp(settings: appSettings));
}

class MyApp extends StatefulWidget {
  final AppSettings settings;
  
  const MyApp({Key? key, required this.settings}) : super(key: key);
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.settings.darkMode;
  }
  
  void toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
    widget.settings.darkMode = isDark;
    widget.settings.save();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuscaGas',
      debugShowCheckedModeBanner: false,
      
      // Aplicar temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Pantalla inicial
      home: SplashScreen(),
      
      // Rutas (se implementarán en pasos posteriores)
      routes: {
        '/map': (context) => Container(), // TODO: MapScreen
        '/settings': (context) => Container(), // TODO: SettingsScreen
      },
    );
  }
}
```

### Uso en Widgets

```dart
// Ejemplo: Obtener color de rango de precio según tema actual
class PriceRangeHelper {
  static Color getPriceRangeColor(BuildContext context, PriceRange range) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (range) {
      case PriceRange.low:
        return isDark ? AppColors.priceLowDark : AppColors.priceLowLight;
      case PriceRange.medium:
        return isDark ? AppColors.priceMediumDark : AppColors.priceMediumLight;
      case PriceRange.high:
        return isDark ? AppColors.priceHighDark : AppColors.priceHighLight;
    }
  }
}

// Ejemplo: Usar estilo de texto personalizado
class StationCard extends StatelessWidget {
  final GasStation station;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              station.name,
              style: AppTheme.stationNameTextStyle(context, isDark: isDark),
            ),
            Text(
              '${station.price} €/L',
              style: AppTheme.priceTextStyle(context, isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## VERIFICACIÓN Y PRUEBAS

### 1. Verificación Visual

**Checklist de Modo Claro:**
- [ ] Fondo principal: blanco/gris muy claro
- [ ] Texto principal: negro/gris oscuro
- [ ] Contraste adecuado (mínimo 4.5:1)
- [ ] AppBar con sombra sutil
- [ ] Cards con elevación visible
- [ ] Colores de precios distinguibles (verde, naranja, rojo)
- [ ] Botones con colores primarios

**Checklist de Modo Oscuro:**
- [ ] Fondo principal: negro/gris muy oscuro
- [ ] Texto principal: blanco/gris claro
- [ ] Contraste adecuado (mínimo 4.5:1)
- [ ] AppBar con superficie elevada
- [ ] Cards con superficie distinta del fondo
- [ ] Colores de precios ajustados para oscuro
- [ ] Botones legibles en fondo oscuro

### 2. Prueba de Accesibilidad

```dart
// test/core/theme/accessibility_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('Accesibilidad de Temas', () {
    test('Modo claro tiene contraste adecuado', () {
      // Verificar ratio de contraste texto sobre fondo
      final backgroundColor = AppColors.backgroundLight;
      final textColor = AppColors.textPrimaryLight;
      
      final contrastRatio = _calculateContrastRatio(backgroundColor, textColor);
      
      expect(contrastRatio, greaterThan(4.5)); // WCAG AA
    });
    
    test('Modo oscuro tiene contraste adecuado', () {
      final backgroundColor = AppColors.backgroundDark;
      final textColor = AppColors.textPrimaryDark;
      
      final contrastRatio = _calculateContrastRatio(backgroundColor, textColor);
      
      expect(contrastRatio, greaterThan(4.5));
    });
    
    test('Precios tienen contraste adecuado en modo claro', () {
      final backgroundColor = AppColors.surfaceLight;
      
      final greenContrast = _calculateContrastRatio(
        backgroundColor,
        AppColors.priceLowLight,
      );
      final orangeContrast = _calculateContrastRatio(
        backgroundColor,
        AppColors.priceMediumLight,
      );
      final redContrast = _calculateContrastRatio(
        backgroundColor,
        AppColors.priceHighLight,
      );
      
      expect(greenContrast, greaterThan(3.0)); // Texto grande
      expect(orangeContrast, greaterThan(3.0));
      expect(redContrast, greaterThan(3.0));
    });
  });
  
  // Función auxiliar para calcular ratio de contraste
  double _calculateContrastRatio(Color color1, Color color2) {
    final l1 = _relativeLuminance(color1);
    final l2 = _relativeLuminance(color2);
    
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  double _relativeLuminance(Color color) {
    final r = _linearize(color.red / 255);
    final g = _linearize(color.green / 255);
    final b = _linearize(color.blue / 255);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  double _linearize(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }
}
```

### 3. Prueba de Widget

```dart
// test/core/theme/theme_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App aplica tema claro correctamente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: Text('Test')),
          body: Text('Test'),
        ),
      ),
    );
    
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, AppColors.surfaceElevatedLight);
  });
  
  testWidgets('App aplica tema oscuro correctamente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          appBar: AppBar(title: Text('Test')),
          body: Text('Test'),
        ),
      ),
    );
    
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, AppColors.surfaceElevatedDark);
  });
}
```

### 4. Comandos de Verificación

```bash
# Verificar compilación sin errores
flutter analyze

# Ejecutar pruebas unitarias
flutter test

# Verificar en hot reload (en emulador)
flutter run
```

---

## CHECKLIST DE IMPLEMENTACIÓN

### Tareas Principales

- [ ] **1. Crear estructura de directorios**
  - [ ] Crear `lib/core/theme/`

- [ ] **2. Implementar paleta de colores**
  - [ ] Crear archivo `lib/core/theme/colors.dart`
  - [ ] Definir colores de rangos de precios (bajo, medio, alto)
  - [ ] Definir colores primarios y secundarios
  - [ ] Definir colores de fondo y superficies
  - [ ] Definir colores de texto
  - [ ] Definir colores de estados (error, éxito, advertencia, info)
  - [ ] Definir colores de UI (divisores, bordes, sombras)
  - [ ] Documentar todos los colores con comentarios

- [ ] **3. Implementar configuración de temas**
  - [ ] Crear archivo `lib/core/theme/app_theme.dart`
  - [ ] Implementar `lightTheme` (ThemeData completo)
  - [ ] Implementar `darkTheme` (ThemeData completo)
  - [ ] Configurar AppBarTheme para ambos modos
  - [ ] Configurar CardTheme
  - [ ] Configurar ButtonThemes (Elevated, Text, Floating)
  - [ ] Configurar InputDecorationTheme
  - [ ] Implementar `_buildTextTheme()` con tipografía completa
  - [ ] Implementar estilos personalizados (precios, distancias, nombres)
  - [ ] Documentar todos los estilos

- [ ] **4. Integrar con MaterialApp**
  - [ ] Modificar `main.dart` para cargar AppSettings
  - [ ] Aplicar `theme` y `darkTheme` en MaterialApp
  - [ ] Configurar `themeMode` según preferencia de usuario
  - [ ] Implementar función para cambiar tema dinámicamente

- [ ] **5. Verificar accesibilidad**
  - [ ] Verificar ratios de contraste (WCAG AA mínimo 4.5:1)
  - [ ] Probar con modo claro en emulador
  - [ ] Probar con modo oscuro en emulador
  - [ ] Verificar legibilidad de todos los textos
  - [ ] Verificar diferenciación de colores de precios

- [ ] **6. Escribir pruebas**
  - [ ] Tests de contraste de colores
  - [ ] Tests de aplicación de temas
  - [ ] Tests de widget con temas

- [ ] **7. Verificar compilación**
  - [ ] Ejecutar `flutter analyze` sin errores
  - [ ] Ejecutar `flutter test` exitosamente
  - [ ] Probar hot reload con cambio de tema

### Criterios de Aceptación

✅ **Paso 10 completado cuando:**
1. Paleta de colores completa implementada en `colors.dart`
2. Temas claro y oscuro configurados en `app_theme.dart`
3. Tipografía Material Design 3 aplicada correctamente
4. Contraste de colores cumple WCAG 2.1 nivel AA
5. Temas se aplican globalmente en MaterialApp
6. Preferencia de tema se persiste en AppSettings
7. Cambio de tema funciona dinámicamente
8. Todos los componentes (AppBar, Card, Button) estilizados
9. Pruebas de accesibilidad pasan exitosamente
10. `flutter analyze` no muestra errores

---

## NOTAS IMPORTANTES

### Mejores Prácticas

**Colores:**
1. **Usar constantes** en lugar de valores hardcodeados
2. **Proporcionar variantes** para modo claro y oscuro
3. **Documentar propósito** de cada color
4. **Verificar contraste** antes de usar combinaciones
5. **Usar semántica** (success, error, warning) en lugar de nombres de color

**Temas:**
1. **Configurar Material 3** con `useMaterial3: true`
2. **Usar ColorScheme** en lugar de colores directos
3. **Aplicar estilos consistentes** a todos los componentes
4. **Evitar override** de estilos en widgets individuales
5. **Documentar customizaciones** específicas de la app

### Errores Comunes a Evitar

❌ **No hacer:**
- Usar colores hardcodeados en widgets (ej: `Colors.red`)
- Ignorar contraste en modo oscuro
- Crear temas que no son accesibles
- Mezclar Material 2 y Material 3
- Olvidar persistir preferencia de tema

✅ **Hacer:**
- Usar `Theme.of(context).colorScheme.primary`
- Verificar contraste con herramientas WCAG
- Probar con usuarios reales en ambos modos
- Usar Material 3 consistentemente
- Guardar preferencia en AppSettings

### Recursos de Accesibilidad

**Herramientas de Verificación:**
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Color Contrast Analyzer](https://www.tpgi.com/color-contrast-checker/)
- Flutter DevTools (Accessibility Inspector)

**Ratios de Contraste WCAG:**
- Texto normal (< 18px): Mínimo 4.5:1
- Texto grande (≥ 18px o ≥ 14px bold): Mínimo 3:1
- Nivel AAA: 7:1 (texto normal), 4.5:1 (texto grande)

### Material Design 3

**Recursos:**
- [Material Design 3](https://m3.material.io/)
- [Flutter Material 3](https://docs.flutter.dev/ui/design/material)
- [Color System](https://m3.material.io/styles/color/system/overview)
- [Typography](https://m3.material.io/styles/typography/overview)

---

**Fecha de creación:** 18 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3  
**Paso:** 10 de 28
