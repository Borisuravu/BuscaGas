/// Entidad de dominio: Configuración de la Aplicación
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('searchRadius', searchRadius);
    await prefs.setString('preferredFuel', preferredFuel.name);
    await prefs.setBool('darkMode', darkMode);
    if (lastUpdateTimestamp != null) {
      await prefs.setString('lastUpdateTimestamp', lastUpdateTimestamp!.toIso8601String());
    }
  }
  
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    FuelType loadedFuel = FuelType.gasolina95;
    final fuelName = prefs.getString('preferredFuel');
    if (fuelName != null) {
      try {
        loadedFuel = FuelType.values.firstWhere((e) => e.name == fuelName);
      } catch (_) {
        loadedFuel = FuelType.gasolina95;
      }
    }
    
    DateTime? timestamp;
    final timestampStr = prefs.getString('lastUpdateTimestamp');
    if (timestampStr != null) {
      try {
        timestamp = DateTime.parse(timestampStr);
      } catch (_) {
        timestamp = null;
      }
    }
    
    return AppSettings(
      searchRadius: prefs.getInt('searchRadius') ?? 10,
      preferredFuel: loadedFuel,
      darkMode: prefs.getBool('darkMode') ?? false,
      lastUpdateTimestamp: timestamp,
    );
  }
}
