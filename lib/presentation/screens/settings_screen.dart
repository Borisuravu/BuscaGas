import 'package:flutter/material.dart';
import 'package:buscagas/core/app_initializer.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

/// Pantalla de configuración de preferencias
///
/// Responsabilidades:
/// - Mostrar y editar radio de búsqueda
/// - Mostrar y editar combustible preferido
/// - Mostrar y editar tema claro/oscuro
/// - Guardar cambios automáticamente
/// - Aplicar cambios inmediatamente
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estado local
  AppSettings? _settings;
  bool _isLoading = true;

  // Valores seleccionados
  int _selectedRadius = 10;
  FuelType _selectedFuel = FuelType.gasolina95;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Cargar configuración inicial desde base de datos
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await AppSettings.load();

      setState(() {
        _settings = settings;
        _selectedRadius = settings.searchRadius;
        _selectedFuel = settings.preferredFuel;
        _isDarkMode = settings.darkMode;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando configuración: $e');

      // Valores por defecto en caso de error
      setState(() {
        _selectedRadius = 10;
        _selectedFuel = FuelType.gasolina95;
        _isDarkMode = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando configuración: $e')),
        );
      }
    }
  }

  /// Actualizar radio de búsqueda
  Future<void> _updateSearchRadius(int radius) async {
    try {
      if (_settings != null) {
        _settings!.searchRadius = radius;
        await _settings!.save();
        debugPrint('✅ Radio de búsqueda actualizado: $radius km');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Radio de búsqueda: $radius km'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error actualizando radio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  /// Actualizar combustible preferido
  Future<void> _updatePreferredFuel(FuelType fuel) async {
    try {
      if (_settings != null) {
        _settings!.preferredFuel = fuel;
        await _settings!.save();
        debugPrint('✅ Combustible preferido actualizado: ${fuel.displayName}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Combustible preferido: ${fuel.displayName}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error actualizando combustible: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  /// Actualizar tema (claro/oscuro)
  Future<void> _updateTheme(bool isDark) async {
    try {
      if (_settings != null) {
        _settings!.darkMode = isDark;
        await _settings!.save();
        debugPrint('✅ Tema actualizado: ${isDark ? "Oscuro" : "Claro"}');

        // Recargar settings para aplicar el tema
        await AppInitializer.reloadSettings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tema: ${isDark ? "Oscuro" : "Claro"}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error actualizando tema: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoading() : _buildBody(),
    );
  }

  /// Construir indicador de carga
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Construir cuerpo principal
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sección: Radio de búsqueda
          _buildRadiusSection(),
          const SizedBox(height: 32),

          // Sección: Combustible preferido
          _buildFuelSection(),
          const SizedBox(height: 32),

          // Sección: Tema
          _buildThemeSection(),
          const SizedBox(height: 48),

          // Botón: Volver al mapa
          _buildBackButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Construir sección de radio de búsqueda
  Widget _buildRadiusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Radio de búsqueda',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildRadioOption(5),
        _buildRadioOption(10),
        _buildRadioOption(20),
        _buildRadioOption(50),
      ],
    );
  }

  /// Construir opción de radio
  Widget _buildRadioOption(int radiusKm) {
    return RadioListTile<int>(
      title: Text('$radiusKm km'),
      value: radiusKm,
      groupValue: _selectedRadius,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRadius = value;
          });
          _updateSearchRadius(value);
        }
      },
      subtitle: radiusKm == 10
          ? const Text('Recomendado', style: TextStyle(fontSize: 12))
          : null,
    );
  }

  /// Construir sección de combustible preferido
  Widget _buildFuelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Combustible preferido',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<FuelType>(
            value: _selectedFuel,
            isExpanded: true,
            underline: const SizedBox(),
            items: FuelType.values.map((fuel) {
              return DropdownMenuItem<FuelType>(
                value: fuel,
                child: Text(fuel.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFuel = value;
                });
                _updatePreferredFuel(value);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Construir sección de tema
  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isDarkMode ? 'Modo Oscuro' : 'Modo Claro',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  _updateTheme(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construir botón de volver al mapa
  Widget _buildBackButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Volver al Mapa'),
    );
  }
}
