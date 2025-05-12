// user_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

abstract class UserRepository {
  Future<String?> getUserId();
  Future<String?> getToken();
  Future<void> saveAuthentication(String userId, String token);
  Future<void> clearAuthentication();
}

class SharedPreferencesUserRepository implements UserRepository {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';

  @override
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> saveAuthentication(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<void> clearAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_tokenKey);
  }
}