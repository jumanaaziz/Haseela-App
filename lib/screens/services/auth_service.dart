import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String userType,
    String? username,
  }) async {
    try {
      // Check if email already exists
      await _checkEmailUniqueness(email);

      // Check if username already exists (only for Parent)
      if (userType == 'Parent' && username != null) {
        await _checkUsernameUniqueness(username);
      }

      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user data to Firestore
      await _saveUserToFirestore(
        userCredential.user!,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        userType: userType,
        username: username,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Update last login time in Firestore
      await _updateLastLogin(userCredential.user!.uid);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign in with username (converts to email first)
  Future<UserCredential?> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      // Get email from username
      final email = await _getEmailFromUsername(username);

      // Sign in with email
      return await signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Sign in with username failed: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Check if email is unique
  Future<void> _checkEmailUniqueness(String email) async {
    final parentQuery = await _firestore
        .collection('Parents')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final childQuery = await _firestore
        .collection('Children')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (parentQuery.docs.isNotEmpty || childQuery.docs.isNotEmpty) {
      throw Exception('Email already exists!');
    }
  }

  // Check if username is unique
  Future<void> _checkUsernameUniqueness(String username) async {
    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(username)
        .get();

    if (usernameDoc.exists) {
      throw Exception('Username already exists!');
    }
  }

  // Get email from username
  Future<String> _getEmailFromUsername(String username) async {
    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(username)
        .get();

    if (!usernameDoc.exists) {
      throw Exception('Username not found!');
    }

    final email = usernameDoc.data()?['email'];
    if (email == null) {
      throw Exception('Email not found for username!');
    }

    return email;
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(
    User user, {
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String userType,
    String? username,
  }) async {
    final collectionName = userType == 'Parent' ? 'Parents' : 'Children';

    final userData = {
      'uid': user.uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'userType': userType,
      'createdAt': Timestamp.now(),
      'lastLogin': null,
    };

    // Add username for Parent
    if (userType == 'Parent' && username != null) {
      userData['username'] = username;
    }

    // Save to appropriate collection
    await _firestore.collection(collectionName).doc(user.uid).set(userData);

    // Save username mapping for Parent
    if (userType == 'Parent' && username != null) {
      await _firestore.collection('usernames').doc(username).set({
        'uid': user.uid,
        'email': email,
        'userType': userType,
        'createdAt': Timestamp.now(),
      });
    }
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    // Update in both collections
    await Future.wait([
      _firestore
          .collection('Parents')
          .doc(uid)
          .update({'lastLogin': Timestamp.now()})
          .catchError((_) {}), // Ignore if not found
      _firestore
          .collection('Children')
          .doc(uid)
          .update({'lastLogin': Timestamp.now()})
          .catchError((_) {}), // Ignore if not found
    ]);
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      // Try Parents collection first
      final parentDoc = await _firestore.collection('Parents').doc(uid).get();
      if (parentDoc.exists) {
        return parentDoc.data();
      }

      // Try Children collection
      final childDoc = await _firestore.collection('Children').doc(uid).get();
      if (childDoc.exists) {
        return childDoc.data();
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }
}
