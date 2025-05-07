import 'dart:js_interop';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/validators.dart';
import 'auth_result.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:web/web.dart' as web;

class AuthService {

  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Додаємо валідацію в AuthService:
  Future<AuthResult> signup(String email, String password, String name, String phone) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) return AuthResult(error: emailError);

    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) return AuthResult(error: phoneError);

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) return AuthResult(error: passwordError);

    final nameError = Validators.validateName(name);
    if (nameError != null) return AuthResult(error: nameError);

    await firebase_auth.FirebaseAuth.instance.currentUser?.sendEmailVerification();

    try {
      final formattedPhone = Validators.formatPhoneNumber(phone);
      final fbUserCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = fbUserCredential.user;
      if (fbUser == null) {
        return AuthResult(error: 'User creation failed');
      }

      final now = DateTime.now();
      final uid = fbUser.uid;

      final userData = {
        'id': uid,
        'name': name,
        'email': email,
        'phone': formattedPhone,
        'profileImageUrl': null,
        'createdAt': now.toIso8601String(),
        'lastLoginAt': now.toIso8601String(),
        'isEmailVerified': fbUser.emailVerified,
      };

      await _firestore.collection('users').doc(uid).set(userData);

      final token = await fbUser.getIdToken();

      return AuthResult(
        user: User.fromJson(userData),
        token: token,
      );
    } catch (e) {
      return AuthResult(error: _handleFirebaseAuthError(e));
    }
  }

  Future<AuthResult> login(String email, String password) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) return AuthResult(error: emailError);

    if (password.isEmpty) return AuthResult(error: 'Password cannot be empty');

    try {
      final fbUserCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = fbUserCredential.user;

      if (fbUser == null) {
        return AuthResult(error: 'Authentication failed: no user returned');
      }
      if (!fbUser.emailVerified) {
        return AuthResult(error: 'Please verify your email before logging in.');
      }

      final userData = await _getUserData(fbUser.uid, emailVerified: fbUser.emailVerified);
      if (userData == null) {
        return AuthResult(error: 'User data not found');
      }

      final token = await fbUser.getIdToken();

      await _firestore.collection('users').doc(fbUser.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      return AuthResult(
        user: User.fromJson(userData),
        token: token,
      );
    } catch (e, stacktrace) {
      debugPrint('Login error: $e');
      debugPrint('Stacktrace: $stacktrace');
      return AuthResult(error: _handleFirebaseAuthError(e));
    }
  }


  Future<AuthResult> updateProfile(String userId, String name, String phone, web.File? profileImage) async {
    final nameError = Validators.validateName(name);
    if (nameError != null) return AuthResult(error: nameError);

    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) return AuthResult(error: phoneError);

    try {
      final formattedPhone = Validators.formatPhoneNumber(phone);

      final updateData = {
        'name': name,
        'phone': formattedPhone,
      };

      // Обробка зображення профілю
      if (profileImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('$userId.jpg');

        // Отримуємо JSArrayBuffer із web.File
        final arrayBuffer = await profileImage.arrayBuffer().toDart;
        // Конвертуємо JSArrayBuffer у Uint8List
        final uint8List = arrayBuffer.toDart.asUint8List();

        final uploadTask = storageRef.putData(uint8List);
        await uploadTask.whenComplete(() => null);
        final profileImageUrl = await storageRef.getDownloadURL();
        updateData['profileImageUrl'] = profileImageUrl;
      }

      await _firestore.collection('users').doc(userId).update(updateData);
      final fbUser = _firebaseAuth.currentUser;

      final userData = await _getUserData(userId, emailVerified: fbUser?.emailVerified ?? false);
      if (userData == null) {
        return AuthResult(error: 'User data not found');
      }

      final token = await fbUser?.getIdToken(true);

      return AuthResult(
        user: User.fromJson(userData),
        token: token,
      );
    } catch (e) {
      return AuthResult(error: 'Error updating profile: $e');
    }
  }

  /// Оновлення токена
  Future<AuthResult> refreshToken() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return AuthResult(error: 'User not authenticated');
      }

      final String? token = await currentUser.getIdToken(true);

      final userData = await _getUserData(currentUser.uid, emailVerified: currentUser.emailVerified);
      if (userData == null) {
        return AuthResult(error: 'User data not found');
      }

      final user = User.fromJson(userData);

      await _saveToken(token, currentUser.uid);

      return AuthResult(user: user, token: token);
    } catch (e) {
      return AuthResult(error: 'Error refreshing token: $e');
    }
  }

  Future<AuthResult> checkAuth() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return AuthResult(error: 'No user found');
      }

      final token = await currentUser.getIdToken(true);

      final userData = await _getUserData(currentUser.uid, emailVerified: currentUser.emailVerified);
      if (userData == null) {
        return AuthResult(error: 'User data not found');
      }

      return AuthResult(
        user: User.fromJson(userData),
        token: token,
      );
    } catch (e) {
      return AuthResult(error: 'Failed to authenticate: $e');
    }
  }

  Future<void> _saveToken(String? token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
      await prefs.setString('user_id', userId);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return _handleFirebaseAuthError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return 'No user is signed in';
      }

      // Повторна аутентифікація
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Оновлення пароля
      await user.updatePassword(newPassword);
      return null;
    } catch (e) {
      return _handleFirebaseAuthError(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }
      await user.sendEmailVerification();
    } catch (e) {
      throw Exception('Error sending verification email: $e');
    }
  }

  Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
      });
    } catch (e) {
      throw Exception('Error updating FCM token: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String uid, {required bool emailVerified}) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;
    final data = userDoc.data()!;
    data['isEmailVerified'] = emailVerified;
    return data;
  }

  String _handleFirebaseAuthError(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email already in use';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        default:
          return e.message ?? 'Unknown Firebase error';
      }
    }
    return 'Unknown error occurred';
  }
}