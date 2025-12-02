# Paso 19: Configurar Google Maps API Key

## Objetivo

Obtener y configurar correctamente la **API Key de Google Maps** para que el mapa interactivo de BuscaGas funcione correctamente, cumpliendo con los requisitos de visualización cartográfica del proyecto.

---

## 1. Contexto y Requisitos

### 1.1. Requisito Funcional (RF-02)

**RF-02: Visualización en Mapa**
- El sistema mostrará mapa interactivo con marcadores de gasolineras
- Los marcadores usarán código de color según rango de precios
- El mapa permitirá zoom y desplazamiento

### 1.2. Subsistema Relacionado

**SS-03: Visualización Cartográfica**
- Renderizado de mapa
- Gestión de marcadores
- Código de color según precio
- Interacción táctil

### 1.3. Dependencia Instalada

**Paquete:** `google_maps_flutter: ^2.5.0`
- **Estado:** ✅ Ya instalado en `pubspec.yaml`
- **Propósito:** Integración de Google Maps en Flutter
- **Plataforma:** Android (iOS requiere configuración adicional)

---

## 2. Arquitectura de Configuración Actual

### 2.1. Sistema de Placeholders

BuscaGas utiliza un sistema seguro de configuración de API Keys:

```
┌─────────────────────────────────────────────────────┐
│              FLUJO DE CONFIGURACIÓN                 │
└─────────────────────────────────────────────────────┘

1. local.properties (NO en Git)
   ↓
   GOOGLE_MAPS_API_KEY=AIzaSy...
   
2. build.gradle.kts (Lee local.properties)
   ↓
   manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = ...
   
3. AndroidManifest.xml (Usa placeholder)
   ↓
   android:value="${GOOGLE_MAPS_API_KEY}"
   
4. Aplicación ejecutándose
   ↓
   Google Maps activo con tu API Key
```

**Ventajas de este enfoque:**
- ✅ API Key no se sube al repositorio Git
- ✅ Cada desarrollador usa su propia clave
- ✅ Fácil cambio entre entornos (dev/prod)
- ✅ Cumple con mejores prácticas de seguridad

### 2.2. Configuración Existente

**Archivo:** `android/app/build.gradle.kts` (Línea 33)

```kotlin
manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = 
    project.findProperty("GOOGLE_MAPS_API_KEY") ?: ""
```

**Archivo:** `android/app/src/main/AndroidManifest.xml` (Líneas 12-15)

```xml
<!-- Google Maps API Key: loaded from local.properties via manifest placeholder -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}"/>
```

---

## 3. Obtener Google Maps API Key

### 3.1. Crear Proyecto en Google Cloud

**Paso 1: Acceder a Google Cloud Console**

1. Abre tu navegador
2. Ve a: https://console.cloud.google.com/
3. Inicia sesión con tu cuenta de Google

**Paso 2: Crear o Seleccionar Proyecto**

**Opción A: Crear Nuevo Proyecto**
1. Haz clic en el selector de proyectos (parte superior)
2. Clic en "NUEVO PROYECTO"
3. Configura:
   - **Nombre del proyecto:** `BuscaGas` (o el que prefieras)
   - **Organización:** (opcional)
   - **Ubicación:** (opcional)
4. Clic en "CREAR"
5. Espera 10-30 segundos a que se cree el proyecto
6. Selecciona el proyecto creado

**Opción B: Usar Proyecto Existente**
1. Selecciona tu proyecto existente del menú desplegable

### 3.2. Habilitar Maps SDK for Android

**Paso 3: Ir a la Biblioteca de APIs**

1. En el menú lateral izquierdo:
   - **APIs y servicios** → **Biblioteca**
   
2. O usa el buscador en la parte superior:
   - Escribe: "Maps SDK for Android"

**Paso 4: Habilitar la API**

1. Haz clic en **"Maps SDK for Android"**
2. Verás la página de descripción de la API
3. Haz clic en el botón **"HABILITAR"**
4. Espera 5-10 segundos mientras se habilita
5. Deberías ver el mensaje: "API habilitada"

