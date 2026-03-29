import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'intro_screen.dart';
import '../../core/app_status.dart';
import '../maintenance/maintenance_screen.dart';
import '../../ads/remote_config_service.dart';
import '../../services/helper/background_task_service.dart';
import 'package:get/get.dart';
import '../../services/remote_config_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for smooth logo entry
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIntroStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkIntroStatus() async {
    // Smooth delay for branding
    await Future.delayed(const Duration(seconds: 2));

    // Wait for Remote Config to be ready
    final configController = Get.find<RemoteConfigController>();
    if (!configController.isInitialized.value) {
      await configController.isInitialized.stream.firstWhere((isReady) => isReady);
    }

    final prefs = await SharedPreferences.getInstance();
    final introSeen = prefs.getBool('intro_seen') ?? false;

    // Check Maintenance Mode
    final maintenanceMode = RemoteConfigService.getMaintenanceMode();
    AppStatus.isMaintenance = (maintenanceMode == 'on');

    // Resume Background Polling
    BackgroundTaskService.instance.resumeTasks();

    if (mounted) {
      if (AppStatus.isMaintenance) {
        // Destroy entire navigation stack so no back-leaks are possible
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
          (route) => false,
        );
        return;
      }

      if (introSeen) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const IntroScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle pattern or clean white
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium App Logo Look
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome, // Modern AI/Decor icon
                      size: 80,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name with Modern Spacing
                  const Text(
                    'AI DECOR',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transform your space',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Loading / Branding
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurpleAccent,
                      ),
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
