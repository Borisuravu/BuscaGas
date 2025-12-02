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
