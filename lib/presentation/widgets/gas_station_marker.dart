import 'package:flutter/material.dart';
import '../../domain/entities/gas_station.dart';
import '../../domain/entities/fuel_type.dart';

/// Widget personalizado para mostrar un marcador de gasolinera en el mapa.
///
/// Muestra el precio del combustible seleccionado con un código de color
/// basado en el rango de precio (verde=bajo, naranja=medio, rojo=alto).
///
/// Este widget es principalmente decorativo. Para uso real en Google Maps,
/// los marcadores se crean usando BitmapDescriptor con colores personalizados.
class GasStationMarker extends StatelessWidget {
  /// La gasolinera a representar
  final GasStation station;

  /// El tipo de combustible seleccionado para mostrar el precio
  final FuelType selectedFuel;

  /// Callback ejecutado cuando se toca el marcador
  final VoidCallback onTap;

  const GasStationMarker({
    super.key,
    required this.station,
    required this.selectedFuel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener el precio del combustible seleccionado
    final double? price = station.getPriceForFuel(selectedFuel);

    // Determinar el color según el rango de precio
    // Si no hay rango asignado, usar gris por defecto
    final Color markerColor = station.priceRange?.color ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenedor con el precio destacado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: markerColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              price != null ? '\${price.toStringAsFixed(3)} €' : 'N/A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          // Icono de surtidor de gasolina
          Icon(
            Icons.local_gas_station,
            color: markerColor,
            size: 32,
          ),
        ],
      ),
    );
  }
}
