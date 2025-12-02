# Configuración de Google Maps API Key

## ⚠️ IMPORTANTE: Configurar API Key antes de ejecutar

Para que el mapa funcione correctamente, necesitas configurar tu propia API Key de Google Maps.

### 📋 Paso 1: Obtener la API Key

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita **Maps SDK for Android**:
   - En el menú lateral → **APIs y servicios** → **Biblioteca**
   - Busca "Maps SDK for Android"
   - Click en **Habilitar**
4. Ve a **Credenciales** → **Crear credenciales** → **Clave de API**
5. Copia la API Key generada

### 🔧 Paso 2: Configurar la API Key en el proyecto

**IMPORTANTE:** La API Key se configura en `android/local.properties` para mantenerla segura.

1. Abre el archivo: `android/local.properties`
2. Agrega esta línea al final:
   ```properties
   GOOGLE_MAPS_API_KEY=TU_API_KEY_AQUI
   ```
3. Reemplaza `TU_API_KEY_AQUI` con tu API Key real de Google Cloud Console

**Nota de seguridad:** El archivo `local.properties` está en `.gitignore`, por lo que tu API Key NO se subirá a Git.

### 🔐 Paso 3: Obtener tu SHA-1 Fingerprint

Para que Google Maps funcione, necesitas autorizar tu certificado de firma en Google Cloud Console.

**En Windows (PowerShell):**
```powershell
cd $env:USERPROFILE\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**En Linux/Mac:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copia el valor de **SHA-1** que aparece (ejemplo: `8B:0C:2F:98:29:41:...`)

Copia el valor de **SHA-1** que aparece (ejemplo: `8B:0C:2F:98:29:41:...`)

### 🔒 Paso 4: Restringir la API Key en Google Cloud Console

Para mayor seguridad y evitar uso no autorizado:

1. En [Google Cloud Console](https://console.cloud.google.com/), ve a **Credenciales**
2. Click en el nombre de tu API Key
3. En **Restricciones de aplicación**:
   - Selecciona **Aplicaciones de Android**
   - Click en **Agregar un elemento**
   - Pega tu **SHA-1 fingerprint** (del Paso 3)
   - Package name: `com.buscagas.buscagas`
   - Click en **Listo**
4. En **Restricciones de API**:
   - Selecciona **Restringir clave**
   - Marca solo: **Maps SDK for Android**
5. Click en **Guardar**

**Ejemplo de configuración:**
```
Restricción de aplicación: Aplicaciones de Android
  ✓ SHA-1: 8B:0C:2F:98:29:41:D4:83:6B:1B:6B:CD:3C:8A:4D:3A:E8:9A:EF:DB
    Package: com.buscagas.buscagas

Restricción de API:
  ✓ Maps SDK for Android
```

### ✅ Paso 5: Probar la configuración

1. **Limpia el proyecto:**
   ```bash
   flutter clean
   ```

2. **Ejecuta la app:**
   ```bash
   flutter run
   ```

3. **Verifica que funciona:**
   - Deberías ver el mapa de Google Maps cargando
   - Si ves un mapa gris/vacío, revisa los logs con: `flutter logs`

### 🐛 Solución de problemas

**Error: "Authorization failure"**
- Verifica que `GOOGLE_MAPS_API_KEY` esté en `android/local.properties`
- Verifica que el SHA-1 fingerprint esté autorizado en Google Cloud Console
- Asegúrate de que el package name sea exactamente: `com.buscagas.buscagas`
- Reconstruye la app: `flutter clean && flutter run`

**Mapa aparece gris**
- Verifica que **Maps SDK for Android** esté habilitado en Google Cloud Console
- Revisa los permisos de ubicación en AndroidManifest.xml
- Verifica que aceptaste los permisos de ubicación en el dispositivo

**Para producción (release build):**
Necesitarás obtener el SHA-1 de tu keystore de producción:
```bash
keytool -list -v -keystore /ruta/a/tu/keystore.jks -alias tu-alias
```
Y agregarlo también a las restricciones en Google Cloud Console.

---

### 📁 Archivos relevantes:

- **API Key:** `android/local.properties` (no se sube a Git)
- **Configuración:** `android/app/build.gradle.kts` (lee la key de local.properties)
- **Manifest:** `android/app/src/main/AndroidManifest.xml` (usa placeholder `${GOOGLE_MAPS_API_KEY}`)

### 🔐 Seguridad:

✅ `local.properties` está en `.gitignore`  
✅ La API Key NO se sube al repositorio  
✅ La key se inyecta en tiempo de compilación  
✅ Restricciones por SHA-1 y package name  
✅ Solo permite Maps SDK for Android
