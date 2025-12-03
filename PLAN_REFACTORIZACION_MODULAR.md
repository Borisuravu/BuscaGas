# Plan de Refactorización Modular - BuscaGas

**Objetivo**: Refactorizar el proyecto paso a paso en consultas independientes

---

## 📦 MÓDULO 1: Limpieza de Archivos Duplicados
**Tiempo estimado**: 30 minutos  
**Estado**: ✅ Completado

### Tareas:
1. ✅ Eliminar `lib/services/api_service.dart`
2. ✅ Eliminar `lib/services/database_service.dart`
3. ✅ Eliminar `lib/services/sync_service.dart`
4. ✅ Eliminar carpeta `lib/examples/`
5. ✅ Buscar y actualizar imports de archivos eliminados
6. ✅ Verificar compilación con `flutter analyze`

### Archivos afectados:
- `lib/services/api_service.dart` (eliminado)
- `lib/services/database_service.dart` (eliminado)
- `lib/services/sync_service.dart` (eliminado)
- `lib/examples/` (carpeta eliminada)
- `test/integration/api_test.dart` (actualizado)
- `test/services/database_service_test.dart` (actualizado)
- `lib/presentation/screens/splash_screen.dart` (actualizado)
- `lib/domain/entities/app_settings.dart` (actualizado)
- `lib/services/data_sync_service.dart` (actualizado)

### Criterios de éxito:
- ✅ Archivos duplicados eliminados
- ✅ Todos los imports actualizados correctamente
- ✅ `flutter analyze` sin errores (solo 2 warnings y 81 info)
- ✅ La app compila sin errores

---

## 📦 MÓDULO 2: Crear AppInitializer
**Tiempo estimado**: 45 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 1

### Tareas:
1. Crear archivo `lib/core/app_initializer.dart`
2. Implementar clase `AppInitializer` con método `initialize()`
3. Mover toda la lógica de inicialización desde `main.dart`
4. Crear getters estáticos para acceder a servicios
5. Simplificar `main.dart` a ~10 líneas
6. Probar que la app inicia correctamente

### Archivos a crear:
- `lib/core/app_initializer.dart`

### Archivos a modificar:
- `lib/main.dart` (simplificar)

### Criterios de éxito:
- ✅ `AppInitializer` creado y funcional
- ✅ `main.dart` tiene menos de 15 líneas
- ✅ La app inicia sin errores
- ✅ Todos los servicios accesibles mediante `AppInitializer.xxx`

---

## 📦 MÓDULO 3: Eliminar GlobalKey Anti-patrón
**Tiempo estimado**: 20 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 2

### Tareas:
1. Identificar usos de `appKey` en el código
2. Eliminar `final GlobalKey<BuscaGasAppState> appKey = GlobalKey<BuscaGasAppState>();`
3. Eliminar parámetro `key: appKey` de `BuscaGasApp`
4. Actualizar `SettingsBloc` para manejar reload de settings
5. Reemplazar `appKey.currentState?.reloadSettings()` con BLoC events
6. Verificar funcionalidad de recarga de configuración

### Archivos a modificar:
- `lib/main.dart` (eliminar GlobalKey)
- `lib/presentation/blocs/settings/settings_bloc.dart` (agregar evento reload)
- Archivos que usan `appKey` (actualizar)

### Criterios de éxito:
- ✅ No hay referencias a `appKey` en el código
- ✅ La recarga de settings funciona mediante BLoC
- ✅ La app compila y funciona correctamente

---

## 📦 MÓDULO 4: Crear Sistema de Manejo de Errores
**Tiempo estimado**: 30 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 1

### Tareas:
1. Crear carpeta `lib/core/errors/`
2. Crear archivo `lib/core/errors/app_error.dart`
3. Implementar clase `AppError` con factory constructors
4. Implementar enum `ErrorType`
5. Actualizar 2-3 BLoCs para usar `AppError`
6. Probar manejo de errores en la UI

### Archivos a crear:
- `lib/core/errors/app_error.dart`

### Archivos a modificar:
- `lib/presentation/blocs/map/map_bloc.dart` (usar AppError)
- `lib/presentation/blocs/map/map_state.dart` (usar AppError)
- Otros BLoCs según necesidad

