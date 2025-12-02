import 'package:intl/intl.dart';

/// Formateador de precios para mostrar en la UI
class PriceFormatter {
  static final NumberFormat _euroFormat = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 3,
  );

  /// Formatea un precio a string con formato europeo
  static String formatPrice(double price) {
    return _euroFormat.format(price);
  }

  /// Formatea un precio por litro
  static String formatPricePerLiter(double price) {
    return '${formatPrice(price)}/L';
  }
}
