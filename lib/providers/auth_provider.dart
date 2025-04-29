import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:construction_marketplace/services/auth_service.dart';
import 'package:construction_marketplace/models/basic_models.dart';
import 'package:construction_marketplace/utils/constants.dart';
import 'package:construction_marketplace/utils/validators.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
  registering
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  User? _user;
  Timer? _authTimer;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;

  // Getters
  bool get isAuth => token != null;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  bool get isRegistering => _status == AuthStatus.registering;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }
  String? get userId => _userId;
  User? get user => _user;
  bool get isVerified => _user?.isEmailVerified ?? false;

  // Час до закінчення токена (в секундах)
  int get tokenExpiryTime {
    if (_expiryDate == null) return 0;
    return _expiryDate!.difference(DateTime.now()).inSeconds;
  }

  AuthProvider() {
    // Автоматично пробуємо авторизуватися при створенні провайдера
    tryAutoLogin();
  }

  // Методи авторизації

  /// Автоматичний вхід при запуску додатку
  Future<bool> tryAutoLogin() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _authService.checkAuth();

      if (!authResult.success) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _token = authResult.token;
      _user = authResult.user;
      _userId = authResult.user!.id;

      // Розпарсити дату закінчення з JWT токена
      final decodedToken = JwtDecoder.decode(authResult.token!);
      final expiryTimestamp = decodedToken['exp'] * 1000; // Convert seconds to milliseconds
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _autoLogout();
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Реєстрація нового користувача
  Future<bool> signup(String email, String password, String name, String phone) async {
    _status = AuthStatus.registering;
    _errorMessage = null;
    notifyListeners();

    try {
      // Валідація введених даних
      final emailError = Validators.validateEmail(email);
      if (emailError != null) {
        _errorMessage = emailError;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final phoneError = Validators.validatePhone(phone);
      if (phoneError != null) {
        _errorMessage = phoneError;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final passwordError = Validators.validatePassword(password);
      if (passwordError != null) {
        _errorMessage = passwordError;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final nameError = Validators.validateName(name);
      if (nameError != null) {
        _errorMessage = nameError;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final authResult = await _authService.signup(email, password, name, phone);

      if (!authResult.success) {
        _errorMessage = authResult.error;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _token = authResult.token;
      _userId = authResult.user!.id;
      _user = authResult.user;

      // Розпарсити дату закінчення з JWT токена
      final decodedToken = JwtDecoder.decode(authResult.token!);
      final expiryTimestamp = decodedToken['exp'] * 1000; // Convert seconds to milliseconds
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _autoLogout();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Вхід користувача
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // Валідація введених даних
      final emailError = Validators.validateEmail(email);
      if (emailError != null) {
        _errorMessage = emailError;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Password cannot be empty';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final authResult = await _authService.login(email, password);

      if (!authResult.success) {
        _errorMessage = authResult.error;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _token = authResult.token;
      _userId = authResult.user!.id;
      _user = authResult.user;

      // Розпарсити дату закінчення з JWT токена
      final decodedToken = JwtDecoder.decode(authResult.token!);
      final expiryTimestamp = decodedToken['exp'] * 1000; // Convert seconds to milliseconds
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _autoLogout();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Відновлення паролю
  Future<bool> resetPassword(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Валідація емейла
      final emailError = Validators.validateEmail(email);
      if (emailError != null) {
        _errorMessage = emailError;
        notifyListeners();
        return false;
      }

      final error = await _authService.resetPassword(email);
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Вихід з системи
  Future<void> logout() async {
    try {
      await _authService.logout();

      _token = null;
      _userId = null;
      _expiryDate = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;

      if (_authTimer != null) {
        _authTimer!.cancel();
        _authTimer = null;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Оновлення профілю користувача
  Future<bool> updateProfile(String name, String phone, File? imageFile) async {
    if (_token == null || _userId == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
      // Валідація даних
      final nameError = Validators.validateName(name);
      if (nameError != null) {
        _errorMessage = nameError;
        notifyListeners();
        return false;
      }

      final phoneError = Validators.validatePhone(phone);
      if (phoneError != null) {
        _errorMessage = phoneError;
        notifyListeners();
        return false;
      }

      final authResult = await _authService.updateProfile(_userId!, name, phone, imageFile);

      if (!authResult.success) {
        _errorMessage = authResult.error;
        notifyListeners();
        return false;
      }

      _user = authResult.user;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Зміна паролю
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Валідація нового пароля
      final passwordError = Validators.validatePassword(newPassword);
      if (passwordError != null) {
        _errorMessage = passwordError;
        notifyListeners();
        return false;
      }

      final error = await _authService.changePassword(currentPassword, newPassword);
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Надсилання листа для верифікації електронної пошти
  Future<bool> sendEmailVerification() async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Оновлення FCM токена для push-повідомлень
  Future<bool> updateFcmToken(String fcmToken) async {
    if (_userId == null) {
      return false;
    }

    try {
      await _authService.updateFcmToken(_userId!, fcmToken);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Перевірка стану авторизації
  Future<bool> checkAuthStatus() async {
    if (isAuth) {
      return true;
    }

    return tryAutoLogin();
  }

  /// Оновлення токена (примусово)
  Future<bool> refreshToken() async {
    try {
      final authResult = await _authService.refreshToken();

      if (!authResult.success) {
        _errorMessage = authResult.error;
        notifyListeners();
        return false;
      }

      _token = authResult.token;

      // Розпарсити дату закінчення з JWT токена
      final decodedToken = JwtDecoder.decode(authResult.token!);
      final expiryTimestamp = decodedToken['exp'] * 1000; // Convert seconds to milliseconds
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      _autoLogout();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Приватні методи

  /// Автоматичний вихід по закінченню терміну дії токена
  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }

    if (_expiryDate == null) return;

    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;

    // Якщо токен вже прострочений, виходимо відразу
    if (timeToExpiry <= 0) {
      logout();
      return;
    }

    // Якщо до закінчення залишилося менше 5 хвилин, запускаємо оновлення токена
    if (timeToExpiry < 300) {
      refreshToken();
      return;
    }

    _authTimer = Timer(Duration(seconds: timeToExpiry - 60), () {
      // Спробуємо оновити токен за 1 хвилину до закінчення
      refreshToken();
    });
  }

  /// Очищення помилок
  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }
}