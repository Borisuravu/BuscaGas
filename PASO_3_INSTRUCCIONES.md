# PASO 3: Implementar Modelos de Datos

## Información extraída de la Documentación V3 para el Paso 3

---

## 🎯 OBJETIVO DEL PASO 3
- Crear entidades de dominio (GasStation, FuelPrice, AppSettings)
- Crear enumeraciones (FuelType, PriceRange)
- Implementar DTOs para API (modelos de datos)

---

## 📋 ENTIDADES DE DOMINIO (Domain Layer)

### 1. Enumeración: FuelType

**Ubicación:** `lib/domain/entities/fuel_type.dart`

**Valores:**
- `gasolina95` → "Gasolina 95"
- `dieselGasoleoA` → "Diésel Gasóleo A"

**Código completo:**
```dart
enum FuelType {
  gasolina95,
  dieselGasoleoA;
  
  String get displayName {
    switch (this) {
      case FuelType.gasolina95:
        return 'Gasolina 95';
      case FuelType.dieselGasoleoA:
        return 'Diésel Gasóleo A';
    }
  }
}
```

---

### 2. Enumeración: PriceRange

**Ubicación:** `lib/domain/entities/price_range.dart`

**Valores:**
- `low` → Color verde (precio bajo)
- `medium` → Color naranja (precio medio)
- `high` → Color rojo (precio alto)

**Código completo:**
```dart
import 'package:flutter/material.dart';

enum PriceRange {
  low,    // verde
  medium, // amarillo/naranja
  high;   // rojo
  
  Color get color {
    switch (this) {
      case PriceRange.low:
        return Colors.green;
      case PriceRange.medium:
        return Colors.orange;
      case PriceRange.high:
        return Colors.red;
    }
  }
}
```

---

### 3. Entidad: FuelPrice (Value Object)

**Ubicación:** `lib/domain/entities/fuel_price.dart`

**Propiedades:**
- `fuelType`: FuelType (requerido)
- `value`: double (euros por litro, requerido)
- `updatedAt`: DateTime (requerido)

**Métodos:**
- `isOlderThan(Duration)`: bool - Verificar si el precio está desactualizado

**Características:**
- Inmutable (const constructor)
- Usar Equatable para comparaciones

**Código completo:**
```dart
import 'package:equatable/equatable.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class FuelPrice extends Equatable {
  final FuelType fuelType;
  final double value; // euros por litro
  final DateTime updatedAt;
  
  const FuelPrice({
    required this.fuelType,
    required this.value,
    required this.updatedAt,
  });
  
  bool isOlderThan(Duration duration) {
    return DateTime.now().difference(updatedAt) > duration;
  }
  
  @override
  List<Object?> get props => [fuelType, value, updatedAt];
}
```

---

### 4. Entidad: GasStation

**Ubicación:** `lib/domain/entities/gas_station.dart`

**Propiedades:**
- `id`: String (requerido)
- `name`: String (requerido)
- `latitude`: double (requerido)
- `longitude`: double (requerido)
- `address`: String (opcional, default '')
- `locality`: String (opcional, default '')
- `operator`: String (opcional, default '')
- `prices`: List<FuelPrice> (opcional, default [])
- `distance`: double? (nullable, calculado dinámicamente)
- `priceRange`: PriceRange? (nullable, bajo/medio/alto)

**Métodos de negocio:**
- `getPriceForFuel(FuelType)`: double? - Obtener precio de combustible específico
- `isWithinRadius(lat, lon, radiusKm)`: bool - Verificar si está dentro del radio
- `_calculateDistance(lat, lon)`: double - Calcular distancia con Haversine (privado)
- `_degreesToRadians(degrees)`: double - Convertir grados a radianes (privado)

