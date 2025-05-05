import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String? fcmToken; // For push notifications
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? preferences; // User settings
  final List<String>? savedAddressIds; // Saved addresses
  final bool isEmailVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.fcmToken,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
    this.savedAddressIds,
    required this.isEmailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      fcmToken: json['fcmToken'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] is Timestamp
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : DateTime.parse(json['lastLoginAt']),
      preferences: json['preferences'],
      savedAddressIds: json['savedAddressIds'] != null
          ? List<String>.from(json['savedAddressIds'])
          : [],
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences,
      'savedAddressIds': savedAddressIds,
      'isEmailVerified': isEmailVerified
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    List<String>? savedAddressIds,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      savedAddressIds: savedAddressIds ?? this.savedAddressIds,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}