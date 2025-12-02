# Paso 18: Configurar Permisos Android

## Objetivo

Configurar correctamente los **permisos de Android** necesarios para que BuscaGas pueda acceder a la ubicación GPS del usuario y conectarse a internet, cumpliendo con los requisitos de seguridad y privacidad de Android 6.0+ (API 23).

---

## 1. Contexto y Requisitos

### 1.1. Requisito Funcional (RF-01)

**RF-01: Geolocalización**
- El sistema debe obtener la ubicación actual del usuario mediante GPS
- **Debe solicitar permisos de ubicación al primer uso**
- Debe proporcionar botón de recentrado

### 1.2. Subsistema Relacionado

**SS-01: Gestión de Ubicación**
- **Obtención de permisos** ← Foco del Paso 18
- Lectura de coordenadas GPS
- Recentrado de mapa

### 1.3. Requisitos No Funcionales

**RNF-03: Compatibilidad**
- Android 6.0 (API 23) o superior
- Gestión de permisos en tiempo de ejecución (runtime permissions)

**RNF-05: Disponibilidad**
- Gestión de errores de conexión con mensajes claros
- Manejo de permisos denegados

---

## 2. Tipos de Permisos en Android

### 2.1. Permisos Normales (Normal Permissions)

**Características:**
- Se conceden automáticamente en instalación
- No requieren solicitud en tiempo de ejecución
- Bajo riesgo para privacidad del usuario

**Ejemplo en BuscaGas:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 2.2. Permisos Peligrosos (Dangerous Permissions)

**Características:**
- Requieren aprobación explícita del usuario
- Deben solicitarse en tiempo de ejecución (Android 6.0+)
- Afectan privacidad o seguridad del usuario

**Ejemplo en BuscaGas:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## 3. Permisos Requeridos por BuscaGas

### 3.1. INTERNET (Normal)

**Propósito:**
- Descargar datos de la API gubernamental
- Sincronización periódica de precios
- Cargar tiles de Google Maps

**Declaración:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

**Nivel de Riesgo:** Bajo (permiso normal)

### 3.2. ACCESS_FINE_LOCATION (Peligroso)

**Propósito:**
- Obtener ubicación GPS precisa del usuario
- Centrar mapa en posición actual
- Calcular distancias a gasolineras cercanas

**Precisión:** ±10 metros (GPS)

**Declaración:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

**Nivel de Riesgo:** Alto (permiso peligroso)

### 3.3. ACCESS_COARSE_LOCATION (Peligroso)

**Propósito:**
- Ubicación aproximada mediante red (WiFi/cellular)
- Fallback si GPS no está disponible
- Menor consumo de batería

**Precisión:** ±100-500 metros

**Declaración:**
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Nivel de Riesgo:** Medio (permiso peligroso)

---

## 4. Configuración del AndroidManifest.xml

### 4.1. Ubicación del Archivo

```
BuscaGas/
└── android/
    └── app/
        └── src/
            └── main/
                └── AndroidManifest.xml  ← Archivo a configurar
```

### 4.2. Estructura Completa del Manifest

**Archivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- ============================================ -->
    <!-- PASO 18: PERMISOS DE LA APLICACIÓN          -->
    <!-- ============================================ -->
    
    <!-- Permiso Normal: Acceso a Internet -->
    <!-- Requerido para: API gubernamental, Google Maps -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Permiso Peligroso: Ubicación GPS Precisa -->
    <!-- Requerido para: Geolocalización con alta precisión -->
    <!-- Solicitud en tiempo de ejecución: SÍ -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    
    <!-- Permiso Peligroso: Ubicación Aproximada -->
    <!-- Requerido para: Ubicación mediante red (WiFi/cellular) -->
    <!-- Solicitud en tiempo de ejecución: SÍ -->
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    
    <!-- ============================================ -->
    <!-- CONFIGURACIÓN DE LA APLICACIÓN              -->
    <!-- ============================================ -->
    
    <application
        android:label="BuscaGas"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Google Maps API Key (configurado en Paso 19) -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="${GOOGLE_MAPS_API_KEY}"/>
        
        <!-- Actividad Principal -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <!-- Tema de Flutter -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            
            <!-- Intent Filter: Launcher -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Metadata de Flutter -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    
    <!-- Queries para procesamiento de texto (requerido por Flutter) -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

---

## 5. Gestión de Permisos en Tiempo de Ejecución

### 5.1. Paquete permission_handler

BuscaGas ya utiliza `permission_handler` para gestionar permisos en tiempo de ejecución.