**APIs Requeridas:**
- ✅ **Maps SDK for Android** (obligatorio)

**APIs Opcionales (para funcionalidades futuras):**
- ⏳ Places API (búsqueda de lugares)
- ⏳ Directions API (rutas de navegación)
- ⏳ Geocoding API (conversión dirección ↔ coordenadas)

### 3.3. Crear Credenciales (API Key)

**Paso 5: Crear la API Key**

1. En el menú lateral:
   - **APIs y servicios** → **Credenciales**

2. Haz clic en **"+ CREAR CREDENCIALES"**

3. Selecciona **"Clave de API"**

4. Se creará automáticamente una API Key
   - Aparecerá un diálogo con la clave
   - Ejemplo: `AIzaSyB1234567890abcdefGHIJKLMNOPQRSTUVWXYZ`

5. **IMPORTANTE:** Copia la API Key inmediatamente
   - Guárdala en un lugar seguro (notepad, gestor de contraseñas)
   - La necesitarás en el siguiente paso

**Paso 6: Nombrar la API Key (Recomendado)**

1. Haz clic en el lápiz de editar junto a la nueva API Key
2. Cambia el nombre a algo descriptivo:
   - **Nombre:** `BuscaGas Android Maps Key`
3. Guarda los cambios

---

## 4. Configurar API Key en el Proyecto

### 4.1. Método Seguro: local.properties (Recomendado)

Este método **NO** expone tu API Key en el repositorio Git.

**Paso 1: Abrir local.properties**

**Ubicación:** `android/local.properties`

**Contenido actual:**
```properties
sdk.dir=C:\\Users\\Ryuta\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\Users\\Ryuta\\Documents\\flutter\\flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
```

**Paso 2: Agregar tu API Key**

Agrega esta línea al final del archivo:

```properties
GOOGLE_MAPS_API_KEY=AIzaSyB1234567890abcdefGHIJKLMNOPQRSTUVWXYZ
```

**Reemplaza** `AIzaSyB1234567890abcdefGHIJKLMNOPQRSTUVWXYZ` con tu API Key real.

**Archivo completo:**
```properties
sdk.dir=C:\\Users\\Ryuta\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\Users\\Ryuta\\Documents\\flutter\\flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
GOOGLE_MAPS_API_KEY=TU_API_KEY_AQUI
```

**Paso 3: Verificar .gitignore**

Asegúrate de que `android/local.properties` esté en `.gitignore`:

**Ubicación:** `.gitignore` (raíz del proyecto)

```gitignore
# Android
**/android/local.properties
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/key.properties
*.jks
*.keystore
```

✅ Si `**/android/local.properties` está en `.gitignore`, tu API Key está segura.

### 4.2. Método Alternativo: Hardcoded (NO Recomendado)

**⚠️ ADVERTENCIA:** Este método expone tu API Key en Git. Solo para pruebas rápidas.

**Editar AndroidManifest.xml directamente:**

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyB1234567890abcdefGHIJKLMNOPQRSTUVWXYZ"/>
```

**NUNCA hagas commit de este cambio si usas Git.**

---

## 5. Restricciones de Seguridad (Recomendado)

### 5.1. Restricciones de Aplicación Android

Para evitar uso no autorizado de tu API Key:

**Paso 1: Obtener SHA-1 Fingerprint**

**Para Desarrollo (Debug Keystore):**

```bash
# Windows
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Salida esperada:**
```
Certificate fingerprints:
         SHA1: A1:B2:C3:D4:E5:F6:78:90:12:34:56:78:90:AB:CD:EF:12:34:56:78
         SHA256: ...
```

**Copia el SHA-1** (ej: `A1:B2:C3:D4:E5:F6:78:90:12:34:56:78:90:AB:CD:EF:12:34:56:78`)

**Para Producción (Release Keystore):**

