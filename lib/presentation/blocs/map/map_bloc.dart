import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscagas/presentation/blocs/map/map_event.dart';
import 'package:buscagas/presentation/blocs/map/map_state.dart';

/// BLoC para gestión del estado del mapa
class MapBloc extends Bloc<MapEvent, MapState> {
  // TODO: Implement - BLoC del mapa
  // - Inyectar GetNearbyStationsUseCase, AppSettings
  // - Eventos: LoadMapData, ChangeFuelType, RecenterMap
  // - Estados: MapLoading, MapLoaded, MapError
  // - Lógica para cargar, filtrar y actualizar gasolineras
  
  MapBloc() : super(MapInitial());
}