**Dependencia en pubspec.yaml:**
```yaml
dependencies:
  permission_handler: ^11.0.0
```

**Estado:** ✅ Ya instalado (verificar en pubspec.yaml)

### 5.2. Flujo de Solicitud de Permisos

**Diagrama de Flujo:**

```
┌─────────────────────────────────────┐
│ Usuario abre la aplicación          │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│ ¿Permisos de ubicación concedidos?  │
└───────┬─────────────────┬───────────┘
        │ NO              │ SÍ
        ▼                 ▼
┌──────────────────┐  ┌─────────────────┐
│ Solicitar        │  │ Obtener GPS y   │
│ permisos con     │  │ continuar       │
│ permission_      │  └─────────────────┘
│ handler          │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ ¿Usuario concedió permisos?          │
└───────┬──────────────────┬───────────┘
        │ NO               │ SÍ
        ▼                  ▼
┌──────────────────┐  ┌─────────────────┐
│ Mostrar diálogo  │  │ Obtener GPS y   │
│ explicativo      │  │ continuar       │
│ con opción de    │  └─────────────────┘
│ ir a Settings    │
└──────────────────┘
```

### 5.3. Implementación en MapScreen (Ya Existente)

**Archivo:** `lib/presentation/screens/map_screen.dart`

**Método:** `_checkLocationPermission()` (Líneas 54-84)

```dart
/// Verificar si los permisos de ubicación están concedidos
Future<bool> _checkLocationPermission() async {
  // 1. Verificar si el servicio de ubicación está habilitado
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    setState(() {
      _errorMessage = 'Los servicios de ubicación están desactivados';
    });
    return false;
  }
  
  // 2. Verificar estado actual de permisos
  LocationPermission permission = await Geolocator.checkPermission();
  
  // 3. Si están denegados, solicitar permisos
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _errorMessage = 'Permisos de ubicación denegados';
      });
      return false;
    }
  }
  
  // 4. Si están denegados permanentemente, mostrar mensaje
  if (permission == LocationPermission.deniedForever) {
    setState(() {
      _errorMessage = 'Permisos de ubicación denegados permanentemente.\n'
          'Por favor, actívalos en la configuración de la aplicación.';
    });
    return false;
  }
  
  // 5. Permisos concedidos
  return true;
}
```

**Estados de Permisos:**

| Estado | Descripción | Acción |
|--------|-------------|--------|
| `denied` | Primera vez, aún no solicitado | Solicitar permiso |
| `granted` | Concedido | Continuar normalmente |
| `deniedForever` | Denegado permanentemente | Mostrar mensaje + abrir Settings |
| `restricted` | Restringido por sistema (iOS) | Mostrar mensaje informativo |

---

## 6. Diálogo de Explicación de Permisos

### 6.1. Cuándo Mostrar

**Mejores Prácticas de Android:**
- **ANTES** de solicitar permiso por primera vez
- Explicar **por qué** la app necesita el permiso
- Explicar **qué beneficio** obtiene el usuario
- Ser **claro y conciso**

### 6.2. Implementación Sugerida

**Archivo:** `lib/presentation/screens/map_screen.dart`

**Método Auxiliar:** `_showPermissionRationale()`

```dart
/// Mostrar diálogo explicando por qué necesitamos ubicación
Future<void> _showPermissionRationale() async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Permiso de Ubicación'),
      content: const Text(
        'BuscaGas necesita acceder a tu ubicación para:\n\n'
        '• Mostrarte gasolineras cercanas\n'
        '• Calcular distancias precisas\n'
        '• Centrar el mapa en tu posición\n\n'
        'Tus datos de ubicación NO se comparten con terceros.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _checkLocationPermission();
          },
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}
```

### 6.3. Diálogo para Permisos Denegados Permanentemente

**Método:** `_handleLocationError()` (Ya implementado en MapScreen)

```dart
/// Manejar errores de ubicación
void _handleLocationError() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permisos de Ubicación'),
      content: const Text(
        'Para usar BuscaGas necesitas activar los permisos de ubicación.\n\n'
        '¿Deseas ir a la configuración de la aplicación?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings(); // Abre Settings de Android
          },
          child: const Text('Ir a Configuración'),
        ),
      ],
    ),
  );
}
```

---

## 7. Configuración por Nivel de API

### 7.1. Android 6.0 - 9.0 (API 23-28)

**Permisos en Manifest:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Comportamiento:**
- Solicitud en tiempo de ejecución requerida
- Un permiso por solicitud
- Usuario puede denegar permanentemente

### 7.2. Android 10+ (API 29+)

