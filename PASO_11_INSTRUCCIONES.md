# PASO 11: CREAR PANTALLA DE INICIO (SPLASH)

## Objetivo
Implementar la pantalla de inicio (Splash Screen) de BuscaGas, que se mostrará durante la carga inicial de la aplicación y, en la primera ejecución, solicitará al usuario su preferencia de tema (claro/oscuro).

---

## Especificaciones según Documentación V3

### IU-01: Pantalla de Inicio

**Elementos visuales:**
- Logo de BuscaGas (centrado)
- Indicador de carga (spinner/circular progress)
- Texto: "Cargando datos..."
- **[Solo primera vez]** Diálogo: "¿Prefieres tema claro u oscuro?"

**Comportamiento:**
- Duración máxima: 3 segundos
- Transición automática a Pantalla Principal (MapScreen)
- Detección de primera ejecución
- Solicitud de preferencia de tema en primera ejecución
- Persistencia de la flag de primera ejecución

### RF-07: Experiencia Inicial
- Pantalla de inicio con logo durante carga inicial
- Solicitud de preferencia de tema claro/oscuro (solo primera ejecución)

---

## Flujo de Proceso (según DSI 6)

```
INICIO
  ↓
Mostrar Pantalla Inicio con Logo
  ↓
¿Primera Ejecución?
  ├─ Sí → Solicitar preferencia de tema (claro/oscuro)
  └─ No → Continuar
  ↓
[Continúa con permisos de ubicación y carga de datos]
  ↓
Transición a MapScreen
```

---

## Implementación Técnica

### 1. Archivo: `lib/presentation/screens/splash_screen.dart`

**Responsabilidades:**
- Mostrar logo de BuscaGas
- Mostrar indicador de carga
- Detectar si es primera ejecución
- Mostrar diálogo de selección de tema (primera vez)
- Realizar carga inicial de datos
- Navegar a MapScreen cuando termine

**Estructura del Widget:**

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buscagas/core/constants/app_constants.dart';
import 'package:buscagas/domain/entities/app_settings.dart';
import 'package:buscagas/presentation/screens/map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Verificar si es primera ejecución
    // 2. Si es primera vez, mostrar diálogo de tema
    // 3. Realizar carga inicial (opcional)
    // 4. Esperar mínimo de 1-2 segundos para mostrar logo
    // 5. Navegar a MapScreen
  }

  Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_run') ?? true;
  }

  Future<void> _setFirstRunComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run', false);
  }

  Future<void> _showThemeDialog() async {
    // Mostrar diálogo para seleccionar tema
    // Guardar preferencia en AppSettings
  }

  @override
  Widget build(BuildContext context) {
    // UI con logo centrado, spinner y texto
  }
}
```

---

## Componentes a Implementar

### 1.1. Detección de Primera Ejecución

Usar `SharedPreferences` para almacenar una bandera `first_run`:

```dart
Future<bool> _isFirstRun() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('first_run') ?? true;
}

Future<void> _setFirstRunComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('first_run', false);
}
```

### 1.2. Diálogo de Selección de Tema

```dart
Future<void> _showThemeDialog() async {
  final darkMode = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // No permitir cerrar tocando fuera
    builder: (context) => AlertDialog(
      title: const Text('Bienvenido a BuscaGas'),
      content: const Text('¿Prefieres tema claro u oscuro?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('☀️ Claro'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('🌙 Oscuro'),
        ),
      ],
    ),
  ) ?? false; // Default a false (claro) si se cierra de alguna forma
  
  // Guardar preferencia
  final settings = await AppSettings.load();
  settings.darkMode = darkMode;
  await settings.save();
  
  // Actualizar tema de la app (requiere notificar al widget raíz)
  // Esto se manejará mediante el state management de main.dart
}
```

### 1.3. Inicialización de la App

```dart
Future<void> _initializeApp() async {
  try {
    // 1. Verificar primera ejecución
    final isFirstRun = await _isFirstRun();
    
    if (isFirstRun) {
      // Esperar un momento para que se vea el logo
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 2. Mostrar diálogo de tema
      if (mounted) {
        await _showThemeDialog();
      }
      
      // 3. Marcar como completado
      await _setFirstRunComplete();
    }
    
    // 4. Carga inicial (opcional en este paso, se puede hacer en MapScreen)
    // Por ejemplo: cargar settings, verificar caché, etc.
    await Future.delayed(const Duration(seconds: 1));
    
    // 5. Navegar a MapScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    }
  } catch (e) {
    // Manejo de errores
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inicializar: $e')),
      );
    }
  }
}
```

### 1.4. Interfaz de Usuario

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Icon(
            Icons.local_gas_station,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          
          // Nombre de la app
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 40),
          
          // Indicador de carga
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Texto de carga
          Text(
            'Cargando datos...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## Consideraciones de Diseño

### Logo
Para el MVP, usar el icono de Material Design `Icons.local_gas_station`. En una versión posterior, se puede reemplazar por un logo personalizado usando:

```dart
// Opción 1: Imagen local
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
)

