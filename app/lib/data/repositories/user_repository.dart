import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userCollection = 'users';
  static const String _isLoggedInKey = 'is_logged_in';

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_userCollection).doc(userId).get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc, userId as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error getting user: ${e.toString()}');
      return null;
    }
  }

  // Create new user
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_userCollection)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      print('Error creating user: ${e.toString()}');
      rethrow;
    }
  }

  // Update existing user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_userCollection)
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      print('Error updating user: ${e.toString()}');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_userCollection).doc(userId).delete();
    } catch (e) {
      print('Error deleting user: ${e.toString()}');
      rethrow;
    }
  }
}
