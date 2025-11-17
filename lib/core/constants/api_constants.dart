/// Constantes relacionadas con la API del Gobierno
library;

class ApiConstants {
  // URL base de la API
  static const String baseUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/';
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 5);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=UTF-8',
  };
  
  // Códigos de estado
  static const int statusOk = 200;
  static const int statusNotFound = 404;
  static const int statusServerErrorMin = 500;
  
  // Mensajes de error
  static const String errorNoConnection = 'Sin conexión a internet';
  static const String errorTimeout = 'Tiempo de espera agotado';
  static const String errorServerUnavailable = 'Servidor no disponible';
  static const String errorUnknown = 'Error desconocido';
}
