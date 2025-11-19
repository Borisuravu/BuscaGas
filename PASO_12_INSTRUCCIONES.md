# PASO 12: DESARROLLAR PANTALLA PRINCIPAL CON MAPA

## Objetivo
Implementar la pantalla principal (MapScreen) de BuscaGas con mapa interactivo de Google Maps, marcadores de gasolineras con código de colores según precio, selector de combustible, y tarjeta flotante de información.

---

## Especificaciones según Documentación V3

### IU-02: Pantalla Principal - Mapa

**Layout general:**
```
┌─────────────────────────────────────────────────┐
│ [⚙️ Configuración]        BuscaGas        [     │ ← Barra superior (AppBar)
├─────────────────────────────────────────────────┤
│ [Gasolina 95]   [Diésel Gasóleo A]              │ ← Selector combustible
├─────────────────────────────────────────────────┤
│                                                 │
│                 [ MAPA INTERACTIVO ]            │
│                                                 │
│          📍 Marcadores con precios              │
│                                                 │
│                 🔵 Usuario aquí                 │
│                                                 │
│                                                 │
├─────────────────────────────────────────────────┤
│                               [📍 Mi Loc]       │ ← Botón recentrar
└─────────────────────────────────────────────────┘
```

**Elementos visuales:**
- **AppBar:** Título "BuscaGas" centrado, icono de configuración (engranaje) a la derecha
- **Selector de combustible:** Botones segmentados para Gasolina 95 / Diésel Gasóleo A
- **Mapa interactivo:** Google Maps con marcadores de gasolineras
- **Marcadores:** 
  - Color verde: precio en rango bajo
  - Color amarillo/naranja: precio en rango medio
  - Color rojo: precio en rango alto
  - Icono: surtidor de gasolina
  - Label: precio en €/litro
- **Marcador de usuario:** Icono azul indicando ubicación actual
- **Botón de recentrado:** FloatingActionButton con icono de ubicación
- **Tarjeta flotante:** Se muestra al tocar un marcador

**Tarjeta Flotante (Info Card):**
```
┌─────────────────────────────┐
│ Repsol - Av. Principal 123  │ ← Nombre y dirección
│ Gasolina 95: 1.45 €/L       │ ← Tipo de combustible y precio
│ 📍 0.8 km                   │ ← Distancia
└─────────────────────────────┘
```

**Interacciones:**
- Pellizcar: zoom del mapa
- Arrastrar: desplazar mapa
- Tap en marcador: mostrar tarjeta flotante
- Tap en "Mi Loc": recentrar mapa en ubicación actual
- Tap en selector combustible: filtrar y actualizar marcadores
- Tap en engranaje: abrir pantalla de configuración

---

## Requisitos Funcionales Asociados

### RF-01: Geolocalización
- Obtener ubicación actual del usuario mediante GPS
- Solicitar permisos de ubicación (si no se hizo en splash)
- Proporcionar botón de recentrado

### RF-02: Visualización en Mapa
- Mostrar mapa interactivo con marcadores de gasolineras
- Usar código de color según rango de precios
- Permitir zoom y desplazamiento

### RF-03: Filtrado por Combustible
- Selector para Gasolina 95 o Diésel Gasóleo A
- Actualización inmediata de marcadores visibles

### RF-05: Información Básica
- Tarjeta flotante al tocar marcador con:
  * Nombre de la gasolinera
  * Precio del combustible seleccionado
  * Distancia aproximada

---

## Implementación Técnica

### 1. Archivo: `lib/presentation/screens/map_screen.dart`

**Responsabilidades:**
- Mostrar Google Maps centrado en ubicación del usuario
- Renderizar marcadores de gasolineras con colores
- Gestionar selector de combustible
- Mostrar/ocultar tarjeta flotante
- Manejar botón de recentrado
- Solicitar permisos de ubicación
- Navegar a pantalla de configuración

**Estructura básica del Widget:**

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/core/theme/colors.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  FuelType _selectedFuel = FuelType.gasolina95;
  bool _isLoading = true;
  String? _errorMessage;
  
  // TODO: Añadir lista de gasolineras desde repositorio
  // TODO: Añadir markers set
  // TODO: Añadir selected station para tarjeta
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    // 1. Verificar y solicitar permisos
    // 2. Obtener ubicación actual
    // 3. Cargar gasolineras (de momento mock)
    // 4. Actualizar estado
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildRecenterButton(),
    );
  }
}
```

---

## Componentes a Implementar

### 1.1. AppBar

```dart
PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: Text(AppConstants.appName),
    centerTitle: true,
    actions: [
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
        tooltip: 'Configuración',
      ),
    ],
  );
}
```

### 1.2. Selector de Combustible

```dart
Widget _buildFuelSelector() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: Theme.of(context).colorScheme.surface,
    child: Row(
      children: [
        Expanded(
          child: _buildFuelButton(
            FuelType.gasolina95,
            'Gasolina 95',
            _selectedFuel == FuelType.gasolina95,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFuelButton(
            FuelType.dieselGasoleoA,
            'Diésel Gasóleo A',
            _selectedFuel == FuelType.dieselGasoleoA,
          ),
        ),
      ],
    ),
  );
}

