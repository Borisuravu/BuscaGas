# Configuración de Google Maps API Key

## ⚠️ IMPORTANTE: Configurar API Key antes de ejecutar

Para que el mapa funcione correctamente, necesitas configurar tu propia API Key de Google Maps.

### Pasos para obtener la API Key:

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita **Maps SDK for Android**
4. Ve a **Credenciales** → **Crear credenciales** → **Clave de API**
5. Copia la API Key generada

### Configurar la API Key en el proyecto:

1. Abre el archivo: `android/app/src/main/AndroidManifest.xml`
2. Busca la línea:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```
3. Reemplaza `YOUR_API_KEY_HERE` con tu API Key real

### Restricciones recomendadas (Opcional pero importante):

Para mayor seguridad, configura restricciones en tu API Key:

1. En Google Cloud Console, selecciona tu API Key
2. En **Restricciones de aplicación**:
   - Selecciona "Aplicaciones de Android"
   - Añade el SHA-1 fingerprint de tu keystore
3. En **Restricciones de API**:
   - Selecciona "Restringir clave"
   - Selecciona solo "Maps SDK for Android"

### Obtener SHA-1 fingerprint:

Para desarrollo (debug):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Para producción:
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias-name
```

### Verificar que funciona:

1. Ejecuta la aplicación
2. Deberías ver el mapa de Google Maps en la pantalla principal
3. Si ves un mapa gris o vacío, verifica:
   - Que la API Key esté correctamente configurada
   - Que Maps SDK for Android esté habilitado en Google Cloud Console
   - Los logs de Android Studio para mensajes de error

---

**Nota:** No subas tu API Key al control de versiones. El archivo AndroidManifest.xml con `YOUR_API_KEY_HERE` es un placeholder que debe ser reemplazado localmente.
