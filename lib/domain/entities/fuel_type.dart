/// Enumeración: Tipos de Combustible
library;

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