Widget _buildFuelButton(FuelType fuelType, String label, bool isSelected) {
  return ElevatedButton(
    onPressed: () {
      setState(() {
        _selectedFuel = fuelType;
        // TODO: Actualizar marcadores según nuevo combustible
      });
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      foregroundColor: isSelected
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurface,
      elevation: isSelected ? 4 : 1,
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 14),
      textAlign: TextAlign.center,
    ),
  );
}
```

### 1.3. Google Maps

```dart
Widget _buildMap() {
  if (_currentPosition == null) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ),
      zoom: 13.0,
    ),
    onMapCreated: (GoogleMapController controller) {
      _mapController = controller;
    },
    myLocationEnabled: true,
    myLocationButtonEnabled: false, // Usaremos nuestro botón personalizado
    mapType: MapType.normal,
    zoomControlsEnabled: false, // Ocultamos controles por defecto
    // TODO: Añadir markers
    // markers: _markers,
    // TODO: Añadir onTap para ocultar tarjeta
    onTap: (_) {
      // Ocultar tarjeta flotante si está visible
    },
  );
}
```

### 1.4. Botón de Recentrado

```dart
Widget _buildRecenterButton() {
  return FloatingActionButton(
    onPressed: _recenterMap,
    tooltip: 'Mi ubicación',
    child: const Icon(Icons.my_location),
  );
}

Future<void> _recenterMap() async {
  if (_mapController == null) return;
  
  try {
    // Obtener ubicación actual
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // Animar cámara a nueva posición
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 13.0,
        ),
      ),
    );
    
    setState(() {
      _currentPosition = position;
    });
    
    // TODO: Recargar gasolineras cercanas
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }
}
```

### 1.5. Gestión de Permisos

```dart
Future<bool> _checkLocationPermission() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    setState(() {
      _errorMessage = 'Los servicios de ubicación están desactivados';
    });
    return false;
  }
  
  LocationPermission permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _errorMessage = 'Permisos de ubicación denegados';
      });
      return false;
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    setState(() {
      _errorMessage = 'Permisos de ubicación denegados permanentemente';
    });
    return false;
  }
  
  return true;
}

Future<Position?> _getCurrentLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return position;
  } catch (e) {
    debugPrint('Error obteniendo ubicación: $e');
    return null;
  }
}
```

### 1.6. Inicialización Completa

```dart
Future<void> _initializeMap() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  
  try {
    // 1. Verificar permisos
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // 2. Obtener ubicación
    final position = await _getCurrentLocation();
    if (position == null) {
      setState(() {
        _errorMessage = 'No se pudo obtener la ubicación';
        _isLoading = false;
      });
      return;
    }
    
    // 3. Cargar configuración de usuario
    final settings = await AppSettings.load();
    
    setState(() {
      _currentPosition = position;
      _selectedFuel = settings.preferredFuel;
      _isLoading = false;
    });
    
    // 4. TODO: Cargar gasolineras del repositorio
    // await _loadGasStations();
    
  } catch (e) {
    setState(() {
      _errorMessage = 'Error al inicializar mapa: $e';
      _isLoading = false;
    });
  }
}
```

### 1.7. Body Principal

```dart
Widget _buildBody() {
  if (_isLoading) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando mapa...'),
        ],
      ),
    );
  }
  
  if (_errorMessage != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeMap,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
  
  return Column(
    children: [
      _buildFuelSelector(),
      Expanded(child: _buildMap()),
      // TODO: Añadir tarjeta flotante si hay estación seleccionada
    ],
  );
}
```

---

## 2. Widget Reutilizable: Tarjeta de Información

### Archivo: `lib/presentation/widgets/station_info_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