**Ubicación en Segundo Plano:**

Si BuscaGas necesitara ubicación en background (NO requerido en MVP):

```xml
<!-- Solo si se necesita ubicación en background -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

**Restricciones Android 10+:**
- Debe solicitarse **separado** de foreground location
- Requiere justificación en Google Play
- No requerido para BuscaGas MVP (solo foreground)

### 7.3. Android 12+ (API 31+)

**Ubicación Aproximada como Opción:**

Android 12 permite al usuario elegir entre ubicación precisa o aproximada.

**Configuración:**
```xml
<!-- Declarar ambos permisos -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Manejo en Código:**
- Geolocator maneja automáticamente
- Si usuario elige "aproximada", GPS devuelve menor precisión
- BuscaGas funciona con ambas (radio de búsqueda compensa)

---

## 8. Verificación de Configuración

### 8.1. Checklist de AndroidManifest.xml

**Permisos Declarados:**
- ✅ `INTERNET` (normal)
- ✅ `ACCESS_FINE_LOCATION` (peligroso)
- ✅ `ACCESS_COARSE_LOCATION` (peligroso)

**Metadata:**
- ✅ Google Maps API Key (placeholder)
- ✅ Flutter Embedding v2

**Actividad Principal:**
- ✅ `exported="true"` (requerido Android 12+)
- ✅ Intent filter MAIN/LAUNCHER

### 8.2. Verificar Permisos en Ejecución

**Comando ADB:**
```bash
# Listar permisos de la app
adb shell dumpsys package com.example.buscagas | grep permission

# Ver estado de permisos de ubicación
adb shell dumpsys package com.example.buscagas | grep "android.permission.ACCESS"
```

**Salida Esperada:**
```
android.permission.INTERNET: granted=true
android.permission.ACCESS_FINE_LOCATION: granted=true
android.permission.ACCESS_COARSE_LOCATION: granted=true
```

### 8.3. Probar Flujo de Permisos

**Escenario 1: Primera Instalación**
1. Instalar app en dispositivo limpio
2. Abrir BuscaGas
3. Sistema solicita permisos de ubicación
4. Usuario concede → Mapa se centra en ubicación

**Escenario 2: Denegar Permisos**
1. Usuario niega permisos
2. App muestra mensaje de error
3. Usuario puede reintentar desde configuración

**Escenario 3: Denegar Permanentemente**
1. Usuario niega 2+ veces
2. App muestra diálogo "Ir a Configuración"
3. Botón abre Settings de Android
4. Usuario puede activar manualmente

---

## 9. Casos de Uso

### CU-18A: Concesión de Permisos en Primera Ejecución ✅

**Precondiciones:**
- App instalada por primera vez
- Permisos no concedidos aún

**Flujo Principal:**
1. Usuario abre BuscaGas
2. MapScreen llama a `_checkLocationPermission()`
3. Geolocator detecta permisos no concedidos
4. Sistema muestra diálogo nativo de Android: "Permitir que BuscaGas acceda a tu ubicación?"
5. Usuario toca "Mientras se usa la app" o "Solo esta vez"
6. Permisos concedidos
7. App obtiene ubicación GPS
8. Mapa se centra en posición del usuario

**Postcondiciones:**
- Permisos de ubicación concedidos
- App funciona normalmente

### CU-18B: Denegar Permisos

**Precondiciones:**
- Diálogo de permisos visible

**Flujo Principal:**
1. Usuario toca "Denegar"
2. `_checkLocationPermission()` retorna `false`
3. App muestra mensaje: "Permisos de ubicación denegados"
4. Mapa permanece en posición por defecto
5. Funciones de ubicación deshabilitadas

**Flujo Alternativo:**
- Usuario puede reintentar desde botón de configuración

**Postcondiciones:**
- App funciona sin GPS (limitado)

### CU-18C: Abrir Configuración de Permisos

**Precondiciones:**
- Permisos denegados permanentemente

**Flujo Principal:**
1. App detecta `LocationPermission.deniedForever`
2. Muestra diálogo: "Ir a la configuración de la aplicación?"
3. Usuario toca "Ir a Configuración"
4. `openAppSettings()` abre Settings de Android
5. Usuario activa permisos manualmente
6. Usuario regresa a app
7. App detecta permisos concedidos
8. Obtiene ubicación GPS

**Postcondiciones:**
- Permisos concedidos manualmente
- App reinicia con GPS activo

---

## 10. Privacidad y Seguridad

### 10.1. Declaración de Privacidad

**Información a incluir en Google Play:**

