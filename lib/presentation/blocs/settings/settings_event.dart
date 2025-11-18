import 'package:equatable/equatable.dart';
import '../../../domain/entities/fuel_type.dart';

/// Clase base para eventos de configuración
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  
  @override
  List<Object?> get props => [];
}

/// Evento: Cargar configuración guardada
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Evento: Cambiar radio de búsqueda
class ChangeSearchRadius extends SettingsEvent {
  final int radiusKm; // 5, 10, 20, 50
  
  const ChangeSearchRadius({required this.radiusKm});
  
  @override
  List<Object?> get props => [radiusKm];
}

/// Evento: Cambiar combustible preferido
class ChangePreferredFuel extends SettingsEvent {
  final FuelType fuelType;
  
  const ChangePreferredFuel({required this.fuelType});
  
  @override
  List<Object?> get props => [fuelType];
}

/// Evento: Alternar modo oscuro
class ToggleDarkMode extends SettingsEvent {
  final bool isDarkMode;
  
  const ToggleDarkMode({required this.isDarkMode});
  
  @override
  List<Object?> get props => [isDarkMode];
}

/// Evento: Restaurar valores por defecto
class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
