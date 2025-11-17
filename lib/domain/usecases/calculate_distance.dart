/// Caso de uso: Calcular distancia entre dos coordenadas geográficas
library;

import 'dart:math';

class CalculateDistanceUseCase {
  /// Ejecutar caso de uso
  /// 
  /// Calcula la distancia en kilómetros entre dos puntos geográficos
  /// usando la fórmula de Haversine (considera curvatura de la Tierra).
  /// 
  /// [lat1] Latitud del punto 1
  /// [lon1] Longitud del punto 1
  /// [lat2] Latitud del punto 2
  /// [lon2] Longitud del punto 2
  /// 
  /// Retorna distancia en kilómetros
  double call({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    // Radio de la Tierra en kilómetros
    const double earthRadiusKm = 6371.0;
    
    // Convertir grados a radianes
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    // Fórmula de Haversine
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
        cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Distancia = radio * ángulo
    final distance = earthRadiusKm * c;
    
    return distance;
  }
  
  /// Convertir grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