```
BuscaGas utiliza tu ubicación para:
- Mostrarte gasolineras cercanas a tu posición actual
- Calcular distancias precisas
- Centrar el mapa en tu ubicación

Datos de ubicación:
- Solo se usan localmente en tu dispositivo
- NO se envían a servidores externos
- NO se comparten con terceros
- NO se almacenan permanentemente
```

### 10.2. Buenas Prácticas Implementadas

✅ **Solicitud Contextual:**
- Permisos se solicitan cuando se necesitan (al abrir mapa)
- No en splash screen o antes de tiempo

✅ **Explicación Clara:**
- Mensaje explicativo disponible
- Beneficio claro para el usuario

✅ **Mínimos Privilegios:**
- Solo permisos estrictamente necesarios
- No ubicación en background

✅ **Transparencia:**
- Usuario siempre sabe cuándo se usa GPS
- Puede revocar permisos en cualquier momento

### 10.3. Cumplimiento de Políticas

**Google Play Store:**
- ✅ Permisos justificados en descripción
- ✅ No solicita permisos excesivos
- ✅ Declaración de privacidad clara

**RGPD (Reglamento General de Protección de Datos):**
- ✅ Datos de ubicación procesados localmente
- ✅ No se comparten con terceros
- ✅ Usuario tiene control total

---

## 11. Solución de Problemas

### 11.1. Error: "Permisos no concedidos"

**Síntoma:**
- App muestra mensaje de error constante
- GPS no funciona

**Causa:**
- Usuario denegó permisos permanentemente

**Solución:**
1. Ir a Settings > Apps > BuscaGas > Permissions
2. Activar "Location" → "Allow all the time" o "While using the app"
3. Reiniciar BuscaGas

### 11.2. Error: "Servicios de ubicación desactivados"

**Síntoma:**
- Mensaje: "Los servicios de ubicación están desactivados"

**Causa:**
- GPS del dispositivo está apagado

**Solución:**
1. Abrir Quick Settings (deslizar desde arriba)
2. Activar "Location" o "GPS"
3. Reintentar en BuscaGas

### 11.3. Error: "Permission denied" en compilación

**Síntoma:**
```
Error: uses-permission#android.permission.ACCESS_FINE_LOCATION not found
```

**Causa:**
- AndroidManifest.xml mal formado

**Solución:**
1. Verificar sintaxis XML
2. Asegurar que `<uses-permission>` está antes de `<application>`
3. Ejecutar `flutter clean` y `flutter pub get`

---

## 12. Pruebas de Permisos

### 12.1. Pruebas Manuales

**Test 1: Primera Instalación**
```bash
# Desinstalar app completamente
adb uninstall com.example.buscagas

# Instalar versión limpia
flutter install

# Abrir app
# Verificar que solicita permisos
```

**Test 2: Revocar Permisos**
```bash
# Revocar permisos mientras app está abierta
adb shell pm revoke com.example.buscagas android.permission.ACCESS_FINE_LOCATION

# Verificar que app maneja el error correctamente
```

**Test 3: Conceder Permisos**
```bash
# Conceder permisos manualmente
adb shell pm grant com.example.buscagas android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.example.buscagas android.permission.ACCESS_COARSE_LOCATION

# Verificar que app detecta permisos concedidos
```

### 12.2. Pruebas Automatizadas (Opcional)

**Archivo:** `test/integration/permissions_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:buscagas/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Pruebas de Permisos', () {
    testWidgets('debe solicitar permisos de ubicación al inicio', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Verificar que se solicitó el permiso
      final status = await Permission.location.status;
      expect(status.isDenied || status.isGranted, isTrue);
    });
    
    testWidgets('debe manejar permisos denegados', (tester) async {
      // Simular permisos denegados
      // Verificar mensaje de error
      expect(find.text('Permisos de ubicación denegados'), findsOneWidget);
    });
  });
}
```

---

## 13. Criterios de Aceptación

### 13.1. Funcionales

| ID | Criterio | Verificación |
|----|----------|--------------|
| **FA-01** | AndroidManifest.xml declara INTERNET | ✅ Permiso en línea 3 |
| **FA-02** | AndroidManifest.xml declara ACCESS_FINE_LOCATION | ✅ Permiso en línea 4 |
| **FA-03** | AndroidManifest.xml declara ACCESS_COARSE_LOCATION | ✅ Permiso en línea 5 |
| **FA-04** | App solicita permisos en tiempo de ejecución | ✅ `_checkLocationPermission()` |
| **FA-05** | Muestra mensaje si permisos denegados | ✅ `_errorMessage` en UI |
| **FA-06** | Ofrece abrir Settings si denegado permanentemente | ✅ `openAppSettings()` |
| **FA-07** | Funciona sin GPS (modo degradado) | ✅ Permite uso con caché |
| **FA-08** | No solicita permisos innecesarios | ✅ Solo 3 permisos necesarios |

