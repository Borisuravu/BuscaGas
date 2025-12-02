import 'package:equatable/equatable.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/entities/fuel_type.dart';

/// Clase base para todos los estados del mapa
abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

/// Estado: Carga inicial del mapa
class MapInitial extends MapState {
  const MapInitial();
}

/// Estado: Cargando datos (mostrar spinner)
class MapLoading extends MapState {
  const MapLoading();
}

/// Estado: Datos cargados exitosamente
class MapLoaded extends MapState {
  final List<GasStation> stations;
  final FuelType currentFuelType;
  final double currentLatitude;
  final double currentLongitude;
  final int searchRadiusKm;
  final GasStation? selectedStation;

  const MapLoaded({
    required this.stations,
    required this.currentFuelType,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.searchRadiusKm,
    this.selectedStation,
  });

  @override
  List<Object?> get props => [
        stations,
        currentFuelType,
        currentLatitude,
        currentLongitude,
        searchRadiusKm,
        selectedStation,
      ];

  /// Método helper para crear una copia con cambios
  MapLoaded copyWith({
    List<GasStation>? stations,
    FuelType? currentFuelType,
    double? currentLatitude,
    double? currentLongitude,
    int? searchRadiusKm,
    GasStation? selectedStation,
    bool clearSelection = false,
  }) {
    return MapLoaded(
      stations: stations ?? this.stations,
      currentFuelType: currentFuelType ?? this.currentFuelType,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      selectedStation:
          clearSelection ? null : (selectedStation ?? this.selectedStation),
    );
  }
}

/// Estado: Error al cargar datos
class MapError extends MapState {
  final String message;

  const MapError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado: Sin permisos de ubicación
class MapLocationPermissionDenied extends MapState {
  const MapLocationPermissionDenied();
}
