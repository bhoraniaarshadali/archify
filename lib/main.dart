// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:project_home_decor/services/helper/settings_service.dart';
// import 'screens/onboarding/splash_screen.dart';
// import 'ads/ad_manager.dart';
// import 'ads/remote_config_service.dart';
// import 'ads/app_state.dart';
// import 'navigation/app_navigator.dart';
// import 'firebase_options.dart';
//
// import 'services/helper/background_generation_manager.dart';
//
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     debugPrint('🔥 Firebase initialized');
//
//     await RemoteConfigService.init();
//     debugPrint('🔥 Remote Config loaded');
//
//     // ⚡ PERFORMANCE: Defer ads initialization to avoid blocking UI
//     // Ads will be initialized asynchronously after app starts
//     Future.delayed(const Duration(milliseconds: 500), () {
//       AdsManager.instance.init().then((_) {
//         debugPrint('📢 Ads initialized (deferred)');
//       });
//     });
//
//     await AppState.init();
//     debugPrint('App State loaded');
//
//     await SettingsService.instance.init();
//     debugPrint('⚙️ Settings initialized');
//
//     await BackgroundGenerationManager.instance.init();
//     debugPrint('🚀 Background Manager initialized');
//
//     // Resume tasks once on app start
//     BackgroundGenerationManager.instance.resumeAllPendingTasks();
//
//   } catch (e) {
//     debugPrint('[ERROR] ❌ Initialization failed: $e');
//   }
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       debugPrint('📱 App Resumed: Checking for pending tasks...');
//       BackgroundGenerationManager.instance.resumeAllPendingTasks();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: AppNavigator.navigatorKey,
//       title: 'Archify',
//
//       debugShowCheckedModeBanner: false,
//       themeMode: ThemeMode.light,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         brightness: Brightness.light,
//         scaffoldBackgroundColor: const Color(0xFFF8F9FC),
//         cardColor: Colors.white,
//         dividerColor: Colors.grey.shade100,
//         iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
//         textTheme: const TextTheme(
//           titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
//           titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
//           bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
//           bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
//         ),
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project_home_decor/services/helper/settings_service.dart';
import 'screens/onboarding/splash_screen.dart';
import 'ads/ad_manager.dart';
import 'ads/remote_config_service.dart';
import 'ads/app_state.dart';
import 'navigation/app_navigator.dart';
import 'firebase_options.dart';
import 'services/helper/background_generation_manager.dart';
import 'services/helper/background_task_service.dart';
import 'services/premium/billing_service.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/credit_controller.dart';
import 'services/remote_config_controller.dart';
import 'services/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseFailed = false;

  /// 🔥 STEP 1: Firebase Initialization (Isolated)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialized');
  } catch (e) {
    firebaseFailed = true;
    debugPrint('[ERROR] ❌ Firebase initialization failed: $e');
  }

  /// 🚀 STEP 2: Initialize other services only if Firebase is OK
  if (!firebaseFailed) {
    try {
      await RemoteConfigService.init();
      
      await Future.wait([
        AppState.init(),
        SettingsService.instance.init(),
        BackgroundGenerationManager.instance.init(),
      ]);

      // 💳 Initialize Billing (Disabled - Switched to RevenueCat)
      // BillingService().init();

      // 💎 Initialize GetX Controllers & RevenueCat
      Get.put(CreditController());
      Get.put(RemoteConfigController());
      AppConfig.premiumInit();
      await AppConfig.configureSDK();

      debugPrint('✅ Core services initialized');

      // Resume background tasks once on startup
      BackgroundTaskService.instance.resumeTasks();

      // ⚡ PERFORMANCE: Defer ads initialization
      Future.delayed(const Duration(milliseconds: 500), () {
        AdsManager.instance.init().then((_) {
          debugPrint('📢 Ads initialized (deferred)');
        });
      });

    } catch (e) {
      debugPrint('[ERROR] ❌ Secondary services failed: $e');
    }
  }

  runApp(MyApp(firebaseError: firebaseFailed));
}

class MyApp extends StatefulWidget {
  final bool firebaseError;

  const MyApp({super.key, required this.firebaseError});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 🔄 Resume pending AI tasks when app returns
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !widget.firebaseError) {
      debugPrint('📱 App Resumed: Checking for pending tasks...');
      BackgroundTaskService.instance.resumeTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          title: 'Archify',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FC),
            cardColor: Colors.white,
            dividerColor: Colors.grey.shade100,
            iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
            textTheme: const TextTheme(
              titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
              titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
              bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
              bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
            ),
          ),
          home: widget.firebaseError
              ? const FirebaseErrorScreen()
              : const SplashScreen(),
        );
      },
    );
  }
}

/// 🛑 Simple Firebase Error Screen
class FirebaseErrorScreen extends StatelessWidget {
  const FirebaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Service Unavailable',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We are unable to connect to required services right now.\nPlease check your internet connection and restart the app.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