**Código completo:**
```dart
import 'dart:math';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/price_range.dart';

class GasStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String locality;
  final String operator;
  final List<FuelPrice> prices;
  double? distance; // calculado dinámicamente
  PriceRange? priceRange; // bajo, medio, alto
  
  GasStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.locality = '',
    this.operator = '',
    this.prices = const [],
    this.distance,
    this.priceRange,
  });
  
  double? getPriceForFuel(FuelType fuelType) {
    try {
      return prices
          .firstWhere((p) => p.fuelType == fuelType)
          .value;
    } catch (_) {
      return null;
    }
  }
  
  bool isWithinRadius(double lat, double lon, double radiusKm) {
    double distance = _calculateDistance(lat, lon);
    return distance <= radiusKm;
  }
  
  double _calculateDistance(double lat, double lon) {
    // Fórmula de Haversine
    const double earthRadiusKm = 6371.0;
    
    double dLat = _degreesToRadians(latitude - lat);
    double dLon = _degreesToRadians(longitude - lon);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat)) *
        cos(_degreesToRadians(latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
```

---

### 5. Entidad: AppSettings

**Ubicación:** `lib/domain/entities/app_settings.dart`

**Propiedades:**
- `searchRadius`: int (5, 10, 20, 50 km, default 10)
- `preferredFuel`: FuelType (default gasolina95)
- `darkMode`: bool (default false)
- `lastUpdateTimestamp`: DateTime? (nullable)

**Métodos:**
- `save()`: Future<void> - Persistir en SharedPreferences
- `load()`: static Future<AppSettings> - Cargar desde SharedPreferences

**Código completo:**
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class AppSettings {
  int searchRadius; // 5, 10, 20, 50
  FuelType preferredFuel;
  bool darkMode;
  DateTime? lastUpdateTimestamp;
  
  AppSettings({
    this.searchRadius = 10,
    this.preferredFuel = FuelType.gasolina95,
    this.darkMode = false,
    this.lastUpdateTimestamp,
  });
  
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('searchRadius', searchRadius);
    await prefs.setString('preferredFuel', preferredFuel.name);
    await prefs.setBool('darkMode', darkMode);
    if (lastUpdateTimestamp != null) {
      await prefs.setString('lastUpdateTimestamp', lastUpdateTimestamp!.toIso8601String());
    }
  }
  
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    FuelType loadedFuel = FuelType.gasolina95;
    final fuelName = prefs.getString('preferredFuel');
    if (fuelName != null) {
      try {
        loadedFuel = FuelType.values.firstWhere((e) => e.name == fuelName);
      } catch (_) {
        loadedFuel = FuelType.gasolina95;
      }
    }
    
    DateTime? timestamp;
    final timestampStr = prefs.getString('lastUpdateTimestamp');
    if (timestampStr != null) {
      try {
        timestamp = DateTime.parse(timestampStr);
      } catch (_) {
        timestamp = null;
      }
    }
    
    return AppSettings(
      searchRadius: prefs.getInt('searchRadius') ?? 10,
      preferredFuel: loadedFuel,
      darkMode: prefs.getBool('darkMode') ?? false,
      lastUpdateTimestamp: timestamp,
    );
  }
}
```

---

## 📦 MODELOS DE DATOS (Data Layer)

### 6. Modelo API: ApiGasStationResponse

**Ubicación:** `lib/data/models/api_response_model.dart`

**Propósito:** Parsear respuesta completa de la API del Gobierno

**Estructura JSON esperada:**
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
    }
  ]
}
```

**Código completo:**
```dart
import 'package:buscagas/data/models/gas_station_model.dart';

class ApiGasStationResponse {
  final String fecha;
  final List<GasStationModel> listaEESSPrecio;
  
  ApiGasStationResponse({
    required this.fecha,
    required this.listaEESSPrecio,
  });
  
  factory ApiGasStationResponse.fromJson(Map<String, dynamic> json) {
    return ApiGasStationResponse(
      fecha: json['Fecha'] ?? '',
      listaEESSPrecio: (json['ListaEESSPrecio'] as List?)
          ?.map((e) => GasStationModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'Fecha': fecha,
      'ListaEESSPrecio': listaEESSPrecio.map((e) => e.toJson()).toList(),
    };
  }
}
```

---

### 7. Modelo: GasStationModel (DTO)

**Ubicación:** `lib/data/models/gas_station_model.dart`

**Propósito:** 
- Parsear JSON de API
- Serializar para base de datos
- Convertir a/desde entidad de dominio

**Propiedades (según API):**
- `ideess`: String (IDEESS)
- `rotulo`: String (Rótulo)
- `direccion`: String (Dirección)
- `localidad`: String (Localidad)
- `latitud`: String (Latitud)
- `longitud`: String (Longitud WGS84)
- `precioGasolina95`: String? (Precio Gasolina 95 E5)
- `precioDiesel`: String? (Precio Gasoleo A)

