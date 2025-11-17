/// Enumeración: Rangos de Precio
library;

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
