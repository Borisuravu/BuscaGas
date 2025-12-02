import 'package:equatable/equatable.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/entities/fuel_type.dart';

/// Clase base para todos los eventos del mapa
abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar datos del mapa con ubicación específica
class LoadMapData extends MapEvent {
  final double latitude;
  final double longitude;

  const LoadMapData({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Evento: Cambiar tipo de combustible seleccionado
class ChangeFuelType extends MapEvent {
  final FuelType fuelType;

  const ChangeFuelType({required this.fuelType});

  @override
  List<Object?> get props => [fuelType];
}

/// Evento: Recentrar mapa en ubicación actual
class RecenterMap extends MapEvent {
  const RecenterMap();
}

/// Evento: Actualizar datos desde la API
class RefreshMapData extends MapEvent {
  const RefreshMapData();
}

/// Evento: Seleccionar una gasolinera en el mapa
class SelectStation extends MapEvent {
  final GasStation? station; // null para deseleccionar

  const SelectStation({this.station});

  @override
  List<Object?> get props => [station];
}

/// Evento: Cambiar radio de búsqueda (cuando se modifica desde configuración)
class ChangeSearchRadius extends MapEvent {
  final int radiusKm;

  const ChangeSearchRadius({required this.radiusKm});

  @override
  List<Object?> get props => [radiusKm];
}
