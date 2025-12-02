import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscagas/core/theme/app_theme.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/splash_screen.dart';
import 'package:buscagas/presentation/screens/map_screen.dart';
import 'package:buscagas/presentation/screens/settings_screen.dart';
import 'package:buscagas/presentation/blocs/map/map_bloc.dart';
import 'package:buscagas/presentation/blocs/map/map_event.dart';
import 'package:buscagas/domain/usecases/get_nearby_stations.dart';
import 'package:buscagas/domain/usecases/filter_by_fuel_type.dart';
import 'package:buscagas/domain/usecases/calculate_distance.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';
import 'package:buscagas/services/location_service.dart';
import 'package:buscagas/services/data_sync_service.dart';

/// Key global para acceder al estado de la app desde cualquier lugar
final GlobalKey<BuscaGasAppState> appKey = GlobalKey<BuscaGasAppState>();

/// Punto de entrada de la aplicación BuscaGas
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos
  final databaseDataSource = DatabaseDataSource();
  await databaseDataSource.database; // Asegurar que la DB está creada

  // Crear data sources
  final apiDataSource = ApiDataSource();

  // Crear repositorio
  final repository = GasStationRepositoryImpl(
    apiDataSource,
    databaseDataSource,
  );

  // Cargar configuración inicial
  final settings = await AppSettings.load();

  // Crear casos de uso
  final getNearbyStations = GetNearbyStationsUseCase(repository);
  final filterByFuelType = FilterByFuelTypeUseCase();
  final calculateDistance = CalculateDistanceUseCase();
  final locationService = LocationService();

  // Crear servicio de sincronización automática
  final dataSyncService = DataSyncService(repository);

  runApp(
    BuscaGasApp(
      key: appKey,
      getNearbyStations: getNearbyStations,
      filterByFuelType: filterByFuelType,
      calculateDistance: calculateDistance,
      locationService: locationService,
      dataSyncService: dataSyncService,
      initialSettings: settings,
    ),
  );
}

/// Widget raíz de la aplicación
class BuscaGasApp extends StatefulWidget {
  final GetNearbyStationsUseCase getNearbyStations;
  final FilterByFuelTypeUseCase filterByFuelType;
  final CalculateDistanceUseCase calculateDistance;
  final LocationService locationService;
  final DataSyncService dataSyncService;
  final AppSettings initialSettings;

  const BuscaGasApp({
    super.key,
    required this.getNearbyStations,
    required this.filterByFuelType,
    required this.calculateDistance,
    required this.locationService,
    required this.dataSyncService,
    required this.initialSettings,
  });

  @override
  BuscaGasAppState createState() => BuscaGasAppState();
}

class BuscaGasAppState extends State<BuscaGasApp> {
  late AppSettings _settings;
  late MapBloc _mapBloc;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;

    // Crear MapBloc
    _mapBloc = MapBloc(
      getNearbyStations: widget.getNearbyStations,
      filterByFuelType: widget.filterByFuelType,
      calculateDistance: widget.calculateDistance,
      settings: _settings,
      locationService: widget.locationService,
    );

    // Configurar sincronización automática
    _setupAutoSync();
  }

  /// Configurar sincronización automática cada 30 minutos
  void _setupAutoSync() {
    // Configurar callback cuando hay datos actualizados
    widget.dataSyncService.onDataUpdated = () {
      debugPrint('🔄 Datos sincronizados, refrescando mapa...');
      // Disparar evento para refrescar el mapa
      _mapBloc.add(const RefreshMapData());
    };

    // Configurar callback para errores
    widget.dataSyncService.onSyncError = (error) {
      debugPrint('⚠️ Error en sincronización automática: $error');
      // Opcionalmente mostrar notificación al usuario
    };

    // Iniciar sincronización periódica
    widget.dataSyncService.startPeriodicSync();
    debugPrint('✅ Sincronización automática configurada (cada 30 minutos)');
  }

  @override
  void dispose() {
    // Detener sincronización cuando se cierre la app
    widget.dataSyncService.stopPeriodicSync();
    _mapBloc.close();
    super.dispose();
  }

  /// Método público para recargar settings desde otros widgets
  Future<void> reloadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _mapBloc,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // Configuración de temas
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _settings.darkMode ? ThemeMode.dark : ThemeMode.light,

        // Configurar rutas de navegación
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/map': (context) => const MapScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
