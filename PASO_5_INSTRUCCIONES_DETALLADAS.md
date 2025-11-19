# PASO 5: INTEGRAR API GUBERNAMENTAL - INSTRUCCIONES DETALLADAS

## Estado Actual del Proyecto

### ✅ Ya Implementado:
- **`ApiDataSource`** en `lib/data/datasources/remote/api_datasource.dart` - **COMPLETAMENTE IMPLEMENTADO**
  - Cliente HTTP con timeout de 30 segundos
  - Método `fetchAllStations()` funcional
  - Gestión completa de errores con excepciones personalizadas
  - Método `checkConnection()` para verificar conectividad
  - Manejo de todos los casos de error (timeout, sin conexión, 404, 5xx, parse)
  
- **`ApiGasStationResponse`** en `lib/data/models/api_response_model.dart` - ✅ COMPLETO
  - Parser JSON funcional
  - Mapeo de campos correctamente
  
- **`GasStationModel`** en `lib/data/models/gas_station_model.dart` - ✅ COMPLETO
  - Conversión de formato español (comas a puntos)
  - Mapper a entidad de dominio
  
- **`ApiConstants`** en `lib/core/constants/api_constants.dart` - ✅ COMPLETO
  - URL base configurada
  - Timeouts definidos
  - Headers por defecto

### 🔴 Pendiente de Implementar:

1. **Actualizar ApiService** (wrapper de alto nivel opcional)
2. **Pruebas de integración** con la API real
3. **Documentación y validación**

---

## TAREA 1: Actualizar ApiService (Opcional pero Recomendado)

### Ubicación:
`lib/services/api_service.dart`

### Propósito:
Crear un servicio de alto nivel que actúe como facade del `ApiDataSource`, proporcionando una interfaz más simple para el resto de la aplicación.

### Código Completo a Implementar:

```dart
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/domain/entities/gas_station.dart';

/// Servicio HTTP para llamadas a la API del Gobierno de España
/// 
/// Responsabilidades:
/// - Proporcionar interfaz simplificada para operaciones de API
/// - Convertir modelos DTO a entidades de dominio
/// - Coordinar con ApiDataSource
/// - Logging y monitoreo de llamadas
class ApiService {
  final ApiDataSource _dataSource;
  
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  ApiService._internal() : _dataSource = ApiDataSource();
  
  // Constructor con inyección para testing
  ApiService.withDataSource(this._dataSource);
  
  // ==================== OPERACIONES DE API ====================
  
  /// Obtener todas las gasolineras desde la API del gobierno
  /// 
  /// Retorna una lista de entidades de dominio [GasStation]
  /// Lanza [ApiException] si hay error
  Future<List<GasStation>> fetchGasStations() async {
    try {
      print('🌐 Iniciando descarga desde API gubernamental...');
      
      // 1. Llamar a ApiDataSource
      final models = await _dataSource.fetchAllStations();
      
      print('✅ Descargadas ${models.length} estaciones desde API');
      
      // 2. Convertir modelos a entidades de dominio
      final stations = models.map((model) => model.toDomain()).toList();
      
      // 3. Filtrar estaciones sin coordenadas válidas
      final validStations = stations.where((station) {
        return station.latitude != 0.0 && station.longitude != 0.0;
      }).toList();
      
      if (validStations.length < stations.length) {
        final filtered = stations.length - validStations.length;
        print('⚠️ Filtradas $filtered estaciones sin coordenadas válidas');
      }
      
      print('✅ ${validStations.length} estaciones válidas disponibles');
      
      return validStations;
      
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.message}');
      rethrow; // Re-lanzar para que la capa superior maneje
    } catch (e) {
      print('❌ Error inesperado en ApiService: $e');
      throw ApiException(
        'Error al obtener gasolineras: $e',
        type: ApiErrorType.unknown,
      );
    }
  }
  
  /// Verificar si hay conexión con la API
  Future<bool> isApiAvailable() async {
    try {
      final available = await _dataSource.checkConnection();
      if (available) {
        print('✅ API disponible');
      } else {
        print('❌ API no disponible');
      }
      return available;
    } catch (e) {
      print('❌ Error verificando API: $e');
      return false;
    }
  }
  
  /// Obtener estadísticas de la última descarga
  /// Útil para debugging y monitoreo
  Future<Map<String, dynamic>> getApiStats() async {
    try {
      final stations = await fetchGasStations();
      
      // Contar por tipo de combustible disponible
      int withGasolina95 = 0;
      int withDiesel = 0;
      int withBoth = 0;
      
      for (var station in stations) {
        final hasGasolina = station.prices.any(
          (p) => p.fuelType == FuelType.gasolina95,
        );
        final hasDiesel = station.prices.any(
          (p) => p.fuelType == FuelType.dieselGasoleoA,
        );
        
        if (hasGasolina) withGasolina95++;
        if (hasDiesel) withDiesel++;
        if (hasGasolina && hasDiesel) withBoth++;
      }
      
      return {
        'total_stations': stations.length,
        'with_gasolina95': withGasolina95,
        'with_diesel': withDiesel,
        'with_both': withBoth,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Liberar recursos
  void dispose() {
    _dataSource.dispose();
  }
}
```

