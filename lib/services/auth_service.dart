import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDocument(
    User user,
    String role, {
    Map<String, dynamic>? userData,
  }) async {
    try {
      // Get name from userData or fallback
      final String userName = userData?['name'] ?? user.displayName ?? 'User';

      // Generate user ID from name
      final String userId = "${userName.replaceAll(' ', '')}ID";

      // Create a base user document
      final Map<String, dynamic> userDoc = {
        'email': user.email,
        'uid': user.uid,
        'role': role,
        'name': userName,
        'id': userId, // Add auto-generated ID
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add athlete-specific fields if role is athlete
      if (role == 'athlete') {
        userDoc['heartrate'] = null;
        userDoc['temp'] = null;
      }

      // Merge with any additional user data
      if (userData != null) {
        userDoc.addAll(userData);
        // Make sure the auto-generated ID isn't overwritten if not specified
        if (!userData.containsKey('id')) {
          userDoc['id'] = userId;
        }
      }

      // Save to Firestore users collection
      await _firestore.collection('users').doc(user.uid).set(userDoc);

      print('✅ User document created in Firestore');
      print('Auto-generated user ID: $userId');
      print('Role: $role');
      if (role == 'athlete') {
        print('Athlete-specific fields initialized: heartrate=null, temp=null');
      }
      userDoc.forEach((key, value) {
        print('   - $key: $value');
      });
    } catch (e) {
      print('❌ Error creating user document: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {
          'role': 'athlete',
          'name': 'Default User',
          'id': 'DefaultUserID',
        };
      }

      // Try to get user document from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      // If the document exists, return the data
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('✅ User data retrieved from Firestore');
        return userData;
      }

      // Generate name and ID for fallback data
      final String userName =
          currentUser.displayName ?? 'User ${currentUser.uid.substring(0, 4)}';
      final String userId = "${userName.replaceAll(' ', '')}ID";

      // Fallback data if not found
      return {
        'role': 'athlete',
        'email': currentUser.email,
        'uid': currentUser.uid,
        'name': userName,
        'id': userId,
      };
    } catch (e) {
      print('❌ Error getting user data: $e');
      // Return default data in case of error
      return {
        'role': 'athlete',
        'name': 'Default User',
        'id': 'DefaultUserID',
        'error': e.toString(),
      };
    }
  }

  // Add new method to get all athletes
  Future<List<Map<String, dynamic>>> getAllAthletes() async {
    try {
      // Query Firestore for all users with role 'athlete'
      final QuerySnapshot athletesSnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'athlete')
              .get();

      // Convert QuerySnapshot to List of Maps
      final List<Map<String, dynamic>> athletes =
          athletesSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      print('✅ Retrieved ${athletes.length} athletes from Firestore');
      return athletes;
    } catch (e) {
      print('❌ Error getting athletes: $e');
      return [];
    }
  }

  // Add method to get a specific athlete's data
  Future<Map<String, dynamic>?> getAthleteData(String uid) async {
    try {
      final DocumentSnapshot athleteDoc =
          await _firestore.collection('users').doc(uid).get();

      if (athleteDoc.exists) {
        final athleteData = athleteDoc.data() as Map<String, dynamic>;
        return athleteData;
      }

      return null;
    } catch (e) {
      print('❌ Error getting athlete data: $e');
      return null;
    }
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Debug: Attempting login for $email');

      // First authenticate with Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        print('\n🔐 Debug: Authentication Successful');
        print('   - Email: ${userCredential.user?.email}');
        print('   - UID: ${userCredential.user?.uid}');

        print('\n🔄 Debug: Fetching Firestore Data...');
        final userData = await _firebaseService.getUserData();

        print('\n✅ Debug: Login Complete');
        print('Firebase Auth User:');
        print('   - Email: ${userCredential.user?.email}');
        print('   - UID: ${userCredential.user?.uid}');
        print('\nFirestore User Data:');
        userData.forEach((key, value) {
          print('   - $key: $value');
        });

        return {
          'success': true,
          'user': userCredential.user,
          'userData': userData,
          'message': 'Login successful',
        };
      }

      print('Debug: No user returned from authentication');
      return {'success': false, 'message': 'Authentication failed'};
    } on FirebaseAuthException catch (e) {
      print('Debug: FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Wrong password provided';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Debug: Unexpected error during login: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String role, {
    Map<String, dynamic>? userData,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password cannot be empty',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters long',
        };
      }

      // Create user with reCAPTCHA verification
      await _auth.setSettings(appVerificationDisabledForTesting: false);
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Create user document with role and additional data
        await _firebaseService.createUserDocument(
          userCredential.user!,
          role,
          userData: userData,
        );

        return {
          'success': true,
          'user': userCredential.user,
          'role': role,
          'userData': userData,
          'message': 'Registration successful',
        };
      } else {
        return {'success': false, 'message': 'Registration failed'};
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
