import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../services/helper/my_creations_service.dart';
import '../creations/my_creations_screen.dart';
import '../explore/explore_screen.dart';
import 'ai_tools_dashboard.dart';
import '../../widgets/daily_credit_badge.dart';

import '../assistants/assistants_screen.dart';
import '../premium/premium_module_screen.dart';
import '../settings/settings_screen.dart';
import '../../navigation/app_navigator.dart';
import '../../ads/app_state.dart';
import '../../ads/remote_config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color kAccentColor = Color(0xFF000000);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _bottomNavAnim;

  // Use a List of widgets to maintain state via IndexedStack
  final List<Widget> _screens = const [
    _HomeWrapper(),
    AssistantsScreen(),
    ExploreScreen(),
    MyCreationsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Warm up creations cache for the notification dot
    MyCreationsService.getCreations();
    // Set system UI once, not in build()
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _bottomNavAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bottomNavAnim.forward();
  }

  @override
  void dispose() {
    _bottomNavAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnnotatedRegion is more efficient than calling SystemChrome inside build
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            _buildBottomFloatingTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomFloatingTabs() {
    final mq = MediaQuery.of(context);

    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        if (!AppState().showBottomNav) return const SizedBox.shrink();
        
        return FadeTransition(
          opacity: CurvedAnimation(parent: _bottomNavAnim, curve: Curves.easeIn),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20 + mq.padding.bottom,
              ),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: Row(
                  children: [
                    _navTab(0, "Home", CupertinoIcons.home),
                    if (RemoteConfigService.isFeatureEnabled(FeatureType.chatbot))
                      _navTab(1, "Assistants", CupertinoIcons.person_2),
                    _navTab(2, "Explore", CupertinoIcons.compass),
                    _navTab(3, "History", CupertinoIcons.time),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navTab(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedIndex = index);
          // Always ensure bottom nav is visible when switching main tabs
          // ExploreScreen will handle hiding it if needed
          AppState().setShowBottomNav(true);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? HomeScreen.kAccentColor : Colors.grey,
                ),
                if (index == 3)
                  ValueListenableBuilder<int>(
                    valueListenable: MyCreationsService.creationsChangeNotifier,
                    builder: (context, val, child) {
                      if (MyCreationsService.isVideoProcessingSync()) {
                        return Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? HomeScreen.kAccentColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeWrapper extends StatelessWidget {
  const _HomeWrapper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black, size: 22),
          onPressed: () => AppNavigator.push(context, const SettingsScreen()),
        ),
        title: const Text(
          'Archify',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        actions: [
          // PRO Button
          ListenableBuilder(
            listenable: AppState(),
            builder: (context, _) {
              if (AppState.isPremiumUser) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => AppNavigator.push(context, const PremiumModuleScreen()),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE2B029), Color(0xFFF1D483)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Center(child: DailyCreditBadge(themeColor: Colors.black)),
          const SizedBox(width: 16),
        ],
      ),
      body: const AiToolsDashboard(),
    );
  }
}