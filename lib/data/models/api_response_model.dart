/// Modelo DTO para respuesta de la API del Gobierno
library;

import 'package:buscagas/data/models/gas_station_model.dart';

class ApiGasStationResponse {
  final String fecha;
  final List<GasStationModel> listaEESSPrecio;

  ApiGasStationResponse({
    required this.fecha,
    required this.listaEESSPrecio,
  });

  factory ApiGasStationResponse.fromJson(Map<String, dynamic> json) {
    return ApiGasStationResponse(
      fecha: json['Fecha'] ?? '',
      listaEESSPrecio: (json['ListaEESSPrecio'] as List?)
              ?.map((e) => GasStationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Fecha': fecha,
      'ListaEESSPrecio': listaEESSPrecio.map((e) => e.toJson()).toList(),
    };
  }
}