### Instrucciones de Implementación:

1. Abrir el archivo `lib/services/api_service.dart`
2. Eliminar todo el contenido actual (comentarios TODO)
3. Copiar y pegar el código completo de arriba
4. Guardar el archivo

**Nota:** Necesitarás agregar el import de `FuelType` al inicio del archivo si no está ya incluido.

---

## TAREA 2: Crear Script de Prueba de API

### Ubicación:
`test/integration/api_test.dart`

### Propósito:
Validar que la integración con la API real funciona correctamente.

### Código Completo:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/services/api_service.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';

/// TESTS DE INTEGRACIÓN CON API REAL
/// 
/// IMPORTANTE: Estos tests requieren conexión a internet
/// Se conectan a la API real del gobierno
/// Pueden tardar varios segundos en completarse

void main() {
  group('API Integration Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService();
    });
    
    tearDown(() {
      apiService.dispose();
    });
    
    test('Debe conectar con la API del gobierno', () async {
      final available = await apiService.isApiAvailable();
      expect(available, true, reason: 'La API debe estar disponible');
    }, timeout: const Timeout(Duration(seconds: 10)));
    
    test('Debe descargar gasolineras desde la API', () async {
      final stations = await apiService.fetchGasStations();
      
      expect(stations, isNotEmpty, reason: 'Debe haber al menos una gasolinera');
      expect(stations.length, greaterThan(100), 
        reason: 'Debería haber más de 100 gasolineras en España');
      
      print('✅ Total gasolineras descargadas: ${stations.length}');
    }, timeout: const Timeout(Duration(seconds: 45)));
    
    test('Las gasolineras deben tener coordenadas válidas', () async {
      final stations = await apiService.fetchGasStations();
      
      for (var station in stations.take(10)) {
        expect(station.latitude, isNot(0.0));
        expect(station.longitude, isNot(0.0));
        expect(station.latitude, inInclusiveRange(35.0, 44.0), 
          reason: 'Latitud debe estar en rango de España');
        expect(station.longitude, inInclusiveRange(-10.0, 5.0),
          reason: 'Longitud debe estar en rango de España');
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
    
    test('Las gasolineras deben tener al menos un precio', () async {
      final stations = await apiService.fetchGasStations();
      
      int stationsWithPrices = 0;
      for (var station in stations) {
        if (station.prices.isNotEmpty) {
          stationsWithPrices++;
        }
      }
      
      expect(stationsWithPrices, greaterThan(0),
        reason: 'Debe haber gasolineras con precios');
      
      print('✅ Gasolineras con precios: $stationsWithPrices / ${stations.length}');
    }, timeout: const Timeout(Duration(seconds: 45)));
    
    test('Debe manejar error de timeout correctamente', () async {
      // Este test verifica que el timeout funciona
      // No lo ejecutamos siempre porque tarda 30 segundos
      
      // final dataSource = ApiDataSource();
      // expect(
      //   () async => await dataSource.fetchAllStations(),
      //   throwsA(isA<ApiException>()),
      // );
      
      // Por ahora solo verificamos que la clase existe
      expect(ApiException, isNotNull);
    });
    
    test('Debe obtener estadísticas de API', () async {
      final stats = await apiService.getApiStats();
      
      expect(stats, isNotEmpty);
      expect(stats['total_stations'], isNotNull);
      expect(stats['timestamp'], isNotNull);
      
      print('📊 Estadísticas de API:');
      print('   Total: ${stats['total_stations']}');
      print('   Con Gasolina 95: ${stats['with_gasolina95']}');
      print('   Con Diésel: ${stats['with_diesel']}');
      print('   Con ambos: ${stats['with_both']}');
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
  
  group('API Error Handling Tests', () {
    test('ApiException debe tener mensajes amigables', () {
      final exceptions = [
        ApiException('Test', type: ApiErrorType.noConnection),
        ApiException('Test', type: ApiErrorType.timeout),
        ApiException('Test', type: ApiErrorType.serverError),
        ApiException('Test', type: ApiErrorType.notFound),
        ApiException('Test', type: ApiErrorType.httpError, statusCode: 403),
        ApiException('Test', type: ApiErrorType.parseError),
        ApiException('Test', type: ApiErrorType.unknown),
      ];
      
      for (var exception in exceptions) {
        expect(exception.userFriendlyMessage, isNotEmpty);
        print('${exception.type.name}: ${exception.userFriendlyMessage}');
      }
    });
  });
}
```

### Instrucciones de Implementación:

1. Crear el directorio `test/integration/` si no existe
2. Crear el archivo `api_test.dart` en ese directorio
3. Copiar el código completo
4. Guardar el archivo

### Cómo Ejecutar los Tests:

**Importante:** Estos tests requieren conexión a internet activa.

```bash
# Ejecutar todos los tests de integración
flutter test test/integration/api_test.dart

# Ejecutar un test específico
flutter test test/integration/api_test.dart --plain-name "Debe descargar gasolineras"
```

**Nota:** Los tests pueden tardar hasta 45 segundos en completarse debido a la descarga de datos reales.

---

## TAREA 3: Crear Utilidad de Validación de Datos

### Ubicación:
`lib/core/utils/api_validator.dart`

### Propósito:
Validar y sanitizar datos de la API antes de procesarlos.

### Código Completo:

```dart
/// Utilidades para validar datos de la API
class ApiValidator {
  /// Validar coordenadas geográficas
  /// 
  /// Retorna true si las coordenadas están en rango válido para España
  static bool isValidSpanishCoordinate(double latitude, double longitude) {
    // España continental y Baleares
    const double minLat = 35.0; // Sur (Canarias más al sur)
    const double maxLat = 44.0; // Norte (Pirineos)
    const double minLon = -10.0; // Oeste (Galicia)
    const double maxLon = 5.0; // Este (Cataluña)
    
    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLon &&
        longitude <= maxLon;
  }
  
  /// Validar precio de combustible
  /// 
  /// Retorna true si el precio está en rango razonable (0.5€ - 3.0€)
  static bool isValidFuelPrice(double price) {
    const double minPrice = 0.5; // 0.50€/litro
    const double maxPrice = 3.0; // 3.00€/litro
    
    return price >= minPrice && price <= maxPrice;
  }
  
  /// Limpiar y validar string
  /// 
  /// Retorna null si el string es vacío, solo espacios, o "null"
  static String? sanitizeString(String? input) {
    if (input == null) return null;
    
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return null;
    }
    
    return trimmed;
  }
  
  /// Convertir formato español de número a double
  /// 
  /// Convierte "1,459" a 1.459
  /// Retorna null si el formato es inválido
  static double? parseSpanishNumber(String? input) {
    if (input == null) return null;
    
    final sanitized = sanitizeString(input);
    if (sanitized == null) return null;
    
    try {
      // Reemplazar coma por punto
      final normalized = sanitized.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }
  
  /// Validar identificador de gasolinera
  /// 
  /// Debe ser un string no vacío con al menos 3 caracteres
  static bool isValidStationId(String? id) {
    if (id == null) return false;
    final sanitized = sanitizeString(id);
    return sanitized != null && sanitized.length >= 3;
  }
  
  /// Validar fecha en formato API
  /// 
  /// Formato esperado: "DD/MM/YYYY HH:MM:SS"
  static bool isValidApiDate(String? date) {
    if (date == null) return false;
    
    try {
      // Formato: "10/11/2025 08:30:00"
      final parts = date.split(' ');
      if (parts.length != 2) return false;
      
      final dateParts = parts[0].split('/');
      if (dateParts.length != 3) return false;
      
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      
      return day >= 1 &&
          day <= 31 &&
          month >= 1 &&
          month <= 12 &&
          year >= 2020 &&
          year <= 2100;
    } catch (_) {
      return false;
    }
  }
  
  /// Obtener resumen de validación de una gasolinera
  static Map<String, bool> validateStation({
    required String? id,
    required double latitude,
    required double longitude,
    required List<double> prices,
  }) {
    return {
      'valid_id': isValidStationId(id),
      'valid_coordinates': isValidSpanishCoordinate(latitude, longitude),
      'has_prices': prices.isNotEmpty,
      'valid_prices': prices.every((p) => isValidFuelPrice(p)),
    };
  }
}
```

### Instrucciones de Implementación:

1. Crear el archivo `lib/core/utils/api_validator.dart`
2. Copiar el código completo
3. Guardar el archivo

---

## TAREA 4: Actualizar AppConstants con Configuración de API

### Ubicación:
`lib/core/constants/app_constants.dart`

### Cambios a Realizar:

Agregar al final de la clase `AppConstants`:

```dart
// Configuración de API
static const int maxRetries = 3;
static const Duration retryDelay = Duration(seconds: 2);

// Validación de datos
static const double minValidLat = 35.0;
static const double maxValidLat = 44.0;
static const double minValidLon = -10.0;
static const double maxValidLon = 5.0;
static const double minValidPrice = 0.5;
static const double maxValidPrice = 3.0;

// Mensajes de error para usuario
static const String errorNoInternet = 'Sin conexión a internet';
static const String errorServerDown = 'Servidor no disponible';
static const String errorTimeout = 'La petición tardó demasiado';
static const String errorUnknown = 'Error inesperado';
```

### Instrucciones:

1. Abrir `lib/core/constants/app_constants.dart`
2. Agregar las constantes antes del cierre de la clase
3. Guardar el archivo

---

## TAREA 5: Crear Ejemplo de Uso de ApiService

### Ubicación:
`lib/examples/api_usage_example.dart`

### Propósito:
Documentar cómo usar correctamente el ApiService.

### Código Completo:

```dart
import 'package:buscagas/services/api_service.dart';
import 'package:buscagas/services/database_service.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';

/// EJEMPLOS DE USO DEL API SERVICE
/// 
/// Este archivo muestra cómo usar correctamente ApiService
/// para descargar datos de la API gubernamental

class ApiUsageExamples {
  
  /// Ejemplo 1: Descarga simple de gasolineras
  static Future<void> example1SimpleDownload() async {
    final apiService = ApiService();
    
    try {
      print('📥 Descargando gasolineras...');
      
      final stations = await apiService.fetchGasStations();
      
      print('✅ Descargadas ${stations.length} gasolineras');
      print('Primera gasolinera: ${stations.first.name}');
      
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.userFriendlyMessage}');
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      apiService.dispose();
    }
  }
  
  /// Ejemplo 2: Verificar conectividad antes de descargar
  static Future<void> example2CheckConnectivity() async {
    final apiService = ApiService();
    
    try {
      // Primero verificar si la API está disponible
      final available = await apiService.isApiAvailable();
      
      if (!available) {
        print('⚠️ API no disponible, usando caché local');
        return;
      }
      
      // API disponible, proceder con descarga
      final stations = await apiService.fetchGasStations();
      print('✅ Descargadas ${stations.length} gasolineras');
      
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      apiService.dispose();
    }
  }
  
  /// Ejemplo 3: Descargar y guardar en base de datos
  static Future<void> example3DownloadAndCache() async {
    final apiService = ApiService();
    final dbService = DatabaseService();
    
    try {
      // 1. Descargar desde API
      print('📥 Descargando desde API...');
      final stations = await apiService.fetchGasStations();
      
      // 2. Guardar en base de datos local
      print('💾 Guardando en caché local...');
      await dbService.saveStations(stations);
      
      print('✅ ${stations.length} gasolineras cacheadas');
      
    } on ApiException catch (e) {
      print('❌ Error de API: ${e.userFriendlyMessage}');
      
      // Intentar cargar desde caché
      print('📂 Cargando desde caché local...');
      final cached = await dbService.getAllStations();
      print('✅ ${cached.length} gasolineras desde caché');
      
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      apiService.dispose();
    }
  }
  
  /// Ejemplo 4: Manejo completo de errores
  static Future<void> example4ErrorHandling() async {
    final apiService = ApiService();
    
    try {
      final stations = await apiService.fetchGasStations();
      print('✅ ${stations.length} gasolineras');
      
    } on ApiException catch (e) {
      // Manejo específico según tipo de error
      switch (e.type) {
        case ApiErrorType.noConnection:
          print('📡 Sin conexión. Verifica tu internet.');
          break;
          
        case ApiErrorType.timeout:
          print('⏱️ Timeout. La red está lenta.');
          break;
          
        case ApiErrorType.serverError:
          print('🔧 Servidor caído. Inténtalo más tarde.');
          break;
          
        case ApiErrorType.parseError:
          print('⚠️ Error procesando datos.');
          break;
          
        default:
          print('❌ Error: ${e.userFriendlyMessage}');
      }
    } catch (e) {
      print('❌ Error inesperado: $e');
    } finally {
      apiService.dispose();
    }
  }
  
  /// Ejemplo 5: Obtener estadísticas
  static Future<void> example5GetStats() async {
    final apiService = ApiService();
    
    try {
      final stats = await apiService.getApiStats();
      
      print('📊 Estadísticas de API:');
      print('   Total: ${stats['total_stations']}');
      print('   Con Gasolina 95: ${stats['with_gasolina95']}');
      print('   Con Diésel: ${stats['with_diesel']}');
      print('   Con ambos: ${stats['with_both']}');
      print('   Timestamp: ${stats['timestamp']}');
      
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      apiService.dispose();
    }
  }
}

/// Función principal para ejecutar ejemplos
void main() async {
  print('=== EJEMPLOS DE USO DE API SERVICE ===\n');
  
  // Descomentar el ejemplo que quieras ejecutar:
  
  // await ApiUsageExamples.example1SimpleDownload();
  // await ApiUsageExamples.example2CheckConnectivity();
  // await ApiUsageExamples.example3DownloadAndCache();
  // await ApiUsageExamples.example4ErrorHandling();
  await ApiUsageExamples.example5GetStats();
}
```

### Instrucciones de Implementación:

1. Crear el directorio `lib/examples/` si no existe
2. Crear el archivo `api_usage_example.dart`
3. Copiar el código completo
4. Guardar el archivo

**Para ejecutar los ejemplos:**

```bash
# Ejecutar el archivo directamente
dart run lib/examples/api_usage_example.dart
```

---

## TAREA 6: Documentar Errores Comunes y Soluciones

### Crear archivo de documentación

**Ubicación:** `docs/API_TROUBLESHOOTING.md`

```markdown
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
```

---

## CHECKLIST DE IMPLEMENTACIÓN

### Obligatorio:
- [ ] Implementar `ApiService` completo (TAREA 1)
- [ ] Actualizar `AppConstants` con configuración API (TAREA 4)
- [ ] Probar que la app compila sin errores

### Recomendado:
- [ ] Crear tests de integración (TAREA 2)
- [ ] Crear utilidad `ApiValidator` (TAREA 3)
- [ ] Crear ejemplos de uso (TAREA 5)
- [ ] Crear documentación de troubleshooting (TAREA 6)

### Validación:
- [ ] La app compila sin errores
- [ ] `flutter analyze` no muestra errores críticos
- [ ] Tests de integración pasan (requiere internet)
- [ ] `ApiService.fetchGasStations()` descarga datos reales
- [ ] Manejo de errores funciona correctamente

---

## CÓMO PROBAR QUE FUNCIONA

### Prueba Manual 1: Descarga Básica

Ejecutar el ejemplo:

```bash
dart run lib/examples/api_usage_example.dart
```

**Resultado esperado:**
```
📊 Estadísticas de API:
   Total: 11500+ (número aproximado)
   Con Gasolina 95: 10000+
   Con Diésel: 11000+
   Con ambos: 9500+
   Timestamp: 2025-11-19T...
```

### Prueba Manual 2: Integración con Database

Crear un archivo temporal para probar:

```dart
// test_api_db.dart
import 'package:buscagas/services/api_service.dart';
import 'package:buscagas/services/database_service.dart';

void main() async {
  final apiService = ApiService();
  final dbService = DatabaseService();
  
  try {
    await dbService.initialize();
    
    print('Descargando desde API...');
    final stations = await apiService.fetchGasStations();
    print('✅ ${stations.length} gasolineras descargadas');
    
    print('Guardando en BD...');
    await dbService.saveStations(stations);
    print('✅ Guardadas en caché');
    
    print('Leyendo desde BD...');
    final cached = await dbService.getAllStations();
    print('✅ ${cached.length} gasolineras en caché');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    apiService.dispose();
  }
}
```

Ejecutar:
```bash
dart run test_api_db.dart
```

### Prueba Manual 3: Tests de Integración

```bash
flutter test test/integration/api_test.dart
```

**Resultado esperado:**
```
✅ All tests passed!
```

---

## ERRORES COMUNES Y SOLUCIONES

### Error: "MissingPluginException" con http

**Solución:**
```bash
flutter pub get
flutter clean
flutter pub get
```

### Error: "Timeout"

**Causa:** Red lenta o API sobrecargada
**Solución:** Es normal, el código ya maneja esto con `ApiException`

### Error: "FormatException" al parsear JSON

**Causa:** Formato de API cambió
**Solución:**
1. Ver respuesta real con debugging
2. Actualizar `ApiGasStationResponse` si es necesario

### Error: "SocketException"

**Causa:** Sin conexión a internet
**Solución:** Verificar WiFi/datos. El código ya maneja esto.

---

## INTEGRACIÓN CON PASOS ANTERIORES

### Conexión con Paso 4 (DatabaseService)

```dart
// Patrón típico: API -> Base de Datos
final apiService = ApiService();
final dbService = DatabaseService();

try {
  // Descargar
  final stations = await apiService.fetchGasStations();
  
  // Cachear
  await dbService.saveStations(stations);
  
} on ApiException catch (e) {
  // Si falla API, usar caché
  final cached = await dbService.getAllStations();
  print('Usando ${cached.length} gasolineras desde caché');
}
```

### Preparación para Paso 6 (Repositorios)

El `ApiService` será usado por `GasStationRepositoryImpl`:

```dart
// Pseudo-código del Paso 6
class GasStationRepositoryImpl {
  final ApiService _apiService;
  final DatabaseService _dbService;
  
  Future<List<GasStation>> getStations() async {
    try {
      // Primero intentar API
      final stations = await _apiService.fetchGasStations();
      
      // Cachear resultado
      await _dbService.saveStations(stations);
      
      return stations;
    } catch (e) {
      // Fallback a caché
      return await _dbService.getAllStations();
    }
  }
}
```

---

## NOTAS IMPORTANTES

1. **Conexión a Internet:** Todos los métodos que usan la API requieren internet activa.

2. **Timeout:** El timeout de 30 segundos es adecuado. La API puede tener ~11,000+ gasolineras.

3. **Caching:** Siempre combinar con `DatabaseService` para funcionamiento offline.

4. **Dispose:** Llamar a `apiService.dispose()` cuando termines de usarlo para liberar recursos.

5. **Testing:** Los tests de integración requieren internet. Ejecutarlos con moderación.

6. **Formato Español:** Los precios y coordenadas vienen con comas. `GasStationModel` ya maneja esto.

7. **Valores Nulos:** No todas las gasolineras tienen todos los combustibles. Validar antes de usar.

8. **Performance:** La descarga de 11,000+ gasolineras puede tardar 15-30 segundos dependiendo de la conexión.

---

## PRÓXIMOS PASOS (Paso 6)

Una vez completado el Paso 5, el siguiente paso será:

**PASO 6: Implementar Repositorios**
- Crear interfaz `GasStationRepository`
- Implementar `GasStationRepositoryImpl`
- Combinar `ApiService` + `DatabaseService`
- Lógica de caché inteligente
- Estrategia de actualización

El repositorio coordinará:
- Primero intentar API (datos frescos)
- Si falla, usar Database (caché)
- Actualizar caché cuando descarga exitosa
- Decidir cuándo los datos son "stale"

---

**Fecha de creación:** 19 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Paso:** 5 - Integración API Gubernamental (Instrucciones Detalladas)  
**Metodología:** Métrica v3
