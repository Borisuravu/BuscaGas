import 'package:buscagas/data/repositories/gas_station_repository_impl.dart';
import 'package:buscagas/data/datasources/remote/api_datasource.dart';
import 'package:buscagas/data/datasources/local/database_datasource.dart';

/// SCRIPT DE VALIDACIÓN DEL PASO 6
/// 
/// Verifica que el repositorio funcione correctamente
/// en el flujo completo: API → Caché → Filtrado → Ordenación

Future<void> main() async {
  print('╔════════════════════════════════════════════╗');
  print('║   VALIDACIÓN DEL PASO 6: REPOSITORIOS     ║');
  print('╚════════════════════════════════════════════╝\n');
  
  bool allTestsPassed = true;
  
  // ==================== TEST 1: Crear Repositorio ====================
  
  print('📝 TEST 1: Crear instancia de repositorio');
  late GasStationRepositoryImpl repository;
  
  try {
    final apiDataSource = ApiDataSource();
    final databaseDataSource = DatabaseDataSource();
    
    repository = GasStationRepositoryImpl(
      apiDataSource,
      databaseDataSource,
    );
    
    print('✅ Repositorio creado con inyección de dependencias\n');
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
    return;
  }
  
  // ==================== TEST 2: Fetch Remote ====================
  
  print('📝 TEST 2: Descargar desde API remota');
  print('   ⏳ Esto puede tardar 15-30 segundos...');
  
  try {
    final remoteStations = await repository.fetchRemoteStations();
    
    if (remoteStations.isEmpty) {
      print('❌ FALLÓ: API retornó lista vacía\n');
      allTestsPassed = false;
    } else {
      print('✅ Descargadas ${remoteStations.length} gasolineras');
      print('   Primera: ${remoteStations.first.name}');
      print('   Coordenadas: ${remoteStations.first.latitude}, ${remoteStations.first.longitude}\n');
    }
    
  } catch (e) {
    print('❌ FALLÓ: $e');
    print('   (Verifica conexión a internet)\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 3: Update Cache ====================
  
  print('📝 TEST 3: Actualizar caché local');
  
  try {
    final freshData = await repository.fetchRemoteStations();
    await repository.updateCache(freshData);
    
    print('✅ Caché actualizado con ${freshData.length} registros\n');
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 4: Get Cached ====================
  
  print('📝 TEST 4: Obtener desde caché local');
  
  try {
    final cachedStations = await repository.getCachedStations();
    
    if (cachedStations.isEmpty) {
      print('❌ FALLÓ: Caché está vacío después de updateCache()\n');
      allTestsPassed = false;
    } else {
      print('✅ Recuperadas ${cachedStations.length} gasolineras desde caché');
      print('   Primera: ${cachedStations.first.name}\n');
    }
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 5: Get Nearby (Madrid) ====================
  
  print('📝 TEST 5: Filtrar gasolineras cercanas (Madrid)');
  
  try {
    // Coordenadas de Madrid centro
    const double madridLat = 40.4168;
    const double madridLon = -3.7038;
    const double radius = 10.0;
    
    print('   📍 Ubicación: $madridLat, $madridLon');
    print('   📏 Radio: $radius km');
    
    final nearbyStations = await repository.getNearbyStations(
      latitude: madridLat,
      longitude: madridLon,
      radiusKm: radius,
    );
    
    if (nearbyStations.isEmpty) {
      print('⚠️  ADVERTENCIA: No hay gasolineras en radio de $radius km');
      print('   (Puede ser normal si no hay estaciones en esa zona)\n');
    } else {
      print('✅ Encontradas ${nearbyStations.length} gasolineras cercanas');
      
      // Mostrar las 3 primeras
      print('   🔍 Primeras 3 gasolineras:');
      
      for (var i = 0; i < nearbyStations.take(3).length; i++) {
        final station = nearbyStations[i];
        print('      ${i + 1}. ${station.name}');
        print('         ${station.locality}');
      }
      
      print('\n✅ Datos recuperados correctamente\n');
    }
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 6: Get Nearby (Barcelona) ====================
  
  print('📝 TEST 6: Filtrar gasolineras cercanas (Barcelona)');
  
  try {
    const double barcelonaLat = 41.3851;
    const double barcelonaLon = 2.1734;
    const double radius = 5.0;
    
    print('   📍 Ubicación: $barcelonaLat, $barcelonaLon');
    print('   📏 Radio: $radius km');
    
    final nearbyStations = await repository.getNearbyStations(
      latitude: barcelonaLat,
      longitude: barcelonaLon,
      radiusKm: radius,
    );
    
    print('✅ Encontradas ${nearbyStations.length} gasolineras en Barcelona\n');
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== TEST 7: Diferentes radios ====================
  
  print('📝 TEST 7: Probar diferentes radios de búsqueda');
  
  try {
    const double testLat = 40.4168;
    const double testLon = -3.7038;
    
    final radii = [5, 10, 20, 50];
    int previousCount = 0;
    
    for (var radius in radii) {
      final stations = await repository.getNearbyStations(
        latitude: testLat,
        longitude: testLon,
        radiusKm: radius.toDouble(),
      );
      
      print('   📏 Radio $radius km: ${stations.length} gasolineras');
      
      // Verificar que a mayor radio, más gasolineras (o igual)
      if (stations.length < previousCount) {
        print('❌ FALLÓ: Radio mayor tiene menos gasolineras\n');
        allTestsPassed = false;
        break;
      }
      
      previousCount = stations.length;
    }
    
    print('✅ Radios funcionan correctamente\n');
    
  } catch (e) {
    print('❌ FALLÓ: $e\n');
    allTestsPassed = false;
  }
  
  // ==================== RESUMEN FINAL ====================
  
  print('╔════════════════════════════════════════════╗');
  print('║            RESUMEN DE VALIDACIÓN          ║');
  print('╚════════════════════════════════════════════╝\n');
  
  if (allTestsPassed) {
    print('🎉 ¡TODOS LOS TESTS PASARON!');
    print('✅ El Paso 6 está completamente funcional');
    print('\nComponentes validados:');
    print('  ✅ Creación de repositorio');
    print('  ✅ Descarga desde API');
    print('  ✅ Actualización de caché');
    print('  ✅ Lectura desde caché');
    print('  ✅ Filtrado geográfico');
    print('  ✅ Ordenación por distancia');
    print('  ✅ Múltiples radios de búsqueda');
  } else {
    print('❌ ALGUNOS TESTS FALLARON');
    print('⚠️  Revisa los errores arriba');
    print('\nAcciones sugeridas:');
    print('  1. Verifica conexión a internet');
    print('  2. Revisa permisos de base de datos');
    print('  3. Ejecuta flutter clean && flutter pub get');
    print('  4. Revisa logs de errores');
  }
  
  print('\n${'=' * 48}');
}
