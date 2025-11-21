# PASO 14: Implementar Widgets Reutilizables

**Fecha de creación:** 21 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3

---

## ÍNDICE

1. [Contexto y Objetivos](#contexto-y-objetivos)
2. [Widgets a Implementar](#widgets-a-implementar)
3. [Especificaciones de Diseño](#especificaciones-de-diseño)
4. [Implementación Detallada](#implementación-detallada)
5. [Integración con Otros Componentes](#integración-con-otros-componentes)
6. [Pruebas y Validación](#pruebas-y-validación)

---

## CONTEXTO Y OBJETIVOS

### Descripción General
El Paso 14 consiste en la implementación de widgets reutilizables que se utilizarán a lo largo de la aplicación para mantener consistencia visual y facilitar el mantenimiento del código.

### Objetivos Específicos
1. Crear widget de marcador de gasolinera personalizado
2. Implementar widget de tarjeta de información (info card)
3. Desarrollar widget de selector de combustible

### Referencia Arquitectónica
- **Capa:** Presentación (Presentation Layer)
- **Subsistema:** SS-06 (Interfaz de Usuario)
- **Ubicación:** `lib/presentation/widgets/`

### Requisitos Relacionados
- **RF-02:** Visualización en Mapa - Los marcadores deben usar código de color según rango de precios
- **RF-03:** Filtrado por Combustible - Selector debe permitir cambio entre Gasolina 95 y Diésel
- **RF-05:** Información Básica - Tarjeta flotante con nombre, precio y distancia
- **RNF-02:** Usabilidad - Interfaz minimalista y clara
- **RNF-06:** Accesibilidad - Contraste adecuado en ambos modos

---

## WIDGETS A IMPLEMENTAR

### 1. GasStationMarker
**Propósito:** Representar visualmente una gasolinera en el mapa con código de color según precio.

**Características:**
- Muestra el precio del combustible seleccionado
- Código de color según rango de precio (verde/amarillo/rojo)
- Icono de surtidor de gasolina
- Interactivo (responde a taps)

### 2. StationInfoCard
**Propósito:** Mostrar información detallada de una gasolinera al seleccionar un marcador.

**Características:**
- Tarjeta flotante con elevación
- Nombre y dirección de la gasolinera
- Precio del combustible seleccionado destacado
- Distancia aproximada desde ubicación del usuario
- Colores según rango de precio

### 3. FuelSelector
**Propósito:** Permitir al usuario seleccionar el tipo de combustible a visualizar.

**Características:**
- Selector horizontal con opciones: Gasolina 95 y Diésel Gasóleo A
- Indicador visual del combustible seleccionado
- Actualización inmediata al cambiar selección
- Diseño coherente con tema de la aplicación

---

## ESPECIFICACIONES DE DISEÑO

### Paleta de Colores (Según Rango de Precio)

Según la documentación (DSI 4 - Diseño de Clases):

```dart
enum PriceRange {
  low,    // verde
  medium, // amarillo
  high;   // rojo
  
  Color get color {
    switch (this) {
      case PriceRange.low:
        return Colors.green;
      case PriceRange.medium:
        return Colors.orange;
      case PriceRange.high:
        return Colors.red;
    }
  }
}
```

### Tipografía
- **Precio destacado:** 20pt, Bold
- **Nombre de gasolinera:** 18pt, Bold
- **Dirección:** 14pt, Regular, Grey[600]
- **Distancia:** 14pt, Regular, Grey
- **Precio en marcador:** 12pt, Bold, White

### Espaciados
- Padding de tarjeta: 16px
- Margin de tarjeta: 16px en todos los lados
- Separación entre elementos: 8-12px
- Border radius de contenedores: 4px

---

## IMPLEMENTACIÓN DETALLADA

### 1. Widget: GasStationMarker

**Ubicación:** `lib/presentation/widgets/gas_station_marker.dart`

**Especificación DSI 7:**

```dart
class GasStationMarker extends StatelessWidget {
  final GasStation station;
  final FuelType selectedFuel;
  final VoidCallback onTap;
  
  const GasStationMarker({
    required this.station,
    required this.selectedFuel,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    double? price = station.getPriceForFuel(selectedFuel);
    Color markerColor = station.priceRange?.color ?? Colors.grey;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Precio destacado
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: markerColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              price != null ? '${price.toStringAsFixed(3)} €' : 'N/A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          // Icono de surtidor
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
```

**Propiedades:**
- `station` (GasStation): Entidad de dominio con datos de la gasolinera
- `selectedFuel` (FuelType): Tipo de combustible actualmente seleccionado
- `onTap` (VoidCallback): Función a ejecutar cuando se toca el marcador

**Comportamiento:**
1. Obtiene el precio del combustible seleccionado usando `station.getPriceForFuel(selectedFuel)`
2. Determina el color basándose en `station.priceRange?.color`
3. Si no hay precio disponible, muestra "N/A"
4. Si no hay rango de precio asignado, usa gris como color por defecto
5. Formatea precio a 3 decimales (ej: 1.459 €)

**Consideraciones:**
- El widget es `StatelessWidget` porque no mantiene estado interno
- El color del marcador debe coincidir con el color del icono para coherencia visual
- El texto del precio tiene fondo de color para mejor legibilidad sobre el mapa

---

### 2. Widget: StationInfoCard

**Ubicación:** `lib/presentation/widgets/station_info_card.dart`

**Especificación DSI 7:**

```dart
class StationInfoCard extends StatelessWidget {
  final GasStation station;
  final FuelType selectedFuel;
  
  const StationInfoCard({
    required this.station,
    required this.selectedFuel,
  });
  
  @override
  Widget build(BuildContext context) {
    double? price = station.getPriceForFuel(selectedFuel);
    
    return Card(
      elevation: 8,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              station.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              station.address,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedFuel.displayName}:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  price != null ? '${price.toStringAsFixed(3)} €/L' : 'N/A',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: station.priceRange?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  station.distance != null
                      ? '${station.distance!.toStringAsFixed(1)} km'
                      : '',
                  style: TextStyle(color: Colors.grey),
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

**Propiedades:**
- `station` (GasStation): Entidad de dominio con datos completos de la gasolinera
- `selectedFuel` (FuelType): Tipo de combustible para mostrar precio específico

**Estructura Visual:**
```
┌─────────────────────────────────────┐
│  Nombre Gasolinera              (18pt, Bold)
│  Dirección                      (14pt, Grey)
│  
│  Gasolina 95:           1.459 €/L
│  (16pt)                 (20pt, Bold, Color)
│  
│  📍 0.8 km             (14pt, Grey)
└─────────────────────────────────────┘
```

**Comportamiento:**
1. Obtiene precio del combustible seleccionado
2. Muestra nombre de gasolinera en negrita
3. Muestra dirección en texto secundario (gris)
4. Presenta precio destacado con color según rango
5. Incluye icono de ubicación con distancia formateada a 1 decimal
6. Si no hay distancia calculada, oculta el indicador de distancia

**Consideraciones:**
- `elevation: 8` proporciona sombra pronunciada para destacar sobre el mapa
- `MainAxisSize.min` evita que la tarjeta ocupe más espacio del necesario
- `CrossAxisAlignment.start` alinea contenido a la izquierda
- El color del precio usa `station.priceRange?.color` para coherencia con marcador

---

### 3. Widget: FuelSelector

**Ubicación:** `lib/presentation/widgets/fuel_selector.dart`

**Especificación basada en IU-02:**

```dart
class FuelSelector extends StatelessWidget {
  final FuelType selectedFuel;
  final Function(FuelType) onFuelChanged;
  
  const FuelSelector({
    Key? key,
    required this.selectedFuel,
    required this.onFuelChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
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
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fuel.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
```

**Propiedades:**
- `selectedFuel` (FuelType): Combustible actualmente seleccionado
- `onFuelChanged` (Function(FuelType)): Callback ejecutado al cambiar selección

**Estructura Visual:**
```
┌──────────────────────────────────────────────┐
│  [Gasolina 95]      [Diésel Gasóleo A]       │
│   (selected)           (unselected)          │
└──────────────────────────────────────────────┘
```

**Comportamiento:**
1. Itera sobre todos los valores de `FuelType.values`
2. Para cada tipo de combustible, crea un botón
3. Aplica estilo diferente al combustible seleccionado (color primario, texto en negrita)
4. Los combustibles no seleccionados tienen color surfaceVariant y texto normal
5. Al tocar un botón, ejecuta `onFuelChanged(fuel)` con el nuevo tipo
6. Usa `Expanded` para distribuir espacio equitativamente

**Consideraciones:**
- Usa `Theme.of(context)` para adaptar colores automáticamente al tema (claro/oscuro)
- `GestureDetector` en lugar de botones para mayor control sobre diseño
- `BoxShadow` sutil para separar visualmente del mapa
- `BorderRadius.circular(8)` para bordes redondeados modernos

---

## INTEGRACIÓN CON OTROS COMPONENTES

### Integración con MapScreen

**Uso de GasStationMarker:**

En `lib/presentation/screens/map_screen.dart`, el widget se usa para generar marcadores de Google Maps:

```dart
Set<Marker> _buildMarkers(List<GasStation> stations, FuelType selectedFuel) {
  return stations.map((station) {
    return Marker(
      markerId: MarkerId(station.id),
      position: LatLng(station.latitude, station.longitude),
      onTap: () {
        setState(() {
          _selectedStation = station;
        });
      },
      icon: _createCustomMarkerIcon(station, selectedFuel),
    );
  }).toSet();
}
```

**Nota:** La integración real de widgets personalizados como marcadores en Google Maps requiere convertir el widget a `BitmapDescriptor`. Una aproximación simplificada es usar marcadores estándar con colores personalizados:

```dart
BitmapDescriptor _getMarkerIcon(GasStation station) {
  double hue = 0; // rojo por defecto
  
  if (station.priceRange == PriceRange.low) {
    hue = BitmapDescriptor.hueGreen;
  } else if (station.priceRange == PriceRange.medium) {
    hue = BitmapDescriptor.hueOrange;
  } else if (station.priceRange == PriceRange.high) {
    hue = BitmapDescriptor.hueRed;
  }
  
  return BitmapDescriptor.defaultMarkerWithHue(hue);
}
```

### Uso de StationInfoCard:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        if (state is MapLoaded) {
          return Stack(
            children: [
              GoogleMap(
                // ... configuración del mapa
                markers: _buildMarkers(state.stations, state.currentFuel),
              ),
              _buildFuelSelector(state.currentFuel),
              if (_selectedStation != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: StationInfoCard(
                    station: _selectedStation!,
                    selectedFuel: state.currentFuel,
                  ),
                ),
            ],
          );
        }
        return SizedBox();
      },
    ),
  );
}
```

### Uso de FuelSelector:

```dart
Widget _buildFuelSelector(FuelType currentFuel) {
  return Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: FuelSelector(
      selectedFuel: currentFuel,
      onFuelChanged: (fuel) {
        context.read<MapBloc>().add(ChangeFuelType(fuelType: fuel));
      },
    ),
  );
}
```

### Dependencias de Entidades de Dominio

Los widgets dependen de las siguientes entidades (ya implementadas en pasos anteriores):

**GasStation** (`lib/domain/entities/gas_station.dart`):
- Propiedades: `id`, `name`, `latitude`, `longitude`, `address`, `locality`, `operator`, `prices`, `distance`, `priceRange`
- Métodos: `getPriceForFuel(FuelType)`, `isWithinRadius(...)`, `calculateDistance(...)`

**FuelType** (`lib/domain/entities/fuel_type.dart`):
- Enum con valores: `gasolina95`, `dieselGasoleoA`
- Getter: `displayName` (retorna "Gasolina 95" o "Diésel Gasóleo A")

**PriceRange** (`lib/domain/entities/price_range.dart`):
- Enum con valores: `low`, `medium`, `high`
- Getter: `color` (retorna Colors.green, Colors.orange, Colors.red)

---

## ESTRUCTURA DE ARCHIVOS

Después de implementar el Paso 14, la estructura de `lib/presentation/widgets/` debe ser:

```
lib/presentation/widgets/
├── gas_station_marker.dart      # Marcador de gasolinera en mapa
├── station_info_card.dart        # Tarjeta flotante de información
└── fuel_selector.dart            # Selector de tipo de combustible
```

---

## PRUEBAS Y VALIDACIÓN

### Pruebas Unitarias de Widgets

**Ubicación:** `test/presentation/widgets/`

#### Prueba de GasStationMarker:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/price_range.dart';
import 'package:buscagas/presentation/widgets/gas_station_marker.dart';

void main() {
  group('GasStationMarker Widget Tests', () {
    testWidgets('debe mostrar precio correctamente formateado', (tester) async {
      final station = GasStation(
        id: '1',
        name: 'Test Station',
        latitude: 40.4,
        longitude: -3.7,
        prices: [
          FuelPrice(
            fuelType: FuelType.gasolina95,
            value: 1.459,
            updatedAt: DateTime.now(),
          ),
        ],
        priceRange: PriceRange.low,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GasStationMarker(
              station: station,
              selectedFuel: FuelType.gasolina95,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1.459 €'), findsOneWidget);
    });

    testWidgets('debe mostrar N/A cuando no hay precio', (tester) async {
      final station = GasStation(
        id: '1',
        name: 'Test Station',
        latitude: 40.4,
        longitude: -3.7,
        prices: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GasStationMarker(
              station: station,
              selectedFuel: FuelType.gasolina95,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('debe ejecutar callback al hacer tap', (tester) async {
      bool tapped = false;
      final station = GasStation(
        id: '1',
        name: 'Test',
        latitude: 40.4,
        longitude: -3.7,
        prices: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GasStationMarker(
              station: station,
              selectedFuel: FuelType.gasolina95,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GasStationMarker));
      expect(tapped, true);
    });
  });
}
```

#### Prueba de StationInfoCard:

```dart
void main() {
  group('StationInfoCard Widget Tests', () {
    testWidgets('debe mostrar nombre y dirección de la gasolinera', (tester) async {
      final station = GasStation(
        id: '1',
        name: 'Repsol',
        latitude: 40.4,
        longitude: -3.7,
        address: 'Av. Principal 123',
        prices: [
          FuelPrice(
            fuelType: FuelType.gasolina95,
            value: 1.459,
            updatedAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StationInfoCard(
              station: station,
              selectedFuel: FuelType.gasolina95,
            ),
          ),
        ),
      );

      expect(find.text('Repsol'), findsOneWidget);
      expect(find.text('Av. Principal 123'), findsOneWidget);
    });

    testWidgets('debe mostrar distancia si está disponible', (tester) async {
      final station = GasStation(
        id: '1',
        name: 'Test',
        latitude: 40.4,
        longitude: -3.7,
        prices: [],
      );
      station.distance = 0.8;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StationInfoCard(
              station: station,
              selectedFuel: FuelType.gasolina95,
            ),
          ),
        ),
      );

      expect(find.text('0.8 km'), findsOneWidget);
    });
  });
}
```

#### Prueba de FuelSelector:

```dart
void main() {
  group('FuelSelector Widget Tests', () {
    testWidgets('debe mostrar todos los tipos de combustible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FuelSelector(
              selectedFuel: FuelType.gasolina95,
              onFuelChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Gasolina 95'), findsOneWidget);
      expect(find.text('Diésel Gasóleo A'), findsOneWidget);
    });

    testWidgets('debe ejecutar callback al cambiar combustible', (tester) async {
      FuelType? changedFuel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FuelSelector(
              selectedFuel: FuelType.gasolina95,
              onFuelChanged: (fuel) => changedFuel = fuel,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Diésel Gasóleo A'));
      expect(changedFuel, FuelType.dieselGasoleoA);
    });
  });
}
```

### Validación Visual

**Checklist de Validación:**

- [ ] **GasStationMarker:**
  - [ ] Muestra precio con 3 decimales (ej: 1.459 €)
  - [ ] Color verde para precios bajos
  - [ ] Color naranja para precios medios
  - [ ] Color rojo para precios altos
  - [ ] Muestra "N/A" cuando no hay precio
  - [ ] Icono de surtidor visible y del mismo color que el contenedor
  - [ ] Responde al tap correctamente

- [ ] **StationInfoCard:**
  - [ ] Nombre en negrita y tamaño adecuado
  - [ ] Dirección en color gris secundario
  - [ ] Precio destacado y coloreado según rango
  - [ ] Distancia formateada a 1 decimal con icono de ubicación
  - [ ] Tarjeta tiene elevación visible (sombra)
  - [ ] Texto del combustible usa `displayName` correctamente

- [ ] **FuelSelector:**
  - [ ] Ambas opciones visibles horizontalmente
  - [ ] Opción seleccionada destacada con color primario
  - [ ] Opción seleccionada en negrita
  - [ ] Opciones no seleccionadas con color surfaceVariant
  - [ ] Cambio de selección actualiza visualmente de inmediato
  - [ ] Se adapta correctamente al tema claro y oscuro

### Validación de Accesibilidad

**Requisitos (RNF-06):**
- [ ] Contraste adecuado entre texto y fondo en ambos temas
- [ ] Tamaño de texto legible sin zoom (mínimo 12pt)
- [ ] Áreas táctiles de al menos 48x48 dp (especialmente en FuelSelector)

### Validación de Integración

**En MapScreen:**
- [ ] Marcadores aparecen correctamente en el mapa
- [ ] Colores de marcadores coinciden con rangos de precio
- [ ] Al tocar marcador, aparece StationInfoCard
- [ ] Información en tarjeta coincide con gasolinera seleccionada
- [ ] FuelSelector cambia filtro de combustible al seleccionar
- [ ] Cambio de combustible actualiza marcadores visibles

---

## CRITERIOS DE ACEPTACIÓN

### Funcionales:
1. ✅ Los tres widgets están implementados y funcionan correctamente
2. ✅ GasStationMarker muestra precios formateados y usa código de color
3. ✅ StationInfoCard presenta toda la información requerida (nombre, dirección, precio, distancia)
4. ✅ FuelSelector permite cambiar entre Gasolina 95 y Diésel
5. ✅ Los widgets responden correctamente a interacciones del usuario
6. ✅ Integración con MapScreen funciona sin errores

### No Funcionales:
1. ✅ Tiempo de renderizado < 16ms (60 FPS)
2. ✅ Los widgets se adaptan a temas claro y oscuro
3. ✅ Contraste de colores cumple con WCAG 2.1 nivel AA
4. ✅ No hay warnings de compilación
5. ✅ Código sigue convenciones de Dart (flutter analyze sin errores)

### Cobertura de Pruebas:
1. ✅ Al menos 80% de cobertura en pruebas unitarias de widgets
2. ✅ Todos los escenarios críticos tienen pruebas (precio disponible, precio null, tap, cambio de combustible)
3. ✅ Pruebas pasan en CI/CD

---

## NOTAS ADICIONALES

### Conversión de Widget a Marcador de Mapa

Para integrar `GasStationMarker` como marcador real de Google Maps, se requiere convertir el widget a imagen:

```dart
import 'dart:ui' as ui;

Future<BitmapDescriptor> _createMarkerImageFromWidget(
  Widget widget,
  Size size,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  final widgetToRender = MediaQuery(
    data: MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ),
  );
  
  final renderObject = RenderRepaintBoundary();
  final renderView = RenderView(
    window: ui.window,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: renderObject,
    ),
    configuration: ViewConfiguration(
      size: size,
      devicePixelRatio: 1.0,
    ),
  );
  
  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  
  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();
  
  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: renderObject,
    child: widgetToRender,
  ).attachToRenderTree(buildOwner);
  
  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();
  
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();
  
  final image = await renderObject.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}
```

**Nota:** Esta funcionalidad es opcional para el MVP y puede implementarse en fases posteriores de optimización.

### Optimización de Rendimiento

Para mejorar el rendimiento con muchos marcadores:

1. **Limitar marcadores visibles:** Solo renderizar gasolineras dentro de los límites del mapa
2. **Clustering:** Agrupar marcadores cercanos cuando el zoom es bajo
3. **Lazy loading:** Cargar información detallada solo cuando se selecciona un marcador

### Extensibilidad Futura

Los widgets están diseñados para ser extendidos en futuras versiones:

- **GasStationMarker:** Añadir animaciones, badges de favoritos
- **StationInfoCard:** Añadir botón de navegación, horarios, servicios adicionales
- **FuelSelector:** Soportar más tipos de combustible (Gasolina 98, E10, etc.)

---

## COMANDOS DE DESARROLLO

### Crear archivos de widgets:

```powershell
# Crear directorio si no existe
New-Item -ItemType Directory -Force -Path "lib/presentation/widgets"

# Crear archivos vacíos
New-Item -ItemType File -Path "lib/presentation/widgets/gas_station_marker.dart"
New-Item -ItemType File -Path "lib/presentation/widgets/station_info_card.dart"
New-Item -ItemType File -Path "lib/presentation/widgets/fuel_selector.dart"
```

### Ejecutar pruebas:

```powershell
# Ejecutar todas las pruebas de widgets
flutter test test/presentation/widgets/

# Ejecutar con cobertura
flutter test --coverage
```

### Validar código:

```powershell
# Analizar código
flutter analyze lib/presentation/widgets/

# Formatear código
flutter format lib/presentation/widgets/
```

---

## REFERENCIAS

### Documentación Métrica V3:
- **DSI 1:** Definición de la Arquitectura del Sistema
- **DSI 4:** Diseño de Clases (GasStation, FuelPrice, FuelType, PriceRange)
- **DSI 7:** Diseño de Interfaces (GasStationMarker, StationInfoCard)
- **ASI 7:** Definición de Interfaces de Usuario (IU-02)
- **EVS 3:** Requisitos Funcionales y No Funcionales

### Entidades de Dominio:
- `lib/domain/entities/gas_station.dart`
- `lib/domain/entities/fuel_type.dart`
- `lib/domain/entities/fuel_price.dart`
- `lib/domain/entities/price_range.dart` (si existe)

### Pantallas Relacionadas:
- `lib/presentation/screens/map_screen.dart`

---

## CHECKLIST DE FINALIZACIÓN

Antes de considerar el Paso 14 como completado, verificar:

- [ ] Los 3 widgets están implementados en `lib/presentation/widgets/`
- [ ] Cada widget tiene su archivo independiente
- [ ] Los widgets usan correctamente las entidades de dominio
- [ ] Se adaptan al tema claro y oscuro
- [ ] Pruebas unitarias implementadas y pasando
- [ ] Integración con MapScreen funcional
- [ ] No hay errores de compilación (`flutter analyze`)
- [ ] Código formateado correctamente (`flutter format`)
- [ ] Documentación inline (comentarios) en código complejo
- [ ] Archivo PASO_14_COMPLETADO.md creado con resumen
- [ ] PASOS_DESARROLLO.md actualizado con estado "Completado"

---

**FIN DEL DOCUMENTO**
