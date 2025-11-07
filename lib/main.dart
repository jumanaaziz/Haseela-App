import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/auth_wrapper.dart';
import 'screens/utils/seed_dummy_data.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Enable Firebase Performance collection even in debug
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  // ✅ Create a trace for overall app response time
  final overallTrace = FirebasePerformance.instance.newTrace(
    "overall_response_time",
  );
  await overallTrace.start();
  debugPrint("🚀 overall_response_time trace started...");

  // Optional: load any data you want to include in the response measurement
  // (like preloading Firestore user data, preferences, etc.)
  // await seedDummyDataForNouf();

  runApp(
    MyApp(
      onFirstFrameRendered: () async {
        // Stop trace after first frame (UI is ready)
        await overallTrace.stop();
        debugPrint("✅ overall_response_time trace stopped.");
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final Future<void> Function()? onFirstFrameRendered;
  const MyApp({super.key, this.onFirstFrameRendered});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'SPProText'),
          home: _RootWrapper(onFirstFrameRendered: onFirstFrameRendered),
        );
      },
    );
  }
}

// Helper widget to detect first frame rendering
class _RootWrapper extends StatefulWidget {
  final Future<void> Function()? onFirstFrameRendered;
  const _RootWrapper({this.onFirstFrameRendered});

  @override
  State<_RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<_RootWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.onFirstFrameRendered != null) {
        await widget.onFirstFrameRendered!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AuthWrapper();
  }
}
