import 'package:flutter/material.dart';

/// Widget personalizado para marcador de gasolinera en el mapa
class GasStationMarker extends StatelessWidget {
  const GasStationMarker({super.key});
  
  @override
  Widget build(BuildContext context) {
    // TODO: Implement - Marcador de gasolinera
    // - Precio destacado en contenedor con color según rango
    // - Icono de surtidor (Icons.local_gas_station)
    // - Colores: verde (bajo), naranja (medio), rojo (alto)
    // - GestureDetector para manejar onTap
    return const Icon(Icons.local_gas_station);
  }
}
