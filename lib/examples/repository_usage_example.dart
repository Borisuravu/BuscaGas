import 'package:buscagas/domain/repositories/gas_station_repository.dart';
import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

/// EJEMPLOS DE USO DEL REPOSITORY PATTERN
///
/// Este archivo muestra cómo usar GasStationRepository
/// en diferentes escenarios de la aplicación

class RepositoryUsageExamples {
  /// Ejemplo 1: Inicialización del repositorio con inyección de dependencias
  static GasStationRepository createRepository() {
    final apiDataSource = ApiDataSource();
    final databaseDataSource = DatabaseDataSource();

    return GasStationRepositoryImpl(
      apiDataSource,
      databaseDataSource,
    );
  }

  /// Ejemplo 2: Carga inicial de datos (primera vez que se abre la app)
  static Future<void> example1InitialLoad() async {
    print('\n=== EJEMPLO 1: Carga Inicial ===\n');

    final repository = createRepository();

    try {
      // 1. Intentar obtener datos desde API
      print('📥 Descargando datos desde API...');
      final stations = await repository.fetchRemoteStations();
      print('✅ Descargadas ${stations.length} gasolineras');

      // 2. Guardar en caché para uso offline
      print('💾 Guardando en caché local...');
      await repository.updateCache(stations);
      print('✅ Caché actualizado');

      // 3. Mostrar primeras 3 estaciones
      print('\n📋 Primeras 3 gasolineras:');
      for (var station in stations.take(3)) {
        print('  - ${station.name} (${station.locality})');
        print('    ${station.latitude}, ${station.longitude}');
      }
    } catch (e) {
      print('❌ Error en carga inicial: $e');
    }
  }

  /// Ejemplo 2: Obtener gasolineras cercanas a ubicación del usuario
  static Future<void> example2GetNearby() async {
    print('\n=== EJEMPLO 2: Gasolineras Cercanas ===\n');

    final repository = createRepository();

    try {
      // Coordenadas de Madrid centro
      const double userLat = 40.4168;
      const double userLon = -3.7038;
      const double radiusKm = 10.0;

      print('📍 Ubicación del usuario: $userLat, $userLon');
      print('🔍 Buscando en radio de $radiusKm km...');

      final nearbyStations = await repository.getNearbyStations(
        latitude: userLat,
        longitude: userLon,
        radiusKm: radiusKm,
      );

      print('✅ Encontradas ${nearbyStations.length} gasolineras cercanas');

      // Mostrar las 5 más cercanas
      print('\n📋 5 gasolineras más cercanas:');
      for (var i = 0; i < nearbyStations.take(5).length; i++) {
        final station = nearbyStations[i];
        print('  ${i + 1}. ${station.name}');
        print('     Dirección: ${station.address}');
        print('     Localidad: ${station.locality}');
      }
    } catch (e) {
      print('❌ Error al buscar cercanas: $e');
    }
  }

