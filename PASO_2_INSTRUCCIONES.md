# PASO 2: Crear Proyecto Flutter Inicial

## Información extraída de la Documentación V3 para el Paso 2

---

## 🎯 OBJETIVO DEL PASO 2
- Inicializar proyecto con Flutter CLI
- Configurar estructura de carpetas según Clean Architecture
- Añadir dependencias básicas en pubspec.yaml

---

## 📋 REQUISITOS DEL PROYECTO

### Información General (PSI 1)
- **Nombre:** BuscaGas
- **Descripción:** Localizador de gasolineras económicas en España
- **Plataforma:** Android (API 23+)
- **Framework:** Flutter/Dart
- **Versión:** 1.0.0+1

### Compatibilidad (RNF-03)
- Android 6.0 (API 23) o superior
- Flutter SDK 3.10+
- Dart SDK 3.0+

---

## 🏗️ ARQUITECTURA (DSI 2)

### Patrón Arquitectónico
**Clean Architecture con Capas:**

```
┌───────────────┐
│ Presentation  │ ← Pantallas, Widgets, BLoC
└───────┬───────┘
        │ depende
        ▼
┌───────────────┐      ┌──────────┐
│    Domain     │◄─────│   Core   │ ← Utilidades, Constantes, Temas
└───────┬───────┘      └──────────┘
        │ depende          ▲
        ▼                  │
┌───────────────┐          │
│     Data      │──────────┘ ← Repositorios, Modelos, Data Sources
└───────┬───────┘
        │ depende
        ▼
┌───────────────┐
│   Services    │ ← Servicios del sistema (GPS, HTTP, DB)
└───────────────┘
```

### 5 Módulos Principales

**Módulo 1: Core**
- Configuración global
- Constantes (API, App)
- Utilidades comunes (calculadora de distancias, formateador de precios)
- Gestión de temas (claro/oscuro)

**Módulo 2: Data**
- Modelos de datos
- Repositorios (implementaciones)
- Data sources (API remota y base de datos local)
- DTOs y mappers

**Módulo 3: Domain**
- Entidades de negocio (GasStation, FuelPrice, AppSettings)
- Casos de uso
- Interfaces de repositorios
- Reglas de negocio

**Módulo 4: Presentation**
- Screens (splash, map, settings)
- Widgets (marcadores, tarjetas, selectores)
- State management (BLoC)
- Navegación

**Módulo 5: Services**
- Servicios de terceros
- Servicios del sistema (GPS, almacenamiento, sincronización)

---

## 📁 ESTRUCTURA DE DIRECTORIOS COMPLETA (DSI 8)

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── colors.dart
│   └── utils/
│       ├── distance_calculator.dart
│       └── price_formatter.dart
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── database_datasource.dart
│   │   └── remote/
│   │       └── api_datasource.dart
│   ├── models/
│   │   ├── gas_station_model.dart
│   │   ├── fuel_price_model.dart
│   │   └── api_response_model.dart
│   └── repositories/
│       └── gas_station_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── gas_station.dart
│   │   ├── fuel_price.dart
│   │   └── app_settings.dart
│   ├── repositories/
│   │   └── gas_station_repository.dart
│   └── usecases/
│       ├── get_nearby_stations.dart
│       ├── filter_by_fuel_type.dart
│       └── calculate_distance.dart
├── presentation/
│   ├── blocs/
│   │   ├── map/
│   │   │   ├── map_bloc.dart
│   │   │   ├── map_event.dart
│   │   │   └── map_state.dart
│   │   └── settings/
│   │       ├── settings_bloc.dart
│   │       ├── settings_event.dart
│   │       └── settings_state.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── map_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── gas_station_marker.dart
│       ├── info_card.dart
│       └── fuel_selector.dart
└── services/
    ├── location_service.dart
    ├── api_service.dart
    ├── database_service.dart
    └── sync_service.dart
```

---

## 📦 DEPENDENCIAS (DSI 8 - pubspec.yaml)

### Información del Proyecto
```yaml
name: buscagas
description: Localizador de gasolineras económicas en España
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
```

### Dependencies (Producción)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # Networking
  http: ^1.1.0
  dio: ^5.3.3
  
  # Local Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  
  # Maps
  google_maps_flutter: ^2.5.0
  
  # Location
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  
  # Utilities
  intl: ^0.18.1
  equatable: ^2.0.5
```

### Dev Dependencies (Desarrollo)
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.2
```

---

## 🔧 CONFIGURACIÓN INICIAL

### Android Configuration
**Compatibilidad mínima:** Android 6.0 (API 23)

---

## ✅ CHECKLIST PASO 2

### Tareas a Completar:
1. ✅ Crear proyecto Flutter con comando CLI
2. ✅ Configurar `pubspec.yaml` con:
   - Información del proyecto
   - SDK constraints
   - Todas las dependencias listadas
3. ✅ Crear estructura completa de carpetas en `lib/`
4. ✅ Crear archivos placeholder (vacíos o con estructura básica) en cada carpeta
5. ✅ Verificar que el proyecto compila sin errores
6. ✅ Ejecutar `flutter pub get` para descargar dependencias

### Archivos Mínimos para Crear (como placeholder):
- `lib/main.dart` (punto de entrada básico)
- Cada archivo `.dart` listado en la estructura con comentario `// TODO: Implement`
- Total: ~27 archivos Dart

---

## 📝 NOTAS IMPORTANTES

### Principios de Clean Architecture a Seguir:
1. **Separación de responsabilidades** por capas
2. **Inversión de dependencias**: las capas superiores dependen de abstracciones
3. **Domain** es independiente de frameworks y UI
4. **Data** implementa las interfaces definidas en Domain
5. **Presentation** solo conoce Domain, no Data directamente

### Próximos Pasos (no en Paso 2):
- Paso 3: Implementar modelos de datos y entidades
- Paso 4: Configurar base de datos local
- Paso 5: Integrar API gubernamental

---

## 🎯 CRITERIO DE ÉXITO DEL PASO 2

**El Paso 2 está completo cuando:**
- ✅ Proyecto Flutter creado y compilable
- ✅ Estructura de carpetas completa según Clean Architecture
- ✅ Todas las dependencias en `pubspec.yaml` descargadas sin errores
- ✅ Archivos placeholder creados en su ubicación correcta
- ✅ Comando `flutter run` ejecuta sin errores de configuración

---

**Fecha de creación:** 17 de noviembre de 2025  
**Basado en:** BuscaGas Documentacion V3 (Métrica v3)
