import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Platform-specific test to identify where the Pigeon error occurs
class PlatformTest extends StatefulWidget {
  const PlatformTest({super.key});

  @override
  State<PlatformTest> createState() => _PlatformTestState();
}

class _PlatformTestState extends State<PlatformTest> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Platform & Firebase Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Platform info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Information:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Platform: ${kIsWeb ? 'Web' : defaultTargetPlatform}'),
                  Text('Is Web: $kIsWeb'),
                  Text('Is Debug: $kDebugMode'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Test buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testBasicFirebase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Basic Firebase'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthInstance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Auth Instance'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthStream,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Auth Stream'),
            ),
            const SizedBox(height: 20),

            // Status display
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
                    'Status:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _status.contains('ERROR') ||
                              _status.contains('FAILED')
                          ? Colors.red
                          : _status.contains('SUCCESS')
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

  Future<void> _testBasicFirebase() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing basic Firebase...';
    });

    try {
      print('=== BASIC FIREBASE TEST ===');

      // Test 1: Check if Firebase is initialized
      try {
        final app = Firebase.app();
        print('✓ Firebase app: ${app.name}');
        setState(() {
          _status = 'SUCCESS: Firebase app initialized (${app.name})';
        });
      } catch (e) {
        print('✗ Firebase app error: $e');
        setState(() {
          _status = 'ERROR: Firebase app not initialized - $e';
        });
      }
    } catch (e) {
      print('✗ Basic Firebase test error: $e');
      setState(() {
        _status = 'ERROR: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthInstance() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Auth instance...';
    });

    try {
      print('=== AUTH INSTANCE TEST ===');

      // Test 1: Get Auth instance
      print('Step 1: Getting Firebase Auth instance');
      final auth = FirebaseAuth.instance;
      print('✓ Auth instance: $auth');

      // Test 2: Get current user
      print('Step 2: Getting current user');
      final user = auth.currentUser;
      print('✓ Current user: $user');

      setState(() {
        _status =
            'SUCCESS: Auth instance working (User: ${user?.uid ?? 'null'})';
      });
    } catch (e) {
      print('✗ Auth instance error: $e');
      print('Error type: ${e.runtimeType}');
      setState(() {
        _status = 'ERROR: Auth instance failed - $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthStream() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Auth stream...';
    });

    try {
      print('=== AUTH STREAM TEST ===');

      // Test 1: Get auth state changes stream
      print('Step 1: Getting auth state changes stream');
      final stream = FirebaseAuth.instance.authStateChanges();
      print('✓ Stream created: $stream');

      // Test 2: Listen to stream for a short time
      print('Step 2: Listening to stream...');
      final subscription = stream.listen(
        (user) {
          print('✓ Stream event: User = ${user?.uid ?? 'null'}');
        },
        onError: (error) {
          print('✗ Stream error: $error');
        },
      );

      // Wait a bit then cancel
      await Future.delayed(const Duration(seconds: 2));
      await subscription.cancel();
      print('✓ Stream test completed');

      setState(() {
        _status = 'SUCCESS: Auth stream working correctly';
      });
    } catch (e) {
      print('✗ Auth stream error: $e');
      print('Error type: ${e.runtimeType}');
      setState(() {
        _status = 'ERROR: Auth stream failed - $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
