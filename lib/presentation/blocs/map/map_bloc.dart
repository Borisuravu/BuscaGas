import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/usecases/get_nearby_stations.dart';
import '../../../domain/usecases/filter_by_fuel_type.dart';
import '../../../domain/usecases/calculate_distance.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/entities/fuel_type.dart';
import '../../../domain/entities/price_range.dart';
import '../../../services/location_service.dart';
import 'map_event.dart';
import 'map_state.dart';

/// BLoC para gestionar el estado del mapa principal
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetNearbyStationsUseCase _getNearbyStations;
  final FilterByFuelTypeUseCase _filterByFuelType;
  final CalculateDistanceUseCase _calculateDistance;
  final AppSettings _settings;
  final LocationService _locationService;

  MapBloc({
    required GetNearbyStationsUseCase getNearbyStations,
    required FilterByFuelTypeUseCase filterByFuelType,
    required CalculateDistanceUseCase calculateDistance,
    required AppSettings settings,
    required LocationService locationService,
  })  : _getNearbyStations = getNearbyStations,
        _filterByFuelType = filterByFuelType,
        _calculateDistance = calculateDistance,
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
      if (stations.length > 50) {
        stations = stations.sublist(0, 50);
      }

      // 6. Clasificar por rangos de precio
      _assignPriceRanges(stations, _settings.preferredFuel);

      // 7. Emitir estado cargado
      emit(MapLoaded(
        stations: stations,
        currentFuelType: _settings.preferredFuel,
        currentLatitude: event.latitude,
        currentLongitude: event.longitude,
        searchRadiusKm: _settings.searchRadius,
      ));
    } catch (e) {
      emit(MapError(message: 'Error al cargar datos: ${e.toString()}'));
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
      List<GasStation> filteredStations = _filterByFuelType.call(
        stations: currentState.stations,
        fuelType: event.fuelType,
      );

      // 2. Reclasificar por rangos de precio
      _assignPriceRanges(filteredStations, event.fuelType);

      // 3. Emitir nuevo estado
      emit(currentState.copyWith(
        stations: filteredStations,
        currentFuelType: event.fuelType,
        clearSelection: true,
      ));
    } catch (e) {
      emit(MapError(message: 'Error al cambiar combustible: ${e.toString()}'));
    }
  }

  /// Handler: Recentrar mapa
  Future<void> _onRecenterMap(
    RecenterMap event,
    Emitter<MapState> emit,
  ) async {
    try {
      // Usar el servicio de ubicación
      Position position = await _locationService.getCurrentPosition();

      // Recargar datos con nueva ubicación
      add(LoadMapData(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } on LocationServiceDisabledException {
      emit(const MapError(
          message:
              'Servicio de ubicación deshabilitado. Por favor, activa el GPS.'));
    } on PermissionDeniedException {
      emit(const MapLocationPermissionDenied());
    } catch (e) {
      emit(MapError(message: 'Error al obtener ubicación: ${e.toString()}'));
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

  /// Método auxiliar: Clasificar gasolineras por rango de precio
  void _assignPriceRanges(List<GasStation> stations, FuelType fuelType) {
    // 1. Extraer precios válidos
    List<double> prices = stations
        .map((s) => s.getPriceForFuel(fuelType))
        .whereType<double>()
        .toList();

    if (prices.isEmpty) return;

    // 2. Calcular percentiles (33% y 66%)
    prices.sort();
    int count = prices.length;

    double p33 = prices[(count * 0.33).floor()];
    double p66 = prices[(count * 0.66).floor()];

    // 3. Asignar rangos
    for (var station in stations) {
      double? price = station.getPriceForFuel(fuelType);
      if (price == null) continue;

      if (price <= p33) {
        station.priceRange = PriceRange.low;
      } else if (price <= p66) {
        station.priceRange = PriceRange.medium;
      } else {
        station.priceRange = PriceRange.high;
      }
    }
  }
}
