import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to check Firebase configuration and diagnose issues
class FirebaseConfigChecker {
  static Future<Map<String, dynamic>> checkConfiguration() async {
    final results = <String, dynamic>{};

    try {
      // Check 1: Firebase Core initialization
      print('=== FIREBASE CONFIGURATION CHECK ===');

      // Check if Firebase is initialized
      try {
        final app = Firebase.app();
        results['firebase_initialized'] = true;
        results['firebase_app_name'] = app.name;
        print('✓ Firebase Core initialized: ${app.name}');
      } catch (e) {
        results['firebase_initialized'] = false;
        results['firebase_error'] = e.toString();
        print('✗ Firebase Core not initialized: $e');
        return results;
      }

      // Check 2: Firebase Auth instance
      try {
        final auth = FirebaseAuth.instance;
        results['auth_instance'] = true;
        print('✓ Firebase Auth instance created');

        // Check current user
        final currentUser = auth.currentUser;
        results['current_user'] = currentUser?.uid ?? 'null';
        print('✓ Current user: ${currentUser?.uid ?? 'null'}');

        // Check auth state changes stream
        try {
          auth.authStateChanges();
          results['auth_stream'] = true;
          print('✓ Auth state changes stream accessible');
        } catch (e) {
          results['auth_stream'] = false;
          results['auth_stream_error'] = e.toString();
          print('✗ Auth state changes stream error: $e');
        }
      } catch (e) {
        results['auth_instance'] = false;
        results['auth_error'] = e.toString();
        print('✗ Firebase Auth instance error: $e');
      }

      // Check 3: Firestore instance
      try {
        final firestore = FirebaseFirestore.instance;
        results['firestore_instance'] = true;
        print('✓ Firestore instance created');

        // Test a simple read operation
        try {
          await firestore.collection('test').limit(1).get();
          results['firestore_read'] = true;
          print('✓ Firestore read operation successful');
        } catch (e) {
          results['firestore_read'] = false;
          results['firestore_read_error'] = e.toString();
          print('✗ Firestore read operation failed: $e');
        }
      } catch (e) {
        results['firestore_instance'] = false;
        results['firestore_error'] = e.toString();
        print('✗ Firestore instance error: $e');
      }

      // Check 4: Platform-specific checks
      if (kIsWeb) {
        results['platform'] = 'web';
        print('Platform: Web');
      } else {
        results['platform'] = defaultTargetPlatform.toString();
        print('Platform: ${defaultTargetPlatform}');
      }

      // Check 5: Test authentication method
      try {
        // This will fail but should give us useful error information
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'testpassword',
        );
        results['auth_test'] = 'unexpected_success';
        print('⚠ Unexpected: Auth test succeeded with test credentials');
      } catch (e) {
        if (e is FirebaseAuthException) {
          results['auth_test'] = 'expected_failure';
          results['auth_test_error_code'] = e.code;
          results['auth_test_error_message'] = e.message;
          print('✓ Auth test failed as expected: ${e.code} - ${e.message}');
        } else {
          results['auth_test'] = 'unexpected_error';
          results['auth_test_error'] = e.toString();
          print('✗ Auth test failed with unexpected error: $e');
        }
      }
    } catch (e) {
      results['general_error'] = e.toString();
      print('✗ General configuration check error: $e');
    }

    print('=== CONFIGURATION CHECK COMPLETE ===');
    return results;
  }

  static void printResults(Map<String, dynamic> results) {
    print('\n=== FIREBASE CONFIGURATION SUMMARY ===');
    results.forEach((key, value) {
      final status = value is bool ? (value ? '✓' : '✗') : 'ℹ';
      print('$status $key: $value');
    });
    print('=====================================\n');
  }
}
