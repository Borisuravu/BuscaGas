# BuscaGas 🚗⛽

**BuscaGas** es una aplicación móvil desarrollada en Flutter que permite a los usuarios encontrar gasolineras cercanas, comparar precios de combustible en tiempo real y optimizar sus decisiones de repostaje.

## 📱 Características

- **🗺️ Mapa Interactivo**: Visualiza gasolineras cercanas en Google Maps con marcadores personalizados
- **📍 Ubicación en Tiempo Real**: Detecta automáticamente tu ubicación actual
- **💰 Comparación de Precios**: Compara precios de diferentes tipos de combustible (Gasolina 95, Diesel, etc.)
- **🎨 Clasificación por Rangos**: Identifica gasolineras económicas, medias y caras mediante colores
- **🔍 Filtros Avanzados**: Filtra por tipo de combustible y radio de búsqueda
- **💾 Caché Inteligente**: Sistema de caché de dos niveles (memoria + SQLite) para acceso rápido
- **🔄 Sincronización**: Actualiza datos desde la API del Gobierno de España
- **⚙️ Configuración Personalizable**: Ajusta preferencias de ubicación y combustible
- **🌙 Modo Oscuro**: Interfaz adaptable según preferencias del sistema

## 🏗️ Arquitectura

El proyecto sigue los principios de **Clean Architecture** con una separación clara de responsabilidades:

```
lib/
├── core/                    # Funcionalidades transversales
│   ├── app_initializer.dart # Inicialización centralizada
│   ├── errors/             # Sistema de manejo de errores
│   ├── cache/              # Caché en memoria (TTL)
│   └── utils/              # Utilidades (Debouncer, etc.)
├── data/                    # Capa de datos
│   ├── datasources/        # Fuentes de datos (API, DB)
│   ├── models/             # Modelos de datos
│   └── repositories/       # Implementación de repositorios
├── domain/                  # Capa de dominio (lógica de negocio)
│   ├── entities/           # Entidades del dominio
│   ├── repositories/       # Contratos de repositorios
│   └── usecases/           # Casos de uso
├── presentation/            # Capa de presentación
│   ├── blocs/              # Gestión de estado (BLoC)
│   ├── screens/            # Pantallas de la app
│   └── widgets/            # Componentes reutilizables
└── services/                # Servicios (ubicación, sincronización)
```

### Patrones Implementados

- **BLoC Pattern**: Gestión de estado reactiva y predecible
- **Repository Pattern**: Abstracción de fuentes de datos
- **UseCase Pattern**: Encapsulación de lógica de negocio
- **Dependency Injection**: Mediante `AppInitializer` centralizado
- **Caché de Dos Niveles**: SimpleCache (memoria) + SQLite (persistente)

## 🚀 Instalación

### Requisitos Previos

- Flutter SDK (3.0 o superior)
- Dart SDK (3.0 o superior)
- Android Studio / VS Code
- Google Maps API Key

### Configuración

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/BuscaGas.git
   cd BuscaGas
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Google Maps API Key**
   - Obtén una API Key desde [Google Cloud Console](https://console.cloud.google.com/)
   - Habilita las siguientes APIs:
     - Maps SDK for Android
     - Geocoding API (opcional)
   - Agrega tu API Key en `android/local.properties`:
     ```properties
     MAPS_API_KEY=TU_API_KEY_AQUI
     ```

4. **Verificar configuración**
   ```bash
   flutter analyze
   ```

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 🧪 Testing

El proyecto cuenta con una suite completa de tests:

### Ejecutar Todos los Tests
```bash
flutter test
```

### Ejecutar Tests con Cobertura
```bash
flutter test --coverage
```

### Ejecutar Tests Específicos
```bash
# Tests de casos de uso
flutter test test/domain/usecases/

# Tests de repositorios
flutter test test/repositories/

# Tests de servicios
flutter test test/services/
```

### Cobertura Actual
- **63 tests en total**
- 50 tests de casos de uso (UseCases)
- 13 tests de repositorios
- 100% de los tests pasando ✅

## 📝 Comandos Útiles

```bash
# Analizar código (linting)
flutter analyze

# Formatear código
flutter format .

# Limpiar build
flutter clean

# Reconstruir proyecto
flutter pub get

# Generar APK
flutter build apk

# Ver árbol de dependencias
flutter pub deps
```

## 🔧 Optimizaciones Implementadas

1. **Caché Inteligente**: Sistema de caché de dos niveles reduce llamadas a la API
2. **Límite de Marcadores**: Máximo 50 marcadores en mapa para mantener 60 FPS
3. **Debouncer**: Previene ejecuciones excesivas en búsquedas y filtros
4. **Lazy Loading**: Inicialización diferida de servicios no críticos
5. **Price Ranges**: Clasificación eficiente por percentiles (P33/P66)

## 📚 Documentación Adicional

- [Configuración de Google Maps](GOOGLE_MAPS_SETUP.md)
- [Plan de Refactorización](PLAN_REFACTORIZACION_MODULAR.md)
- [Instrucciones Críticas del Mapa](docs/MAPA_INSTRUCCIONES_CRITICAS.md)
- [Solución Carga Infinita](SOLUCION_CARGA_INFINITA.md)

## 🛠️ Tecnologías Utilizadas

- **Flutter** - Framework UI multiplataforma
- **Dart** - Lenguaje de programación
- **Google Maps Flutter** - Integración de mapas
- **BLoC/Cubit** - Gestión de estado
- **Equatable** - Comparación de objetos
- **SQLite (sqflite)** - Base de datos local
- **Geolocator** - Servicios de ubicación
- **HTTP** - Cliente HTTP para API
- **Mockito** - Framework de testing

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👥 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Realiza tus cambios y commits (`git commit -m 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📧 Contacto

Para preguntas o sugerencias, por favor abre un issue en el repositorio.

---

**Desarrollado con ❤️ usando Flutter**