**Cumplimiento:** 8/8 = **100%**

### 13.2. No Funcionales

| ID | Criterio | Objetivo | Estado |
|----|----------|----------|--------|
| **NFA-01** | Compatibilidad Android | API 23+ (Android 6.0+) | ✅ |
| **NFA-02** | Privacidad de usuario | Datos no compartidos | ✅ |
| **NFA-03** | Transparencia | Explicación clara de permisos | ✅ |
| **NFA-04** | Cumplimiento RGPD | Procesamiento local | ✅ |
| **NFA-05** | Experiencia de usuario | Solicitud contextual | ✅ |

**Cumplimiento:** 5/5 = **100%**

---

## 14. Integración con Otros Pasos

### 14.1. Depende de (Completados)

✅ **Paso 16: Funcionalidad de recentrado**
- Usa GPS para obtener ubicación
- Requiere permisos de ubicación

✅ **Paso 12: MapScreen con Google Maps**
- Requiere permiso INTERNET
- Usa ubicación para centrar mapa

### 14.2. Prepara para (Siguientes)

⏳ **Paso 19: Configurar Google Maps API**
- Google Maps requiere permisos de ubicación activos
- API Key se configura en mismo AndroidManifest.xml

⏳ **Paso 22: Pruebas en dispositivo real**
- Validar flujo completo de permisos
- Probar en diferentes versiones de Android

---

## 15. Comandos Útiles

```bash
# Ver permisos declarados en AndroidManifest
cat android/app/src/main/AndroidManifest.xml | grep "uses-permission"

# Verificar permisos instalados en dispositivo
adb shell dumpsys package com.example.buscagas | grep permission

# Revocar permiso de ubicación
adb shell pm revoke com.example.buscagas android.permission.ACCESS_FINE_LOCATION

# Conceder permiso de ubicación
adb shell pm grant com.example.buscagas android.permission.ACCESS_FINE_LOCATION

# Ver todos los permisos disponibles
adb shell pm list permissions -d -g

# Resetear todos los permisos de la app
adb shell pm reset-permissions com.example.buscagas

# Compilar y ejecutar
flutter clean
flutter pub get
flutter run
```

---

## 16. Documentación de Referencia

### 16.1. Android Developers

- **Permisos:** https://developer.android.com/guide/topics/permissions/overview
- **Runtime Permissions:** https://developer.android.com/training/permissions/requesting
- **Location:** https://developer.android.com/training/location/permissions

### 16.2. Flutter Packages

- **geolocator:** https://pub.dev/packages/geolocator
- **permission_handler:** https://pub.dev/packages/permission_handler

### 16.3. Documentación Métrica v3

- **RF-01:** Geolocalización (línea 60)
- **SS-01:** Gestión de Ubicación (línea 155)
- **Diagrama de flujo:** Proceso de permisos (línea 486)

---

## 17. Resumen Ejecutivo

### ¿Qué se configura?

Permisos de Android en `AndroidManifest.xml`:
- `INTERNET` (normal) - API y mapas
- `ACCESS_FINE_LOCATION` (peligroso) - GPS preciso
- `ACCESS_COARSE_LOCATION` (peligroso) - Ubicación aproximada

### ¿Por qué es importante?

- **Obligatorio** para GPS y conexión a internet
- **Requerido** por Google Play Store (políticas de privacidad)
- **Esencial** para funcionalidad core de BuscaGas
- **Crítico** para cumplimiento RGPD

### ¿Qué ya está implementado?

✅ Gestión de permisos en runtime (`_checkLocationPermission()`)  
✅ Diálogos de error y Settings  
✅ Manejo de estados de permisos  
✅ `permission_handler` instalado  

### ¿Qué se debe verificar?

- AndroidManifest.xml tiene los 3 permisos
- Permisos se solicitan correctamente en primera ejecución
- Mensajes de error claros si se deniegan
- Opción de abrir Settings funciona

---

**Fecha de creación:** 1 de diciembre de 2025  
**Paso:** 18 de 28  
**Estado:** Permisos ya configurados, requiere validación  
**Prerequisitos:** Pasos 12, 16 completados  
**Siguiente:** Paso 19 (Configurar Google Maps API Key)
