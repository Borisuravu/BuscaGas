import 'package:flutter/material.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

/// Tarjeta flotante que muestra información de una gasolinera
/// 
/// Muestra:
/// - Nombre de la gasolinera
/// - Dirección
/// - Precio del combustible seleccionado
/// - Distancia desde la ubicación del usuario
class StationInfoCard extends StatelessWidget {
  final GasStation station;
  final FuelType selectedFuel;
  final VoidCallback? onClose;
  
  const StationInfoCard({
    super.key,
    required this.station,
    required this.selectedFuel,
    this.onClose,
  });
  
  @override
  Widget build(BuildContext context) {
    final price = station.getPriceForFuel(selectedFuel);
    final priceColor = station.priceRange?.color ?? 
                       Theme.of(context).colorScheme.primary;
    
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nombre de la gasolinera con botón de cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Dirección
            Text(
              station.address,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            
            // Precio del combustible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedFuel.displayName}:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  price != null ? '${price.toStringAsFixed(3)} €/L' : 'N/A',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: priceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Distancia
            if (station.distance != null)
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${station.distance!.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