/// Tarjeta flotante que muestra información de una gasolinera
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
            // Nombre de la gasolinera
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
```

---

## 3. Marcadores Personalizados (Futuro)

Para el MVP, Google Maps usará marcadores estándar. En fases posteriores se pueden crear marcadores personalizados:

```dart
// TODO: Implementar en pasos posteriores
Future<BitmapDescriptor> _createCustomMarker(
  double price,
  Color color,
) async {
  // Crear imagen personalizada con precio y color
  // Usar package: custom_marker o similar
}
```

---

## Integración con Pasos Anteriores

### Compatibilidad con Tema Claro/Oscuro

El mapa debe respetar el tema actual de la aplicación:

```dart
// En _buildMap()
GoogleMap(
  // ... otras propiedades
  mapType: MapType.normal,
  // Estilo del mapa según tema
  style: Theme.of(context).brightness == Brightness.dark
      ? _darkMapStyle // JSON string con estilo oscuro
      : null, // Estilo claro por defecto
)
```

**Estilo de mapa oscuro (opcional):**
```dart
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  // ... más estilos
]
''';
```

### Uso de AppSettings

```dart
// Cargar combustible preferido al iniciar
final settings = await AppSettings.load();
setState(() {
  _selectedFuel = settings.preferredFuel;
  // _searchRadius = settings.searchRadius; // Para filtrar gasolineras
});
```

### Uso de AppColors

```dart
import 'package:buscagas/core/theme/colors.dart';

// Colores para marcadores según rango de precio
final markerColor = switch (station.priceRange) {
  PriceRange.low => AppColors.priceLowLight, // o Dark según tema
  PriceRange.medium => AppColors.priceMediumLight,
  PriceRange.high => AppColors.priceHighLight,
  _ => Theme.of(context).colorScheme.primary,
};
```

---

## Configuración de Google Maps

### 1. Obtener API Key

1. Ir a [Google Cloud Console](https://console.cloud.google.com/)
2. Crear proyecto o seleccionar existente
3. Habilitar "Maps SDK for Android"
4. Crear credenciales → API Key
5. Restringir API Key (opcional pero recomendado):
   - Restricción de aplicación: Android apps
   - Añadir SHA-1 fingerprint del keystore
   - Restricciones de API: Solo Maps SDK for Android

### 2. Configurar Android

**android/app/src/main/AndroidManifest.xml:**

```xml
<manifest ...>
  <application ...>
    <!-- Google Maps API Key -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="TU_API_KEY_AQUI"/>
    
    <activity ...>
      ...
    </activity>
  </application>
  
  <!-- Permisos necesarios -->
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
</manifest>
```

### 3. Configurar pubspec.yaml

Ya incluidas en pasos anteriores:
```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
```

---

## Manejo de Errores

### Casos a considerar:

1. **Sin permisos de ubicación:**
   - Mostrar mensaje explicativo
   - Botón para abrir configuración de la app
   - Permitir uso limitado (sin centrar en usuario)

2. **Sin conexión a internet:**
   - Mostrar mensaje informativo
   - Intentar cargar desde caché (si existe)
   - Botón de reintentar

3. **Servicio de ubicación desactivado:**
   - Detectar con `Geolocator.isLocationServiceEnabled()`
   - Mostrar diálogo explicativo
   - Botón para abrir configuración del sistema

4. **API Key inválida:**
   - Google Maps mostrará mensaje de error
   - Verificar configuración en AndroidManifest.xml

```dart
Future<void> _handleLocationError() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permisos de Ubicación'),
      content: const Text(
        'Esta aplicación necesita acceso a tu ubicación para '
        'mostrarte gasolineras cercanas.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            openAppSettings(); // De permission_handler
          },
          child: const Text('Configuración'),
        ),
      ],
    ),
  );
}
```

---

## Testing

### Pruebas a realizar:

1. **Carga inicial:**
   - Verificar solicitud de permisos
   - Verificar obtención de ubicación
   - Verificar centrado del mapa en ubicación del usuario

2. **Selector de combustible:**
   - Cambiar entre Gasolina 95 y Diésel
   - Verificar actualización visual del selector
   - TODO: Verificar actualización de marcadores

3. **Interacción con mapa:**
   - Zoom con pellizco
   - Desplazamiento con arrastre
   - TODO: Tap en marcador muestra tarjeta

4. **Botón de recentrado:**
   - Centrar mapa en ubicación actual
   - Animación suave de cámara
   - TODO: Actualizar gasolineras cercanas

5. **Navegación:**
   - Tap en configuración abre SettingsScreen
   - Regresar desde configuración mantiene estado del mapa

6. **Temas:**
   - Verificar AppBar en modo claro
   - Verificar AppBar en modo oscuro
   - Verificar selector de combustible en ambos temas

7. **Manejo de errores:**
   - Denegar permisos → Mostrar mensaje
   - Desactivar ubicación → Mostrar mensaje
   - Simular error de red → Manejar gracefully

---

## Notas de Implementación

### Para el MVP (Paso 12):

**Implementar:**
- ✅ Estructura básica de MapScreen
- ✅ AppBar con navegación a configuración
- ✅ Selector de combustible funcional
- ✅ Google Maps centrado en ubicación
- ✅ Botón de recentrado
- ✅ Gestión de permisos de ubicación
- ✅ Widget StationInfoCard
- ✅ Manejo de estados (cargando, error)
- ✅ Compatibilidad con temas claro/oscuro

**Pendiente para pasos posteriores:**
- ⏳ Carga real de gasolineras desde API/BD (Paso 4-6)
- ⏳ Marcadores en el mapa (requiere datos)
- ⏳ Cálculo de distancias (Paso 7)
- ⏳ Clasificación por rangos de precio (Paso 15)
- ⏳ Tarjeta flotante interactiva (requiere datos)
- ⏳ Estilo de mapa oscuro personalizado
- ⏳ Marcadores personalizados con precios

### Datos Mock Temporales (Opcional):

Para visualizar la pantalla sin conexión a API:

```dart
final List<GasStation> _mockStations = [
  GasStation(
    id: '1',
    name: 'Repsol',
    latitude: _currentPosition!.latitude + 0.01,
    longitude: _currentPosition!.longitude + 0.01,
    address: 'Calle Principal 123',
    locality: 'Madrid',
    operator: 'Repsol',
    prices: [
      FuelPrice(fuelType: FuelType.gasolina95, value: 1.459),
      FuelPrice(fuelType: FuelType.dieselGasoleoA, value: 1.389),
    ],
  ),
  // ... más estaciones mock
];
```

---

## Mejoras Futuras (Post-MVP)

1. **Clustering de marcadores:**
   - Agrupar marcadores cuando hay muchos en una zona
   - Mostrar número de gasolineras en el cluster

2. **Búsqueda por dirección:**
   - Barra de búsqueda en AppBar
   - Autocompletado de direcciones
   - Centrar mapa en dirección buscada

3. **Filtros avanzados:**
   - Por operadora (Repsol, Cepsa, etc.)
   - Por servicios (lavado, tienda, etc.)
   - Por rango de precio

4. **Información adicional en tarjeta:**
   - Horario de apertura
   - Servicios disponibles
   - Botón de navegación (abrir Google Maps/Waze)

5. **Caché de tiles del mapa:**
   - Mapas offline para uso sin conexión
   - Reducir consumo de datos

---

## Checklist de Implementación

- [ ] Configurar Google Maps API Key en Android
- [ ] Crear archivo `lib/presentation/screens/map_screen.dart`
- [ ] Implementar `_buildAppBar()` con navegación a settings
- [ ] Implementar `_buildFuelSelector()` con botones segmentados
- [ ] Implementar `_buildMap()` con GoogleMap widget
- [ ] Implementar `_buildRecenterButton()` con FloatingActionButton
- [ ] Implementar `_checkLocationPermission()`
- [ ] Implementar `_getCurrentLocation()`
- [ ] Implementar `_initializeMap()` con flujo completo
- [ ] Implementar `_recenterMap()` con animación de cámara
- [ ] Implementar `_buildBody()` con estados de carga/error
- [ ] Crear `lib/presentation/widgets/station_info_card.dart`
- [ ] Implementar widget StationInfoCard completo
- [ ] Probar en modo claro y oscuro
- [ ] Probar permisos de ubicación
- [ ] Probar navegación a SettingsScreen
- [ ] Verificar que no hay errores de compilación
- [ ] Probar en dispositivo real (GPS)

---

## Dependencias Necesarias

Ya incluidas en `pubspec.yaml`:
- `google_maps_flutter: ^2.5.0` ✓
- `geolocator: ^10.1.0` ✓
- `permission_handler: ^11.0.1` ✓

---

## Recursos Adicionales

- [Google Maps Flutter Documentation](https://pub.dev/packages/google_maps_flutter)
- [Geolocator Documentation](https://pub.dev/packages/geolocator)
- [Google Maps Platform](https://developers.google.com/maps)
- [Map Styling Wizard](https://mapstyle.withgoogle.com/) - Para crear estilos personalizados

---

**Fecha de creación:** 18 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Paso:** 12 - Pantalla Principal con Mapa  
**Metodología:** Métrica v3
