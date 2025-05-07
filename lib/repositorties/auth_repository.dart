// 1. First, let's create the missing AuthRepository class
// Create a new file: lib/repositories/auth_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:web/web.dart' as web;
import '../models/user.dart' as app_user;

class AuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return {'success': false, 'error': 'Login failed'};
      }

      final userData = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userData.exists) {
        return {'success': false, 'error': 'User data not found'};
      }

      final user = app_user.User.fromJson({
        'id': userCredential.user!.uid,
        ...userData.data()!,
        'isEmailVerified': userCredential.user!.emailVerified,
      });

      final token = await userCredential.user!.getIdToken();

      return {
        'success': true,
        'user': user,
        'token': token,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signup(String email, String password, String name, String phone) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return {'success': false, 'error': 'Sign up failed'};
      }

      final now = DateTime.now();
      final user = app_user.User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        profileImageUrl: null,
        fcmToken: null,
        createdAt: now,
        lastLoginAt: now,
        preferences: null,
        savedAddressIds: null,
        isEmailVerified: userCredential.user!.emailVerified,
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());

      final token = await userCredential.user!.getIdToken();

      return {
        'success': true,
        'user': user,
        'token': token,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await _auth.signOut();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(String userId, String name, String phone, web.File? profileImage) async {
    try {
      // Update user profile data
      final updateData = {
        'name': name,
        'phone': phone,
      };

      // Handle profile image upload if provided
      if (profileImage != null) {
        // Process web file
        final path = 'profile_images/$userId.jpg';
        final ref = _storage.ref().child(path);

        // Convert web file to bytes - implementation will be fixed in the service layer
        // since we're addressing error 4 differently
        // This is just a placeholder for the repository structure

        // updateData['profileImageUrl'] = await ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(userId).update(updateData);

      // Get updated user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'success': false, 'error': 'User not found'};
      }

      final user = app_user.User.fromJson({
        'id': userId,
        ...userDoc.data()!,
        'isEmailVerified': _auth.currentUser?.emailVerified ?? false,
      });

      final token = await _auth.currentUser?.getIdToken();

      return {
        'success': true,
        'user': user,
        'token': token,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> checkAuth() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return {'success': false, 'error': 'User data not found'};
      }

      final user = app_user.User.fromJson({
        'id': currentUser.uid,
        ...userDoc.data()!,
        'isEmailVerified': currentUser.emailVerified,
      });

      final token = await currentUser.getIdToken();

      return {
        'success': true,
        'user': user,
        'token': token,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}