**Métodos:**
- `fromJson(Map)`: factory - Parsear desde API
- `toJson()`: Map - Serializar
- `toDomain()`: GasStation - Convertir a entidad de dominio
- `fromEntity(GasStation)`: factory - Convertir desde entidad
- `_parsePrice(String)`: double? - Helper para parsear precios (privado)

**Código completo:**
```dart
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class GasStationModel {
  final String ideess;
  final String rotulo;
  final String direccion;
  final String localidad;
  final String latitud;
  final String longitud;
  final String? precioGasolina95;
  final String? precioDiesel;
  
  GasStationModel({
    required this.ideess,
    required this.rotulo,
    required this.direccion,
    required this.localidad,
    required this.latitud,
    required this.longitud,
    this.precioGasolina95,
    this.precioDiesel,
  });
  
  factory GasStationModel.fromJson(Map<String, dynamic> json) {
    return GasStationModel(
      ideess: json['IDEESS']?.toString() ?? '',
      rotulo: json['Rótulo']?.toString() ?? '',
      direccion: json['Dirección']?.toString() ?? '',
      localidad: json['Localidad']?.toString() ?? '',
      latitud: json['Latitud']?.toString() ?? '0',
      longitud: json['Longitud (WGS84)']?.toString() ?? '0',
      precioGasolina95: json['Precio Gasolina 95 E5']?.toString(),
      precioDiesel: json['Precio Gasoleo A']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'IDEESS': ideess,
      'Rótulo': rotulo,
      'Dirección': direccion,
      'Localidad': localidad,
      'Latitud': latitud,
      'Longitud (WGS84)': longitud,
      'Precio Gasolina 95 E5': precioGasolina95,
      'Precio Gasoleo A': precioDiesel,
    };
  }
  
  // Mapper a entidad de dominio
  GasStation toDomain() {
    List<FuelPrice> prices = [];
    
    if (precioGasolina95 != null) {
      double? price = _parsePrice(precioGasolina95!);
      if (price != null) {
        prices.add(FuelPrice(
          fuelType: FuelType.gasolina95,
          value: price,
          updatedAt: DateTime.now(),
        ));
      }
    }
    
    if (precioDiesel != null) {
      double? price = _parsePrice(precioDiesel!);
      if (price != null) {
        prices.add(FuelPrice(
          fuelType: FuelType.dieselGasoleoA,
          value: price,
          updatedAt: DateTime.now(),
        ));
      }
    }
    
    return GasStation(
      id: ideess,
      name: rotulo,
      latitude: double.tryParse(latitud.replaceAll(',', '.')) ?? 0.0,
      longitude: double.tryParse(longitud.replaceAll(',', '.')) ?? 0.0,
      address: direccion,
      locality: localidad,
      operator: rotulo,
      prices: prices,
    );
  }
  
  factory GasStationModel.fromEntity(GasStation entity) {
    String? gasolina95;
    String? diesel;
    
    for (var price in entity.prices) {
      if (price.fuelType == FuelType.gasolina95) {
        gasolina95 = price.value.toString().replaceAll('.', ',');
      } else if (price.fuelType == FuelType.dieselGasoleoA) {
        diesel = price.value.toString().replaceAll('.', ',');
      }
    }
    
    return GasStationModel(
      ideess: entity.id,
      rotulo: entity.name,
      direccion: entity.address,
      localidad: entity.locality,
      latitud: entity.latitude.toString().replaceAll('.', ','),
      longitud: entity.longitude.toString().replaceAll('.', ','),
      precioGasolina95: gasolina95,
      precioDiesel: diesel,
    );
  }
  
  double? _parsePrice(String priceStr) {
    try {
      // Reemplazar coma por punto y parsear
      return double.parse(priceStr.replaceAll(',', '.'));
    } catch (_) {
      return null;
    }
  }
}
```

---

### 8. Modelo: FuelPriceModel

**Ubicación:** `lib/data/models/fuel_price_model.dart`

**Propósito:** Modelo de datos para persistencia en base de datos

