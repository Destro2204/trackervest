import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserDocument(User user, String role) async {
    try {
      final userData = {
        'email': user.email,
        'id': user.uid,
        'role': role,
        'name': user.displayName ?? 'User',
        'groupId': 'default',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      print('✅ Debug: User document created successfully');
    } catch (e) {
      print('❌ Debug: Error creating user document: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('🚫 Debug: No authenticated user found');
        return null;
      }

      // Try to get user document by email first
      print(
        '🔍 Debug: Searching for user document with email: ${currentUser.email}',
      );
      final QuerySnapshot queryResult =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: currentUser.email)
              .limit(1)
              .get();

      if (queryResult.docs.isNotEmpty) {
        final userData = queryResult.docs.first.data() as Map<String, dynamic>;
        print('✅ Debug: Found user data by email:');
        userData.forEach((key, value) => print('   - $key: $value'));
        return userData;
      }

      print(
        '⚠️ Debug: No user document found with email, trying ID: ${currentUser.uid}',
      );
      final DocumentSnapshot docSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        print('✅ Debug: Found user data by UID:');
        userData.forEach((key, value) => print('   - $key: $value'));
        return userData;
      }

      print('❌ Debug: No user document found in Firestore');
      return null;
    } catch (e) {
      print('❌ Debug: Error in getUserData: $e');
      return null;
    }
  }

  Future<String> getUserRole() async {
    final userData = await getUserData();
    return userData?['role'] ?? 'athlete';
  }
}
