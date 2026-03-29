import 'package:flutter/material.dart';
import '../ads/ad_manager.dart';
import '../ads/app_state.dart';
import '../ads/remote_config_service.dart';

/// Central navigation helper that manages ad display based on Remote Config.
///
/// All screens should use `AppNavigator.push(...)`, `AppNavigator.pop(...)`
/// instead of calling `Navigator` directly. This ensures consistent ad frequency logic.
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Navigation counter for frequency-based interstitials
  static int _navigationCount = 0;


  // ========== Public Navigation Methods ==========

  /// Standard push navigation with ad support
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page,
  ) async {
    _incrementCounter();
    _maybeShowInterstitial();
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  /// Push with custom route
  static Future<T?> pushRoute<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) async {
    _incrementCounter();
    _maybeShowInterstitial();
    return Navigator.of(context).push<T>(route);
  }

  /// Push replacement navigation with ad support
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page,
  ) async {
    _incrementCounter();
    _maybeShowInterstitial();
    return Navigator.of(
      context,
    ).pushReplacement<T, TO>(MaterialPageRoute(builder: (_) => page));
  }

  /// Pop navigation with ad support
  static void pop(BuildContext context, [Object? result]) {
    _incrementCounter();
    _maybeShowInterstitial();
    Navigator.of(context).pop(result);
  }

  /// Manually trigger ad check (e.g., for tab changes)
  static Future<void> checkAndShowAd() async {
    _incrementCounter();
    await _maybeShowInterstitial();
  }

  // ========== Internal Logic ==========

  static void _incrementCounter() {
    _navigationCount++;
  }

  /// Checks all conditions and shows interstitial if appropriate
  static Future<void> _maybeShowInterstitial() async {
    // 1. Premium users never see ads
    if (AppState.isPremiumUser) {
      debugPrint('Ad skipped: Premium user');
      return;
    }

    // 2. Manually disabled by user
    if (!AppState.adsAllowedManually) {
      debugPrint('Ad skipped: Manually disabled');
      return;
    }

    // 3. Global kill switch - ad ID = '11' disables all ads
    if (RemoteConfigService.isAdsGloballyDisabled()) {
      debugPrint('Ad skipped: Globally disabled (Remote Config)');
      return;
    }

    // 4. Frequency logic - 0 means show every time, >0 means skip N navigations
    final freq = RemoteConfigService.getInterstitialFrequency();

    if (freq < 0) {
      debugPrint('Ad skipped: Invalid frequency ($freq)');
      return;
    }

    // freq=0 → show every time (mod 1)
    // freq=1 → show every 2nd (mod 2)
    // freq=2 → show every 3rd (mod 3)
    final modValue = freq + 1;

    if (_navigationCount % modValue != 0) {
      debugPrint(
        'Ad skipped: Frequency check ($_navigationCount % $modValue != 0)',
      );
      return;
    }

    // 5. All checks passed - show ad
    debugPrint(
      'Showing interstitial ad (count: $_navigationCount, freq: $freq)',
    );

    if (!AdsManager.instance.initialized) {
      await AdsManager.instance.init();
    }

    AdsManager.instance.showInterstitialIfAvailable();
  }
}
