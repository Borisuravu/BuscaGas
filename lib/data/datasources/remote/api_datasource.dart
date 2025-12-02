/// Fuente de datos remota: API del Gobierno de España
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:buscagas/data/models/api_response_model.dart';
import 'package:buscagas/data/models/gas_station_model.dart';
import 'package:buscagas/core/utils/performance_monitor.dart';

// Función top-level para compute() - parseo en background
List<GasStationModel> _parseGasStationsInBackground(Map<String, dynamic> json) {
  final apiResponse = ApiGasStationResponse.fromJson(json);
  return apiResponse.listaEESSPrecio;
}

class ApiDataSource {
  // URL base de la API gubernamental
  static const String _baseUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/';
  
  // Endpoints por CCAA (Comunidades Autónomas) - MUCHO MÁS RÁPIDO
  static const String _baseUrlCCAA =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/FiltroCCAA/';

  // Cliente HTTP
  final http.Client _client;

  // Constructor con inyección de dependencias (permite testing)
  ApiDataSource({http.Client? client}) : _client = client ?? http.Client();
  
  /// Detectar código CCAA por coordenadas GPS (aproximado)
  /// Retorna código de 2 dígitos o null si no se puede determinar
  String? _detectCCAAByCoordinates(double lat, double lon) {
    // Rangos aproximados de coordenadas por CCAA (España peninsular + islas)
    // Formato: latMin, latMax, lonMin, lonMax, código
    final ccaaRanges = [
      // Madrid (centro)
      [40.0, 41.2, -4.5, -3.0, '13'],
      // Cataluña (noreste)
      [40.5, 42.9, 0.1, 3.4, '09'],
      // Andalucía (sur)
      [36.0, 38.8, -7.5, -1.6, '01'],
      // Comunidad Valenciana (este)
      [37.8, 40.8, -1.5, 0.5, '10'],
      // Galicia (noroeste)
      [41.8, 43.8, -9.3, -6.7, '12'],
      // Castilla y León (norte-centro)
      [40.0, 43.2, -7.0, -1.5, '07'],
      // País Vasco (norte)
      [42.8, 43.5, -3.2, -1.7, '16'],
      // Aragón (noreste-centro)
      [39.8, 42.9, -2.2, 0.8, '02'],
      // Castilla-La Mancha (centro-sur)
      [38.0, 41.2, -5.3, -0.8, '08'],
      // Murcia (sureste)
      [37.4, 38.8, -2.4, -0.6, '14'],
      // Asturias (norte)
      [42.9, 43.7, -7.2, -4.5, '03'],
      // Extremadura (oeste)
      [37.9, 40.5, -7.6, -4.7, '11'],
      // Islas Baleares
      [38.6, 40.1, 1.2, 4.4, '04'],
      // Canarias (Las Palmas)
      [27.6, 29.5, -18.2, -13.4, '05'],
      // Canarias (Tenerife)
      [28.0, 28.6, -17.0, -16.1, '05'],
      // Cantabria
      [42.8, 43.5, -4.9, -3.1, '06'],
      // La Rioja
      [41.9, 42.7, -3.2, -1.7, '17'],
      // Navarra
      [41.9, 43.3, -2.5, -0.7, '15'],
    ];
    
    // Buscar CCAA que contenga las coordenadas
    for (var range in ccaaRanges) {
      final latMin = range[0] as double;
      final latMax = range[1] as double;
      final lonMin = range[2] as double;
      final lonMax = range[3] as double;
      final code = range[4] as String;
      
      if (lat >= latMin && lat <= latMax && lon >= lonMin && lon <= lonMax) {
        return code;
      }
    }
    
    return null; // No se pudo determinar
  }

