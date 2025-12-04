import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/errors/app_error.dart';
import '../../../domain/usecases/get_nearby_stations.dart';
import '../../../domain/usecases/filter_by_fuel_type.dart';
import '../../../domain/usecases/calculate_distance.dart';
import '../../../domain/usecases/assign_price_range.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../services/location_service.dart';
import 'map_event.dart';
import 'map_state.dart';

/// BLoC para gestionar el estado del mapa principal
/// 
/// Optimizaciones implementadas:
/// - Límite de 50 marcadores para mantener 60 FPS en el mapa
/// - Ordenamiento por distancia para mostrar las gasolineras más cercanas
/// - Filtrado por tipo de combustible preferido
/// - Clasificación por rangos de precio
class MapBloc extends Bloc<MapEvent, MapState> {
  /// Límite máximo de marcadores en el mapa para mantener rendimiento óptimo
  /// 
  /// Valor recomendado: 50 marcadores
  /// - Mantiene 60 FPS en dispositivos de gama media/baja
  /// - Reduce uso de memoria y batería
  /// - Muestra solo las gasolineras más cercanas y relevantes
  static const int maxMarkersOnMap = 50;
  final GetNearbyStationsUseCase _getNearbyStations;
  final FilterByFuelTypeUseCase _filterByFuelType;
  final CalculateDistanceUseCase _calculateDistance;
  final AssignPriceRangeUseCase _assignPriceRange;
  final AppSettings _settings;
  final LocationService _locationService;

  MapBloc({
    required GetNearbyStationsUseCase getNearbyStations,
    required FilterByFuelTypeUseCase filterByFuelType,
    required CalculateDistanceUseCase calculateDistance,
    required AssignPriceRangeUseCase assignPriceRange,
    required AppSettings settings,
    required LocationService locationService,
  })  : _getNearbyStations = getNearbyStations,
        _filterByFuelType = filterByFuelType,
        _calculateDistance = calculateDistance,
        _assignPriceRange = assignPriceRange,
        _settings = settings,
        _locationService = locationService,
        super(const MapInitial()) {
    // Registrar handlers para cada evento
    on<LoadMapData>(_onLoadMapData);
    on<ChangeFuelType>(_onChangeFuelType);
    on<RecenterMap>(_onRecenterMap);
    on<RefreshMapData>(_onRefreshMapData);
    on<SelectStation>(_onSelectStation);
    on<ChangeSearchRadius>(_onChangeSearchRadius);
  }

  /// Handler: Cargar datos del mapa
  Future<void> _onLoadMapData(
    LoadMapData event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());

    try {
      // 1. Obtener gasolineras cercanas
      List<GasStation> stations = await _getNearbyStations.call(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: _settings.searchRadius.toDouble(),
      );

      // 2. Filtrar por combustible preferido
      stations = _filterByFuelType.call(
        stations: stations,
        fuelType: _settings.preferredFuel,
      );

      // 3. Calcular distancias
      for (var station in stations) {
        station.distance = _calculateDistance.call(
          lat1: event.latitude,
          lon1: event.longitude,
          lat2: station.latitude,
          lon2: station.longitude,
        );
      }

      // 4. Ordenar por distancia
      stations.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

      // 5. Limitar a 50 marcadores más cercanos (optimización de rendimiento)
      // Esto mantiene 60 FPS en el mapa y reduce el uso de memoria
      if (stations.length > maxMarkersOnMap) {
        stations = stations.sublist(0, maxMarkersOnMap);
      }

      // 6. Clasificar por rangos de precio
      _assignPriceRange.call(
        stations: stations,
        fuelType: _settings.preferredFuel,
      );

      // 7. Emitir estado cargado
      emit(MapLoaded(
        stations: stations,
        currentFuelType: _settings.preferredFuel,
        currentLatitude: event.latitude,
        currentLongitude: event.longitude,
        searchRadiusKm: _settings.searchRadius,
      ));
    } catch (e, stackTrace) {
      emit(MapError(
        error: AppError.network(
          message: 'Error al cargar datos del mapa',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
    }
  }

  /// Handler: Cambiar tipo de combustible
  Future<void> _onChangeFuelType(
    ChangeFuelType event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) return;

    final currentState = state as MapLoaded;

    try {
      // 1. Volver a filtrar con nuevo tipo de combustible
      final List<GasStation> filteredStations = _filterByFuelType.call(
        stations: currentState.stations,
        fuelType: event.fuelType,
      );

      // 2. Reclasificar por rangos de precio
      _assignPriceRange.call(
        stations: filteredStations,
        fuelType: event.fuelType,
      );

      // 3. Emitir nuevo estado
      emit(currentState.copyWith(
        stations: filteredStations,
        currentFuelType: event.fuelType,
        clearSelection: true,
      ));
    } catch (e, stackTrace) {
      emit(MapError(
        error: AppError.data(
          message: 'Error al filtrar por tipo de combustible',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
    }
  }

  /// Handler: Recentrar mapa
  Future<void> _onRecenterMap(
    RecenterMap event,
    Emitter<MapState> emit,
  ) async {
    try {
      // Usar el servicio de ubicación
      final Position position = await _locationService.getCurrentPosition();

      // Recargar datos con nueva ubicación
      add(LoadMapData(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } on LocationServiceDisabledException catch (e, stackTrace) {
      emit(MapError(
        error: AppError.permission(
          message: 'Servicio de ubicación deshabilitado. Por favor, activa el GPS.',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
    } on PermissionDeniedException {
      emit(const MapLocationPermissionDenied());
    } catch (e, stackTrace) {
      emit(MapError(
        error: AppError.permission(
          message: 'Error al obtener ubicación',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
    }
  }

  /// Handler: Actualizar datos
  Future<void> _onRefreshMapData(
    RefreshMapData event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) return;

    final currentState = state as MapLoaded;

    // Recargar con ubicación actual
    add(LoadMapData(
      latitude: currentState.currentLatitude,
      longitude: currentState.currentLongitude,
    ));
  }

  /// Handler: Seleccionar gasolinera
  void _onSelectStation(
    SelectStation event,
    Emitter<MapState> emit,
  ) {
    if (state is! MapLoaded) return;

    final currentState = state as MapLoaded;

    emit(currentState.copyWith(
      selectedStation: event.station,
    ));
  }

  /// Handler: Cambiar radio de búsqueda
  Future<void> _onChangeSearchRadius(
    ChangeSearchRadius event,
    Emitter<MapState> emit,
  ) async {
    if (state is! MapLoaded) return;

    final currentState = state as MapLoaded;

    // Actualizar configuración
    _settings.searchRadius = event.radiusKm;
    await _settings.save();

    // Recargar datos con nuevo radio
    add(LoadMapData(
      latitude: currentState.currentLatitude,
      longitude: currentState.currentLongitude,
    ));
  }
}
