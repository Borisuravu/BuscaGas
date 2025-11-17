import 'package:flutter/material.dart';

/// Pantalla principal con mapa interactivo
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    // TODO: Implement - Pantalla principal con mapa
    // - AppBar con título y botón de configuración
    // - Selector de combustible (Gasolina 95 / Diésel)
    // - GoogleMap con marcadores de gasolineras
    // - Tarjeta flotante al seleccionar marcador
    // - Botón de "Mi ubicación" para recentrar
    // - BlocBuilder<MapBloc, MapState> para reactivity
    return Scaffold(
      appBar: AppBar(
        title: const Text('BuscaGas'),
      ),
      body: const Center(
        child: Text('TODO: MapScreen'),
      ),
    );
  }
}
