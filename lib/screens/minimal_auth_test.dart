import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Minimal authentication test to isolate the Pigeon error
class MinimalAuthTest extends StatefulWidget {
  const MinimalAuthTest({super.key});

  @override
  State<MinimalAuthTest> createState() => _MinimalAuthTestState();
}

class _MinimalAuthTestState extends State<MinimalAuthTest> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _result = 'Ready to test';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testAuth() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing...';
    });

    try {
      print('=== MINIMAL AUTH TEST ===');

      // Test 1: Check Firebase Auth instance
      print('Step 1: Getting Firebase Auth instance');
      final auth = FirebaseAuth.instance;
      print('✓ Firebase Auth instance: $auth');

      // Test 2: Check current user
      print('Step 2: Getting current user');
      final user = auth.currentUser;
      print('✓ Current user: $user');

      // Test 3: Try sign in with invalid credentials (should fail gracefully)
      print('Step 3: Testing sign in with invalid credentials');
      try {
        await auth.signInWithEmailAndPassword(
          email: 'invalid@test.com',
          password: 'invalidpassword',
        );
        print('⚠ Unexpected: Sign in succeeded with invalid credentials');
        setState(() {
          _result = 'ERROR: Sign in succeeded with invalid credentials';
        });
      } catch (e) {
        print('✓ Expected failure: $e');
        if (e is FirebaseAuthException) {
          print('✓ Firebase Auth Exception: ${e.code} - ${e.message}');
          setState(() {
            _result = 'SUCCESS: Firebase Auth working correctly (${e.code})';
          });
        } else {
          print('✗ Unexpected error type: ${e.runtimeType}');
          setState(() {
            _result = 'ERROR: Unexpected error type - ${e.runtimeType}';
          });
        }
      }
    } catch (e) {
      print('✗ General error: $e');
      setState(() {
        _result = 'ERROR: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testWithRealCredentials() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _result = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Testing with real credentials...';
    });

    try {
      print('=== REAL CREDENTIALS TEST ===');
      print('Email: ${_emailController.text}');

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      print('✓ Sign in successful!');
      print('User ID: ${userCredential.user?.uid}');

      setState(() {
        _result = 'SUCCESS: Login worked! User: ${userCredential.user?.uid}';
      });
    } catch (e) {
      print('✗ Sign in failed: $e');
      if (e is FirebaseAuthException) {
        print('Firebase Auth Exception: ${e.code} - ${e.message}');
        setState(() {
          _result = 'FAILED: ${e.code} - ${e.message}';
        });
      } else {
        print('Unexpected error: ${e.runtimeType}');
        setState(() {
          _result = 'ERROR: ${e.runtimeType} - $e';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimal Auth Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Minimal Firebase Auth Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _testAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Firebase Auth (Invalid Credentials)'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _testWithRealCredentials,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test with Real Credentials'),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Result:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _result.contains('ERROR') ||
                              _result.contains('FAILED')
                          ? Colors.red
                          : _result.contains('SUCCESS')
                          ? Colors.green
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Check console for detailed logs',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

