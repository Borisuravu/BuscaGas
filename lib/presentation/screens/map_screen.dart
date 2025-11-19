import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/settings_screen.dart';

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
  Position? _currentPosition;
  FuelType _selectedFuel = FuelType.gasolina95;
  bool _isLoading = true;
  String? _errorMessage;
  
  // TODO: Añadir lista de gasolineras desde repositorio en pasos futuros
  // TODO: Añadir markers set en pasos futuros
  // TODO: Añadir selected station para tarjeta en pasos futuros
  
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
      setState(() {
        _errorMessage = 'Los servicios de ubicación están desactivados';
      });
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Permisos de ubicación denegados';
        });
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Permisos de ubicación denegados permanentemente.\n'
            'Por favor, actívalos en la configuración de la aplicación.';
      });
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // 1. Verificar permisos
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // 2. Obtener ubicación
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage = 'No se pudo obtener la ubicación';
          _isLoading = false;
        });
        return;
      }
      
      // 3. Cargar configuración de usuario
      final settings = await AppSettings.load();
      
      setState(() {
        _currentPosition = position;
        _selectedFuel = settings.preferredFuel;
        _isLoading = false;
      });
      
      // 4. TODO: Cargar gasolineras del repositorio en pasos futuros
      // await _loadGasStations();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar mapa: $e';
        _isLoading = false;
      });
    }
  }
  
  /// Recentrar el mapa en la ubicación actual
  Future<void> _recenterMap() async {
    if (_mapController == null) return;
    
    try {
      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Animar cámara a nueva posición
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13.0,
          ),
        ),
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      // TODO: Recargar gasolineras cercanas en pasos futuros
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    }
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
  Widget _buildFuelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildFuelButton(
              FuelType.gasolina95,
              'Gasolina 95',
              _selectedFuel == FuelType.gasolina95,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFuelButton(
              FuelType.dieselGasoleoA,
              'Diésel Gasóleo A',
              _selectedFuel == FuelType.dieselGasoleoA,
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
        setState(() {
          _selectedFuel = fuelType;
          // TODO: Actualizar marcadores según nuevo combustible en pasos futuros
        });
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
  
  /// Construir el mapa de Google Maps
  Widget _buildMap() {
    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 13.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // Usamos nuestro botón personalizado
      mapType: MapType.normal,
      zoomControlsEnabled: false, // Ocultamos controles por defecto
      // TODO: Añadir markers en pasos futuros
      // markers: _markers,
      // TODO: Añadir onTap para ocultar tarjeta en pasos futuros
      onTap: (_) {
        // Ocultar tarjeta flotante si está visible
      },
    );
  }
  
  /// Construir botón de recentrado
  Widget _buildRecenterButton() {
    return FloatingActionButton(
      onPressed: _recenterMap,
      tooltip: 'Mi ubicación',
      child: const Icon(Icons.my_location),
    );
  }
  
  /// Construir cuerpo principal con estados
  Widget _buildBody() {
    if (_isLoading) {
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
    
    if (_errorMessage != null) {
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
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeMap,
                child: const Text('Reintentar'),
              ),
              if (_errorMessage!.contains('permanentemente'))
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
    
    return Column(
      children: [
        _buildFuelSelector(),
        Expanded(child: _buildMap()),
        // TODO: Añadir tarjeta flotante si hay estación seleccionada en pasos futuros
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _isLoading || _errorMessage != null 
          ? null 
          : _buildRecenterButton(),
    );
  }
}