```bash
keytool -list -v -keystore /ruta/a/tu/keystore.jks -alias tu-alias
```

**Paso 2: Configurar Restricciones en Google Cloud**

1. Ve a **Credenciales** en Google Cloud Console
2. Haz clic en tu API Key (`BuscaGas Android Maps Key`)
3. En **Restricciones de aplicación**:
   - Selecciona **"Aplicaciones de Android"**
   - Haz clic en **"+ AGREGAR UN ELEMENTO"**
   - Ingresa:
     * **Nombre del paquete:** `com.buscagas.buscagas`
     * **Huella digital del certificado SHA-1:** (pega tu SHA-1)
   - Haz clic en **"LISTO"**

4. En **Restricciones de API**:
   - Selecciona **"Restringir clave"**
   - Marca solo: **"Maps SDK for Android"**

5. Haz clic en **"GUARDAR"**

**Resultado:**
- ✅ Tu API Key solo funcionará con tu app (paquete `com.buscagas.buscagas`)
- ✅ Solo se puede usar con Maps SDK for Android
- ✅ Protegida contra uso no autorizado

### 5.2. Restricciones de Cuota (Opcional)

**Configurar límites de uso diario:**

1. En Google Cloud Console:
   - **APIs y servicios** → **Cuotas**
2. Busca "Maps SDK for Android"
3. Configura límites diarios (ej: 25,000 solicitudes/día)

**Beneficio:** Evita costos inesperados si se excede el uso gratuito.

---

## 6. Verificación de Configuración

### 6.1. Compilar el Proyecto

**Paso 1: Limpiar y Recompilar**

```bash
flutter clean
flutter pub get
cd android
./gradlew clean  # En Windows: gradlew.bat clean
cd ..
```

**Paso 2: Verificar que la API Key se carga correctamente**

Revisa el archivo generado (temporal):

```bash
# No existe hasta que compiles
# Pero puedes verificar que build.gradle.kts lea local.properties
```

### 6.2. Ejecutar en Dispositivo/Emulador

**Comando:**
```bash
flutter run
```

**Qué esperar:**

✅ **Configuración Correcta:**
- Mapa de Google Maps visible
- Puedes hacer zoom y desplazarte
- Marcadores (si ya están implementados) se muestran correctamente

❌ **Configuración Incorrecta:**

**Síntoma 1: Mapa gris/blanco**
- **Causa:** API Key no configurada o inválida
- **Solución:** Verifica `local.properties` y que la clave sea correcta

**Síntoma 2: Error en Logcat**
```
Authorization failure. Please see https://developers.google.com/maps/documentation/android-api/start for how to correctly set up the map.
```
- **Causa:** Maps SDK for Android no habilitado
- **Solución:** Habilita la API en Google Cloud Console

**Síntoma 3: "This API project is not authorized..."**
- **Causa:** Restricciones de aplicación incorrectas
- **Solución:** Verifica SHA-1 y nombre del paquete

### 6.3. Revisar Logs de Android

**Android Studio:**
1. Abre **Logcat** (parte inferior)
2. Filtra por: `Google Maps`
3. Busca mensajes de error o advertencias

**Mensajes esperados (OK):**
```
I/Google Maps Android API: Google Play services client version: 12451000
I/Google Maps Android API: Google Play services package version: 231214022
```

**Mensajes de error comunes:**
```
E/Google Maps Android API: Authorization failure
E/Google Maps Android API: API key not found
```

---

## 7. Pruebas de Validación

### 7.1. Prueba Visual Básica

**Test 1: Cargar Mapa**
1. Abre BuscaGas en el emulador/dispositivo
2. El mapa debe mostrarse correctamente
3. Posición inicial: España (o tu ubicación GPS)

**Test 2: Interacción con el Mapa**
1. Pellizca para hacer zoom → debe funcionar
2. Arrastra el mapa → debe desplazarse
3. Toca el botón "Mi ubicación" → debe centrarse en tu posición

