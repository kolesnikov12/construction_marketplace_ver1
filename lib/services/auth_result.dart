import '../models/user.dart';

class AuthResult {
  final User? user;
  final String? token;
  final String? error;

  AuthResult({this.user, this.token, this.error});

  bool get success => error == null && user != null && token != null;
}