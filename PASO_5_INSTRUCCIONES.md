# PASO 5: Integrar API Gubernamental

## Información extraída de la Documentación V3 para el Paso 5

---

## 🎯 OBJETIVO DEL PASO 5
- Crear cliente HTTP para la API del Gobierno de España
- Implementar parseo de respuestas JSON
- Gestionar errores de red y validación de datos
- Crear ApiDataSource con operaciones de descarga

---

## 🌐 INFORMACIÓN DE LA API GUBERNAMENTAL

### Fuente de Datos Oficial

**Proveedor:** Ministerio para la Transición Ecológica y el Reto Demográfico del Gobierno de España

**URL de la API:**
```
https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/
```

**Método:** GET

**Autenticación:** No requiere (API pública)

**Formato de respuesta:** JSON

**Frecuencia de actualización:** Datos oficiales actualizados periódicamente por el gobierno

**Características:**
- Acceso público sin necesidad de API Key
- Respuestas en formato JSON estructurado
- Incluye todas las estaciones de servicio terrestres de España
- Precios actualizados de múltiples tipos de combustible

---

## 📋 ESTRUCTURA DE LA RESPUESTA JSON

### Formato completo de la API:

```json
{
  "Fecha": "10/11/2025 08:30:00",
  "ListaEESSPrecio": [
    {
      "IDEESS": "1234",
      "Rótulo": "REPSOL",
      "Dirección": "AVENIDA PRINCIPAL 123",
      "Localidad": "MADRID",
      "Latitud": "40.416775",
      "Longitud (WGS84)": "-3.703790",
      "Precio Gasolina 95 E5": "1,459",
      "Precio Gasoleo A": "1,389"
    },
    {
      "IDEESS": "5678",
      "Rótulo": "CEPSA",
      "Dirección": "CALLE SECUNDARIA 45",
      "Localidad": "BARCELONA",
      "Latitud": "41.385064",
      "Longitud (WGS84)": "2.173404",
      "Precio Gasolina 95 E5": "1,479",
      "Precio Gasoleo A": "1,399"
    }
  ]
}
```

### Campos principales:

**Nivel raíz:**
- `Fecha`: String - Fecha y hora de actualización de los datos (formato: "DD/MM/YYYY HH:MM:SS")
- `ListaEESSPrecio`: Array - Lista de estaciones de servicio

**Cada estación (dentro de ListaEESSPrecio):**
- `IDEESS`: String - Identificador único de la estación
- `Rótulo`: String - Nombre comercial/operador
- `Dirección`: String - Dirección completa
- `Localidad`: String - Municipio/ciudad
- `Latitud`: String - Coordenada latitud (formato con coma: "40,416775")
- `Longitud (WGS84)`: String - Coordenada longitud (formato con coma: "-3,703790")
- `Precio Gasolina 95 E5`: String - Precio gasolina 95 (formato con coma: "1,459") - **Puede ser null**
- `Precio Gasoleo A`: String - Precio diésel (formato con coma: "1,389") - **Puede ser null**

### ⚠️ PECULIARIDADES IMPORTANTES:

1. **Formato numérico español:**
   - Decimales con **coma** (`,`) en lugar de punto (`.`)
   - Ejemplo: `"1,459"` debe convertirse a `1.459`
   - Aplica a: precios, latitud, longitud

2. **Valores nulos:**
   - No todas las gasolineras tienen todos los combustibles
   - Los campos de precio pueden ser `null` o cadena vacía
   - Validación necesaria antes de parsear

3. **Coordenadas:**
   - Vienen como Strings, no como números
   - Requieren conversión con reemplazo de coma

4. **Nombre del campo longitud:**
   - Incluye espacio y paréntesis: `"Longitud (WGS84)"`
   - Usar nombre exacto en el parseo

---

## 🗂️ UBICACIÓN DEL ARCHIVO

**Ruta:** `lib/data/datasources/remote/api_datasource.dart`

**Propósito:** Fuente de datos remota que encapsula todas las llamadas HTTP a la API gubernamental

---

