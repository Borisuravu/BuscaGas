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

  // Cliente HTTP
  final http.Client _client;

  // Constructor con inyección de dependencias (permite testing)
  ApiDataSource({http.Client? client}) : _client = client ?? http.Client();

  /// Obtener todas las estaciones de servicio desde la API
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
