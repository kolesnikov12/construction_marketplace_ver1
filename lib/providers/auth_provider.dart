import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:construction_marketplace/utils/constants.dart';

import '../models/basic_models.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  User? _user;
  Timer? _authTimer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  User? get user {
    return _user;
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(Constants.prefsUserData)) {
      return false;
    }

    final extractedUserData = json.decode(prefs.getString(Constants.prefsUserData)!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate'] as String);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = extractedUserData['token'] as String;
    _userId = extractedUserData['userId'] as String;
    _expiryDate = expiryDate;

    await _fetchUserDetails();

    _autoLogout();
    notifyListeners();
    return true;
  }

  Future<void> signup(String email, String password, String name, String phone) async {
    try {
      // For demo purposes, simulate successful signup
      // In a real app, this would make an API call
      print('Signup: $email, $name, $phone');
      await Future.delayed(Duration(seconds: 1));

      // After signup, login automatically
      await login(email, password);
    } catch (error) {
      throw error;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      // For demo purposes, simulate successful login
      // In a real app, this would make an API call
      print('Login: $email');
      await Future.delayed(Duration(seconds: 1));

      // Mock successful response
      _token = 'mock_token';
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _expiryDate = DateTime.now().add(Duration(hours: 1));

      // Create a mock user
      _user = User(
        id: _userId!,
        name: 'Test User',
        email: email,
        phone: '+1 123-456-7890',
        profileImageUrl: null,
      );

      _autoLogout();
      notifyListeners();

      // Store the auth data in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate!.toIso8601String(),
      });
      prefs.setString(Constants.prefsUserData, userData);
    } catch (error) {
      throw error;
    }
  }

  Future<void> _fetchUserDetails() async {
    if (_token == null || _userId == null) return;

    try {
      // For demo purposes, create mock user data
      // In a real app, this would make an API call
      _user = User(
        id: _userId!,
        name: 'Test User',
        email: 'user@example.com',
        phone: '+1 123-456-7890',
        profileImageUrl: null,
      );

      notifyListeners();
    } catch (error) {
      print('Error fetching user details: $error');
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    _user = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.remove(Constants.prefsUserData);
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }

  Future<void> updateProfile(String name, String phone, String? imageUrl) async {
    if (_token == null || _userId == null) return;

    try {
      // For demo purposes, just update the local user object
      // In a real app, this would make an API call
      _user = User(
        id: _userId!,
        name: name,
        email: _user!.email,
        phone: phone,
        profileImageUrl: imageUrl,
      );

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_token == null || _userId == null) return;

    try {
      // For demo purposes, just print the change
      // In a real app, this would make an API call
      print('Changing password from $currentPassword to $newPassword');
      await Future.delayed(Duration(seconds: 1));

    } catch (error) {
      rethrow;
    }
  }
}