import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logist_app/core/error/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('Should handle FirebaseAuthException correctly', () {
      final authException = FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for this email.',
      );

      final handledError = ErrorHandler.handleError(authException);

      expect(handledError, isA<AuthException>());
      expect(handledError.code, equals('user_not_found'));
      expect(handledError.message, equals('Пользователь не найден'));
    });

    test('Should handle wrong password error', () {
      final authException = FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password provided.',
      );

      final handledError = ErrorHandler.handleError(authException);

      expect(handledError, isA<AuthException>());
      expect(handledError.code, equals('wrong_password'));
      expect(handledError.message, equals('Неверный пароль'));
    });

    test('Should handle email already in use error', () {
      final authException = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already in use.',
      );

      final handledError = ErrorHandler.handleError(authException);

      expect(handledError, isA<AuthException>());
      expect(handledError.code, equals('email_already_in_use'));
      expect(handledError.message, equals('Email уже используется'));
    });

    test('Should handle weak password error', () {
      final authException = FirebaseAuthException(
        code: 'weak-password',
        message: 'Password is too weak.',
      );

      final handledError = ErrorHandler.handleError(authException);

      expect(handledError, isA<AuthException>());
      expect(handledError.code, equals('weak_password'));
      expect(handledError.message, equals('Пароль слишком слабый'));
    });

    test('Should return same exception if already handled', () {
      final originalException = AuthException('Custom error', code: 'custom');

      final handledError = ErrorHandler.handleError(originalException);

      expect(handledError, same(originalException));
    });

    test('Should handle unknown errors', () {
      final unknownError = Exception('Unknown error');

      final handledError = ErrorHandler.handleError(unknownError);

      expect(handledError, isA<AppException>());
      expect(handledError.code, equals('unknown_error'));
      expect(handledError.message, equals('Произошла неизвестная ошибка'));
    });

    test('Should get correct error messages', () {
      final networkError = NetworkException('Network error', code: 'network_error');
      final authError = AuthException('Auth error', code: 'user_not_found');
      final validationError = ValidationException('Validation error', code: 'invalid_format');

      expect(ErrorHandler.getErrorMessage(networkError), equals('Проверьте подключение к интернету и попробуйте снова'));
      expect(ErrorHandler.getErrorMessage(authError), equals('Пользователь с такими данными не найден'));
      expect(ErrorHandler.getErrorMessage(validationError), equals('Validation error'));
    });

    test('Should get correct error titles', () {
      final networkError = NetworkException('Network error');
      final authError = AuthException('Auth error');
      final validationError = ValidationException('Validation error');

      expect(ErrorHandler.getErrorTitle(networkError), equals('Ошибка сети'));
      expect(ErrorHandler.getErrorTitle(authError), equals('Ошибка аутентификации'));
      expect(ErrorHandler.getErrorTitle(validationError), equals('Ошибка валидации'));
    });
  });

  group('ErrorLogger Tests', () {
    test('Should log errors without throwing', () {
      final error = AuthException('Test error', code: 'test');

      expect(() => ErrorLogger.logError(error, context: 'test'), returnsNormally);
    });

    test('Should log info without throwing', () {
      expect(() => ErrorLogger.logInfo('Test info', context: 'test'), returnsNormally);
    });

    test('Should log warnings without throwing', () {
      expect(() => ErrorLogger.logWarning('Test warning', context: 'test'), returnsNormally);
    });
  });
}
