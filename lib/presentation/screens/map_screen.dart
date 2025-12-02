import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/presentation/screens/settings_screen.dart';
import 'package:buscagas/presentation/blocs/map/map_bloc.dart';
import 'package:buscagas/presentation/blocs/map/map_event.dart';
import 'package:buscagas/presentation/blocs/map/map_state.dart';
import 'package:buscagas/presentation/widgets/station_info_card.dart';

/// Pantalla principal con mapa interactivo
///
/// Responsabilidades:
/// - Mostrar Google Maps centrado en ubicación del usuario
/// - Renderizar marcadores de gasolineras con colores
/// - Gestionar selector de combustible
/// - Mostrar/ocultar tarjeta flotante
/// - Manejar botón de recentrado
/// - Solicitar permisos de ubicación
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Verificar si los permisos de ubicación están concedidos
  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtener la ubicación actual del usuario
  Future<Position?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Inicializar el mapa y cargar datos
  Future<void> _initializeMap() async {
    try {
      // 1. Verificar permisos
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        return;
      }

      // 2. Obtener ubicación
      final position = await _getCurrentLocation();
      if (position == null) {
        return;
      }

      // 3. Disparar evento BLoC para cargar datos
      if (mounted) {
        context.read<MapBloc>().add(LoadMapData(
              latitude: position.latitude,
              longitude: position.longitude,
            ));
      }
    } catch (e) {
      debugPrint('Error al inicializar mapa: $e');
    }
  }

  /// Recentrar el mapa en la ubicación actual
  Future<void> _recenterMap() async {
    context.read<MapBloc>().add(const RecenterMap());
  }

  /// Manejar error de permisos con diálogo
  Future<void> _handleLocationError() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de Ubicación'),
        content: const Text(
          'Esta aplicación necesita acceso a tu ubicación para '
          'mostrarte gasolineras cercanas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  /// Construir AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppConstants.appName),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          tooltip: 'Configuración',
        ),
      ],
    );
  }

  /// Construir selector de combustible
  Widget _buildFuelSelector(FuelType currentFuel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildFuelButton(
              FuelType.gasolina95,
              'Gasolina 95',
              currentFuel == FuelType.gasolina95,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFuelButton(
              FuelType.dieselGasoleoA,
              'Diésel Gasóleo A',
              currentFuel == FuelType.dieselGasoleoA,
            ),
          ),
        ],
      ),
    );
  }

  /// Construir botón individual de combustible
  Widget _buildFuelButton(FuelType fuelType, String label, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        context.read<MapBloc>().add(ChangeFuelType(fuelType: fuelType));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        elevation: isSelected ? 4 : 1,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Construir el mapa de Google Maps con marcadores
  Widget _buildMap(MapLoaded state) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              state.currentLatitude,
              state.currentLongitude,
            ),
            zoom: 13.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          markers: _buildMarkers(state.stations, state.currentFuelType),
          onTap: (_) => _onMapTapped(),
        ),

        // Tarjeta flotante si hay estación seleccionada
        if (state.selectedStation != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: StationInfoCard(
              station: state.selectedStation!,
              selectedFuel: state.currentFuelType,
              onClose: () => _onCloseCard(),
            ),
          ),
      ],
    );
  }

  /// Construir marcadores dinámicamente
  Set<Marker> _buildMarkers(List<GasStation> stations, FuelType fuelType) {
    return stations.map((station) {
      final price = station.getPriceForFuel(fuelType);
      final color = station.priceRange?.color ?? Colors.grey;

      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(color),
        ),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: price != null
              ? '${price.toStringAsFixed(3)} €/L - ${station.distance?.toStringAsFixed(1)} km'
              : 'Precio no disponible',
        ),
        onTap: () => _onMarkerTapped(station),
      );
    }).toSet();
  }

  /// Obtener color de marcador según precio
  double _getMarkerHue(Color color) {
    if (color == Colors.green || color.value == 0xFF4CAF50) {
      return BitmapDescriptor.hueGreen;
    }
    if (color == Colors.orange || color.value == 0xFFFF9800) {
      return BitmapDescriptor.hueOrange;
    }
    if (color == Colors.red || color.value == 0xFFF44336) {
      return BitmapDescriptor.hueRed;
    }
    return BitmapDescriptor.hueAzure;
  }

  /// Callback cuando se toca un marcador
  void _onMarkerTapped(GasStation station) {
    context.read<MapBloc>().add(SelectStation(station: station));
  }

  /// Callback cuando se cierra la tarjeta
  void _onCloseCard() {
    context.read<MapBloc>().add(const SelectStation(station: null));
  }

  /// Callback cuando se toca el mapa
  void _onMapTapped() {
    final state = context.read<MapBloc>().state;
    if (state is MapLoaded && state.selectedStation != null) {
      _onCloseCard();
    }
  }

  /// Construir botón de recentrado
  Widget _buildRecenterButton() {
    return FloatingActionButton(
      onPressed: _recenterMap,
      tooltip: 'Mi ubicación',
      child: const Icon(Icons.my_location),
    );
  }

  /// Construir cuerpo principal con BLoC
  Widget _buildBody() {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        // Manejar errores
        if (state is MapError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is MapLocationPermissionDenied) {
          _handleLocationError();
        }
      },
      builder: (context, state) {
        if (state is MapLoading || state is MapInitial) {
          return _buildLoadingView();
        } else if (state is MapLoaded) {
          return _buildMapView(state);
        } else if (state is MapError) {
          return _buildErrorView(state.message);
        } else if (state is MapLocationPermissionDenied) {
          return _buildErrorView(
            'Permisos de ubicación denegados.\nPor favor, actívalos en la configuración.',
          );
        }
        return _buildLoadingView();
      },
    );
  }

  /// Vista de carga
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando mapa...'),
        ],
      ),
    );
  }

  /// Vista del mapa con datos
  Widget _buildMapView(MapLoaded state) {
    return Column(
      children: [
        _buildFuelSelector(state.currentFuelType),
        Expanded(child: _buildMap(state)),
      ],
    );
  }

  /// Vista de error
  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeMap,
              child: const Text('Reintentar'),
            ),
            if (message.contains('permanentemente') ||
                message.contains('denegados'))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: _handleLocationError,
                  child: const Text('Abrir Configuración'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildRecenterButton(),
    );
  }
}
