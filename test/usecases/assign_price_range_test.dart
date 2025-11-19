import 'package:flutter_test/flutter_test.dart';
import 'package:buscagas/domain/usecases/assign_price_range.dart';
import 'package:buscagas/domain/entities/gas_station.dart';
import 'package:buscagas/domain/entities/fuel_type.dart';
import 'package:buscagas/domain/entities/fuel_price.dart';
import 'package:buscagas/domain/entities/price_range.dart';

void main() {
  group('AssignPriceRangeUseCase', () {
    late AssignPriceRangeUseCase useCase;
    
    setUp(() {
      useCase = AssignPriceRangeUseCase();
    });
    
    test('debe asignar rangos correctamente a 9 gasolineras', () {
      // Arrange: 9 gasolineras con precios uniformemente distribuidos
      final stations = List.generate(9, (i) {
        return GasStation(
          id: '$i',
          name: 'Gasolinera $i',
          latitude: 40.0,
          longitude: -3.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.40 + (i * 0.05), // 1.40, 1.45, 1.50, ..., 1.80
              updatedAt: DateTime.now(),
            ),
          ],
        );
      });
      
      // Act
      useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert: Verificar distribución de rangos
      final lowCount = stations.where((s) => s.priceRange == PriceRange.low).length;
      final mediumCount = stations.where((s) => s.priceRange == PriceRange.medium).length;
      final highCount = stations.where((s) => s.priceRange == PriceRange.high).length;
      
      expect(lowCount, 3); // 33%
      expect(mediumCount, 3); // 33%
      expect(highCount, 3); // 33%
      
      // Verificar que las 3 primeras son "low"
      expect(stations[0].priceRange, PriceRange.low);
      expect(stations[1].priceRange, PriceRange.low);
      expect(stations[2].priceRange, PriceRange.low);
    });
    
    test('debe asignar null si no hay precios', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Sin Precios',
          latitude: 40.0,
          longitude: -3.0,
          prices: [],
        ),
      ];
      
      // Act
      useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert
      expect(stations.first.priceRange, isNull);
    });
    
    test('debe asignar medium si solo hay 1 precio', () {
      // Arrange
      final stations = [
        GasStation(
          id: '1',
          name: 'Única',
          latitude: 40.0,
          longitude: -3.0,
          prices: [
            FuelPrice(
              fuelType: FuelType.gasolina95,
              value: 1.45,
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];
      
      // Act
      useCase(
        stations: stations,
        fuelType: FuelType.gasolina95,
      );
      
      // Assert
      expect(stations.first.priceRange, PriceRange.medium);
    });
  });
}
