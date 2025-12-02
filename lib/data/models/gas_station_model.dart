/// Modelo de datos para Gasolinera (Data Layer)
library;

import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class GasStationModel {
  final String ideess;
  final String rotulo;
  final String direccion;
  final String localidad;
  final String latitud;
  final String longitud;
  final String? precioGasolina95;
  final String? precioDiesel;

  GasStationModel({
    required this.ideess,
    required this.rotulo,
    required this.direccion,
    required this.localidad,
    required this.latitud,
    required this.longitud,
    this.precioGasolina95,
    this.precioDiesel,
  });

  factory GasStationModel.fromJson(Map<String, dynamic> json) {
    return GasStationModel(
      ideess: json['IDEESS']?.toString() ?? '',
      rotulo: json['Rótulo']?.toString() ?? '',
      direccion: json['Dirección']?.toString() ?? '',
      localidad: json['Localidad']?.toString() ?? '',
      latitud: json['Latitud']?.toString() ?? '0',
      longitud: json['Longitud (WGS84)']?.toString() ?? '0',
      precioGasolina95: json['Precio Gasolina 95 E5']?.toString(),
      precioDiesel: json['Precio Gasoleo A']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IDEESS': ideess,
      'Rótulo': rotulo,
      'Dirección': direccion,
      'Localidad': localidad,
      'Latitud': latitud,
      'Longitud (WGS84)': longitud,
      'Precio Gasolina 95 E5': precioGasolina95,
      'Precio Gasoleo A': precioDiesel,
    };
  }

  // Mapper a entidad de dominio
  GasStation toDomain() {
    List<FuelPrice> prices = [];

    if (precioGasolina95 != null) {
      double? price = _parsePrice(precioGasolina95!);
      if (price != null) {
        prices.add(FuelPrice(
          fuelType: FuelType.gasolina95,
          value: price,
          updatedAt: DateTime.now(),
        ));
      }
    }

    if (precioDiesel != null) {
      double? price = _parsePrice(precioDiesel!);
      if (price != null) {
        prices.add(FuelPrice(
          fuelType: FuelType.dieselGasoleoA,
          value: price,
          updatedAt: DateTime.now(),
        ));
      }
    }

    return GasStation(
      id: ideess,
      name: rotulo,
      latitude: double.tryParse(latitud.replaceAll(',', '.')) ?? 0.0,
      longitude: double.tryParse(longitud.replaceAll(',', '.')) ?? 0.0,
      address: direccion,
      locality: localidad,
      operator: rotulo,
      prices: prices,
    );
  }

  factory GasStationModel.fromEntity(GasStation entity) {
    String? gasolina95;
    String? diesel;

    for (var price in entity.prices) {
      if (price.fuelType == FuelType.gasolina95) {
        gasolina95 = price.value.toString().replaceAll('.', ',');
      } else if (price.fuelType == FuelType.dieselGasoleoA) {
        diesel = price.value.toString().replaceAll('.', ',');
      }
    }

    return GasStationModel(
      ideess: entity.id,
      rotulo: entity.name,
      direccion: entity.address,
      localidad: entity.locality,
      latitud: entity.latitude.toString().replaceAll('.', ','),
      longitud: entity.longitude.toString().replaceAll('.', ','),
      precioGasolina95: gasolina95,
      precioDiesel: diesel,
    );
  }

  double? _parsePrice(String priceStr) {
    try {
      // Reemplazar coma por punto y parsear
      return double.parse(priceStr.replaceAll(',', '.'));
    } catch (_) {
      return null;
    }
  }
}