## 📦 DEPENDENCIAS NECESARIAS

Las dependencias ya están configuradas en `pubspec.yaml`:

```yaml
dependencies:
  # Networking
  http: ^1.1.0
  dio: ^5.3.3
```

**Decisión de implementación:**
- Usar **`http`** para este paso (más simple para GET requests)
- `dio` está disponible para funcionalidades avanzadas futuras (interceptors, retries, etc.)

---

## 📝 IMPLEMENTACIÓN COMPLETA

### Código del ApiDataSource:

```dart
/// Fuente de datos remota: API del Gobierno de España
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buscagas/data/models/api_response_model.dart';
import 'package:buscagas/data/models/gas_station_model.dart';

class ApiDataSource {
  // URL base de la API gubernamental
  static const String _baseUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/';
  
  // Cliente HTTP
  final http.Client _client;
  
  // Constructor con inyección de dependencias (permite testing)
  ApiDataSource({http.Client? client}) : _client = client ?? http.Client();
  
  /// Obtener todas las estaciones de servicio desde la API
  Future<List<GasStationModel>> fetchAllStations() async {
    try {
      // 1. Realizar petición GET
      final response = await _client.get(
        Uri.parse(_baseUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException(
            'Timeout: La petición tardó más de 30 segundos',
            type: ApiErrorType.timeout,
          );
        },
      );
      
      // 2. Verificar código de estado HTTP
      if (response.statusCode == 200) {
        // 3. Parsear respuesta JSON
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        // 4. Crear objeto de respuesta
        final apiResponse = ApiGasStationResponse.fromJson(jsonData);
        
        // 5. Retornar lista de modelos
        return apiResponse.listaEESSPrecio;
        
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Endpoint no encontrado (404)',
          type: ApiErrorType.notFound,
        );
      } else if (response.statusCode >= 500) {
        throw ApiException(
          'Error del servidor (${response.statusCode})',
          type: ApiErrorType.serverError,
        );
      } else {
        throw ApiException(
          'Error HTTP: ${response.statusCode}',
          type: ApiErrorType.httpError,
          statusCode: response.statusCode,
        );
      }
      
    } on ApiException {
      // Re-lanzar excepciones de API
      rethrow;
    } catch (e) {
      // Capturar otros errores (red, parseo, etc.)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException')) {
        throw ApiException(
          'Sin conexión a internet',
          type: ApiErrorType.noConnection,
        );
      } else if (e.toString().contains('FormatException')) {
        throw ApiException(
          'Error al parsear JSON: ${e.toString()}',
          type: ApiErrorType.parseError,
        );
      } else {
        throw ApiException(
          'Error desconocido: ${e.toString()}',
          type: ApiErrorType.unknown,
        );
      }
    }
  }
  
  /// Verificar conectividad con la API
  Future<bool> checkConnection() async {
    try {
      final response = await _client.head(Uri.parse(_baseUrl)).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  
  /// Cerrar cliente HTTP (liberar recursos)
  void dispose() {
    _client.close();
  }
}

// ==================== EXCEPCIONES PERSONALIZADAS ====================

/// Tipos de errores de API
enum ApiErrorType {
  noConnection,     // Sin internet
  timeout,          // Timeout de petición
  serverError,      // Error 5xx
  notFound,         // Error 404
  httpError,        // Otros errores HTTP
  parseError,       // Error al parsear JSON
  unknown,          // Error desconocido
}

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  
  ApiException(
    this.message, {
    required this.type,
    this.statusCode,
  });
  
  @override
  String toString() {
    return 'ApiException [${type.name}]: $message';
  }
  
  /// Obtener mensaje amigable para el usuario
  String get userFriendlyMessage {
    switch (type) {
      case ApiErrorType.noConnection:
        return 'No hay conexión a internet. Por favor, verifica tu conexión.';
      case ApiErrorType.timeout:
        return 'La petición tardó demasiado. Inténtalo de nuevo.';
      case ApiErrorType.serverError:
        return 'El servidor no está disponible. Inténtalo más tarde.';
      case ApiErrorType.notFound:
        return 'Servicio no encontrado. Contacta con soporte.';
      case ApiErrorType.httpError:
        return 'Error al conectar con el servidor (código: $statusCode).';
      case ApiErrorType.parseError:
        return 'Error al procesar los datos. Inténtalo más tarde.';
      case ApiErrorType.unknown:
        return 'Error inesperado. Por favor, inténtalo de nuevo.';
    }
  }
}
```

