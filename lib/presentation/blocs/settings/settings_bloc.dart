import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscagas/presentation/blocs/settings/settings_event.dart';
import 'package:buscagas/presentation/blocs/settings/settings_state.dart';

/// BLoC para gestión de la configuración
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  // TODO: Implement - BLoC de configuración
  // - Cargar y guardar configuración de usuario
  // - Eventos: LoadSettings, UpdateSearchRadius, UpdatePreferredFuel, ToggleDarkMode
  // - Estados: SettingsLoading, SettingsLoaded, SettingsError
  
  SettingsBloc() : super(SettingsInitial());
}