**Propiedades:**
- `fuelType`: String (nombre del enum)
- `value`: double
- `updatedAt`: DateTime

**Métodos:**
- `fromJson(Map)`: factory
- `toJson()`: Map
- `toDomain()`: FuelPrice
- `fromEntity(FuelPrice)`: factory

**Código completo:**
```dart
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';

class FuelPriceModel {
  final String fuelType; // nombre del enum como string
  final double value;
  final DateTime updatedAt;
  
  FuelPriceModel({
    required this.fuelType,
    required this.value,
    required this.updatedAt,
  });
  
  factory FuelPriceModel.fromJson(Map<String, dynamic> json) {
    return FuelPriceModel(
      fuelType: json['fuelType'] as String,
      value: (json['value'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'fuelType': fuelType,
      'value': value,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  FuelPrice toDomain() {
    FuelType type;
    try {
      type = FuelType.values.firstWhere((e) => e.name == fuelType);
    } catch (_) {
      type = FuelType.gasolina95; // fallback
    }
    
    return FuelPrice(
      fuelType: type,
      value: value,
      updatedAt: updatedAt,
    );
  }
  
  factory FuelPriceModel.fromEntity(FuelPrice entity) {
    return FuelPriceModel(
      fuelType: entity.fuelType.name,
      value: entity.value,
      updatedAt: entity.updatedAt,
    );
  }
}
```

---

## ✅ CHECKLIST PASO 3

### Archivos a crear/modificar:

**Domain/Entities (5 archivos):**
1. ✅ `lib/domain/entities/fuel_type.dart` - Enum con 2 valores
2. ✅ `lib/domain/entities/price_range.dart` - Enum con 3 valores y colores
3. ✅ `lib/domain/entities/fuel_price.dart` - Value object inmutable
4. ✅ `lib/domain/entities/gas_station.dart` - Entidad principal con lógica de negocio
5. ✅ `lib/domain/entities/app_settings.dart` - Entidad de configuración

**Data/Models (3 archivos):**
6. ✅ `lib/data/models/api_response_model.dart` - DTO para respuesta completa API
7. ✅ `lib/data/models/gas_station_model.dart` - DTO con mappers
8. ✅ `lib/data/models/fuel_price_model.dart` - DTO de precio

### Tareas:
1. ✅ Crear archivos de enumeraciones
2. ✅ Implementar entidades de dominio con lógica de negocio
3. ✅ Implementar modelos DTO con mappers
4. ✅ Verificar que compila sin errores (`flutter analyze`)
5. ✅ Probar parseo de JSON de ejemplo

---

## 🔍 NOTAS IMPORTANTES

### Mapeo de nombres API → Código:
- **API**: "IDEESS" → **Código**: `id`
- **API**: "Rótulo" → **Código**: `name`
- **API**: "Dirección" → **Código**: `address`
- **API**: "Latitud" → **Código**: `latitude`
- **API**: "Longitud (WGS84)" → **Código**: `longitude`
- **API**: "Precio Gasolina 95 E5" → **Código**: `precioGasolina95`
- **API**: "Precio Gasoleo A" → **Código**: `precioDiesel`

### Parseo de precios:
- Los precios vienen con **coma** como separador decimal: "1,459"
- Hay que reemplazar `,` por `.` antes de parsear a double
- Manejar valores nulos (algunas gasolineras no tienen todos los combustibles)

### Coordenadas:
- También vienen con coma: "40,416775"
- Reemplazar `,` por `.` y parsear a double
- Si falla el parseo, usar 0.0 como fallback

---

## 🎯 CRITERIOS DE ÉXITO DEL PASO 3

**El Paso 3 está completo cuando:**
- ✅ Todas las entidades de dominio creadas y compilando
- ✅ Todos los modelos DTO creados con mappers funcionales
- ✅ Enumeraciones implementadas con getters útiles
- ✅ `flutter analyze` sin errores
- ✅ Mappers `toDomain()` y `fromEntity()` funcionando correctamente

---

**Fecha de creación:** 17 de noviembre de 2025  
**Basado en:** BuscaGas Documentacion V3 (Métrica v3)  
**Sección:** DSI 4 - Diseño de Clases, DSI 5 - Diseño de Arquitectura de Datos
