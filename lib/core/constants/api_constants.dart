/// Constantes relacionadas con la API del Gobierno de España
class ApiConstants {
  // TODO: Implement - Definir URL base de la API gubernamental
  // URL: https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/
  
  static const String baseUrl = '';
  static const String stationsEndpoint = '';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