**Test 3: Marcadores (Si ya implementados)**
1. Verifica que los marcadores se muestran
2. Colores según rango de precio funcionan
3. Tap en marcador muestra tarjeta de información

### 7.2. Pruebas de Conectividad

**Test 4: Sin Internet**
1. Desactiva WiFi y datos móviles
2. Abre BuscaGas
3. El mapa debe cargar tiles de caché (si las hay)
4. Mensaje de error claro si no hay caché

**Test 5: Internet Lento**
1. Limita velocidad de conexión (Android Developer Options)
2. Abre BuscaGas
3. Tiles del mapa deben cargar progresivamente
4. Indicador de carga visible

### 7.3. Validación de Configuración

**Checklist de Verificación:**

| Item | Estado | Verificación |
|------|--------|--------------|
| API Key obtenida de Google Cloud | ☐ | Copia guardada en lugar seguro |
| Maps SDK for Android habilitado | ☐ | Visible en Google Cloud Console |
| API Key en `local.properties` | ☐ | Archivo editado correctamente |
| `local.properties` en `.gitignore` | ☐ | API Key no se sube a Git |
| Placeholder en `AndroidManifest.xml` | ☐ | `${GOOGLE_MAPS_API_KEY}` presente |
| Gradle lee `local.properties` | ☐ | `manifestPlaceholders` en `build.gradle.kts` |
| Compilación exitosa | ☐ | `flutter run` sin errores |
| Mapa visible en app | ☐ | No aparece gris/blanco |
| Zoom y desplazamiento funcional | ☐ | Interacción táctil funciona |
| Restricciones de seguridad configuradas | ☐ | SHA-1 y paquete agregados |

---

## 8. Solución de Problemas

### 8.1. Mapa Aparece Gris o Vacío

**Causa Probable:** API Key no configurada o inválida

**Soluciones:**

1. **Verificar `local.properties`:**
   ```properties
   GOOGLE_MAPS_API_KEY=TU_CLAVE_AQUI
   ```
   - Asegúrate de que no haya espacios extra
   - Verifica que la clave esté completa

2. **Recompilar completamente:**
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

3. **Verificar en Logcat:**
   - Busca errores relacionados con "Authorization"
   - Copia el mensaje de error y búscalo en Google

### 8.2. Error: "API key not found"

**Causa:** Gradle no está leyendo `local.properties`

**Soluciones:**

1. **Verificar sintaxis en `build.gradle.kts`:**
   ```kotlin
   manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = 
       project.findProperty("GOOGLE_MAPS_API_KEY") ?: ""
   ```

2. **Verificar que `local.properties` existe:**
   ```bash
   # Debería existir en android/local.properties
   ls android/local.properties
   ```

3. **Método alternativo temporal:**
   - Edita `AndroidManifest.xml` directamente (hardcoded)
   - Solo para debugging, NO para producción

### 8.3. Error: "This API project is not authorized..."

**Causa:** Restricciones de aplicación Android incorrectas

**Soluciones:**

1. **Verificar SHA-1:**
   - Ejecuta comando `keytool` nuevamente
   - Compara SHA-1 con el configurado en Google Cloud

2. **Verificar nombre del paquete:**
   - Debe ser exactamente: `com.buscagas.buscagas`
   - Verifica en `build.gradle.kts` → `applicationId`

3. **Quitar restricciones temporalmente:**
   - En Google Cloud Console
   - Cambia a "Ninguna" en Restricciones de aplicación
   - Guarda y prueba
   - Si funciona, el problema es el SHA-1 o el paquete

### 8.4. Tiles del Mapa No Cargan

**Causa:** Problemas de red o caché

**Soluciones:**

1. **Verificar conexión a internet:**
   - Abre navegador y verifica conectividad

2. **Limpiar caché de app:**
   ```bash
   # Android Studio: Tools > Device File Explorer
   # Borrar: data/data/com.buscagas.buscagas/cache
   ```

