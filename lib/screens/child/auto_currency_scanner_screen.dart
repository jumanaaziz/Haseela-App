import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AutoCurrencyScannerScreen extends StatefulWidget {
  final Function(double) onAmountDetected;

  const AutoCurrencyScannerScreen({
    super.key,
    required this.onAmountDetected,
  });

  @override
  State<AutoCurrencyScannerScreen> createState() =>
      _AutoCurrencyScannerScreenState();
}

class _AutoCurrencyScannerScreenState extends State<AutoCurrencyScannerScreen> {
  // Camera
  CameraController? _cameraController;
  bool _isInitialized = false;

  // Detection state
  bool _isScanning = false;
  Timer? _scanTimer;
  String _statusMessage = 'Position currency in frame';
  Color _statusColor = Colors.white;

  // API credentials (same as your HomeScreen)
  static const String _sightengineUser = '209062856';
  static const String _sightengineSecret = '8ujGHfdeRzqJevsGymCThN4zFy3DeBxL';
  static const String _roboflowApiKey = 'VMf2fKPJgmup0N31XCxN';
  static const String _roboflowModelId = 'saudi_currencies-4ipct/5';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No camera found on this device');
        return;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startAutoScanning();
      }
    } catch (e) {
      print('❌ Camera initialization error: $e');
      _showError('Failed to initialize camera: $e');
    }
  }

  void _startAutoScanning() {
    // Scan every 1.5 seconds automatically
    _scanTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      if (_isInitialized && !_isScanning && mounted) {
        _performScan();
      }
    });
  }

  Future<void> _performScan() async {
    if (_isScanning || !_isInitialized || _cameraController == null) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning...';
      _statusColor = Color(0xFFFFA500);
    });

    try {
      // Capture current frame
      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      print('📸 Frame captured: ${file.path}');

      // Step 1: Check if money exists with SightEngine
      setState(() {
        _statusMessage = 'Checking for currency...';
      });

      final bool containsMoney = await _detectMoneyWithSightEngine(file);

      if (!containsMoney) {
        setState(() {
          _statusMessage = 'No currency detected';
          _statusColor = Color(0xFFFF6A5D);
          _isScanning = false;
        });
        
        // Auto-reset status after 1 second
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Position currency in frame';
              _statusColor = Colors.white;
            });
          }
        });
        return;
      }

      // Step 2: Detect amount with Roboflow
      setState(() {
        _statusMessage = 'Reading amount...';
      });

      final double? amount = await _extractAmountWithRoboflow(file);

      if (amount == null || amount <= 0) {
        setState(() {
          _statusMessage = 'Cannot read amount - adjust position';
          _statusColor = Color(0xFFFFA500);
          _isScanning = false;
        });
        
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _statusMessage = 'Position currency in frame';
              _statusColor = Colors.white;
            });
          }
        });
        return;
      }

      // SUCCESS - Stop scanning and show confirmation
      _scanTimer?.cancel();
      
      setState(() {
        _statusMessage = '${amount.toStringAsFixed(0)} SAR detected!';
        _statusColor = Color(0xFF47C272);
        _isScanning = false;
      });

      // Show confirmation dialog
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        _showConfirmationDialog(amount);
      }

    } catch (e) {
      print('❌ Scan error: $e');
      setState(() {
        _statusMessage = 'Scan failed - please try again';
        _statusColor = Color(0xFFFF6A5D);
        _isScanning = false;
      });
      
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _statusMessage = 'Position currency in frame';
            _statusColor = Colors.white;
          });
        }
      });
    }
  }

  Future<bool> _detectMoneyWithSightEngine(File file) async {
    try {
      print('🔍 SightEngine: Checking for money...');

      final Uri uri = Uri.parse('https://api.sightengine.com/1.0/check.json');

      var request = http.MultipartRequest('POST', uri);
      request.fields['models'] = 'money';
      request.fields['api_user'] = _sightengineUser;
      request.fields['api_secret'] = _sightengineSecret;
      request.files.add(await http.MultipartFile.fromPath('media', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        print('❌ SightEngine failed: ${response.statusCode}');
        return false;
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse.containsKey('money')) {
        final moneyData = jsonResponse['money'];
        if (moneyData is Map && moneyData.containsKey('prob')) {
          final double probability = (moneyData['prob'] ?? 0.0).toDouble();
          print('💰 Money probability: ${(probability * 100).toStringAsFixed(1)}%');
          return probability > 0.5;
        }
      }

      return false;
    } catch (e) {
      print('❌ SightEngine error: $e');
      return false;
    }
  }

  Future<double?> _extractAmountWithRoboflow(File file) async {
    try {
      print('🔍 Roboflow: Detecting amount...');

      final List<int> imageBytes = await file.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final Uri uri = Uri.parse(
        'https://detect.roboflow.com/$_roboflowModelId'
        '?api_key=$_roboflowApiKey'
        '&confidence=50'
        '&overlap=30',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      );

      if (response.statusCode != 200) {
        print('❌ Roboflow failed: ${response.statusCode}');
        return null;
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final predictions = jsonResponse['predictions'] as List?;

      if (predictions == null || predictions.isEmpty) {
        print('⚠️ No predictions found');
        return null;
      }

      List<Map<String, dynamic>> validDetections = [];

      for (var prediction in predictions) {
        final String className =
            (prediction['class'] as String?)?.toLowerCase() ?? '';
        final double confidence = (prediction['confidence'] ?? 0).toDouble();
        final double? amount = _extractAmountFromClassName(className);

        if (amount != null && amount > 0 && confidence >= 0.5) {
          validDetections.add({
            'amount': amount,
            'confidence': confidence,
          });
        }
      }

      if (validDetections.isEmpty) return null;

      // Sort by confidence
      validDetections.sort(
          (a, b) => (b['confidence'] as double).compareTo(a['confidence']));

      final double detectedAmount = validDetections.first['amount'];
      print('✅ Amount detected: $detectedAmount SAR');

      return detectedAmount;
    } catch (e) {
      print('❌ Roboflow error: $e');
      return null;
    }
  }

  double? _extractAmountFromClassName(String className) {
    if (className.isEmpty) return null;

    String cleaned = className.toLowerCase().trim();

    final Map<String, double> textToNumber = {
      'one': 1.0,
      'five': 5.0,
      'ten': 10.0,
      'fifty': 50.0,
      'hundred': 100.0,
      'fivehundred': 500.0,
      'five hundred': 500.0,
      '1': 1.0,
      '5': 5.0,
      '10': 10.0,
      '50': 50.0,
      '100': 100.0,
      '500': 500.0,
    };

    cleaned = cleaned
        .replaceAll('riyal', '')
        .replaceAll('riyals', '')
        .replaceAll('sar', '')
        .replaceAll('sr', '')
        .replaceAll('saudi', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('  ', ' ')
        .trim();

    for (var entry in textToNumber.entries) {
      if (cleaned == entry.key || cleaned.contains(entry.key)) {
        final amount = entry.value;
        if (_isValidSaudiDenomination(amount)) {
          return amount;
        }
      }
    }

    final RegExp numberPattern = RegExp(r'(\d+)');
    final match = numberPattern.firstMatch(cleaned);

    if (match != null) {
      final String numStr = match.group(1)!;
      final double? amount = double.tryParse(numStr);

      if (amount != null && _isValidSaudiDenomination(amount)) {
        return amount;
      }
    }

    return null;
  }

  bool _isValidSaudiDenomination(double amount) {
    const validDenominations = [1.0, 5.0, 10.0, 50.0, 100.0, 500.0];
    return validDenominations.contains(amount);
  }

  void _showConfirmationDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF47C272), size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              'Currency Detected!',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Color(0xFF47C272).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text(
                    'Detected Amount',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color(0xFF718096),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${amount.toStringAsFixed(0)} SAR',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF47C272),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Add this to your wallet?',
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF1C1243),
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Restart scanning
              setState(() {
                _statusMessage = 'Position currency in frame';
                _statusColor = Colors.white;
              });
              _startAutoScanning();
            },
            child: Text(
              'Scan Again',
              style: TextStyle(
                color: Color(0xFF718096),
                fontFamily: 'SF Pro Text',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onAmountDetected(amount);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF47C272),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Confirm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(0xFFFF6A5D),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF47C272)),
                  SizedBox(height: 16.h),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),

          // Scanning Overlay
          if (_isInitialized)
            CustomPaint(
              painter: ScannerOverlayPainter(isScanning: _isScanning),
              child: SizedBox.expand(),
            ),

          // Close Button
          Positioned(
            top: 50.h,
            left: 20.w,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),

          // Status Message
          Positioned(
            top: 50.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isScanning)
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_statusColor),
                        ),
                      ),
                    if (_isScanning) SizedBox(width: 8.w),
                    Icon(
                      _isScanning ? Icons.search : Icons.camera_alt,
                      color: _statusColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 40.h,
            left: 20.w,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF47C272), size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Auto-scanning every 1.5 seconds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '• Hold currency flat in frame\n'
                    '• Ensure good lighting\n'
                    '• Keep camera steady',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      height: 1.4,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Scanner Overlay Painter