// Opción 2: SVG (requiere flutter_svg)
SvgPicture.asset(
  'assets/images/logo.svg',
  width: 100,
  height: 100,
)
```

### Colores y Tema
- Usar los colores del tema actual (`Theme.of(context)`)
- El diálogo debe respetar el tema del sistema hasta que el usuario elija
- Después de la selección, la app debe cambiar al tema elegido

### Tiempos
- Mínimo de visualización: 1 segundo (para que se vea el logo)
- Máximo de visualización: 3 segundos (según especificación)
- Si la carga es muy rápida, añadir delay artificial
- Si la carga es muy lenta, considerar mostrar mensaje de progreso

---

## Integración con main.dart

Para que el cambio de tema funcione correctamente después del diálogo, `main.dart` debe reaccionar a los cambios:

### Opción 1: Recargar la app completa (simple)

```dart
// En splash_screen.dart, después de guardar settings
if (mounted) {
  // Forzar reconstrucción completa de la app
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const BuscaGasApp()),
  );
}
```

### Opción 2: State management (recomendado)

```dart
// Usar un provider o similar para notificar cambios de tema
// Ya implementado en main.dart con StatefulWidget
```

---

## Manejo de Errores

### Casos a considerar:
1. **SharedPreferences no disponible**: Tratar como primera ejecución
2. **Usuario cierra el diálogo**: Usar tema claro por defecto
3. **Error al guardar settings**: Mostrar mensaje y continuar
4. **Error de navegación**: Registrar error y reintentar

```dart
try {
  // Código de inicialización
} catch (e) {
  debugPrint('Error en splash: $e');
  
  // Intentar navegar de todos modos
  if (mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }
}
```

---

## Testing

### Pruebas a realizar:

1. **Primera ejecución:**
   - Verificar que se muestra el diálogo
   - Seleccionar tema claro → Verificar que se aplica
   - Seleccionar tema oscuro → Verificar que se aplica
   - Verificar que la flag se guarda correctamente

2. **Ejecuciones posteriores:**
   - Verificar que NO se muestra el diálogo
   - Verificar que se navega directamente a MapScreen
   - Verificar que el tema guardado se aplica

3. **Tiempos:**
   - Verificar duración mínima de 1 segundo
   - Verificar que no excede 3 segundos
   - Verificar transición suave

4. **Errores:**
   - Simular error en SharedPreferences
   - Simular error en AppSettings
   - Verificar que la app no se bloquea

---

## Mejoras Futuras (Post-MVP)

1. **Animación del logo:**
   - Fade in del logo
   - Animación de escala
   - Transición suave a MapScreen

2. **Splash screen nativo:**
   - Configurar splash nativo en Android
   - Evitar "pantalla blanca" inicial

3. **Progreso de carga detallado:**
   - Mostrar qué se está cargando
   - Barra de progreso en lugar de spinner
   - Mensajes específicos (Cargando datos, Obteniendo ubicación, etc.)

4. **Verificación de conectividad:**
   - Detectar si hay conexión a internet
   - Mostrar mensaje si no hay conexión
   - Opción de continuar con caché

5. **Precarga de datos:**
   - Iniciar descarga de API en splash
   - Cachear datos mientras se muestra el logo
   - Optimizar tiempo de carga

---

## Checklist de Implementación

- [ ] Crear archivo `lib/presentation/screens/splash_screen.dart`
- [ ] Implementar `_isFirstRun()` con SharedPreferences
- [ ] Implementar `_setFirstRunComplete()`
- [ ] Crear diálogo de selección de tema `_showThemeDialog()`
- [ ] Implementar método `_initializeApp()` con flujo completo
- [ ] Diseñar UI con logo, spinner y texto
- [ ] Configurar navegación a MapScreen
- [ ] Integrar con AppSettings para guardar tema
- [ ] Añadir manejo de errores
- [ ] Probar primera ejecución
- [ ] Probar ejecuciones posteriores
- [ ] Verificar tiempos de carga
- [ ] Verificar cambio de tema funciona correctamente

---

## Dependencias Necesarias

Ya incluidas en `pubspec.yaml`:
- `shared_preferences: ^2.2.2` ✓
- `flutter/material.dart` ✓

---

## Notas Importantes

1. **Orden de ejecución**: El splash screen es la primera pantalla que ve el usuario, por lo que cualquier error aquí es crítico.

2. **Tema inicial**: Hasta que el usuario elija, se debe usar el tema del sistema o un tema por defecto.

3. **No bloquear**: La carga debe ser asíncrona y no bloquear la UI.

4. **Timeout**: Si la carga tarda más de 3 segundos, considerar mostrar un mensaje o continuar de todos modos.

5. **Permisos**: En este paso NO se solicitan permisos de ubicación (eso se hará en MapScreen o en un paso posterior).

---

**Fecha de creación:** 18 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Paso:** 11 - Pantalla de Inicio (Splash)  
**Metodología:** Métrica v3
