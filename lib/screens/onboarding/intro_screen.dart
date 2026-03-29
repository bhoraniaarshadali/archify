import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ads/ad_manager.dart';
import '../../ads/app_state.dart';
import '../../ads/nativeAds/native_ad_widget.dart';
import '../../ads/remote_config_service.dart';
import '../../services/helper/connectivity_service.dart';
import '../home/home_screen.dart';
import '../../navigation/app_navigator.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();

  bool get showAds =>
      !AppState.isPremiumUser &&
      AppState.adsAllowedManually &&
      !RemoteConfigService.isAdsGloballyDisabled() &&
      ConnectivityService().currentStatus;

  int currentIndex = 0;

  final List<String> images = [
    "assets/images/styles/exterior/modern.jpg",
    "assets/images/styles/interior/modern.jpg",
    "assets/images/styles/interior/luxury.jpg",
  ];

  final List<String> titles = [
    "AI Exterior Redesign",
    "Interior Transformation",
    "Realistic Style Swaps",
  ];

  final List<String> subtitles = [
    "Visualize your dream home exterior with powerful AI transformation in seconds.",
    "Change furniture, wall colors, and decor effortlessly with just one photo.",
    "Apply professional architectural styles to any building with amazing detail.",
  ];

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.isOnline.removeListener(
      _onConnectivityChanged,
    );
    _controller.dispose();
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: showAds ? 4 : 3,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemBuilder: (context, index) {
              if (showAds && index == 2) {
                return IntroAdPage(onNext: _handleNext);
              }
              final int realIndex = (showAds && index > 2) ? index - 1 : index;
              return IntroPage(
                image: images[realIndex],
                title: titles[realIndex],
                subtitle: subtitles[realIndex],
                currentIndex: currentIndex,
                showAds: showAds,
                onNext: _handleNext,
              );
            },
          ),
          
          // Global Skip Button
          if (!((showAds && currentIndex == 3) || (!showAds && currentIndex == 2)))
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: TextButton(
                onPressed: _completeIntro,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("intro_seen", true);
    if (!mounted) return;
    AppNavigator.pushReplacement(context, const HomeScreen());
  }

  Future<void> _handleNext() async {
    final bool last = showAds ? currentIndex == 3 : currentIndex == 2;
    if (!last) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeIntro();
    }
  }
}

class IntroPage extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final int currentIndex;
  final bool showAds;
  final VoidCallback onNext;

  const IntroPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.currentIndex,
    required this.showAds,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final bool isLast = showAds ? currentIndex == 3 : currentIndex == 2;
    final int dotIndex = (showAds && currentIndex > 2)
        ? currentIndex - 1
        : currentIndex;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full screen background image
        Image.asset(image, fit: BoxFit.cover),

        // Gradient overlay for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.1),
                Colors.white.withOpacity(0.8),
                Colors.white,
              ],
              stops: const [0.0, 0.4, 0.7, 0.9],
            ),
          ),
        ),

        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Dots(dotIndex),
              const SizedBox(height: 30),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              _NextButton(isLast: isLast, onTap: onNext),
            ],
          ),
        ),
      ],
    );
  }
}

class IntroAdPage extends StatelessWidget {
  final VoidCallback onNext;
  const IntroAdPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final adHelper = AdsManager.instance.nativeIntroAd;
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Full Screen Native Ad
            Positioned.fill(
              child: ListenableBuilder(
                listenable: adHelper,
                builder: (context, _) {
                  if (adHelper.isAdLoaded && adHelper.nativeAd != null) {
                    return NativeAdWidget(
                      nativeAd: adHelper.nativeAd!,
                      height: mq.height, // Full height ad
                    );
                  } else if (adHelper.lastError != null) {
                    return Center(
                      child: TextButton(
                        onPressed: () => adHelper.loadAd(null),
                        child: const Text("Retry loading ad"),
                      ),
                    );
                  } else {
                    adHelper.loadAd(null);
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int index;
  const _Dots(this.index);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          height: 6,
          width: index == i ? 30 : 12,
          decoration: BoxDecoration(
            color: index == i ? Colors.deepPurpleAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final bool isLast;
  final VoidCallback onTap;
  const _NextButton({required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: Text(
        isLast ? "Get Started" : "Continue",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
