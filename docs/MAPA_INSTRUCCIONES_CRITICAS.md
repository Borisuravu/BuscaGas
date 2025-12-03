# Instrucciones para Evitar Romper el Mapa en el Proyecto BuscaGas

Este documento contiene las instrucciones y recomendaciones para evitar que el mapa de Google Maps deje de funcionar al realizar modificaciones en el proyecto.

---

## Archivos Críticos
Evita realizar cambios innecesarios en los siguientes archivos, ya que contienen configuraciones esenciales para el correcto funcionamiento del mapa:

1. **`android/local.properties`**
   - Contiene el `API Key` de Google Maps.
   - **No modificar ni eliminar el valor de la clave `MAPS_API_KEY`**.

2. **`android/app/build.gradle.kts`**
   - Configura la carga del `API Key` desde `local.properties`.
   - **No modificar la sección que carga las propiedades del archivo `local.properties`**.

3. **`android/app/src/main/AndroidManifest.xml`**
   - Declara los permisos necesarios y el placeholder para el `API Key`.
   - **No eliminar ni modificar las siguientes secciones:**
     - Permisos de ubicación (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`).
     - Línea que referencia el `API Key` en `<meta-data>`.

---

## APIs Habilitadas en Google Cloud Console
Asegúrate de que las siguientes APIs estén habilitadas en Google Cloud Console:

- **Maps SDK for Android**
- **Geocoding API** (si se usa para direcciones).
- **Places API** (si se usa para búsquedas de lugares).

---

## Permisos de Ubicación
El mapa requiere permisos de ubicación para funcionar correctamente. Verifica que:

1. Los permisos estén declarados en `AndroidManifest.xml`.
2. La aplicación solicite los permisos al usuario en tiempo de ejecución.

---

## Pruebas Recomendadas
Antes de realizar cambios en el proyecto, realiza las siguientes pruebas:

1. **Verificar el Mapa:**
   - Asegúrate de que el mapa se renderiza correctamente.
   - Comprueba que los marcadores y otras funcionalidades del mapa funcionan como se espera.

2. **Probar Permisos:**
   - Simula escenarios donde los permisos de ubicación son denegados.
   - Verifica que la aplicación maneje estos casos correctamente.

---

## Buenas Prácticas
1. **Documentar Cambios:**
   - Si necesitas modificar alguno de los archivos críticos, documenta detalladamente los cambios realizados.

2. **Crear Ramas:**
   - Realiza los cambios en una rama separada y prueba el mapa antes de fusionar los cambios en la rama principal.

3. **Revisiones de Código:**
   - Solicita revisiones de código para cambios en los archivos críticos.

4. **Logs Detallados:**
   - Agrega logs en las partes críticas del código relacionadas con Google Maps para facilitar la depuración.

---

## Contacto
Si tienes dudas o necesitas realizar cambios en los archivos críticos, consulta con el responsable del proyecto antes de proceder.