### Criterios de éxito:
- ✅ `AppError` creado y documentado
- ✅ Al menos 2 BLoCs usando `AppError`
- ✅ Errores se muestran consistentemente en UI
- ✅ Sin errores de compilación

---

## 📦 MÓDULO 5: Refactorizar MapBloc
**Tiempo estimado**: 45 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 4

### Tareas:
1. Verificar que `AssignPriceRangeUseCase` existe en `lib/domain/usecases/`
2. Si no existe, crearlo con la lógica de `_assignPriceRanges`
3. Mover lógica de `_assignPriceRanges` del MapBloc al UseCase
4. Actualizar MapBloc para usar el caso de uso
5. Eliminar método `_assignPriceRanges` de MapBloc
6. Probar que la clasificación de precios funciona

### Archivos a modificar:
- `lib/presentation/blocs/map/map_bloc.dart` (simplificar)
- `lib/domain/usecases/assign_price_range.dart` (verificar/mejorar)

### Criterios de éxito:
- ✅ MapBloc no tiene lógica de negocio
- ✅ `AssignPriceRangeUseCase` maneja toda la lógica
- ✅ La clasificación de precios funciona igual
- ✅ Código más limpio y testeable

---

## 📦 MÓDULO 6: Implementar SimpleCache
**Tiempo estimado**: 20 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 1

### Tareas:
1. Crear carpeta `lib/core/cache/`
2. Crear archivo `lib/core/cache/simple_cache.dart`
3. Implementar clase `SimpleCache<T>`
4. Implementar clase privada `_CacheEntry<T>`
5. Integrar caché en `GasStationRepositoryImpl`
6. Probar que el caché funciona correctamente

### Archivos a crear:
- `lib/core/cache/simple_cache.dart`

### Archivos a modificar:
- `lib/data/repositories/gas_station_repository_impl.dart` (agregar caché)

### Criterios de éxito:
- ✅ `SimpleCache` implementado
- ✅ Repositorio usa caché para consultas repetidas
- ✅ Caché expira después de 30 minutos
- ✅ Mejora perceptible en velocidad de consultas

---

## 📦 MÓDULO 7: Implementar Debouncer
**Tiempo estimado**: 15 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 1

### Tareas:
1. Crear archivo `lib/core/utils/debouncer.dart`
2. Implementar clase `Debouncer`
3. Identificar campos de búsqueda en la app
4. Integrar debouncer en búsquedas/filtros
5. Probar que solo se ejecuta después de pausar escritura

### Archivos a crear:
- `lib/core/utils/debouncer.dart`

### Archivos a modificar:
- Widgets con búsqueda (si existen)

### Criterios de éxito:
- ✅ `Debouncer` implementado
- ✅ Búsquedas no se ejecutan en cada tecla
- ✅ Mejora en rendimiento de búsquedas
- ✅ Experiencia de usuario más fluida

---

## 📦 MÓDULO 8: Verificar Optimizaciones de Mapa
**Tiempo estimado**: 15 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 5

### Tareas:
1. Verificar que MapBloc limita estaciones a 50
2. Si no está implementado, agregar límite
3. Probar con dataset grande (500+ estaciones)
4. Verificar rendimiento del mapa
5. Documentar la optimización

### Archivos a modificar:
- `lib/presentation/blocs/map/map_bloc.dart` (verificar límite)

### Criterios de éxito:
- ✅ Mapa solo muestra máximo 50 marcadores
- ✅ Rendimiento fluido (60 FPS)
- ✅ No hay lag al mover el mapa
- ✅ Código documentado

---

## 📦 MÓDULO 9: Mejorar Lints
**Tiempo estimado**: 10 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Ninguno (independiente)

### Tareas:
1. Abrir `analysis_options.yaml`
2. Agregar reglas de linting recomendadas
3. Ejecutar `flutter analyze`
4. Corregir warnings importantes (máximo 5)
5. Verificar que no hay errores críticos

### Archivos a modificar:
- `analysis_options.yaml`

### Criterios de éxito:
- ✅ Lints mejorados configurados
- ✅ `flutter analyze` ejecutado
- ✅ Warnings críticos corregidos
- ✅ Código más consistente

