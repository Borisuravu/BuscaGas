# Plan de Desarrollo BuscaGas - Pasos Genéricos

## Proyecto: Localizador de Gasolineras Económicas en España

---

## FASE 1: PREPARACIÓN DEL ENTORNO

### Paso 1: Configurar el entorno de desarrollo
- Instalar Flutter SDK y Dart
- Configurar Android Studio o VS Code
- Verificar configuración de Android SDK
- Preparar emulador o dispositivo físico de pruebas

### Paso 2: Crear proyecto Flutter inicial
- Inicializar proyecto con Flutter CLI
- Configurar estructura de carpetas según Clean Architecture
- Añadir dependencias básicas en pubspec.yaml

---

## FASE 2: CAPA DE DATOS

### Paso 3: Implementar modelos de datos
- Crear entidades de dominio (GasStation, FuelPrice, AppSettings)
- Crear enumeraciones (FuelType, PriceRange)
- Implementar DTOs para API

### Paso 4: Configurar base de datos local
- Implementar esquema SQLite
- Crear servicio de base de datos
- Implementar operaciones CRUD básicas

### Paso 5: Integrar API gubernamental
- Crear cliente HTTP para API de datos abiertos
- Implementar parseo de respuestas JSON
- Gestionar errores de red

### Paso 6: Implementar repositorios
- Crear interfaces de repositorios
- Implementar repositorios con fuentes locales y remotas
- Añadir lógica de caché

---

## FASE 3: LÓGICA DE NEGOCIO

### Paso 7: Implementar casos de uso
- Caso de uso: obtener gasolineras cercanas
- Caso de uso: filtrar por tipo de combustible
- Caso de uso: calcular distancias (Haversine)

### Paso 8: Crear gestión de estado (BLoC)
- Implementar MapBloc para pantalla principal
- Implementar SettingsBloc para configuración
- Definir eventos y estados

### Paso 9: Implementar servicios del sistema
- Servicio de geolocalización (GPS)
- Servicio de sincronización periódica
- Servicio de almacenamiento de preferencias

---

## FASE 4: INTERFAZ DE USUARIO

### Paso 10: Configurar temas y estilos
- Crear tema claro y oscuro
- Definir paleta de colores
- Configurar tipografías

### Paso 11: Crear pantalla de inicio (Splash)
- Diseñar logo y pantalla de carga
- Implementar diálogo de selección de tema (primera vez)
- Añadir lógica de carga inicial

⚠️ Notas Importantes:
TODOs pendientes para futuros pasos:

Cargar datos reales de gasolineras (requiere Pasos 4-6)
Mostrar marcadores en el mapa
Calcular distancias (Paso 7)
Tarjeta de información interactiva
El código actual es un MVP funcional que proporciona la estructura base

No hay errores de compilación

Solo advertencias menores de estilo (prefer_const_constructors, avoid_print)

### Paso 12: Desarrollar pantalla principal con mapa ✅
- Integrar Google Maps
- Implementar marcadores personalizados con colores
- Crear tarjeta flotante de información
- Añadir selector de combustible

### Paso 13: Crear pantalla de configuración ✅ COMPLETADO
- Diseñar formulario de preferencias
- Implementar controles para radio de búsqueda
- Añadir selector de combustible preferido
- Implementar toggle de tema

**Estado:** ✅ Completado el 19 de noviembre de 2025
- Documentación: PASO_13_INSTRUCCIONES.md
- Resumen: PASO_13_COMPLETADO.md
- Implementación: lib/presentation/screens/settings_screen.dart (332 líneas)
- Funcionalidades:
  * Radio de búsqueda (5, 10, 20, 50 km) con RadioListTile
  * Combustible preferido (Gasolina 95, Diésel) con DropdownButton
  * Tema claro/oscuro con Switch y actualización en tiempo real
  * Guardado automático en SQLite
  * Feedback visual con SnackBar
  * Integración completa con main.dart para actualización de tema

### Paso 14: Implementar widgets reutilizables
- Widget de marcador de gasolinera
- Widget de tarjeta de información
- Widget de selector de combustible

---

## FASE 5: FUNCIONALIDADES AVANZADAS

### Paso 15: Implementar cálculo de rangos de precio
- Algoritmo de clasificación por percentiles
- Asignación de colores a marcadores

### Paso 16: Añadir funcionalidad de recentrado
- Botón de "Mi ubicación"
- Actualizar mapa con nueva posición

### Paso 17: Implementar actualización automática
- Timer periódico en foreground
- Comparación de datos frescos vs caché
- Notificación silenciosa de actualización

---

## FASE 6: PERMISOS Y CONFIGURACIÓN

### Paso 18: Configurar permisos Android
- Permisos de ubicación en AndroidManifest.xml
- Permisos de internet
- Gestión de solicitud de permisos en tiempo de ejecución

### Paso 19: Configurar Google Maps API
- Obtener API Key de Google Cloud
- Configurar credenciales en Android

---

## FASE 7: PRUEBAS

### Paso 20: Escribir pruebas unitarias
- Pruebas de casos de uso
- Pruebas de cálculo de distancias
- Pruebas de clasificación de precios

### Paso 21: Realizar pruebas de integración
- Pruebas de conexión con API real
- Pruebas de base de datos
- Pruebas de flujo completo

### Paso 22: Pruebas en dispositivo real
- Verificar funcionalidad de GPS
- Comprobar rendimiento en diferentes dispositivos
- Validar experiencia de usuario

---

## FASE 8: OPTIMIZACIÓN Y PULIDO

### Paso 23: Optimizar rendimiento
- Mejorar tiempos de carga
- Optimizar consultas a base de datos
- Reducir consumo de batería

### Paso 24: Gestión de errores
- Mensajes de error claros
- Fallback a caché cuando no hay conexión
- Manejo de permisos denegados

### Paso 25: Accesibilidad y UX
- Verificar contraste de colores
- Comprobar tamaño de fuentes
- Mejorar feedback visual

---

## FASE 9: PREPARACIÓN PARA LANZAMIENTO

### Paso 26: Configurar build de producción
- Configurar versión y código de versión
- Generar icono de aplicación
- Configurar nombre de aplicación

### Paso 27: Generar APK/AAB
- Crear keystore para firma
- Compilar versión release
- Probar versión de producción

### Paso 28: Documentación final
- README del proyecto
- Documentación de instalación
- Guía de usuario básica

---

## NOTAS IMPORTANTES

- Cada paso se desarrollará en detalle cuando se implemente
- Se seguirá la documentación Métrica v3 adjunta como referencia
- Se aplicarán principios de Clean Architecture
- Se priorizará MVP: funcionalidades básicas primero

---

**Fecha de creación:** 17 de noviembre de 2025  
**Proyecto:** BuscaGas v1.0.0  
**Metodología:** Métrica v3
