/// Entidad de dominio: Gasolinera
library;

import 'dart:math';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/price_range.dart';

class GasStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String locality;
  final String operator;
  final List<FuelPrice> prices;
  double? distance; // calculado dinámicamente
  PriceRange? priceRange; // bajo, medio, alto
  
  GasStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.locality = '',
    this.operator = '',
    this.prices = const [],
    this.distance,
    this.priceRange,
  });
  
  double? getPriceForFuel(FuelType fuelType) {
    try {
      return prices
          .firstWhere((p) => p.fuelType == fuelType)
          .value;
    } catch (_) {
      return null;
    }
  }
  
  bool isWithinRadius(double lat, double lon, double radiusKm) {
    double distance = _calculateDistance(lat, lon);
    return distance <= radiusKm;
  }
  
  double _calculateDistance(double lat, double lon) {
    // Fórmula de Haversine
    const double earthRadiusKm = 6371.0;
    
    double dLat = _degreesToRadians(latitude - lat);
    double dLon = _degreesToRadians(longitude - lon);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat)) *
        cos(_degreesToRadians(latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