3. **Reinstalar app:**
   ```bash
   flutter clean
   flutter run
   ```

### 8.5. Costos Inesperados

**Prevención:**

1. **Configurar alertas de facturación:**
   - Google Cloud Console → Facturación
   - Configurar presupuesto y alertas

2. **Límites de cuota:**
   - APIs y servicios → Cuotas
   - Configurar límite diario (ej: 25,000 solicitudes)

3. **Monitorear uso:**
   - Google Cloud Console → APIs y servicios → Panel
   - Revisar gráficos de uso diario

**Nivel Gratuito de Google Maps:**
- **$200 USD de crédito mensual** (gratis)
- Aproximadamente **28,000 cargas de mapa/mes** gratis
- BuscaGas con 100 usuarios activos diarios → ~3,000 cargas/mes → Gratis

---

## 9. Mejores Prácticas de Seguridad

### 9.1. Proteger la API Key

✅ **Hacer:**
- Usar `local.properties` (no versionado en Git)
- Agregar restricciones de aplicación (SHA-1)
- Limitar APIs habilitadas (solo Maps SDK for Android)
- Configurar alertas de cuota

❌ **NO Hacer:**
- Hardcodear API Key en código fuente
- Subir `local.properties` a Git
- Compartir API Key públicamente (GitHub, Stack Overflow)
- Dejar API Key sin restricciones

### 9.2. Variables de Entorno por Ambiente

**Para múltiples ambientes (dev/staging/prod):**

**local.properties:**
```properties
# Desarrollo
GOOGLE_MAPS_API_KEY_DEV=AIzaSyDEV...

# Producción
GOOGLE_MAPS_API_KEY_PROD=AIzaSyPROD...
```

**build.gradle.kts:**
```kotlin
val mapsApiKey = when (System.getenv("BUILD_ENV")) {
    "production" -> project.findProperty("GOOGLE_MAPS_API_KEY_PROD")
    else -> project.findProperty("GOOGLE_MAPS_API_KEY_DEV")
}

manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey ?: ""
```

### 9.3. Rotación de API Keys

**Cuándo rotar:**
- Si la clave se expone accidentalmente (GitHub, logs)
- Cada 6-12 meses (buena práctica)
- Antes de lanzar a producción (cambiar de dev a prod)

**Cómo rotar:**
1. Crear nueva API Key en Google Cloud
2. Actualizar `local.properties` con nueva clave
3. Recompilar y probar
4. Desactivar API Key antigua después de 1-2 semanas

---

## 10. Documentación Complementaria

### 10.1. Referencias Oficiales

**Google Maps Platform:**
- Documentación: https://developers.google.com/maps/documentation/android-sdk
- Guía de inicio: https://developers.google.com/maps/documentation/android-sdk/start
- Precios: https://developers.google.com/maps/billing-and-pricing/pricing

**Flutter Google Maps:**
- Paquete: https://pub.dev/packages/google_maps_flutter
- Documentación: https://pub.dev/packages/google_maps_flutter#usage
- Ejemplos: https://github.com/flutter/packages/tree/main/packages/google_maps_flutter

**Google Cloud Console:**
- Consola: https://console.cloud.google.com/
- APIs y servicios: https://console.cloud.google.com/apis
- Facturación: https://console.cloud.google.com/billing

### 10.2. Recursos Adicionales

