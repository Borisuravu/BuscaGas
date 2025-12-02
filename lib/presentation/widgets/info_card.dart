import 'package:flutter/material.dart';

/// Tarjeta flotante con información de gasolinera seleccionada
class InfoCard extends StatelessWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Selecciona una gasolinera para ver detalles'),
      ),
    );
  }
}
