import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code});
}

class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code});
}

class PermissionException extends AppException {
  PermissionException(super.message, {super.code});
}

class ErrorHandler {
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    // Network errors
    if (error is SocketException) {
      return NetworkException('Ошибка подключения к интернету',
          code: 'network_error');
    }

    if (error is HttpException) {
      return NetworkException('Ошибка сети: ${error.message}',
          code: 'http_error');
    }

    // Firebase Auth errors
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }

    // Firestore errors
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    // General exceptions
    if (error is FormatException) {
      return ValidationException('Ошибка формата данных', code: 'format_error');
    }

    if (error is ArgumentError) {
      return ValidationException('Неверный аргумент: ${error.message}',
          code: 'argument_error');
    }

    // Unknown errors
    return AppException(
      'Произошла неизвестная ошибка',
      code: 'unknown_error',
      originalError: error,
    );
  }

  static AuthException _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthException('Пользователь не найден', code: 'user_not_found');
      case 'wrong-password':
        return AuthException('Неверный пароль', code: 'wrong_password');
      case 'email-already-in-use':
        return AuthException('Email уже используется',
            code: 'email_already_in_use');
      case 'weak-password':
        return AuthException('Пароль слишком слабый', code: 'weak_password');
      case 'invalid-email':
        return AuthException('Неверный формат email', code: 'invalid_email');
      case 'user-disabled':
        return AuthException('Учетная запись отключена', code: 'user_disabled');
      case 'too-many-requests':
        return AuthException('Слишком много запросов. Попробуйте позже',
            code: 'too_many_requests');
      case 'operation-not-allowed':
        return AuthException('Операция не разрешена',
            code: 'operation_not_allowed');
      case 'invalid-credential':
        return AuthException('Неверные учетные данные',
            code: 'invalid_credential');
      case 'account-exists-with-different-credential':
        return AuthException(
            'Учетная запись существует с другими учетными данными',
            code: 'account_exists_with_different_credential');
      case 'requires-recent-login':
        return AuthException('Требуется повторный вход',
            code: 'requires_recent_login');
      default:
        return AuthException('Ошибка аутентификации: ${error.message}',
            code: error.code);
    }
  }

  static AppException _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return DatabaseException('Отсутствуют права доступа',
            code: 'permission_denied');
      case 'not-found':
        return DatabaseException('Документ не найден', code: 'not_found');
      case 'already-exists':
        return DatabaseException('Документ уже существует',
            code: 'already_exists');
      case 'resource-exhausted':
        return DatabaseException('Превышен лимит ресурсов',
            code: 'resource_exhausted');
      case 'failed-precondition':
        return DatabaseException('Невыполненные условия',
            code: 'failed_precondition');
      case 'aborted':
        return DatabaseException('Операция отменена', code: 'aborted');
      case 'out-of-range':
        return DatabaseException('Выход за пределы диапазона',
            code: 'out_of_range');
      case 'unimplemented':
        return DatabaseException('Операция не реализована',
            code: 'unimplemented');
      case 'internal':
        return DatabaseException('Внутренняя ошибка сервера', code: 'internal');
      case 'unavailable':
        return NetworkException('Сервис недоступен', code: 'unavailable');
      case 'data-loss':
        return DatabaseException('Потеря данных', code: 'data_loss');
      case 'unauthenticated':
        return AuthException('Требуется аутентификация',
            code: 'unauthenticated');
      case 'deadline-exceeded':
        return NetworkException('Превышено время ожидания',
            code: 'deadline_exceeded');
      default:
        if (error.message?.contains('storage') == true) {
          return StorageException('Ошибка хранилища: ${error.message}',
              code: error.code);
        }
        return DatabaseException('Ошибка базы данных: ${error.message}',
            code: error.code);
    }
  }

  static String getErrorMessage(AppException exception) {
    switch (exception.code) {
      // Network errors
      case 'network_error':
        return 'Проверьте подключение к интернету и попробуйте снова';
      case 'http_error':
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Сервис временно недоступен. Попробуйте позже';

      // Auth errors
      case 'user_not_found':
        return 'Пользователь с такими данными не найден';
      case 'wrong_password':
        return 'Неверный пароль. Проверьте и попробуйте снова';
      case 'email_already_in_use':
        return 'Этот email уже используется. Попробуйте другой';
      case 'weak_password':
        return 'Пароль должен содержать минимум 8 символов, включая заглавные буквы и цифры';
      case 'invalid_email':
        return 'Введите корректный email адрес';
      case 'user_disabled':
        return 'Ваша учетная запись была отключена. Свяжитесь с администратором';
      case 'too_many_requests':
        return 'Слишком много попыток входа. Подождите несколько минут и попробуйте снова';
      case 'invalid_credential':
        return 'Неверные учетные данные. Проверьте email и пароль';

      // Database errors
      case 'permission_denied':
        return 'У вас нет прав для выполнения этой операции';
      case 'not_found':
        return 'Запись не найдена';
      case 'already_exists':
        return 'Такая запись уже существует';
      case 'resource_exhausted':
        return 'Превышен лимит. Попробуйте позже';

      // Storage errors
      default:
        return exception.message;
    }
  }

  static String getErrorTitle(AppException exception) {
    if (exception is NetworkException) return 'Ошибка сети';
    if (exception is ValidationException) return 'Ошибка валидации';
    if (exception is AuthException) return 'Ошибка аутентификации';
    if (exception is StorageException) return 'Ошибка хранилища';
    if (exception is DatabaseException) return 'Ошибка базы данных';
    if (exception is PermissionException) return 'Ошибка прав доступа';
    return 'Ошибка';
  }
}

class ErrorLogger {
  static void logError(AppException error, {String? context}) {
    // In production, you would send this to a logging service
    // print('ERROR: ${error.runtimeType}');
    // print('Code: ${error.code}');
    // print('Message: ${error.message}');
    // if (context != null) {
    //   print('Context: $context');
    // }
    // if (error.originalError != null) {
    //   print('Original error: ${error.originalError}');
    // }
  }

  static void logInfo(String message, {String? context}) {
    // print('INFO: $message');
    // if (context != null) {
    //   print('Context: $context');
    // }
  }

  static void logWarning(String message, {String? context}) {
    // print('WARNING: $message');
    // if (context != null) {
    //   print('Context: $context');
    // }
  }
}