**Tutoriales:**
- [Codelab: Google Maps en Flutter](https://codelabs.developers.google.com/codelabs/google-maps-in-flutter)
- [Restricciones de API Key](https://cloud.google.com/docs/authentication/api-keys)

**Herramientas:**
- [Playground de API Key](https://developers.google.com/maps/documentation/javascript/get-api-key)
- [Calculadora de precios](https://developers.google.com/maps/billing-and-pricing/pricing)

---

## 11. Integración con BuscaGas

### 11.1. Componentes que Requieren API Key

**MapScreen (`lib/presentation/screens/map_screen.dart`):**
```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(40.4168, -3.7038), // Madrid
    zoom: 6.0,
  ),
  myLocationEnabled: true,
  myLocationButtonEnabled: false,
  zoomControlsEnabled: false,
  // ... La API Key se configura automáticamente desde AndroidManifest
)
```

**No requiere cambios en código Dart.** Google Maps lee automáticamente la API Key del `AndroidManifest.xml`.

### 11.2. Funcionalidades Habilitadas

Con la API Key configurada, BuscaGas puede:

✅ **Funcionalidades Actuales:**
- Mostrar mapa interactivo de España
- Zoom y desplazamiento
- Marcador de ubicación del usuario
- Tiles de mapa actualizados

✅ **Funcionalidades Futuras (Pasos siguientes):**
- Marcadores de gasolineras con código de color
- Tarjetas de información al tocar marcadores
- Cálculo de rutas (requiere Directions API)
- Búsqueda de lugares (requiere Places API)

### 11.3. Preparación para Paso 20 (Pruebas)

Con la API Key configurada, el Paso 20 podrá:
- Probar visualización de mapas en tests de integración
- Validar carga de marcadores
- Verificar interacción táctil con el mapa

---

## 12. Criterios de Aceptación

### 12.1. Funcionales

| ID | Criterio | Verificación |
|----|----------|--------------|
| **FA-01** | API Key obtenida de Google Cloud Console | ✅ Clave guardada en lugar seguro |
| **FA-02** | Maps SDK for Android habilitado | ✅ Visible en Google Cloud Dashboard |
| **FA-03** | API Key configurada en `local.properties` | ✅ Archivo editado correctamente |
| **FA-04** | Placeholder en `AndroidManifest.xml` funcional | ✅ `${GOOGLE_MAPS_API_KEY}` presente |
| **FA-05** | Mapa se renderiza correctamente en app | ✅ No aparece gris o vacío |
| **FA-06** | Zoom y desplazamiento funcionan | ✅ Interacción táctil correcta |
| **FA-07** | Ubicación del usuario se muestra | ✅ Marcador azul visible |
| **FA-08** | Tiles del mapa cargan correctamente | ✅ Imágenes de Google Maps visibles |

**Cumplimiento Esperado:** 8/8 = **100%**

### 12.2. No Funcionales

| ID | Criterio | Objetivo | Estado |
|----|----------|----------|--------|
| **NFA-01** | Seguridad | API Key NO en repositorio Git | ✅ |
| **NFA-02** | Rendimiento | Mapa carga en < 3 segundos | ✅ |
| **NFA-03** | Restricciones | SHA-1 configurado para producción | ⏳ |
| **NFA-04** | Monitoreo | Alertas de cuota configuradas | ⏳ |
| **NFA-05** | Documentación | Instrucciones claras para equipo | ✅ |

**Cumplimiento Mínimo (MVP):** 3/5 = **60%** (NFA-01, NFA-02, NFA-05)  
**Cumplimiento Completo:** 5/5 = **100%** (incluye restricciones y monitoreo)

---

## 13. Comandos Útiles

### 13.1. Gestión de Certificados

```bash
# Ver debug keystore SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Ver release keystore SHA-1 (cuando tengas uno)
keytool -list -v -keystore /path/to/release.keystore -alias release-alias

# Generar nuevo keystore para producción (Paso 27)
keytool -genkey -v -keystore buscagas-release.keystore -alias buscagas -keyalg RSA -keysize 2048 -validity 10000
```

### 13.2. Limpieza y Reconstrucción

```bash
# Limpieza completa
flutter clean
cd android
./gradlew clean  # Windows: gradlew.bat clean
cd ..

# Reinstalar dependencias
flutter pub get

# Reconstruir
flutter run

# Ver logs mientras se ejecuta
flutter logs
```

### 13.3. Debugging

```bash
# Ver variables de Gradle
cd android
./gradlew properties | grep GOOGLE_MAPS_API_KEY

# Ver AndroidManifest compilado (temporal)
# Se genera en: build/app/intermediates/merged_manifests/debug/AndroidManifest.xml

# Ejecutar con logs detallados
flutter run -v
```

---

## 14. Checklist de Implementación

### Antes de Empezar
- [ ] Cuenta de Google activa
- [ ] Acceso a Google Cloud Console
- [ ] Proyecto BuscaGas abierto en VS Code
- [ ] Flutter y Android SDK configurados

### Obtención de API Key
- [ ] Creado/seleccionado proyecto en Google Cloud
- [ ] Habilitado "Maps SDK for Android"
- [ ] Creada API Key nueva
- [ ] Copiada API Key en lugar seguro
- [ ] Nombrada API Key descriptivamente

### Configuración en Proyecto
- [ ] Editado `android/local.properties`
- [ ] Agregada línea `GOOGLE_MAPS_API_KEY=...`
- [ ] Verificado `.gitignore` incluye `local.properties`
- [ ] Verificado placeholder en `AndroidManifest.xml`
- [ ] Verificado `build.gradle.kts` lee la propiedad

### Seguridad (Opcional pero Recomendado)
- [ ] Obtenido SHA-1 fingerprint de debug keystore
- [ ] Configuradas restricciones de aplicación Android
- [ ] Configuradas restricciones de API (solo Maps SDK)
- [ ] Configuradas alertas de cuota

### Validación
- [ ] Ejecutado `flutter clean`
- [ ] Ejecutado `flutter run`
- [ ] Mapa se muestra correctamente
- [ ] Zoom funciona
- [ ] Desplazamiento funciona
- [ ] No hay errores en Logcat

### Documentación
- [ ] Anotado dónde está guardada la API Key
- [ ] Documentado para otros desarrolladores del equipo
- [ ] Creado backup de API Key en gestor de contraseñas

---

## 15. Próximos Pasos

### Paso 20: Escribir Pruebas Unitarias
Con la API Key configurada, podrás:
- Crear tests de integración para MapScreen
- Validar que los marcadores se crean correctamente
- Probar interacción con el mapa

### Paso 21: Pruebas de Integración
- Probar conexión con API real de gasolineras
- Validar renderizado de marcadores en mapa
- Verificar flujo completo de usuario

### Paso 22: Pruebas en Dispositivo Real
- Probar en múltiples dispositivos Android
- Validar rendimiento de mapas
- Verificar GPS y permisos de ubicación

---

## 16. Resumen Ejecutivo

### ¿Qué se configura?

**API Key de Google Maps** para habilitar el mapa interactivo:
- Obtenida de Google Cloud Console
- Configurada en `android/local.properties` (no versionado)
- Inyectada en `AndroidManifest.xml` vía Gradle placeholders

### ¿Por qué es importante?

- **Obligatorio** para que Google Maps funcione
- **Crítico** para RF-02 (Visualización en Mapa)
- **Fundamental** para mostrar marcadores de gasolineras
- **Requerido** para todas las funcionalidades cartográficas

### ¿Qué se debe hacer?

1. ✅ Crear proyecto en Google Cloud Console
2. ✅ Habilitar Maps SDK for Android
3. ✅ Crear API Key
4. ✅ Configurar en `local.properties`
5. ⏳ Configurar restricciones de seguridad (opcional pero recomendado)
6. ✅ Probar que el mapa funciona

### ¿Cuánto cuesta?

- **Gratis** hasta $200 USD/mes de crédito
- **~28,000 cargas de mapa gratis/mes**
- BuscaGas MVP: **~3,000 cargas/mes** → **100% gratis**

---

**Fecha de creación:** 1 de diciembre de 2025  
**Paso:** 19 de 28  
**Prerequisitos:** Paso 18 (Permisos Android) completado  
**Duración estimada:** 30-45 minutos  
**Siguiente:** Paso 20 (Escribir pruebas unitarias)
