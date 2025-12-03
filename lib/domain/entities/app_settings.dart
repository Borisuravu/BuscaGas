/// Entidad de dominio: Configuración de la Aplicación
library;

import 'package:flutter/material.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

class AppSettings {
  int searchRadius; // 5, 10, 20, 50
  FuelType preferredFuel;
  bool darkMode;
  DateTime? lastUpdateTimestamp;

  AppSettings({
    this.searchRadius = 10,
    this.preferredFuel = FuelType.gasolina95,
    this.darkMode = false,
    this.lastUpdateTimestamp,
  });

  Future<void> save() async {
    try {
      final dbDataSource = DatabaseDataSource();

      // Guardar en base de datos
      await dbDataSource.updateSettings({
        'search_radius': searchRadius,
        'preferred_fuel': preferredFuel.name,
        'dark_mode': darkMode ? 1 : 0,
      });

      debugPrint('✅ Configuración guardada en BD');
    } catch (e) {
      debugPrint('❌ Error guardando configuración en BD: $e');
    }
  }

  static Future<AppSettings> load() async {
    try {
      final dbDataSource = DatabaseDataSource();
      final settings = await dbDataSource.getSettings();

      if (settings != null) {
        // Cargar desde base de datos
        FuelType fuelType = FuelType.gasolina95;
        try {
          fuelType = FuelType.values.firstWhere(
            (e) => e.name == settings['preferred_fuel'],
          );
        } catch (_) {
          fuelType = FuelType.gasolina95;
        }

        DateTime? timestamp;
        if (settings['last_api_sync'] != null) {
          try {
            timestamp = DateTime.parse(settings['last_api_sync'] as String);
          } catch (_) {
            timestamp = null;
          }
        }

        return AppSettings(
          searchRadius: settings['search_radius'] as int? ?? 10,
          preferredFuel: fuelType,
          darkMode: (settings['dark_mode'] as int? ?? 0) == 1,
          lastUpdateTimestamp: timestamp,
        );
      } else {
        // Si no hay datos en BD, devolver valores por defecto
        return AppSettings(
          searchRadius: 10,
          preferredFuel: FuelType.gasolina95,
          darkMode: false,
        );
      }
    } catch (e) {
      debugPrint('Error cargando configuración desde BD: $e');
      // Fallback a valores por defecto
      return AppSettings(
        searchRadius: 10,
        preferredFuel: FuelType.gasolina95,
        darkMode: false,
      );
    }
  }
}
