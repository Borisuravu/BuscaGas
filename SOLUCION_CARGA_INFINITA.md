# 🔧 Solución: Carga Infinita en MapScreen

## 🐛 Problema Reportado
Después de seleccionar tema (claro/oscuro) y aceptar permisos de ubicación, la aplicación se quedaba cargando infinitamente mostrando un `CircularProgressIndicator`.

## 🔍 Diagnóstico

### Causa Raíz
En `map_screen.dart`, el método `initState()` llamaba dos funciones async **sin esperar** su completitud:

```dart
@override
void initState() {
  super.initState();
  _initializeMarkerIcons();
  _initializeDependencies();  // ← async pero NO await
  _initializeMap();            // ← async pero NO await
}
```

### Flujo Problemático
1. `initState()` se ejecuta de forma **síncrona**
2. Lanza `_initializeDependencies()` (async) sin esperar
3. Lanza `_initializeMap()` (async) sin esperar
4. `initState()` termina **inmediatamente**
5. `build()` se ejecuta con `_mapBloc == null`
6. Muestra `CircularProgressIndicator` infinitamente:
   ```dart
   if (_mapBloc == null) {
     return const Scaffold(
       body: Center(
         child: CircularProgressIndicator(),
       ),
     );
   }
   ```
7. Cuando `_initializeDependencies()` termina y crea `_mapBloc`, **nunca llama a `setState()`**
8. El widget **nunca se reconstruye**, quedando atascado en loading

### Problema Secundario
`_initializeMap()` se ejecutaba **en paralelo** con `_initializeDependencies()`, intentando usar `_mapBloc` antes de que existiera:

```dart
Future<void> _initializeMap() async {
  // ...
  if (mounted && _mapBloc != null) {  // ← _mapBloc aún es null
    _mapBloc!.add(LoadMapData(...));
  }
}
```

## ✅ Solución Implementada

### 1. Inicialización Secuencial
Crear un método wrapper que ejecute las operaciones **en orden**:

```dart
@override
void initState() {
  super.initState();
  _initializeMarkerIcons();
  _initializeAsync();  // ← Nuevo wrapper async
}

/// Inicializar todo de forma ordenada
Future<void> _initializeAsync() async {
  await _initializeDependencies();  // ← ESPERA a que termine
  await _initializeMap();            // ← LUEGO ejecuta esto
}
```

### 2. Llamar setState al Completar
Al final de `_initializeDependencies()`, forzar reconstrucción del widget:

```dart
Future<void> _initializeDependencies() async {
  // ... crear apiDataSource, repository, etc.
  
  // Crear MapBloc
  _mapBloc = MapBloc(...);
  
  // Crear sincronización
  _dataSyncService = DataSyncService(repository);
  _dataSyncService?.startPeriodicSync();
  
  debugPrint('✅ Dependencias de MapScreen inicializadas');
  
  // ✨ CRÍTICO: Actualizar UI para mostrar el widget
  if (mounted) {
    setState(() {});  // ← Reconstruye con _mapBloc != null
  }
}
```

## 📊 Resultado

### Antes
```
Usuario acepta tema → acepta permisos → ⏳ Loading infinito
```

### Después
```
Usuario acepta tema → acepta permisos → ✅ Mapa carga correctamente
```

### Flujo Correcto
1. `initState()` llama a `_initializeAsync()`
2. `_initializeAsync()` **espera** a `_initializeDependencies()`
3. `_initializeDependencies()` crea `_mapBloc`
4. `setState()` reconstruye el widget
5. `build()` ve `_mapBloc != null` y muestra el `BlocProvider`
6. `_initializeMap()` se ejecuta con `_mapBloc` ya creado
7. Pide permisos y carga datos en el mapa

## 🎯 Lecciones Aprendidas

### ❌ Error Común
Llamar funciones async desde `initState()` sin manejar correctamente el ciclo de vida:

```dart
// INCORRECTO
@override
void initState() {
  super.initState();
  _asyncMethod();  // Se lanza pero no se espera
}
```

### ✅ Patrón Correcto
Usar un wrapper async y llamar `setState()` cuando los datos estén listos:

```dart
// CORRECTO
@override
void initState() {
  super.initState();
  _initializeAsync();
}

Future<void> _initializeAsync() async {
  await _loadData();
  if (mounted) {
    setState(() {});
  }
}
```

### 🔑 Regla Clave
**Siempre que modifiques el estado en una operación async iniciada desde `initState()`, debes llamar a `setState()` para reconstruir el widget.**

## 📝 Archivos Modificados
- `lib/presentation/screens/map_screen.dart`
  - Líneas 51-61: Nuevo método `_initializeAsync()`
  - Líneas 107-111: Agregado `setState()` al final de `_initializeDependencies()`

## 🧪 Validación
Para probar que la solución funciona:
1. Desinstalar la app completamente
2. Reinstalar y ejecutar
3. Seleccionar tema (claro u oscuro)
4. Aceptar permisos de ubicación
5. ✅ El mapa debe cargar correctamente en ~2-3 segundos

---
**Fecha:** 2 de diciembre de 2025  
**Problema:** Carga infinita después de seleccionar tema y permisos  
**Solución:** Inicialización secuencial con setState()
