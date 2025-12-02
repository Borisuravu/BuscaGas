import 'package:flutter/foundation.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

/// Servicio HTTP para llamadas a la API del Gobierno de España
///
/// Responsabilidades:
/// - Proporcionar interfaz simplificada para operaciones de API
/// - Convertir modelos DTO a entidades de dominio
/// - Coordinar con ApiDataSource
/// - Logging y monitoreo de llamadas
class ApiService {
  final ApiDataSource _dataSource;

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() : _dataSource = ApiDataSource();

  // Constructor con inyección para testing
  ApiService.withDataSource(this._dataSource);

  // ==================== OPERACIONES DE API ====================

  /// Obtener todas las gasolineras desde la API del gobierno
  ///
  /// Retorna una lista de entidades de dominio [GasStation]
  /// Lanza [ApiException] si hay error
  Future<List<GasStation>> fetchGasStations() async {
    try {
      debugPrint('🌐 Iniciando descarga desde API gubernamental...');

      // 1. Llamar a ApiDataSource
      final models = await _dataSource.fetchAllStations();

      debugPrint('✅ Descargadas ${models.length} estaciones desde API');

      // 2. Convertir modelos a entidades de dominio
      final stations = models.map((model) => model.toDomain()).toList();

      // 3. Filtrar estaciones sin coordenadas válidas
      final validStations = stations.where((station) {
        return station.latitude != 0.0 && station.longitude != 0.0;
      }).toList();

      if (validStations.length < stations.length) {
        final filtered = stations.length - validStations.length;
        debugPrint('⚠️ Filtradas $filtered estaciones sin coordenadas válidas');
      }

      debugPrint('✅ ${validStations.length} estaciones válidas disponibles');

      return validStations;
    } on ApiException catch (e) {
      debugPrint('❌ Error de API: ${e.message}');
      rethrow; // Re-lanzar para que la capa superior maneje
    } catch (e) {
      debugPrint('❌ Error inesperado en ApiService: $e');
      throw ApiException(
        'Error al obtener gasolineras: $e',
        type: ApiErrorType.unknown,
      );
    }
  }

  /// Verificar si hay conexión con la API
  Future<bool> isApiAvailable() async {
    try {
      final available = await _dataSource.checkConnection();
      if (available) {
        debugPrint('✅ API disponible');
      } else {
        debugPrint('❌ API no disponible');
      }
      return available;
    } catch (e) {
      debugPrint('❌ Error verificando API: $e');
      return false;
    }
  }

  /// Obtener estadísticas de la última descarga
  /// Útil para debugging y monitoreo
  Future<Map<String, dynamic>> getApiStats() async {
    try {
      final stations = await fetchGasStations();

      // Contar por tipo de combustible disponible
      int withGasolina95 = 0;
      int withDiesel = 0;
      int withBoth = 0;

      for (var station in stations) {
        final hasGasolina = station.prices.any(
          (p) => p.fuelType == FuelType.gasolina95,
        );
        final hasDiesel = station.prices.any(
          (p) => p.fuelType == FuelType.dieselGasoleoA,
        );

        if (hasGasolina) withGasolina95++;
        if (hasDiesel) withDiesel++;
        if (hasGasolina && hasDiesel) withBoth++;
      }

      return {
        'total_stations': stations.length,
        'with_gasolina95': withGasolina95,
        'with_diesel': withDiesel,
        'with_both': withBoth,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Liberar recursos
  void dispose() {
    _dataSource.dispose();
  }
}
