import 'package:flutter_test/flutter_test.dart';
import 'package:logist_app/core/validation/validators.dart';

void main() {
  group('Email Validation Tests', () {
    test('Valid email should pass', () {
      final result = Validators.validateEmail('test@example.com');
      expect(result.isValid, isTrue);
    });

    test('Empty email should fail', () {
      final result = Validators.validateEmail('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Email обязателен'));
    });

    test('Invalid email format should fail', () {
      final result = Validators.validateEmail('invalid-email');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Неверный формат email'));
    });

    test('Null email should fail', () {
      final result = Validators.validateEmail(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Email обязателен'));
    });
  });

  group('Phone Validation Tests', () {
    test('Valid phone should pass', () {
      final result = Validators.validatePhone('+79991234567');
      expect(result.isValid, isTrue);
    });

    test('Empty phone should fail', () {
      final result = Validators.validatePhone('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Телефон обязателен'));
    });

    test('Invalid phone format should fail', () {
      final result = Validators.validatePhone('abc123');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Неверный формат телефона'));
    });

    test('Null phone should fail', () {
      final result = Validators.validatePhone(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Телефон обязателен'));
    });
  });

  group('Password Validation Tests', () {
    test('Valid password should pass', () {
      final result = Validators.validatePassword('Password123');
      expect(result.isValid, isTrue);
    });

    test('Empty password should fail', () {
      final result = Validators.validatePassword('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Пароль обязателен'));
    });

    test('Short password should fail', () {
      final result = Validators.validatePassword('123');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Пароль должен содержать минимум 8 символов'));
    });

    test('Too long password should fail', () {
      final result = Validators.validatePassword('a' * 129);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Пароль не должен превышать 128 символов'));
    });

    test('Null password should fail', () {
      final result = Validators.validatePassword(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Пароль обязателен'));
    });
  });

  group('Name Validation Tests', () {
    test('Valid name should pass', () {
      final result = Validators.validateName('John Doe');
      expect(result.isValid, isTrue);
    });

    test('Valid Russian name should pass', () {
      final result = Validators.validateName('Иван Иванов');
      expect(result.isValid, isTrue);
    });

    test('Empty name should fail', () {
      final result = Validators.validateName('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Имя обязательно'));
    });

    test('Short name should fail', () {
      final result = Validators.validateName('A');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Имя должно содержать минимум 2 символа'));
    });

    test('Too long name should fail', () {
      final result = Validators.validateName('a' * 101);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Имя не должно превышать 100 символов'));
    });

    test('Invalid characters should fail', () {
      final result = Validators.validateName('John123');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Имя содержит недопустимые символы'));
    });

    test('Null name should fail', () {
      final result = Validators.validateName(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Имя обязательно'));
    });
  });

  group('Required Field Validation Tests', () {
    test('Non-empty field should pass', () {
      final result = Validators.validateRequired('some value', 'Field Name');
      expect(result.isValid, isTrue);
    });

    test('Empty field should fail', () {
      final result = Validators.validateRequired('', 'Field Name');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Field Name обязательно'));
    });

    test('Whitespace-only field should fail', () {
      final result = Validators.validateRequired('   ', 'Field Name');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Field Name обязательно'));
    });

    test('Null field should fail', () {
      final result = Validators.validateRequired(null, 'Field Name');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Field Name обязательно'));
    });
  });

  group('Weight Validation Tests', () {
    test('Valid weight should pass', () {
      final result = Validators.validateWeight('100.5');
      expect(result.isValid, isTrue);
    });

    test('Empty weight should fail', () {
      final result = Validators.validateWeight('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Вес обязателен'));
    });

    test('Negative weight should fail', () {
      final result = Validators.validateWeight('-10');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Вес должен быть положительным числом'));
    });

    test('Zero weight should fail', () {
      final result = Validators.validateWeight('0');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Вес должен быть положительным числом'));
    });

    test('Too heavy weight should fail', () {
      final result = Validators.validateWeight('50001');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Вес не должен превышать 50000 кг'));
    });

    test('Invalid weight format should fail', () {
      final result = Validators.validateWeight('abc');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Неверный формат веса'));
    });

    test('Null weight should fail', () {
      final result = Validators.validateWeight(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Вес обязателен'));
    });
  });

  group('Address Validation Tests', () {
    test('Valid address should pass', () {
      final result = Validators.validateAddress('123 Main St, City');
      expect(result.isValid, isTrue);
    });

    test('Empty address should fail', () {
      final result = Validators.validateAddress('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Адрес обязателен'));
    });

    test('Short address should fail', () {
      final result = Validators.validateAddress('123');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Адрес должен содержать минимум 5 символов'));
    });

    test('Too long address should fail', () {
      final result = Validators.validateAddress('a' * 501);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Адрес не должен превышать 500 символов'));
    });

    test('Null address should fail', () {
      final result = Validators.validateAddress(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Адрес обязателен'));
    });
  });

  group('Description Validation Tests', () {
    test('Valid description should pass', () {
      final result = Validators.validateDescription('This is a valid description');
      expect(result.isValid, isTrue);
    });

    test('Empty description should pass', () {
      final result = Validators.validateDescription('');
      expect(result.isValid, isTrue);
    });

    test('Null description should pass', () {
      final result = Validators.validateDescription(null);
      expect(result.isValid, isTrue);
    });

    test('Too long description should fail', () {
      final result = Validators.validateDescription('a' * 1001);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Описание не должно превышать 1000 символов'));
    });
  });

  group('Date Validation Tests', () {
    test('Valid date should pass', () {
      final result = Validators.validateDate(DateTime.now());
      expect(result.isValid, isTrue);
    });

    test('Null date should fail', () {
      final result = Validators.validateDate(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Дата обязательна'));
    });

    test('Future date too far should fail', () {
      final futureDate = DateTime.now().add(const Duration(days: 366));
      final result = Validators.validateDate(futureDate);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Дата не должна быть в будущем более чем на год'));
    });
  });

  group('URL Validation Tests', () {
    test('Valid URL should pass', () {
      final result = Validators.validateUrl('https://example.com');
      expect(result.isValid, isTrue);
    });

    test('Empty URL should pass', () {
      final result = Validators.validateUrl('');
      expect(result.isValid, isTrue);
    });

    test('Null URL should pass', () {
      final result = Validators.validateUrl(null);
      expect(result.isValid, isTrue);
    });

    test('Invalid URL should fail', () {
      final result = Validators.validateUrl('not-a-url');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Неверный формат URL'));
    });
  });

  group('Number Validation Tests', () {
    test('Valid number should pass', () {
      final result = Validators.validateNumber('123.45');
      expect(result.isValid, isTrue);
    });

    test('Number with min constraint should pass', () {
      final result = Validators.validateNumber('50', min: 0);
      expect(result.isValid, isTrue);
    });

    test('Number below min should fail', () {
      final result = Validators.validateNumber('-10', min: 0);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Значение должно быть не менее 0'));
    });

    test('Number with max constraint should pass', () {
      final result = Validators.validateNumber('50', max: 100);
      expect(result.isValid, isTrue);
    });

    test('Number above max should fail', () {
      final result = Validators.validateNumber('150', max: 100);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Значение должно быть не более 100'));
    });

    test('Invalid number format should fail', () {
      final result = Validators.validateNumber('abc');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Неверный формат числа'));
    });

    test('Empty number should fail', () {
      final result = Validators.validateNumber('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Значение обязательно'));
    });

    test('Null number should fail', () {
      final result = Validators.validateNumber(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Значение обязательно'));
    });
  });

  group('Select Validation Tests', () {
    test('Selected value should pass', () {
      final result = Validators.validateSelect('some_value', 'Field Name');
      expect(result.isValid, isTrue);
    });

    test('Empty select should fail', () {
      final result = Validators.validateSelect('', 'Field Name');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Field Name обязательно выбрать'));
    });

    test('Null select should fail', () {
      final result = Validators.validateSelect(null, 'Field Name');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Field Name обязательно выбрать'));
    });
  });
}