---

## 📦 MÓDULO 10: Tests Esenciales - Casos de Uso
**Tiempo estimado**: 40 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulos 1, 5

### Tareas:
1. Verificar tests existentes en `test/domain/usecases/`
2. Asegurar que hay test para `GetNearbyStationsUseCase`
3. Asegurar que hay test para `FilterByFuelTypeUseCase`
4. Asegurar que hay test para `AssignPriceRangeUseCase`
5. Ejecutar `flutter test` y verificar que pasen

### Archivos a verificar/crear:
- `test/domain/usecases/get_nearby_stations_test.dart`
- `test/domain/usecases/filter_by_fuel_type_test.dart`
- `test/domain/usecases/assign_price_range_test.dart`

### Criterios de éxito:
- ✅ Al menos 3 tests de casos de uso
- ✅ Todos los tests pasan
- ✅ Cobertura básica de lógica de negocio
- ✅ Tests documentados

---

## 📦 MÓDULO 11: Tests del Repositorio
**Tiempo estimado**: 20 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Módulo 6

### Tareas:
1. Verificar tests en `test/repositories/`
2. Asegurar test para `fetchRemoteStations()`
3. Asegurar test para `getNearbyStations()`
4. Ejecutar tests y verificar que pasen
5. Documentar casos de prueba

### Archivos a verificar/crear:
- `test/repositories/gas_station_repository_test.dart`

### Criterios de éxito:
- ✅ Al menos 2 tests del repositorio
- ✅ Tests verifican caché
- ✅ Tests verifican manejo de errores
- ✅ Todos pasan correctamente

---

## 📦 MÓDULO 12: Actualizar README
**Tiempo estimado**: 15 minutos  
**Estado**: ⏳ Pendiente  
**Depende de**: Todos los módulos anteriores

### Tareas:
1. Abrir `README.md`
2. Actualizar descripción del proyecto
3. Agregar sección de características
4. Agregar instrucciones de instalación
5. Agregar estructura del proyecto
6. Agregar comandos útiles

### Archivos a modificar:
- `README.md`

### Criterios de éxito:
- ✅ README completo y profesional
- ✅ Instrucciones claras
- ✅ Comandos de testing documentados
- ✅ Arquitectura explicada brevemente

---

## 📊 Resumen de Progreso

### Total de Módulos: 12
- ⏳ Pendientes: 11
- 🔄 En progreso: 0
- ✅ Completados: 1

### Tiempo Total Estimado: ~5.5 horas
### Tiempo Invertido: ~30 minutos

### Orden Sugerido de Ejecución:
1. **Módulo 1** (Limpieza) - Base para todo
2. **Módulo 9** (Lints) - Puede hacerse en paralelo
3. **Módulo 2** (AppInitializer) - Simplifica arquitectura
4. **Módulo 4** (AppError) - Manejo de errores
5. **Módulo 3** (GlobalKey) - Requiere AppInitializer
6. **Módulo 5** (MapBloc) - Requiere AppError
7. **Módulo 6** (SimpleCache) - Optimización
8. **Módulo 7** (Debouncer) - Optimización
9. **Módulo 8** (Mapa) - Requiere MapBloc
10. **Módulo 10** (Tests UC) - Testing
11. **Módulo 11** (Tests Repo) - Testing
12. **Módulo 12** (README) - Documentación final

---

## 🎯 Cómo Usar Este Plan

### En cada consulta:
1. **Referencia el módulo**: "Implementa el Módulo X"
2. **Verifica dependencias**: Asegúrate de que los módulos requeridos estén completos
3. **Marca como completado**: Actualiza el estado cuando termines
4. **Verifica criterios**: Confirma que se cumplen todos los criterios de éxito

### Comandos útiles entre módulos:
```bash
# Verificar compilación
flutter analyze

# Ejecutar tests
flutter test

# Ver errores
flutter run

# Formatear código
flutter format .
```
---

**Última actualización**: 3 de diciembre de 2025  
**Estado del proyecto**: Módulo 1 completado ✅ - Archivos duplicados eliminados y todos los imports actualizados
**Estado del proyecto**: Iniciando refactorización