  /// Ejemplo 3: Estrategia de caché primero (Cache-First)
  /// Cargar desde caché inmediatamente, actualizar en background
  static Future<void> example3CacheFirst() async {
    print('\n=== EJEMPLO 3: Estrategia Cache-First ===\n');

    final repository = createRepository();

    try {
      // PASO 1: Cargar desde caché inmediatamente (rápido)
      print('📂 Cargando desde caché...');
      final cachedStations = await repository.getCachedStations();

      if (cachedStations.isNotEmpty) {
        print('✅ Mostrando ${cachedStations.length} gasolineras en caché');
        print('   (Usuario ve datos inmediatamente)');
      } else {
        print('⚠️ Caché vacío, mostrando pantalla de carga');
      }

      // PASO 2: Actualizar desde API en background (lento)
      print('\n🌐 Actualizando desde API en background...');
      try {
        final freshStations = await repository.fetchRemoteStations();
        await repository.updateCache(freshStations);
        print('✅ Caché actualizado con ${freshStations.length} gasolineras');
        print('   (UI se actualiza con datos frescos)');
      } catch (e) {
        print('⚠️ Error al actualizar, manteniendo caché: $e');
        print('   (Usuario sigue viendo datos antiguos)');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Ejemplo 4: Estrategia de red primero (Network-First)
  /// Intentar API, si falla usar caché
  static Future<void> example4NetworkFirst() async {
    print('\n=== EJEMPLO 4: Estrategia Network-First ===\n');

    final repository = createRepository();

    try {
      // PASO 1: Intentar obtener datos frescos desde API
      print('🌐 Intentando descargar desde API...');

      try {
        final freshStations = await repository.fetchRemoteStations();
        await repository.updateCache(freshStations);

        print('✅ Datos frescos: ${freshStations.length} gasolineras');
        print('   (Usuario ve datos actualizados)');
      } catch (apiError) {
        // PASO 2: Si falla API, usar caché como fallback
        print('⚠️ API no disponible: $apiError');
        print('📂 Intentando cargar desde caché...');

        final cachedStations = await repository.getCachedStations();

        if (cachedStations.isNotEmpty) {
          print('✅ Usando caché: ${cachedStations.length} gasolineras');
          print('   (Usuario ve datos antiguos pero funcionales)');
        } else {
          print('❌ No hay datos en caché');
          print('   (Mostrar mensaje: "Sin conexión y sin datos")');
        }
      }
    } catch (e) {
      print('❌ Error crítico: $e');
    }
  }

  /// Ejemplo 5: Sincronización periódica (usado por SyncService)
  static Future<void> example5PeriodicSync() async {
    print('\n=== EJEMPLO 5: Sincronización Periódica ===\n');

    final repository = createRepository();

    try {
      // Simular sincronización periódica cada X minutos
      print('⏰ Ejecutando sincronización automática...');

      // 1. Obtener datos frescos
      final freshStations = await repository.fetchRemoteStations();

      // 2. Obtener datos actuales en caché
      final cachedStations = await repository.getCachedStations();

      // 3. Comparar si hay cambios
      final hasChanges = freshStations.length != cachedStations.length;

      if (hasChanges) {
        print('🔄 Detectados cambios, actualizando caché...');
        await repository.updateCache(freshStations);
        print('✅ Caché actualizado');
        print('   (Notificar UI: "Datos actualizados")');
      } else {
        print('✅ Datos sin cambios, caché vigente');
        print('   (No se notifica al usuario)');
      }
    } catch (e) {
      print('⚠️ Sincronización fallida: $e');
      print('   (Reintentar en próximo ciclo)');
    }
  }

  /// Ejemplo 6: Búsqueda con diferentes radios
  static Future<void> example6DifferentRadii() async {
    print('\n=== EJEMPLO 6: Búsqueda con Diferentes Radios ===\n');

    final repository = createRepository();

    const double userLat = 40.4168;
    const double userLon = -3.7038;

    final radii = [5, 10, 20, 50]; // Radios configurables en AppSettings

    print('📍 Ubicación: $userLat, $userLon\n');

    for (var radius in radii) {
      try {
        final stations = await repository.getNearbyStations(
          latitude: userLat,
          longitude: userLon,
          radiusKm: radius.toDouble(),
        );

        print('📏 Radio: $radius km → ${stations.length} gasolineras');
      } catch (e) {
        print('📏 Radio: $radius km → Error: $e');
      }
    }
  }
}

/// Función principal para ejecutar ejemplos
void main() async {
  print('╔════════════════════════════════════════════╗');
  print('║  EJEMPLOS DE USO DE REPOSITORY PATTERN    ║');
  print('╚════════════════════════════════════════════╝');

  // Descomentar el ejemplo que quieras ejecutar:

  // await RepositoryUsageExamples.example1InitialLoad();
  // await RepositoryUsageExamples.example2GetNearby();
  // await RepositoryUsageExamples.example3CacheFirst();
  // await RepositoryUsageExamples.example4NetworkFirst();
  // await RepositoryUsageExamples.example5PeriodicSync();
  await RepositoryUsageExamples.example6DifferentRadii();

  print('\n✅ Ejemplos completados');
}
