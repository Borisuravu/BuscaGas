/// Modelo de datos para Precio de Combustible (Data Layer)
library;

import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class FuelPriceModel {
  final String fuelType; // nombre del enum como string
  final double value;
  final DateTime updatedAt;
  
  FuelPriceModel({
    required this.fuelType,
    required this.value,
    required this.updatedAt,
  });
  
  factory FuelPriceModel.fromJson(Map<String, dynamic> json) {
    return FuelPriceModel(
      fuelType: json['fuelType'] as String,
      value: (json['value'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'fuelType': fuelType,
      'value': value,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  FuelPrice toDomain() {
    FuelType type;
    try {
      type = FuelType.values.firstWhere((e) => e.name == fuelType);
    } catch (_) {
      type = FuelType.gasolina95; // fallback
    }
    
    return FuelPrice(
      fuelType: type,
      value: value,
      updatedAt: updatedAt,
    );
  }
  
  factory FuelPriceModel.fromEntity(FuelPrice entity) {
    return FuelPriceModel(
      fuelType: entity.fuelType.name,
      value: entity.value,
      updatedAt: entity.updatedAt,
    );
  }
}
