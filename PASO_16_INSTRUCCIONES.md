# PASO 16: Añadir Funcionalidad de Recentrado - Instrucciones Detalladas

## Índice
1. [Contexto y Objetivos](#contexto-y-objetivos)
2. [Requisitos Funcionales](#requisitos-funcionales)
3. [Especificaciones Técnicas](#especificaciones-técnicas)
4. [Diseño de la Interfaz](#diseño-de-la-interfaz)
5. [Implementación Detallada](#implementación-detallada)
6. [Integración con BLoC](#integración-con-bloc)
7. [Pruebas y Validación](#pruebas-y-validación)
8. [Criterios de Aceptación](#criterios-de-aceptación)

---

## Contexto y Objetivos

### Descripción General
El **Paso 16** implementa la funcionalidad de recentrado del mapa en la ubicación actual del usuario. Esta funcionalidad es fundamental para la experiencia de usuario, permitiendo regresar rápidamente a su posición actual después de explorar el mapa.

### Objetivos del Paso
1. ✅ Añadir botón flotante "Mi ubicación" en la esquina inferior derecha del mapa
2. ✅ Implementar animación suave de cámara al recentrar
3. ✅ Actualizar lista de gasolineras cercanas tras recentrado
4. ✅ Manejar errores de ubicación con mensajes claros
5. ✅ Integrar con sistema de gestión de estado (BLoC/Provider)

### Relación con Otros Pasos
- **Depende de:**
  - Paso 12: MapScreen con Google Maps integrado
  - Paso 7: GetNearbyStationsUseCase
  - Paso 3: Entidades de dominio (GasStation, FuelType)
  - Paso 15: PriceRangeCalculator

- **Prepara para:**
  - Paso 8: Gestión de estado completa con BLoC
  - Paso 17: Actualización automática de datos

---

## Requisitos Funcionales

### RF-01: Geolocalización (Relacionado)
> El sistema debe obtener la ubicación actual del usuario mediante GPS.  
> Debe solicitar permisos de ubicación al primer uso.  
> **Debe proporcionar botón de recentrado.**

**Caso de Uso:** CU-03 - Recentrar Mapa en Ubicación Actual

**Actor:** Usuario conductor

**Precondiciones:**
- Mapa visible en pantalla
- Permisos de ubicación activos
- GPS disponible

**Flujo Principal:**
1. Usuario toca botón "Mi ubicación" (icono 📍)
2. Sistema obtiene coordenadas GPS actuales
3. Sistema centra mapa en nueva posición con animación suave
4. Sistema recalcula gasolineras dentro del radio configurado
5. Sistema actualiza marcadores en el mapa

**Flujo Alternativo 2a: Ubicación no disponible**
- Sistema muestra SnackBar informativo: "Error al obtener ubicación"
- Sistema mantiene última posición conocida
- Usuario puede reintentar

**Flujo Alternativo 2b: Permisos denegados**
- Sistema muestra diálogo explicativo
- Sistema ofrece botón "Abrir Configuración"
- Usuario puede conceder permisos desde ajustes del sistema

**Postcondiciones:**
- Mapa centrado en ubicación actual del usuario
- Datos de gasolineras actualizados para nueva posición
- Variable `_currentPosition` actualizada

---

## Especificaciones Técnicas

### Arquitectura del Componente

```
MapScreen (Presentation)
    |
    v
_recenterMap() método
    |
    |---> Geolocator.getCurrentPosition() (GPS Service)
    |
    |---> GoogleMapController.animateCamera() (Google Maps)
    |
    |---> setState() -> Actualizar _currentPosition
    |
    |---> [FUTURO] MapBloc.add(RecenterMap()) -> Recargar gasolineras
```

### Dependencias Requeridas

Ya incluidas en `pubspec.yaml`:
```yaml
dependencies:
  geolocator: ^10.0.0        # Obtención de ubicación GPS
  google_maps_flutter: ^2.5.0 # Control de cámara y animaciones
  permission_handler: ^11.0.0 # Gestión de permisos (diálogos)
```

### Permisos Android

Ya configurados en `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## Diseño de la Interfaz

### IU-02: Pantalla Principal - Mapa (Actualizada)

#### Layout Completo
```
┌─────────────────────────────────────────────────┐
│ [⚙️ Configuración]        BuscaGas        [     │ ← AppBar
├─────────────────────────────────────────────────┤
│ [Gasolina 95]   [Diésel Gasóleo A]              │ ← Selector combustible
├─────────────────────────────────────────────────┤
│                                                 │
│                 [ MAPA INTERACTIVO ]            │
│                                                 │
│          🟢 🟠 🔴 Marcadores con precios        │
│                                                 │
│                 🔵 Usuario aquí                 │
│                                                 │
│                                                 │
├─────────────────────────────────────────────────┤
│                               [📍 Mi Loc] ←──── │ Botón flotante (FloatingActionButton)
└─────────────────────────────────────────────────┘
```

#### Especificaciones del Botón de Recentrado

**Componente:** `FloatingActionButton`

**Posición:** 
- Esquina inferior derecha
- Padding desde bordes: `FloatingActionButton` por defecto (16px)
- Se oculta cuando:
  - `_isLoading == true` (cargando datos)
  - `_errorMessage != null` (hay error de ubicación)

**Propiedades:**
```dart
FloatingActionButton(
  onPressed: _recenterMap,        // Callback al método de recentrado
  tooltip: 'Mi ubicación',        // Texto de ayuda (long press)
  child: Icon(Icons.my_location), // Icono de ubicación
)
```

**Icono:** `Icons.my_location` (Material Icons)
- Círculo con punto central
- Color: `Theme.of(context).colorScheme.onPrimaryContainer`
- Tamaño: 24x24 px (estándar)

**Color de fondo:**
- Tema claro: `primaryContainer` (azul suave)
- Tema oscuro: `primaryContainer` (azul oscuro)

**Elevación:** 6.0 (por defecto de FloatingActionButton)

**Animación al presionar:**
- Efecto ripple estándar de Material Design
- Feedback háptico (vibración corta) automático

---

## Implementación Detallada

### Estructura Actual de MapScreen

**Estado Relevante:**
```dart
class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;  // Control del mapa
  Position? _currentPosition;           // Ubicación actual
  FuelType _selectedFuel = FuelType.gasolina95;
  bool _isLoading = true;
  String? _errorMessage;
}
```

### Método Principal: `_recenterMap()`

**Ubicación:** `lib/presentation/screens/map_screen.dart`

**Código Completo:**
```dart
/// Recentrar el mapa en la ubicación actual
/// 
/// Flujo:
/// 1. Verificar que el controlador del mapa esté inicializado
/// 2. Obtener ubicación GPS actual con alta precisión
/// 3. Animar cámara a nueva posición con zoom 13
/// 4. Actualizar estado con nueva posición
/// 5. [FUTURO] Recargar gasolineras cercanas
/// 
/// Errores:
/// - Si no hay GPS: Muestra SnackBar con mensaje de error
/// - Si no hay permisos: Ya manejado por _checkLocationPermission()
Future<void> _recenterMap() async {
  // Verificar que el controlador está listo
  if (_mapController == null) return;
  
  try {
    // 1. Obtener ubicación actual con alta precisión
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // 2. Animar cámara a nueva posición
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 13.0, // Zoom estándar para ver gasolineras cercanas
        ),
      ),
    );
    
    // 3. Actualizar estado
    setState(() {
      _currentPosition = position;
    });
    
    // 4. TODO: Recargar gasolineras cercanas (Paso 8 - BLoC)
    // context.read<MapBloc>().add(RecenterMap(
    //   latitude: position.latitude,
    //   longitude: position.longitude,
    // ));
    
  } catch (e) {
    // Manejar error de ubicación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _recenterMap,
          ),
        ),
      );
    }
  }
}
```

### Método Auxiliar: `_buildRecenterButton()`

**Código Completo:**
```dart
/// Construir botón de recentrado
/// 
/// FloatingActionButton con icono de ubicación
/// Se posiciona automáticamente en esquina inferior derecha
Widget _buildRecenterButton() {
  return FloatingActionButton(
    onPressed: _recenterMap,
    tooltip: 'Mi ubicación',
    child: const Icon(Icons.my_location),
  );
}
```

### Integración en el Widget Tree

**Modificación del método `build()`:**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
    floatingActionButton: _isLoading || _errorMessage != null 
        ? null                      // Ocultar si hay error o está cargando
        : _buildRecenterButton(),   // Mostrar en estado normal
  );
}
```

**Lógica de Visibilidad:**
- ✅ **Mostrar botón cuando:**
  - `_isLoading == false` (mapa cargado)
  - `_errorMessage == null` (sin errores)
  - `_currentPosition != null` (hay ubicación)

- ❌ **Ocultar botón cuando:**
  - `_isLoading == true` (pantalla de carga)
  - `_errorMessage != null` (pantalla de error)
  - Permisos denegados (estado de error)

---

## Integración con BLoC

### Evento: RecenterMap

**Ubicación:** `lib/presentation/blocs/map/map_event.dart` (FUTURO - Paso 8)

**Definición:**
```dart
/// Evento para recentrar el mapa en la ubicación actual
/// 
/// Se dispara cuando el usuario toca el botón "Mi ubicación"
/// Causa:
/// - Obtención de nueva posición GPS
/// - Recarga de gasolineras cercanas
/// - Actualización de marcadores
class RecenterMap extends MapEvent {
  final double latitude;
  final double longitude;
  
  const RecenterMap({
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [latitude, longitude];
}
```

### Handler en MapBloc

**Ubicación:** `lib/presentation/blocs/map/map_bloc.dart` (FUTURO - Paso 8)

**Registro del Handler:**
```dart
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetNearbyStationsUseCase _getNearbyStations;
  final AppSettings _settings;
  
  MapBloc(this._getNearbyStations, this._settings) : super(MapLoading()) {
    on<LoadMapData>(_onLoadMapData);
    on<ChangeFuelType>(_onChangeFuelType);
    on<RecenterMap>(_onRecenterMap);  // ← Nuevo handler
  }
  
  // ... otros handlers ...
}
```

**Implementación del Handler:**
```dart
/// Manejar evento de recentrado
/// 
/// 1. Mantener estado actual de combustible
/// 2. Recargar gasolineras con nueva ubicación
/// 3. Recalcular rangos de precio
/// 4. Emitir nuevo estado MapLoaded
Future<void> _onRecenterMap(
  RecenterMap event,
  Emitter<MapState> emit,
) async {
  // Obtener combustible actual del estado previo
  final currentFuel = state is MapLoaded 
      ? (state as MapLoaded).currentFuel 
      : _settings.preferredFuel;
  
  // Emitir loading temporal (opcional, para feedback visual)
  emit(MapLoading());
  
  try {
    // 1. Obtener gasolineras cercanas a nueva ubicación
    final stations = await _getNearbyStations(
      latitude: event.latitude,
      longitude: event.longitude,
      radiusKm: _settings.searchRadius.toDouble(),
      fuelType: currentFuel,
    );
    
    // 2. Asignar rangos de precio
    PriceRangeCalculator.assignPriceRanges(stations, currentFuel);
    
    // 3. Emitir nuevo estado con datos actualizados
    emit(MapLoaded(
      stations: stations,
      currentFuel: currentFuel,
    ));
    
  } catch (e) {
    emit(MapError(message: 'Error al recargar gasolineras: $e'));
  }
}
```

### Uso en MapScreen (FUTURO)

**Modificación de `_recenterMap()` para usar BLoC:**
```dart
Future<void> _recenterMap() async {
  if (_mapController == null) return;
  
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
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
    
    // Disparar evento de recentrado al BLoC
    context.read<MapBloc>().add(RecenterMap(
      latitude: position.latitude,
      longitude: position.longitude,
    ));
    
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }
}
```

---

## Pruebas y Validación

### Pruebas Unitarias

**Archivo:** `test/presentation/screens/map_screen_test.dart`

**Test 1: Verificar que el botón se muestra correctamente**
```dart
testWidgets('debe mostrar FloatingActionButton cuando el mapa está cargado', 
  (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(home: MapScreen()),
  );
  
  // Esperar a que termine la carga
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.byType(FloatingActionButton), findsOneWidget);
  expect(find.byIcon(Icons.my_location), findsOneWidget);
});
```

**Test 2: Verificar que el botón NO se muestra durante carga**
```dart
testWidgets('NO debe mostrar FloatingActionButton mientras carga', 
  (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(home: MapScreen()),
  );
  
  // No esperar a que termine la carga
  await tester.pump(Duration.zero);
  
  // Assert
  expect(find.byType(FloatingActionButton), findsNothing);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

**Test 3: Verificar tooltip**
```dart
testWidgets('botón debe tener tooltip "Mi ubicación"', 
  (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: MapScreen()));
  await tester.pumpAndSettle();
  
  final fab = tester.widget<FloatingActionButton>(
    find.byType(FloatingActionButton),
  );
  
  expect(fab.tooltip, equals('Mi ubicación'));
});
```

### Pruebas de Integración

**Archivo:** `test/integration/recenter_map_test.dart`

**Test: Flujo completo de recentrado**
```dart
testWidgets('debe recentrar mapa al tocar botón', (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Simular ubicación inicial
  // (requiere mock de Geolocator)
  
  // Act
  await tester.tap(find.byIcon(Icons.my_location));
  await tester.pumpAndSettle();
  
  // Assert
  // Verificar que la cámara se movió
  // Verificar que se actualizó _currentPosition
  expect(find.byType(GoogleMap), findsOneWidget);
});
```

### Pruebas Manuales

#### Checklist de Validación

**Funcionalidad Básica:**
- [ ] Botón flotante visible en esquina inferior derecha
- [ ] Icono `my_location` se muestra correctamente
- [ ] Tooltip "Mi ubicación" aparece al mantener presionado
- [ ] Botón responde al toque (efecto ripple)

**Comportamiento de Recentrado:**
- [ ] Toque en botón centra el mapa en ubicación actual
- [ ] Animación de cámara es suave (no abrupta)
- [ ] Zoom final es 13.0
- [ ] Marcador azul de "Mi ubicación" se muestra en el centro

**Manejo de Errores:**
- [ ] Si GPS está desactivado: SnackBar con mensaje claro
- [ ] Si permisos denegados: Diálogo explicativo
- [ ] Botón "Reintentar" en SnackBar funciona
- [ ] Botón "Abrir Configuración" lleva a ajustes del sistema

**Estados de UI:**
- [ ] Botón NO visible durante carga inicial
- [ ] Botón NO visible cuando hay error de permisos
- [ ] Botón reaparece después de conceder permisos

**Temas:**
- [ ] Botón se ve bien en tema claro
- [ ] Botón se ve bien en tema oscuro
- [ ] Contraste adecuado en ambos temas

**Rendimiento:**
- [ ] Tiempo de recentrado < 1 segundo
- [ ] Animación fluida (60 FPS)
- [ ] Sin lag al obtener ubicación

---

## Criterios de Aceptación

### Criterios Funcionales

1. ✅ **Botón de Recentrado Visible**
   - FloatingActionButton presente en MapScreen
   - Icono `Icons.my_location` correcto
   - Tooltip "Mi ubicación" configurado

2. ✅ **Recentrado Funcional**
   - Toque en botón obtiene ubicación GPS actual
   - Mapa se centra en nueva ubicación con animación
   - Zoom final es 13.0
   - Variable `_currentPosition` actualizada

3. ✅ **Manejo de Errores**
   - Error de GPS muestra SnackBar con mensaje claro
   - SnackBar incluye acción "Reintentar"
   - Error de permisos muestra diálogo explicativo

4. ✅ **Estados de UI**
   - Botón oculto durante `_isLoading == true`
   - Botón oculto cuando `_errorMessage != null`
   - Botón visible solo en estado normal

### Criterios No Funcionales

1. ✅ **Rendimiento**
   - Tiempo de obtención de ubicación < 2 segundos
   - Animación de cámara < 1 segundo
   - Respuesta total < 3 segundos

2. ✅ **Usabilidad**
   - Botón accesible con un toque
   - Área táctil mínima 48x48 dp (estándar Material)
   - Feedback visual inmediato al tocar

3. ✅ **Accesibilidad**
   - Tooltip para lectores de pantalla
   - Contraste adecuado (WCAG AA)
   - Tamaño de toque adecuado

4. ✅ **Compatibilidad**
   - Funciona en Android 6.0+ (API 23)
   - Compatible con temas claro/oscuro

### Métricas de Calidad

| Métrica | Valor Esperado | Método de Medición |
|---------|---------------|-------------------|
| Tiempo de recentrado | < 3 segundos | Prueba manual con cronómetro |
| Precisión GPS | ±10 metros | Comparar con Google Maps |
| Tasa de éxito | > 95% | 20 intentos en diferentes ubicaciones |
| Fluidez de animación | 60 FPS | Flutter DevTools (Performance) |

---

## Anexos

### A. Parámetros de Configuración

**Zoom Level:**
```dart
const double RECENTER_ZOOM = 13.0;  // Zoom estándar para gasolineras
```

**Precisión GPS:**
```dart
LocationAccuracy.high  // Precisión < 10 metros (recomendado)
// Alternativas:
// LocationAccuracy.best      // < 5 metros (consume más batería)
// LocationAccuracy.medium    // < 100 metros (ahorra batería)
```

**Duración de SnackBar:**
```dart
const Duration(seconds: 3)  // Tiempo de visualización de errores
```

### B. Códigos de Error Comunes

| Código | Descripción | Mensaje al Usuario |
|--------|-------------|-------------------|
| `PermissionDenied` | Permisos denegados temporalmente | "Permisos de ubicación denegados" |
| `PermissionDeniedForever` | Permisos denegados permanentemente | "Activa permisos en configuración" |
| `LocationServiceDisabled` | GPS desactivado | "Activa los servicios de ubicación" |
| `Timeout` | GPS no responde en 10s | "No se pudo obtener ubicación. Reintentar" |

### C. Referencias de la Documentación

**Secciones Relevantes de la Documentación V3:**

1. **CU-03: Recentrar Mapa en Ubicación Actual** (Línea 237)
   - Actor, precondiciones, flujos, postcondiciones

2. **RF-01: Geolocalización** (Línea 58)
   - Requisito de botón de recentrado

3. **IU-02: Pantalla Principal - Mapa** (Línea 690)
   - Especificaciones visuales del botón

4. **DSI 2: MapBloc - RecenterMap Event** (Línea 1791)
   - Arquitectura de evento de recentrado

5. **ASI 6: Diagrama de Flujo** (Línea 585)
   - Proceso de recentrado en contexto general

### D. Próximos Pasos

**Mejoras Futuras (No en MVP):**

1. **Indicador de Carga en Botón:**
   ```dart
   FloatingActionButton(
     child: _isRecentering 
       ? CircularProgressIndicator(color: Colors.white)
       : Icon(Icons.my_location),
   )
   ```

2. **Vibración Háptica:**
   ```dart
   import 'package:flutter/services.dart';
   HapticFeedback.lightImpact(); // Al tocar botón
   ```

3. **Animación de Icono:**
   ```dart
   AnimatedIcon(
     icon: AnimatedIcons.location_off_location,
     progress: _animationController,
   )
   ```

4. **Recentrado Automático:**
   - Después de X minutos de inactividad
   - Si el usuario se aleja más de Y km

---

## Resumen Ejecutivo

### Estado Actual (PRE-Paso 16)
- ✅ MapScreen implementado con Google Maps
- ✅ Método `_recenterMap()` ya existente y funcional
- ✅ Método `_buildRecenterButton()` ya implementado
- ✅ Botón visible solo en estados normales
- ✅ Manejo de errores con SnackBar
- ⚠️ **NOTA:** El código ya tiene la funcionalidad completa del Paso 16

### Tareas del Paso 16
Dado que el código ya está implementado, este paso consiste en:

1. ✅ **Verificar Implementación Actual**
   - Confirmar que `_recenterMap()` funciona correctamente
   - Validar que `_buildRecenterButton()` se muestra apropiadamente
   - Revisar manejo de errores

2. 📝 **Documentar Funcionalidad**
   - Crear PASO_16_COMPLETADO.md
   - Actualizar PASOS_DESARROLLO.md

3. 🧪 **Validar con Pruebas**
   - Crear test suite para funcionalidad de recentrado
   - Validar casos de error
   - Verificar integración con permisos

4. 🔄 **[OPCIONAL] Preparar para BLoC (Paso 8)**
   - Definir evento `RecenterMap`
   - Preparar handler `_onRecenterMap` en MapBloc
   - Documentar integración futura

### Archivos Afectados
- ✅ `lib/presentation/screens/map_screen.dart` - **YA IMPLEMENTADO**
- 📝 `PASO_16_COMPLETADO.md` - **POR CREAR**
- 📝 `PASOS_DESARROLLO.md` - **ACTUALIZAR**
- 🧪 `test/presentation/screens/map_screen_test.dart` - **POR CREAR**

### Líneas de Código Estimadas
- **Código de producción:** ~50 líneas (YA IMPLEMENTADAS)
- **Pruebas unitarias:** ~150 líneas
- **Documentación:** ~200 líneas

---

**Fecha de creación:** 1 de diciembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3  
**Documento de referencia:** BuscaGas Documentacion V3