class ScannerOverlayPainter extends CustomPainter {
  final bool isScanning;

  ScannerOverlayPainter({required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Scanning frame
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.4,
    );

    // Draw overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Frame border
    final borderPaint = Paint()
      ..color = isScanning ? Color(0xFF47C272) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, Radius.circular(16)),
      borderPaint,
    );

    // Corner indicators
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = isScanning ? Color(0xFF47C272) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
        Offset(frameRect.left, frameRect.top + cornerLength),
        Offset(frameRect.left, frameRect.top),
        cornerPaint);
    canvas.drawLine(Offset(frameRect.left, frameRect.top),
        Offset(frameRect.left + cornerLength, frameRect.top), cornerPaint);

    // Top-right
    canvas.drawLine(
        Offset(frameRect.right - cornerLength, frameRect.top),
        Offset(frameRect.right, frameRect.top),
        cornerPaint);
    canvas.drawLine(Offset(frameRect.right, frameRect.top),
        Offset(frameRect.right, frameRect.top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(
        Offset(frameRect.left, frameRect.bottom - cornerLength),
        Offset(frameRect.left, frameRect.bottom),
        cornerPaint);
    canvas.drawLine(Offset(frameRect.left, frameRect.bottom),
        Offset(frameRect.left + cornerLength, frameRect.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(
        Offset(frameRect.right - cornerLength, frameRect.bottom),
        Offset(frameRect.right, frameRect.bottom),
        cornerPaint);
    canvas.drawLine(
        Offset(frameRect.right, frameRect.bottom - cornerLength),
        Offset(frameRect.right, frameRect.bottom),
        cornerPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return oldDelegate.isScanning != isScanning;
  }
}