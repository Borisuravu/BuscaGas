import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/app_error.dart';
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
    } catch (e, stackTrace) {
      emit(SettingsError(
        error: AppError.database(
          message: 'Error al cargar configuración',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
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
    } catch (e, stackTrace) {
      emit(SettingsError(
        error: AppError.database(
          message: 'Error al cambiar radio de búsqueda',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
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
    } catch (e, stackTrace) {
      emit(SettingsError(
        error: AppError.database(
          message: 'Error al cambiar combustible preferido',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
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
    } catch (e, stackTrace) {
      emit(SettingsError(
        error: AppError.database(
          message: 'Error al cambiar tema',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
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
    } catch (e, stackTrace) {
      emit(SettingsError(
        error: AppError.database(
          message: 'Error al restaurar configuración',
          originalError: e,
          stackTrace: stackTrace,
        ),
      ));
    }
  }
}
