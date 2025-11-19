````markdown
# PASO 13: CREAR PANTALLA DE CONFIGURACIÓN

## Objetivo
Implementar la pantalla de configuración (SettingsScreen) de BuscaGas que permita al usuario personalizar sus preferencias de búsqueda, combustible preferido y tema visual, guardando los cambios de forma persistente y aplicándolos inmediatamente.

---

## Especificaciones según Documentación V3

### IU-03: Pantalla de Configuración

**Layout según diseño:**
```
┌─────────────────────────────────────────────────┐
│ [← Atrás]            Configuración              │
├─────────────────────────────────────────────────┤
│                                                 │
│  Radio de búsqueda                              │
│  ○ 5 km                                         │
│  ● 10 km                                        │
│  ○ 20 km                                        │
│  ○ 50 km                                        │
│                                                 │
│  Combustible preferido                          │
│  [Dropdown: Gasolina 95           ▼]            │
│                                                 │
│  Tema                                           │
│  [Toggle: ☀️ Claro  |  🌙 Oscuro]               │
│                                                 │
│                   [ Volver al Mapa ]            │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Elementos visuales:**
- **AppBar:** Título "Configuración" centrado, botón "Atrás" a la izquierda
- **Radio de búsqueda:** Radio buttons para seleccionar 5, 10, 20 o 50 km
- **Combustible preferido:** Dropdown (DropdownButton) con opciones Gasolina 95 / Diésel Gasóleo A
- **Tema:** Switch/Toggle para alternar entre modo claro y oscuro
- **Botón "Volver al Mapa":** Botón elevado centrado al final

**Comportamiento:**
- Cambios se aplican **inmediatamente** (sin botón "Guardar")
- Al pulsar "Volver", regresa a pantalla de mapa
- Valores se persisten automáticamente en cada cambio
- El tema debe actualizarse en tiempo real (toda la app)

---

## Caso de Uso: CU-02 - Configurar Preferencias

### Actor
Usuario conductor

### Precondiciones
- Aplicación ejecutándose
- Pantalla de mapa visible

### Flujo Principal
1. Usuario toca icono de configuración (engranaje) en MapScreen
2. Sistema muestra pantalla de configuración con valores actuales
3. Usuario modifica radio de búsqueda (5/10/20/50 km)
4. Sistema guarda preferencia automáticamente
5. Usuario selecciona combustible preferido (Gasolina 95 / Diésel Gasóleo A)
6. Sistema guarda preferencia automáticamente
7. Usuario alterna modo claro/oscuro
8. Sistema guarda preferencia automáticamente
9. Sistema actualiza tema de toda la aplicación
10. Usuario regresa al mapa (botón "Volver" o botón "Atrás")
11. MapScreen se actualiza con nuevas preferencias

### Postcondiciones
- Preferencias almacenadas persistentemente en base de datos
- Interfaz actualizada según configuración
- MapScreen usa nuevas preferencias (radio, combustible)

---

## Requisito Funcional Asociado

### RF-06: Configuración
- Radio de búsqueda configurable (5, 10, 20, 50 km)
- Combustible preferido por defecto
- Alternancia entre modo claro/oscuro

**Validación:**
- Los cambios deben persistir entre sesiones
- El radio de búsqueda debe aplicarse en el filtrado de gasolineras
- El combustible preferido debe ser el seleccionado por defecto al abrir la app
- El tema debe cambiar inmediatamente sin necesidad de reiniciar

---

## Arquitectura y Diseño

### Subsistema: SS-05 - Configuración de Usuario

**Responsabilidades:**
- Almacenamiento de preferencias en base de datos SQLite
- Gestión de temas visuales (claro/oscuro)
- Configuración de parámetros de búsqueda (radio, combustible)
- Aplicación inmediata de cambios

### Clase de Dominio: AppSettings

**Ubicación:** `lib/domain/entities/app_settings.dart`

**Propiedades:**
```dart
class AppSettings {
  int searchRadius;        // 5, 10, 20, 50
  FuelType preferredFuel;  // gasolina95, dieselGasoleoA
  bool darkMode;           // true = oscuro, false = claro
  DateTime? lastUpdateTimestamp;
}
```

**Métodos:**
- `Future<void> save()`: Guarda configuración en base de datos
- `static Future<AppSettings> load()`: Carga configuración desde base de datos
- Valores por defecto:
  - `searchRadius`: 10 km
  - `preferredFuel`: FuelType.gasolina95
  - `darkMode`: false

### Enumeración: FuelType

**Ubicación:** `lib/domain/entities/fuel_type.dart`

**Valores:**
```dart
enum FuelType {
  gasolina95,
  dieselGasoleoA;
  
