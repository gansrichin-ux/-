class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({required this.isValid, this.errorMessage});

  factory ValidationResult.success() {
    return const ValidationResult._(isValid: true);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }
}

class Validators {
  static String _formatLimit(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  // Email validation
  static ValidationResult validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('Email обязателен');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return ValidationResult.error('Неверный формат email');
    }

    return ValidationResult.success();
  }

  // Phone validation
  static ValidationResult validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('Телефон обязателен');
    }

    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return ValidationResult.error('Неверный формат телефона');
    }

    return ValidationResult.success();
  }

  // Password validation
  static ValidationResult validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('Пароль обязателен');
    }

    if (value.length < 8) {
      return ValidationResult.error(
          'Пароль должен содержать минимум 8 символов');
    }

    if (value.length > 128) {
      return ValidationResult.error('Пароль не должен превышать 128 символов');
    }

    return ValidationResult.success();
  }

  // Name validation
  static ValidationResult validateName(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('Имя обязательно');
    }

    if (value.length < 2) {
      return ValidationResult.error('Имя должно содержать минимум 2 символа');
    }

    if (value.length > 100) {
      return ValidationResult.error('Имя не должно превышать 100 символов');
    }

    // Allow only letters, spaces, hyphens and apostrophes
    final nameRegex = RegExp(r'^[a-zA-Zа-яА-ЯёЁ\s\-\x27]+$');
    if (!nameRegex.hasMatch(value)) {
      return ValidationResult.error('Имя содержит недопустимые символы');
    }

    return ValidationResult.success();
  }

  // Required field validation
  static ValidationResult validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('$fieldName обязательно');
    }

    return ValidationResult.success();
  }

  // Weight validation
  static ValidationResult validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('Вес обязателен');
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return ValidationResult.error('Неверный формат веса');
    }

    if (weight <= 0) {
      return ValidationResult.error('Вес должен быть положительным числом');
    }

    if (weight > 50000) {
      return ValidationResult.error('Вес не должен превышать 50000 кг');
    }

    return ValidationResult.success();
  }

  // Address validation
  static ValidationResult validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('Адрес обязателен');
    }

    if (value.length < 5) {
      return ValidationResult.error(
          'Адрес должен содержать минимум 5 символов');
    }

    if (value.length > 500) {
      return ValidationResult.error('Адрес не должен превышать 500 символов');
    }

    return ValidationResult.success();
  }

  // Description validation
  static ValidationResult validateDescription(String? value) {
    if (value != null && value.length > 1000) {
      return ValidationResult.error(
          'Описание не должно превышать 1000 символов');
    }

    return ValidationResult.success();
  }

  // Date validation
  static ValidationResult validateDate(DateTime? value) {
    if (value == null) {
      return ValidationResult.error('Дата обязательна');
    }

    if (value.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      return ValidationResult.error(
          'Дата не должна быть в будущем более чем на год');
    }

    return ValidationResult.success();
  }

  // URL validation
  static ValidationResult validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationResult.success(); // URL is optional
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.hasAuthority && uri.path.isEmpty)) {
        return ValidationResult.error('Неверный формат URL');
      }
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Неверный формат URL');
    }
  }

  // Number validation
  static ValidationResult validateNumber(String? value,
      {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('Значение обязательно');
    }

    final number = double.tryParse(value);
    if (number == null) {
      return ValidationResult.error('Неверный формат числа');
    }

    if (min != null && number < min) {
      return ValidationResult.error(
        'Значение должно быть не менее ${_formatLimit(min)}',
      );
    }

    if (max != null && number > max) {
      return ValidationResult.error(
        'Значение должно быть не более ${_formatLimit(max)}',
      );
    }

    return ValidationResult.success();
  }

  // Select validation
  static ValidationResult validateSelect(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return ValidationResult.error('$fieldName обязательно выбрать');
    }

    return ValidationResult.success();
  }
}
