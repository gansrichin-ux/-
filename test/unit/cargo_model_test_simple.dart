import 'package:flutter_test/flutter_test.dart';
import 'package:logist_app/models/cargo_model.dart';

void main() {
  group('CargoModel Tests', () {
    test('CargoModel should create from map correctly', () {
      final cargo = CargoModel(
        id: '1',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
        weightKg: 100.0,
        description: 'Test description',
      );

      expect(cargo.id, equals('1'));
      expect(cargo.title, equals('Test Cargo'));
      expect(cargo.from, equals('Moscow'));
      expect(cargo.to, equals('St. Petersburg'));
      expect(cargo.status, equals('Новый'));
      expect(cargo.weightKg, equals(100.0));
      expect(cargo.description, equals('Test description'));
    });

    test('CargoModel should handle empty photos list', () {
      final cargo = CargoModel(
        id: '1',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
      );

      expect(cargo.photos, isEmpty);
      expect(cargo.driverId, isNull);
      expect(cargo.driverName, isNull);
      expect(cargo.createdAt, isNull);
    });

    test('CargoModel copyWith should work correctly', () {
      final originalCargo = CargoModel(
        id: '1',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
      );

      final updatedCargo = originalCargo.copyWith(
        status: 'В пути',
        driverId: 'driver123',
        driverName: 'John Driver',
      );

      expect(updatedCargo.id, equals(originalCargo.id));
      expect(updatedCargo.title, equals(originalCargo.title));
      expect(updatedCargo.status, equals('В пути'));
      expect(updatedCargo.driverId, equals('driver123'));
      expect(updatedCargo.driverName, equals('John Driver'));
      expect(updatedCargo.from, equals(originalCargo.from));
      expect(updatedCargo.to, equals(originalCargo.to));
    });
  });
}