  String get displayName {
    switch (this) {
      case FuelType.gasolina95:
        return 'Gasolina 95';
      case FuelType.dieselGasoleoA:
        return 'Diésel Gasóleo A';
    }
  }
}
```

---

## Implementación Técnica

### 1. Archivo: `lib/presentation/screens/settings_screen.dart`

**Responsabilidades:**
- Mostrar formulario de configuración
- Cargar valores actuales desde AppSettings
- Actualizar AppSettings al cambiar cada valor
- Notificar a la app principal para actualizar tema
- Navegar de vuelta al mapa

**Estructura del Widget:**

```dart
import 'package:flutter/material.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/main.dart' as main_app;

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
  
  // Valores seleccionados (antes de guardar)
  int _selectedRadius = 10;
  FuelType _selectedFuel = FuelType.gasolina95;
  bool _isDarkMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // Cargar configuración actual
    // Actualizar estado local
  }
  
  Future<void> _updateSearchRadius(int radius) async {
    // Actualizar radio de búsqueda
    // Guardar en BD
  }
  
  Future<void> _updatePreferredFuel(FuelType fuel) async {
    // Actualizar combustible preferido
    // Guardar en BD
  }
  
  Future<void> _updateTheme(bool isDark) async {
    // Actualizar tema
    // Guardar en BD
    // Notificar app principal para recargar tema
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildBody(),
    );
  }
}
```

---

## Componentes a Implementar

### 1.1. Cargar Configuración Inicial

```dart
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
```

### 1.2. AppBar

```dart
PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: const Text('Configuración'),
    centerTitle: true,
    // El botón "Atrás" se agrega automáticamente
  );
}
```

### 1.3. Indicador de Carga

```dart
Widget _buildLoading() {
  return const Center(
    child: CircularProgressIndicator(),
  );
}
```

### 1.4. Cuerpo Principal

```dart
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
```

### 1.5. Sección: Radio de Búsqueda

```dart
Widget _buildRadiusSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Título de sección
      Text(
        'Radio de búsqueda',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      
      // Radio buttons
      _buildRadioOption(5),
      _buildRadioOption(10),
      _buildRadioOption(20),
      _buildRadioOption(50),
    ],
  );
}

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
    // Opcional: agregar descripción
    subtitle: radiusKm == 10 
        ? const Text('Recomendado', style: TextStyle(fontSize: 12))
        : null,
  );
}

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
```

### 1.6. Sección: Combustible Preferido

```dart
Widget _buildFuelSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Título de sección
      Text(
        'Combustible preferido',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      
      // Dropdown
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
          underline: const SizedBox(), // Quitar línea por defecto
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
```

### 1.7. Sección: Tema

```dart
Widget _buildThemeSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Título de sección
      Text(
        'Tema',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      
      // Switch con iconos
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

Future<void> _updateTheme(bool isDark) async {
  try {
    if (_settings != null) {
      _settings!.darkMode = isDark;
      await _settings!.save();
      debugPrint('✅ Tema actualizado: ${isDark ? "Oscuro" : "Claro"}');
      
      // Notificar a la app principal para recargar el tema
      main_app.appKey.currentState?.reloadSettings();
      
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
```

### 1.8. Botón "Volver al Mapa"

```dart
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
```

---

## Integración con main.dart

### GlobalKey para Recargar Tema

El archivo `main.dart` ya tiene implementado el GlobalKey:

```dart
final GlobalKey<BuscaGasAppState> appKey = GlobalKey<BuscaGasAppState>();

class BuscaGasAppState extends State<BuscaGasApp> {
  AppSettings? _settings;
  
  void reloadSettings() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: _settings?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
      // ...
    );
  }
}
```

**Uso desde SettingsScreen:**
```dart
import 'package:buscagas/main.dart' as main_app;

// Después de guardar el cambio de tema
main_app.appKey.currentState?.reloadSettings();
```

---

## Persistencia de Datos

### Base de Datos SQLite

**Tabla:** `app_settings` (singleton, siempre id = 1)

**Esquema:**
```sql
CREATE TABLE app_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    search_radius INTEGER NOT NULL DEFAULT 10,
    preferred_fuel VARCHAR(20) NOT NULL DEFAULT 'gasolina95',
    dark_mode BOOLEAN NOT NULL DEFAULT 0,
    last_api_sync DATETIME
);
```

**Métodos del DatabaseService:**
- `updateSearchRadius(int radius)`
- `updatePreferredFuel(FuelType fuel)`
- `updateDarkMode(bool isDark)`
- `getAppSettings()` → Map con valores actuales

**Implementación en AppSettings:**
```dart
Future<void> save() async {
  final dbService = DatabaseService();
  await dbService.updateSearchRadius(searchRadius);
  await dbService.updatePreferredFuel(preferredFuel);
  await dbService.updateDarkMode(darkMode);
}

static Future<AppSettings> load() async {
  final dbService = DatabaseService();
  final settings = await dbService.getAppSettings();
  
  if (settings != null) {
    return AppSettings(
      searchRadius: settings['search_radius'] ?? 10,
      preferredFuel: FuelType.values.firstWhere(
        (e) => e.name == settings['preferred_fuel'],
        orElse: () => FuelType.gasolina95,
      ),
      darkMode: (settings['dark_mode'] ?? 0) == 1,
    );
  }
  
  // Valores por defecto si no hay datos
  return AppSettings();
}
```

---

## Flujo de Datos

### Actualización de Configuración

```
Usuario cambia valor
        ↓
setState() → Actualiza UI local
        ↓
_updateXXX() → Modifica AppSettings
        ↓
AppSettings.save() → Guarda en SQLite
        ↓
[Si es tema] main_app.reloadSettings() → Recarga tema global
        ↓
SnackBar → Confirma cambio al usuario
```

### Carga Inicial

```
SettingsScreen.initState()
        ↓
_loadSettings()
        ↓
AppSettings.load() → Lee desde SQLite
        ↓
setState() → Actualiza UI con valores actuales
```

### Navegación de Regreso

```
Usuario toca "Volver al Mapa" o botón Atrás
        ↓
Navigator.pop(context)
        ↓
MapScreen visible
        ↓
MapScreen puede recargar con nuevas preferencias
```

---

## Manejo de Errores

### Casos a considerar:

1. **Error al cargar configuración:**
   - Usar valores por defecto
   - Mostrar SnackBar con mensaje de error
   - Permitir al usuario modificar valores

2. **Error al guardar configuración:**
   - Mostrar SnackBar con mensaje de error
   - No revertir cambio en UI (optimistic update)
   - Registrar error en log

3. **Base de datos no disponible:**
   - Fallback a valores en memoria
   - Intentar guardar de nuevo al cerrar pantalla

```dart
try {
  await _settings!.save();
} catch (e) {
  debugPrint('❌ Error guardando configuración: $e');
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al guardar configuración: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

---

## Diseño Visual

### Espaciado y Padding

- **Padding general:** 16px
- **Espacio entre secciones:** 32px
- **Espacio entre título y contenido:** 16px
- **Espacio antes del botón:** 48px
- **Padding del botón:** 16px vertical

### Bordes y Decoración

- **Border radius:** 8px
- **Border color:** `Theme.of(context).colorScheme.outline`
- **Border width:** 1px

### Colores

- **Título de sección:** `Theme.of(context).textTheme.titleLarge`
- **Texto del cuerpo:** `Theme.of(context).textTheme.bodyLarge`
- **Texto secundario:** `Theme.of(context).textTheme.bodyMedium`

### Iconos

- **Modo claro:** `Icons.light_mode`
- **Modo oscuro:** `Icons.dark_mode`
- **Tamaño:** 24px

---

## Testing

### Pruebas a realizar:

1. **Carga inicial:**
   - Verificar que se cargan valores actuales desde BD
   - Verificar valores por defecto si no hay datos

2. **Cambio de radio de búsqueda:**
   - Seleccionar 5 km → Verificar guardado
   - Seleccionar 10 km → Verificar guardado
   - Seleccionar 20 km → Verificar guardado
   - Seleccionar 50 km → Verificar guardado
   - Verificar SnackBar de confirmación

3. **Cambio de combustible:**
   - Seleccionar Gasolina 95 → Verificar guardado
   - Seleccionar Diésel Gasóleo A → Verificar guardado
   - Verificar SnackBar de confirmación

4. **Cambio de tema:**
   - Activar modo oscuro → Verificar cambio visual inmediato
   - Desactivar modo oscuro → Verificar cambio visual inmediato
   - Verificar que toda la app cambia de tema
   - Verificar guardado en BD

5. **Persistencia:**
   - Cambiar valores y cerrar app
   - Abrir app → Verificar que valores se mantienen
   - Verificar en BD que valores están guardados

6. **Navegación:**
   - Botón "Atrás" funciona
   - Botón "Volver al Mapa" funciona
   - MapScreen recibe nuevas preferencias

7. **Manejo de errores:**
   - Simular error en BD
   - Verificar que no se bloquea la app
   - Verificar mensajes de error

---

## Mejoras Futuras (Post-MVP)

1. **Animaciones:**
   - Transición suave al cambiar tema
   - Animación de ripple en radio buttons

2. **Vista previa:**
   - Mostrar ejemplo de mapa con radio seleccionado
   - Mostrar precio de ejemplo con combustible seleccionado

3. **Más opciones:**
   - Unidad de distancia (km / millas)
   - Idioma de la aplicación
   - Notificaciones push
   - Frecuencia de actualización automática

4. **Validación:**
   - Confirmar cambios importantes con diálogo
   - Opción de resetear a valores por defecto

5. **Accesibilidad:**
   - Soporte para lectores de pantalla
   - Aumentar tamaño de fuentes
   - Alto contraste

---

## Checklist de Implementación

### Funcionalidad Core
- [ ] Crear archivo `lib/presentation/screens/settings_screen.dart`
- [ ] Implementar `_loadSettings()` para cargar configuración inicial
- [ ] Implementar `_buildRadiusSection()` con RadioListTile
- [ ] Implementar `_updateSearchRadius()` para guardar radio
- [ ] Implementar `_buildFuelSection()` con DropdownButton
- [ ] Implementar `_updatePreferredFuel()` para guardar combustible
- [ ] Implementar `_buildThemeSection()` con Switch
- [ ] Implementar `_updateTheme()` para guardar y aplicar tema
- [ ] Implementar `_buildBackButton()` para navegación
- [ ] Integrar con `main_app.appKey.currentState?.reloadSettings()`

### UI/UX
- [ ] Diseñar AppBar con título centrado
- [ ] Aplicar espaciado consistente (16/32/48 px)
- [ ] Usar bordes redondeados (8px)
- [ ] Agregar iconos a sección de tema
- [ ] Mostrar SnackBar de confirmación en cada cambio
- [ ] Agregar indicador de carga inicial
- [ ] Verificar diseño en modo claro
- [ ] Verificar diseño en modo oscuro

### Persistencia
- [ ] Verificar que AppSettings.save() funciona
- [ ] Verificar que AppSettings.load() funciona
- [ ] Verificar que valores por defecto son correctos
- [ ] Verificar que cambios persisten entre sesiones

### Integración
- [ ] Navegación desde MapScreen funciona
- [ ] Navegación de vuelta a MapScreen funciona
- [ ] Cambio de tema actualiza toda la app
- [ ] MapScreen usa nuevas preferencias al volver

### Testing
- [ ] Probar carga inicial de valores
- [ ] Probar cambio de cada opción
- [ ] Probar persistencia (cerrar/abrir app)
- [ ] Probar cambio de tema en tiempo real
- [ ] Probar manejo de errores
- [ ] Verificar que no hay errores de compilación

---

## Código de Ejemplo Completo

### Estructura Completa del Widget

```dart
import 'package:flutter/material.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/main.dart' as main_app;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _settings;
  bool _isLoading = true;
  
  int _selectedRadius = 10;
  FuelType _selectedFuel = FuelType.gasolina95;
  bool _isDarkMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
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
  
  Future<void> _updateTheme(bool isDark) async {
    try {
      if (_settings != null) {
        _settings!.darkMode = isDark;
        await _settings!.save();
        debugPrint('✅ Tema actualizado: ${isDark ? "Oscuro" : "Claro"}');
        
        // Notificar a la app principal
        main_app.appKey.currentState?.reloadSettings();
        
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
  
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRadiusSection(),
          const SizedBox(height: 32),
          _buildFuelSection(),
          const SizedBox(height: 32),
          _buildThemeSection(),
          const SizedBox(height: 48),
          _buildBackButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
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
```

---

## Dependencias Necesarias

Ya incluidas en `pubspec.yaml`:
- `flutter/material.dart` ✓
- `shared_preferences` (usado internamente por AppSettings) ✓
- `sqflite` (usado internamente por DatabaseService) ✓

---

## Notas Importantes

1. **Optimistic UI Update:** La UI se actualiza inmediatamente antes de guardar en BD, para mejor experiencia de usuario.

2. **Error Handling:** Cada operación de guardado tiene try-catch para no bloquear la app.

3. **Feedback Visual:** Se muestra SnackBar después de cada cambio para confirmar al usuario.

4. **Tema Global:** El cambio de tema afecta a toda la app gracias a `main_app.appKey.currentState?.reloadSettings()`.

5. **Valores por Defecto:** Si no hay datos en BD o hay error, se usan valores sensatos (10 km, Gasolina 95, modo claro).

6. **Subtítulo Recomendado:** El radio de 10 km tiene un subtítulo "Recomendado" para guiar al usuario.

---

**Fecha de creación:** 19 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Paso:** 13 - Pantalla de Configuración  
**Metodología:** Métrica v3

````
