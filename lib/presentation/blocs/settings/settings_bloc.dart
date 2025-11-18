import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/fuel_type.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC para gestionar el estado de configuración
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AppSettings _settings;
  
  SettingsBloc({required AppSettings settings})
      : _settings = settings,
        super(const SettingsInitial()) {
    // Registrar handlers
    on<LoadSettings>(_onLoadSettings);
    on<ChangeSearchRadius>(_onChangeSearchRadius);
    on<ChangePreferredFuel>(_onChangePreferredFuel);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ResetSettings>(_onResetSettings);
  }
  
  /// Handler: Cargar configuración
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // La configuración ya viene cargada en el constructor
      // Este handler simplemente emite el estado actual
      emit(SettingsLoaded(
        searchRadiusKm: _settings.searchRadius,
        preferredFuel: _settings.preferredFuel,
        isDarkMode: _settings.darkMode,
        lastSyncTimestamp: _settings.lastUpdateTimestamp,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Error al cargar configuración: ${e.toString()}'));
    }
  }
  
  /// Handler: Cambiar radio de búsqueda
  Future<void> _onChangeSearchRadius(
    ChangeSearchRadius event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      // Actualizar configuración
      _settings.searchRadius = event.radiusKm;
      await _settings.save();
      
      // Emitir nuevo estado
      emit(currentState.copyWith(searchRadiusKm: event.radiusKm));
    } catch (e) {
      emit(SettingsError(message: 'Error al cambiar radio: ${e.toString()}'));
    }
  }
  
  /// Handler: Cambiar combustible preferido
  Future<void> _onChangePreferredFuel(
    ChangePreferredFuel event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      // Actualizar configuración
      _settings.preferredFuel = event.fuelType;
      await _settings.save();
      
      // Emitir nuevo estado
      emit(currentState.copyWith(preferredFuel: event.fuelType));
    } catch (e) {
      emit(SettingsError(message: 'Error al cambiar combustible: ${e.toString()}'));
    }
  }
  
  /// Handler: Alternar modo oscuro
  Future<void> _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsLoaded) return;
    
    final currentState = state as SettingsLoaded;
    
    try {
      // Actualizar configuración
      _settings.darkMode = event.isDarkMode;
      await _settings.save();
      
      // Emitir nuevo estado
      emit(currentState.copyWith(isDarkMode: event.isDarkMode));
    } catch (e) {
      emit(SettingsError(message: 'Error al cambiar tema: ${e.toString()}'));
    }
  }
  
  /// Handler: Restaurar valores por defecto
  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      // Valores por defecto
      _settings.searchRadius = 10;
      _settings.preferredFuel = FuelType.gasolina95;
      _settings.darkMode = false;
      await _settings.save();
      
      emit(const SettingsLoaded(
        searchRadiusKm: 10,
        preferredFuel: FuelType.gasolina95,
        isDarkMode: false,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Error al restaurar configuración: ${e.toString()}'));
    }
  }
}