  /// Obtener estaciones de una CCAA específica (RÁPIDO: ~800 estaciones)
  Future<List<GasStationModel>> fetchStationsByCCAA(String ccaaCode) async {
    try {
      debugPrint('📍 Descargando gasolineras de CCAA: $ccaaCode');
      
      PerformanceMonitor.start('API Download CCAA');
      final response = await _client.get(
        Uri.parse('$_baseUrlCCAA$ccaaCode'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept-Encoding': 'gzip',
        },
      ).timeout(
        const Duration(seconds: 30), // Más rápido que descarga completa
        onTimeout: () {
          throw ApiException(
            'Timeout: La petición tardó más de 30 segundos',
            type: ApiErrorType.timeout,
          );
        },
      );
      PerformanceMonitor.stop('API Download CCAA');

      if (response.statusCode == 200) {
        PerformanceMonitor.start('JSON Parse CCAA');
        final Map<String, dynamic> jsonData = json.decode(response.body);
        PerformanceMonitor.stop('JSON Parse CCAA');

        PerformanceMonitor.start('Background Parse CCAA');
        final stations = await compute(_parseGasStationsInBackground, jsonData);
        PerformanceMonitor.stop('Background Parse CCAA');

        debugPrint('✅ ${stations.length} estaciones de CCAA $ccaaCode descargadas');
        return stations;
      } else {
        throw ApiException(
          'Error HTTP ${response.statusCode} al descargar CCAA',
          type: ApiErrorType.httpError,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('❌ Error descargando CCAA $ccaaCode: $e');
      rethrow;
    }
  }
  
  /// Obtener estaciones cercanas a una ubicación (INTELIGENTE)
  /// 1. Detecta CCAA del usuario
  /// 2. Descarga solo esa CCAA (~800 estaciones)
  /// 3. Fallback a descarga completa si falla
  Future<List<GasStationModel>> fetchNearbyStations({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Intentar detectar CCAA
      final ccaaCode = _detectCCAAByCoordinates(latitude, longitude);
      
      if (ccaaCode != null) {
        debugPrint('🎯 Ubicación detectada en CCAA: $ccaaCode');
        debugPrint('⚡ Descarga optimizada: solo ~800 estaciones (vs 11,000)');
        
        try {
          return await fetchStationsByCCAA(ccaaCode);
        } catch (e) {
          debugPrint('⚠️ Fallo descarga CCAA, intentando descarga completa...');
          // Continuar con fallback
        }
      } else {
        debugPrint('📍 No se pudo detectar CCAA, descargando todo');
      }
      
      // Fallback: descarga completa
      return await fetchAllStations();
    } catch (e) {
      debugPrint('❌ Error en fetchNearbyStations: $e');
      rethrow;
    }
  }

  /// Obtener todas las estaciones de servicio desde la API (LENTO: 11,000)
  /// ⚠️ DEPRECADO: Usar fetchNearbyStations() para mejor rendimiento
  Future<List<GasStationModel>> fetchAllStations() async {
    try {
      // 1. Realizar petición GET con compresión gzip
      PerformanceMonitor.start('API Download');
      final response = await _client.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept-Encoding': 'gzip', // Solicitar compresión gzip
        },
      ).timeout(
        const Duration(seconds: 60), // Aumentado a 60s por compresión
        onTimeout: () {
          throw ApiException(
            'Timeout: La petición tardó más de 60 segundos',
            type: ApiErrorType.timeout,
          );
        },
      );
      PerformanceMonitor.stop('API Download');

      // 2. Verificar código de estado HTTP
      if (response.statusCode == 200) {
        // 3. Decodificar JSON en main thread
        PerformanceMonitor.start('JSON Parse');
        final Map<String, dynamic> jsonData = json.decode(response.body);
        PerformanceMonitor.stop('JSON Parse');

        // 4. Parsear en background thread (NO BLOQUEA UI)
        PerformanceMonitor.start('Background Parse');
        final stations = await compute(_parseGasStationsInBackground, jsonData);
        PerformanceMonitor.stop('Background Parse');

        debugPrint('✅ ${stations.length} estaciones descargadas y parseadas');
        return stations;
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Endpoint no encontrado (404)',
          type: ApiErrorType.notFound,
        );
      } else if (response.statusCode >= 500) {
        throw ApiException(
          'Error del servidor (${response.statusCode})',
          type: ApiErrorType.serverError,
        );
      } else {
        throw ApiException(
          'Error HTTP: ${response.statusCode}',
          type: ApiErrorType.httpError,
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      // Re-lanzar excepciones de API
      rethrow;
    } catch (e) {
      // Capturar otros errores (red, parseo, etc.)
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw ApiException(
          'Sin conexión a internet',
          type: ApiErrorType.noConnection,
        );
      } else if (e.toString().contains('FormatException')) {
        throw ApiException(
          'Error al parsear JSON: ${e.toString()}',
          type: ApiErrorType.parseError,
        );
      } else {
        throw ApiException(
          'Error desconocido: ${e.toString()}',
          type: ApiErrorType.unknown,
        );
      }
    }
  }

  /// Verificar conectividad con la API
  Future<bool> checkConnection() async {
    try {
      final response = await _client.head(Uri.parse(_baseUrl)).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Cerrar cliente HTTP (liberar recursos)
  void dispose() {
    _client.close();
  }
}

// ==================== EXCEPCIONES PERSONALIZADAS ====================

/// Tipos de errores de API
enum ApiErrorType {
  noConnection, // Sin internet
  timeout, // Timeout de petición
  serverError, // Error 5xx
  notFound, // Error 404
  httpError, // Otros errores HTTP
  parseError, // Error al parsear JSON
  unknown, // Error desconocido
}

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;

  ApiException(
    this.message, {
    required this.type,
    this.statusCode,
  });

  @override
  String toString() {
    return 'ApiException [${type.name}]: $message';
  }

  /// Obtener mensaje amigable para el usuario
  String get userFriendlyMessage {
    switch (type) {
      case ApiErrorType.noConnection:
        return 'No hay conexión a internet. Por favor, verifica tu conexión.';
      case ApiErrorType.timeout:
        return 'La petición tardó demasiado. Inténtalo de nuevo.';
      case ApiErrorType.serverError:
        return 'El servidor no está disponible. Inténtalo más tarde.';
      case ApiErrorType.notFound:
        return 'Servicio no encontrado. Contacta con soporte.';
      case ApiErrorType.httpError:
        return 'Error al conectar con el servidor (código: $statusCode).';
      case ApiErrorType.parseError:
        return 'Error al procesar los datos. Inténtalo más tarde.';
      case ApiErrorType.unknown:
        return 'Error inesperado. Por favor, inténtalo de nuevo.';
    }
  }
}
