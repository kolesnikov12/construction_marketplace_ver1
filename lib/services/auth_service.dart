class AuthService {}
/*
// Додаємо валідацію в AuthService:

Future<AuthResult> signup(String email, String password, String name, String phone) async {
  // Валідація введених даних
  final emailError = Validators.validateEmail(email);
  if (emailError != null) {
    return AuthResult(error: emailError);
  }

  final phoneError = Validators.validatePhone(phone);
  if (phoneError != null) {
    return AuthResult(error: phoneError);
  }

  final passwordError = Validators.validatePassword(password);
  if (passwordError != null) {
    return AuthResult(error: passwordError);
  }

  final nameError = Validators.validateName(name);
  if (nameError != null) {
    return AuthResult(error: nameError);
  }

  try {
    // Форматуємо телефонний номер перед збереженням
    final formattedPhone = Validators.formatPhoneNumber(phone);

    // Решта коду залишається без змін
    // ...

    // Оновлюємо дані, які зберігаємо в Firestore
    final userData = {
      'id': uid,
      'name': name,
      'email': email,
      'phone': formattedPhone,  // Використовуємо відформатований номер
      'profileImageUrl': null,
      'createdAt': now.toIso8601String(),
      'lastLoginAt': now.toIso8601String(),
      'isEmailVerified': false,
    };

    // ...
  } catch (e) {
    return AuthResult(error: _handleFirebaseAuthError(e));
  }
}

Future<AuthResult> login(String email, String password) async {
  // Валідація введених даних
  final emailError = Validators.validateEmail(email);
  if (emailError != null) {
    return AuthResult(error: emailError);
  }

  if (password.isEmpty) {
    return AuthResult(error: 'Password cannot be empty');
  }

  try {
    // Решта коду залишається без змін
    // ...
  } catch (e) {
    return AuthResult(error: _handleFirebaseAuthError(e));
  }
}

Future<AuthResult> updateProfile(String userId, String name, String phone, File? profileImage) async {
  // Валідація введених даних
  final nameError = Validators.validateName(name);
  if (nameError != null) {
    return AuthResult(error: nameError);
  }

  final phoneError = Validators.validatePhone(phone);
  if (phoneError != null) {
    return AuthResult(error: phoneError);
  }

  try {
    // Форматуємо телефонний номер перед збереженням
    final formattedPhone = Validators.formatPhoneNumber(phone);

    // Підготовка даних для оновлення
    final updateData = {
      'name': name,
      'phone': formattedPhone,  // Використовуємо відформатований номер
    };

    // Решта коду залишається без змін
    // ...
  } catch (e) {
    return AuthResult(error: 'Error updating profile: $e');
  }
}
  /// Оновлення токена
  Future<AuthResult> refreshToken() async {
    try {
      // Отримуємо поточного користувача
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        return AuthResult(error: 'User not authenticated');
      }

      // Генеруємо новий токен
      final String token = await currentUser.getIdToken(true); // force refresh

      // Отримуємо дані користувача з Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return AuthResult(error: 'User data not found');
      }

      final userData = userDoc.data()!;
      userData['isEmailVerified'] = currentUser.emailVerified;

      final user = User.fromJson(userData);

      // Зберігаємо токен локально
      await _saveToken(token, currentUser.uid, user);

      return AuthResult(user: user, token: token);
    } catch (e) {
      return AuthResult(error: 'Error refreshing token: $e');
    }
  }
 */