---

## 🔧 CONSTANTES DE API

### Ubicación: `lib/core/constants/api_constants.dart`

Ya existe un archivo placeholder. Vamos a actualizarlo con las constantes reales:

```dart
/// Constantes relacionadas con la API del Gobierno
library;

class ApiConstants {
  // URL base de la API
  static const String baseUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/';
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 5);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=UTF-8',
  };
  
  // Códigos de estado
  static const int statusOk = 200;
  static const int statusNotFound = 404;
  static const int statusServerErrorMin = 500;
  
  // Mensajes de error
  static const String errorNoConnection = 'Sin conexión a internet';
  static const String errorTimeout = 'Tiempo de espera agotado';
  static const String errorServerUnavailable = 'Servidor no disponible';
  static const String errorUnknown = 'Error desconocido';
}
```

---

## 🧪 USO DEL ApiDataSource

### Ejemplo básico:

```dart
// Crear instancia
final apiDataSource = ApiDataSource();

try {
  // Descargar datos
  List<GasStationModel> stations = await apiDataSource.fetchAllStations();
  
  print('Descargadas ${stations.length} gasolineras');
  
  // Convertir a entidades de dominio
  List<GasStation> entities = stations.map((model) => model.toDomain()).toList();
  
} on ApiException catch (e) {
  // Manejar error de API
  print('Error: ${e.userFriendlyMessage}');
  
  // Tomar acción según el tipo
  switch (e.type) {
    case ApiErrorType.noConnection:
      // Usar caché local
      break;
    case ApiErrorType.timeout:
      // Reintentar
      break;
    default:
      // Mostrar mensaje al usuario
      break;
  }
} finally {
  // Liberar recursos
  apiDataSource.dispose();
}
```

### Verificar conectividad antes de descargar:

```dart
final apiDataSource = ApiDataSource();

bool isConnected = await apiDataSource.checkConnection();

if (isConnected) {
  List<GasStationModel> stations = await apiDataSource.fetchAllStations();
  // Procesar datos
} else {
  // Usar caché local
  print('Sin conexión, usando datos en caché');
}
```

---

## 🛡️ MANEJO DE ERRORES

### Tipos de errores contemplados:

1. **Sin conexión a internet:**
   - Excepción: `ApiException` con tipo `noConnection`
   - Estrategia: Usar datos de caché local

2. **Timeout:**
   - Excepción: `ApiException` con tipo `timeout`
   - Estrategia: Reintentar o usar caché

3. **Error del servidor (5xx):**
   - Excepción: `ApiException` con tipo `serverError`
   - Estrategia: Informar al usuario, usar caché

4. **Endpoint no encontrado (404):**
   - Excepción: `ApiException` con tipo `notFound`
   - Estrategia: Contactar soporte (error crítico)

5. **Error de parseo JSON:**
   - Excepción: `ApiException` con tipo `parseError`
   - Estrategia: Usar caché, notificar error

6. **Error desconocido:**
   - Excepción: `ApiException` con tipo `unknown`
   - Estrategia: Log detallado, usar caché

### Mensajes amigables para el usuario:

Cada `ApiException` tiene un método `userFriendlyMessage` que retorna:
- "No hay conexión a internet. Por favor, verifica tu conexión."
- "La petición tardó demasiado. Inténtalo de nuevo."
- "El servidor no está disponible. Inténtalo más tarde."
- etc.

---

## 📊 FLUJO DE DATOS

```
Usuario solicita datos
        ↓
ApiDataSource.fetchAllStations()
        ↓
HTTP GET a API Gubernamental
        ↓
¿Respuesta exitosa (200)?
    ↓ Sí              ↓ No
Parsear JSON    Lanzar ApiException
    ↓                     ↓
ApiGasStationResponse   Capturar en capa superior
    ↓
List<GasStationModel>
    ↓
Retornar a repositorio
```

