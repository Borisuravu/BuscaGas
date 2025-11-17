/// Value Object de dominio: Precio de Combustible
library;

import 'package:equatable/equatable.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class FuelPrice extends Equatable {
  final FuelType fuelType;
  final double value; // euros por litro
  final DateTime updatedAt;
  
  const FuelPrice({
    required this.fuelType,
    required this.value,
    required this.updatedAt,
  });
  
  bool isOlderThan(Duration duration) {
    return DateTime.now().difference(updatedAt) > duration;
  }
  
  @override
  List<Object?> get props => [fuelType, value, updatedAt];
}
