import 'package:equatable/equatable.dart';
import '../../../core/errors/app_error.dart';
import '../../../domain/entities/fuel_type.dart';

/// Clase base para estados de configuración
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Estado: Configuración inicial (cargando)
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Estado: Configuración cargada
class SettingsLoaded extends SettingsState {
  final int searchRadiusKm;
  final FuelType preferredFuel;
  final bool isDarkMode;
  final DateTime? lastSyncTimestamp;

  const SettingsLoaded({
    required this.searchRadiusKm,
    required this.preferredFuel,
    required this.isDarkMode,
    this.lastSyncTimestamp,
  });

  @override
  List<Object?> get props => [
        searchRadiusKm,
        preferredFuel,
        isDarkMode,
        lastSyncTimestamp,
      ];

  /// Método helper para crear copia con cambios
  SettingsLoaded copyWith({
    int? searchRadiusKm,
    FuelType? preferredFuel,
    bool? isDarkMode,
    DateTime? lastSyncTimestamp,
  }) {
    return SettingsLoaded(
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      preferredFuel: preferredFuel ?? this.preferredFuel,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
    );
  }
}

/// Estado: Error al cargar/guardar configuración
class SettingsError extends SettingsState {
  final AppError error;

  const SettingsError({required this.error});

  @override
  List<Object?> get props => [error];

  /// Getter de conveniencia para el mensaje
  String get message => error.message;
}
