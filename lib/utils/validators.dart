import 'package:flutter/material.dart';

class Validators {
  // Регулярний вираз для валідації email
  static final RegExp _emailRegExp = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$");

  // Регулярний вираз для базової перевірки міжнародного номера телефону
  // Підтримує формати:
  // +380501234567
  // +38 050 123 45 67
  // +38-050-123-45-67
  // 380501234567
  static final RegExp _phoneRegExp = RegExp(
    r'^(\+?[0-9]{1,4})?[\s-]?([0-9]{3,4})[\s-]?([0-9]{3})[\s-]?([0-9]{2})[\s-]?([0-9]{2})$',
  );

  // Перевірка канадського номера телефону
  // Підтримує формати:
  // (123) 456-7890
  // 123-456-7890
  // 123.456.7890
  static final RegExp _canadianPhoneRegExp = RegExp(
    r'^\(?([0-9]{3})\)?[-.●]?([0-9]{3})[-.●]?([0-9]{4})$',
  );

  // Валідація email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }

    if (!_emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    // Перевірка доменної частини email
    final parts = value.split('@');
    if (parts.length != 2 || !parts[1].contains('.')) {
      return 'Please enter a valid email domain';
    }

    // Перевірка на максимальну довжину
    if (value.length > 255) {
      return 'Email is too long';
    }

    return null;
  }

  // Валідація phone
  static String? validatePhone(String? value, {bool allowEmpty = false}) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'Phone number cannot be empty';
    }

    // Видалимо всі нецифрові символи для підрахунку довжини
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Перевірка мінімальної та максимальної довжини
    if (digitsOnly.length < 10) {
      return 'Phone number is too short';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }

    // Перевірка за допомогою регулярних виразів
    if (!_phoneRegExp.hasMatch(value) && !_canadianPhoneRegExp.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Валідація пароля
  static String? validatePassword(String? value, {bool confirmPassword = false}) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }

    if (!confirmPassword && value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!confirmPassword && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!confirmPassword && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (!confirmPassword && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  // Валідація підтвердження пароля
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Валідація імені
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name cannot be empty';
    }

    if (value.length < 2) {
      return 'Name is too short';
    }

    if (value.length > 100) {
      return 'Name is too long';
    }

    return null;
  }

  // Форматування телефонного номера
  static String formatPhoneNumber(String phone) {
    // Видаляємо всі нецифрові символи
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Канадський формат (123) 456-7890
    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }

    // Міжнародний формат
    if (digitsOnly.length > 10) {
      final countryCode = digitsOnly.substring(0, digitsOnly.length - 10);
      final areaCode = digitsOnly.substring(digitsOnly.length - 10, digitsOnly.length - 7);
      final prefix = digitsOnly.substring(digitsOnly.length - 7, digitsOnly.length - 4);
      final lineNumber = digitsOnly.substring(digitsOnly.length - 4);

      return '+$countryCode ($areaCode) $prefix-$lineNumber';
    }

    // Повертаємо оригінальний формат, якщо не вдалося розпізнати
    return phone;
  }
}
