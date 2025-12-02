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
