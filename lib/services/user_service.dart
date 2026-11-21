import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const requiredFields = [
    'uid',
    'firstName',
    'lastName',
    'role',
    'registrationDateTime'
  ];

  Future<void> saveUserRecord(
      User user, {
        required String firstName,
        required String lastName,
        required String role,
      }) {
    return _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'role': role,
      'registrationDateTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userRecord(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// True only when all five required fields exist.
  static bool isComplete(Map<String, dynamic>? data) {
    if (data == null) return false;
    return requiredFields.every((f) => data[f] != null);
  }
}