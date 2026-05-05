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

    test('CargoModel fromMap should work correctly', () {
      final map = {
        'id': '1',
        'title': 'Test Cargo',
        'from': 'Moscow',
        'to': 'St. Petersburg',
        'status': 'Новый',
        'weightKg': 100.0,
        'description': 'Test description',
        'photos': ['photo1.jpg', 'photo2.jpg'],
        'driverId': 'driver123',
        'driverName': 'John Driver',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final cargo = CargoModel.fromMap(map);

      expect(cargo.id, equals('1'));
      expect(cargo.title, equals('Test Cargo'));
      expect(cargo.from, equals('Moscow'));
      expect(cargo.to, equals('St. Petersburg'));
      expect(cargo.status, equals('Новый'));
      expect(cargo.weightKg, equals(100.0));
      expect(cargo.description, equals('Test description'));
      expect(cargo.photos, equals(['photo1.jpg', 'photo2.jpg']));
      expect(cargo.driverId, equals('driver123'));
      expect(cargo.driverName, equals('John Driver'));
      expect(cargo.createdAt, isNotNull);
    });

    test('CargoModel toMap should work correctly', () {
      final cargo = CargoModel(
        id: '1',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
        weightKg: 100.0,
        description: 'Test description',
        photos: ['photo1.jpg', 'photo2.jpg'],
        driverId: 'driver123',
        driverName: 'John Driver',
      );

      final map = cargo.toMap();

      expect(map['id'], equals('1'));
      expect(map['title'], equals('Test Cargo'));
      expect(map['from'], equals('Moscow'));
      expect(map['to'], equals('St. Petersburg'));
      expect(map['status'], equals('Новый'));
      expect(map['weightKg'], equals(100.0));
      expect(map['description'], equals('Test description'));
      expect(map['photos'], equals(['photo1.jpg', 'photo2.jpg']));
      expect(map['driverId'], equals('driver123'));
      expect(map['driverName'], equals('John Driver'));
    });

    test('CargoModel equality should work correctly', () {
      final cargo1 = CargoModel(
        id: '1',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
      );

      final cargo2 = CargoModel(
        id: '1',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
      );

      final cargo3 = CargoModel(
        id: '2',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
      );

      expect(cargo1, equals(cargo2));
      expect(cargo1, isNot(equals(cargo3)));
    });

    test('CargoModel toString should work correctly', () {
      final cargo = CargoModel(
        id: '1',
        title: 'Test Cargo',
        from: 'Moscow',
        to: 'St. Petersburg',
        status: 'Новый',
      );

      final stringRepresentation = cargo.toString();
      expect(stringRepresentation, contains('Test Cargo'));
      expect(stringRepresentation, contains('Moscow'));
      expect(stringRepresentation, contains('St. Petersburg'));
      expect(stringRepresentation, contains('Новый'));
    });

    test('CargoModel should validate required fields', () {
      // Test with empty title
      expect(
        () => CargoModel(
          id: '1',
          title: '',
          from: 'Moscow',
          to: 'St. Petersburg',
          status: 'Новый',
        ),
        throwsA(anything),
      );

      // Test with empty from
      expect(
        () => CargoModel(
          id: '1',
          title: 'Test Cargo',
          from: '',
          to: 'St. Petersburg',
          status: 'Новый',
        ),
        throwsA(anything),
      );

      // Test with empty to
      expect(
        () => CargoModel(
          id: '1',
          title: 'Test Cargo',
          from: 'Moscow',
          to: '',
          status: 'Новый',
        ),
        throwsA(anything),
      );

      // Test with empty status
      expect(
        () => CargoModel(
          id: '1',
          title: 'Test Cargo',
          from: 'Moscow',
          to: 'St. Petersburg',
          status: '',
        ),
        throwsA(anything),
      );
    });

    test('CargoModel should handle negative weight', () {
      expect(
        () => CargoModel(
          id: '1',
          title: 'Test Cargo',
          from: 'Moscow',
          to: 'St. Petersburg',
          status: 'Новый',
          weightKg: -10.0,
        ),
        throwsA(anything),
      );
    });
  });
}
