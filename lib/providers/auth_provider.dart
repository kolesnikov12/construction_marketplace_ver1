import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:construction_marketplace/models/basic_models.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
  registering
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

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
    tryAutoLogin();
  }

  // Методи авторизації
  Future<bool> tryAutoLogin() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _authService.checkAuth();

      if (!authResult.success) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        if (kDebugMode) {
          print('Auth result: success=${authResult.success}, token=${authResult.token}, user=${authResult.user}');
        }
        return false;
      }

      _token = authResult.token;
      _user = authResult.user;
      _userId = authResult.user!.id;

      final decodedToken = JwtDecoder.decode(authResult.token!);
      final expiryTimestamp = decodedToken['exp'] * 1000;
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

  Future<bool> signup(String email, String password, String name, String phone) async {
    _status = AuthStatus.registering;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _authService.signup(email, password, name, phone);

      if (!authResult.success || authResult.user == null) {
        _errorMessage = authResult.error;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();

      final newUser = User(
        id: authResult.user!.id,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: null,
        fcmToken: null,
        createdAt: now,
        lastLoginAt: now,
        preferences: null,
        savedAddressIds: [],
        isEmailVerified: authResult.user!.isEmailVerified,
      );

      await _firestoreService.createUserDocument(user: newUser);

      if (!authResult.user!.isEmailVerified) {
        await _authService.sendEmailVerification();
      }

      _token = authResult.token;
      _userId = newUser.id;
      _user = newUser;

      final decodedToken = JwtDecoder.decode(authResult.token!);
      final expiryTimestamp = decodedToken['exp'] * 1000;
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

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _authService.login(email, password);

      if (!authResult.success) {
        _errorMessage = authResult.error;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        if (kDebugMode) {
          print('Login error: ${authResult.error}');
        }
        return false;
      }

      _token = authResult.token;
      _userId = authResult.user!.id;
      _user = authResult.user;

      final decodedToken = JwtDecoder.decode(authResult.token!);
      if (kDebugMode) {
        print('JwtDecoder.decode(authResult.token!) = $decodedToken');
      }
      final expiryTimestamp = decodedToken['exp'] * 1000;
      _expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _autoLogout();
      notifyListeners();
      return true;
    } catch (e, stack) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      if (kDebugMode) {
        print('Login _errorMessage: ${e.toString()}');
        print('Login exception: $e\n$stack');
      }
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
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

  Future<bool> updateProfile(String name, String phone, web.File? imageFile) async {
    if (_token == null || _userId == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return false;
    }

    try {
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

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _errorMessage = null;
    notifyListeners();

    try {
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

  Future<bool> checkAuthStatus() async {
    if (isAuth) {
      return true;
    }

    return tryAutoLogin();
  }

  Future<bool> refreshToken() async {
    try {
      final authResult = await _authService.refreshToken();

      if (!authResult.success) {
        _errorMessage = authResult.error;
        notifyListeners();
        return false;
      }

      _token = authResult.token;

      final decodedToken = JwtDecoder.decode(authResult.token!);
      final expiryTimestamp = decodedToken['exp'] * 1000;
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

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }

    if (_expiryDate == null) return;

    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;

    if (timeToExpiry <= 0) {
      logout();
      return;
    }

    if (timeToExpiry < 300) {
      refreshToken();
      return;
    }

    _authTimer = Timer(Duration(seconds: timeToExpiry - 60), () {
      refreshToken();
    });
  }

  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }
}