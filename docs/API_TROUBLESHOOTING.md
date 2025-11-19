# Solución de Problemas con la API

## Errores Comunes

### 1. Timeout (30 segundos)

**Síntoma:** La petición tarda más de 30 segundos
**Causa:** Red lenta o servidor sobrecargado
**Solución:**
- Verificar conexión a internet
- Reintentar en unos minutos
- El sistema automáticamente carga desde caché

### 2. Sin Conexión a Internet

**Síntoma:** `ApiException: noConnection`
**Causa:** No hay conectividad de red
**Solución:**
- Verificar WiFi/datos móviles
- La app usa caché local automáticamente
- Mensajes amigables se muestran al usuario

### 3. Error 404 - Endpoint no encontrado

**Síntoma:** `ApiException: notFound`
**Causa:** La URL de la API cambió
**Solución:**
- Verificar `ApiConstants.baseUrl`
- Consultar documentación oficial en datos.gob.es
- Contactar con soporte

### 4. Error 500/503 - Servidor caído

**Síntoma:** `ApiException: serverError`
**Causa:** El servidor del gobierno está caído o en mantenimiento
**Solución:**
- Esperar y reintentar
- Usar datos en caché
- Notificar al usuario del problema temporal

### 5. Error de Parseo JSON

**Síntoma:** `ApiException: parseError`
**Causa:** Formato de respuesta inesperado
**Solución:**
- Verificar estructura de `ApiGasStationResponse`
- Revisar logs para ver JSON recibido
- Actualizar modelos si la API cambió

## Debugging

### Ver respuesta completa de la API

```dart
final response = await http.get(Uri.parse(ApiConstants.baseUrl));
print('Status: ${response.statusCode}');
print('Body: ${response.body}');
```

### Verificar conectividad

```dart
final apiService = ApiService();
final available = await apiService.isApiAvailable();
print('API disponible: $available');
```

### Logs útiles

Todos los métodos de ApiService y ApiDataSource incluyen `print()` statements:
- `🌐` = Inicio de operación
- `✅` = Éxito
- `❌` = Error
- `⚠️` = Advertencia

## Mejores Prácticas

1. **Siempre verificar conectividad** antes de operaciones críticas
2. **Usar try-catch** para manejar ApiException
3. **Mostrar mensajes amigables** al usuario (usar `userFriendlyMessage`)
4. **Tener fallback a caché** cuando falla la API
5. **Usar dispose()** para liberar recursos del cliente HTTP

## Ejemplos de Código

### Patrón completo de manejo de errores

```dart
final apiService = ApiService();
final dbService = DatabaseService();

try {
  // Intentar descargar desde API
  final stations = await apiService.fetchGasStations();
  await dbService.saveStations(stations);
  print('✅ Datos frescos desde API');
  
} on ApiException catch (e) {
  // Error de API, usar caché
  print('⚠️ ${e.userFriendlyMessage}');
  final cached = await dbService.getAllStations();
  print('📂 Usando ${cached.length} gasolineras desde caché');
  
} catch (e) {
  // Error inesperado
  print('❌ Error crítico: $e');
} finally {
  apiService.dispose();
}
```

### Verificar antes de descargar

```dart
final apiService = ApiService();

if (await apiService.isApiAvailable()) {
  final stations = await apiService.fetchGasStations();
  print('✅ ${stations.length} gasolineras');
} else {
  print('⚠️ API no disponible, usando caché');
}
```

## Contacto y Soporte

Si encuentras un error que no está documentado aquí:

1. Verifica la documentación oficial de la API en datos.gob.es
2. Revisa los logs de la aplicación
3. Consulta el archivo `PASO_5_INSTRUCCIONES_DETALLADAS.md`
4. Crea un issue en el repositorio del proyecto

---

**Última actualización:** 19 de noviembre de 2025  
**Versión:** BuscaGas v1.0.0
