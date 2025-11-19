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
