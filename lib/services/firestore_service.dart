import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/basic_models.dart';

class FirestoreService {
  Future<void> createUserDocument({ required User user }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .set(user.toJson());
  }
}