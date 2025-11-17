import 'package:flutter/material.dart';

/// Pantalla de configuración
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    // TODO: Implement - Pantalla de configuración
    // - AppBar con botón "Atrás"
    // - Radio buttons para radio de búsqueda (5/10/20/50 km)
    // - Dropdown para combustible preferido
    // - Toggle para tema claro/oscuro
    // - Botón "Volver al Mapa"
    // - BlocBuilder<SettingsBloc, SettingsState> para reactivity
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: const Center(
        child: Text('TODO: SettingsScreen'),
      ),
    );
  }
}