---

## ✅ CHECKLIST PASO 5

### Archivos a crear/modificar:

1. ✅ `lib/data/datasources/remote/api_datasource.dart`
   - Clase `ApiDataSource` con cliente HTTP
   - Método `fetchAllStations()` para descargar datos
   - Método `checkConnection()` para verificar conectividad
   - Clase `ApiException` con tipos de error
   - Enum `ApiErrorType` para categorizar errores
   - Método `dispose()` para liberar recursos

2. ✅ `lib/core/constants/api_constants.dart`
   - Constante `baseUrl` con URL de API
   - Constantes de timeout
   - Headers por defecto
   - Códigos de estado HTTP
   - Mensajes de error

### Tareas:

1. ✅ Crear directorio `lib/data/datasources/remote/` (si no existe)

2. ✅ Implementar `api_datasource.dart` completo

3. ✅ Actualizar `api_constants.dart` con valores reales

4. ✅ Verificar compilación con `flutter analyze`

5. ✅ (Opcional) Probar conexión real:
   ```dart
   final api = ApiDataSource();
   final stations = await api.fetchAllStations();
   print('Total gasolineras: ${stations.length}');
   ```

---

## 🎯 CRITERIOS DE ÉXITO DEL PASO 5

**El Paso 5 está completo cuando:**
- ✅ ApiDataSource implementado con cliente HTTP
- ✅ Método `fetchAllStations()` descarga datos de API real
- ✅ Parseo JSON funciona correctamente con estructura de gobierno
- ✅ Manejo de errores robusto con tipos específicos
- ✅ Conversión de formato español (comas) a formato numérico
- ✅ Timeout configurado (30 segundos)
- ✅ Verificación de conectividad implementada
- ✅ `flutter analyze` sin errores
- ✅ Excepción personalizada `ApiException` con mensajes amigables

---

## 🔍 NOTAS IMPORTANTES

### Formato de datos español:
- **CRÍTICO:** Todos los números vienen con coma (`,`) como separador decimal
- Requiere reemplazo `.replaceAll(',', '.')` antes de `double.parse()`
- Aplica a: precios, latitudes, longitudes

### Validación de nulos:
- Los precios pueden ser `null` si la gasolinera no vende ese combustible
- Validar antes de parsear: `if (precioGasolina95 != null)`
- Usar operador `??` para valores por defecto

### Headers HTTP:
- `Accept: application/json` indica que esperamos JSON
- `Content-Type` especifica UTF-8 para caracteres españoles (acentos, ñ)

### Timeout:
- 30 segundos para petición completa
- La API puede tardar debido al volumen de datos (miles de gasolineras)
- 5 segundos solo para verificación de conectividad

### Inyección de dependencias:
- Constructor acepta `http.Client?` opcional
- Permite inyectar mock en tests unitarios
- Si no se proporciona, usa cliente real

### Gestión de recursos:
- Método `dispose()` cierra el cliente HTTP
- Importante llamarlo para liberar conexiones
- Especialmente en tests o cuando se crea nueva instancia

### Compatibilidad con modelos:
- `ApiGasStationResponse.fromJson()` ya implementado en Paso 3
- `GasStationModel.fromJson()` ya implementado en Paso 3
- `GasStationModel.toDomain()` convierte a entidad de dominio

---

## 🚀 PRÓXIMOS PASOS

Después del Paso 5, el Paso 6 implementará:
- **Repositorios** que combinen ApiDataSource + DatabaseDataSource
- Lógica de caché inteligente
- Estrategia de sincronización
- Fallback a datos locales cuando falla la API

---

**Fecha de creación:** 17 de noviembre de 2025  
**Basado en:** BuscaGas Documentacion V3 (Métrica v3)  
**Sección:** EVS 2 - Fuentes de Datos, DSI 5 - Modelo de Datos API, ASI 1 - Capa de Datos
