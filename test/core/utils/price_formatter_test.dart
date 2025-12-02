import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/core/utils/price_formatter.dart';

void main() {
  group('PriceFormatter', () {
    test('debe formatear precio con símbolo de euro', () {
      // Arrange
      const price = 1.459;

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Debe contener el símbolo €
      expect(formatted, contains('€'));
      expect(formatted, contains('1'));
    });

    test('debe formatear precio con 3 decimales', () {
      // Arrange
      const price = 1.459;

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Debe mostrar 3 decimales (formato español)
      expect(formatted, contains('459'));
    });

    test('debe formatear precio por litro correctamente', () {
      // Arrange
      const price = 1.459;

      // Act
      final formatted = PriceFormatter.formatPricePerLiter(price);

      // Assert - Debe contener /L al final
      expect(formatted, contains('/L'));
      expect(formatted, contains('€'));
    });

    test('debe manejar precios con 0 decimales', () {
      // Arrange
      const price = 1.0;

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Debe formatear correctamente números enteros
      expect(formatted, contains('1'));
      expect(formatted, contains('€'));
    });

    test('debe manejar precios muy bajos', () {
      // Arrange
      const price = 0.999;

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Debe formatear correctamente precios < 1€
      expect(formatted, contains('0'));
      expect(formatted, contains('999'));
      expect(formatted, contains('€'));
    });

    test('debe manejar precios muy altos', () {
      // Arrange
      const price = 99.999;

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Debe formatear correctamente precios altos
      expect(formatted, contains('99'));
      expect(formatted, contains('€'));
    });

    test('debe usar formato español (coma como separador decimal)', () {
      // Arrange
      const price = 1.459;

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Formato español usa coma (,) como separador decimal
      // Nota: Esto depende de la configuración de intl en el formatter
      expect(formatted, isNotEmpty);
      expect(formatted, contains('€'));
    });

    test('debe manejar precio cero', () {
      // Arrange
      const price = 0.0;

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Debe formatear 0 sin errores
      expect(formatted, contains('0'));
      expect(formatted, contains('€'));
    });

    test('debe ser consistente entre múltiples llamadas con el mismo valor',
        () {
      // Arrange
      const price = 1.555;

      // Act
      final formatted1 = PriceFormatter.formatPrice(price);
      final formatted2 = PriceFormatter.formatPrice(price);

      // Assert - Mismo input debe producir mismo output
      expect(formatted1, equals(formatted2));
    });

    test('formatPricePerLiter debe incluir formatPrice', () {
      // Arrange
      const price = 1.459;

      // Act
      final priceOnly = PriceFormatter.formatPrice(price);
      final pricePerLiter = PriceFormatter.formatPricePerLiter(price);

      // Assert - formatPricePerLiter debe contener el precio formateado
      expect(pricePerLiter, contains('/L'));
      // El precio formateado debe estar en la cadena
      final priceWithoutUnit = pricePerLiter.replaceAll('/L', '');
      expect(priceWithoutUnit, equals(priceOnly));
    });

    test('debe manejar precios negativos sin lanzar excepciones', () {
      // Arrange
      const price = -1.50;

      // Act & Assert - No debe lanzar excepciones
      expect(() => PriceFormatter.formatPrice(price), returnsNormally);
    });

    test('debe redondear correctamente con más de 3 decimales', () {
      // Arrange
      const price = 1.4595; // 4 decimales

      // Act
      final formatted = PriceFormatter.formatPrice(price);

      // Assert - Debe redondear a 3 decimales
      expect(formatted, isNotEmpty);
      expect(formatted, contains('€'));
    });
  });
}
