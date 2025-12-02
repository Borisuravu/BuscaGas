import 'package:flutter/material.dart';
import '../../domain/entities/fuel_type.dart';

/// Selector horizontal de tipo de combustible.
///
/// Permite al usuario seleccionar entre Gasolina 95 y Diésel Gasóleo A.
/// El combustible seleccionado se destaca con color primario y texto en negrita.
///
/// Se adapta automáticamente al tema claro u oscuro de la aplicación.
class FuelSelector extends StatelessWidget {
  /// El tipo de combustible actualmente seleccionado
  final FuelType selectedFuel;

  /// Callback ejecutado cuando el usuario cambia el tipo de combustible
  final Function(FuelType) onFuelChanged;

  const FuelSelector({
    super.key,
    required this.selectedFuel,
    required this.onFuelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: FuelType.values.map((fuel) {
          final isSelected = fuel == selectedFuel;
          return Expanded(
            child: GestureDetector(
              onTap: () => onFuelChanged(fuel),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fuel.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
