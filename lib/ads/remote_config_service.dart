// import 'dart:convert';
//
// import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:flutter/foundation.dart';
//
// class RemoteConfigService {
//   static FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;
//
//   static Future<void> init() async {
//     try {
//       await _remoteConfig.setConfigSettings(
//         RemoteConfigSettings(
//           fetchTimeout: const Duration(seconds: 10),
//           // Set to zero to fetch on every app start/resume
//           minimumFetchInterval: const Duration(seconds: 0),
//         ),
//       );
//       await _remoteConfig.fetchAndActivate();
//       debugPrint('🔥 RemoteConfig: Initialized successfully');
//     } catch (e) {
//       debugPrint('🔥 RemoteConfig: Init failed (offline?): $e');
//       // Continue with cached/default values
//     }
//   }
//
//   // Public method to manually refresh remote config values
//   static Future<void> refresh() async {
//     try {
//       await _remoteConfig.fetchAndActivate();
//     } catch (e) {
//       debugPrint('🔥 RemoteConfig: Refresh failed (offline?): $e');
//       // Keep using cached values
//     }
//   }
//
//   static Map<String, dynamic> _json() {
//     try {
//       final String jsonString = _remoteConfig.getString('v1_home_decor');
//
//       if (jsonString.isEmpty) {
//         return {};
//       }
//       return jsonDecode(jsonString);
//     } catch (e) {
//       debugPrint('🔥 RemoteConfig parse error: $e');
//       return {};
//     }
//   }
//
//   // 📱 AD IDs
//   static String getNativeAdId() {
//     return _json()['nativeAd_id']?.toString() ?? '';
//   }
//
//   static String getInterstitialAdId() {
//     return _json()['interstitialAd_id']?.toString() ?? '';
//   }
//
//   static String getRewardedAdId() {
//     return _json()['rewardAd_id']?.toString() ?? '';
//   }
//
//   static bool isAdsGloballyDisabled() {
//     final nativeId = getNativeAdId();
//     final interstitialId = getInterstitialAdId();
//     return nativeId == '11' || interstitialId == '11';
//   }
//
//   // 📊 AD FREQUENCY
//   static int getInterstitialFrequency() {
//     return _json()['interstitial_frequency'] ?? 1;
//   }
//
//   // 🛠️ API KEYS
//   static String getKieApiKey() {
//     return _json()['kie_api_key']?.toString() ?? '';
//   }
//
//   static String getApiFreeKey() {
//     return _json()['apifree_key']?.toString() ?? '';
//   }
//
//   static String getMaintenanceMode() {
//     // Check both as top-level and inside the JSON map for flexibility
//     final topLevel = _remoteConfig.getString('maintenance_mode');
//     if (topLevel.isNotEmpty) return topLevel;
//
//     return _json()['maintenance_mode']?.toString() ?? 'off';
//   }
// }


import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;

  // ⚡ PERFORMANCE: JSON parsing is expensive, so we cache it.
  static Map<String, dynamic>? _cachedJson;

  static Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // 🚀 PRODUCTION: 1 hour interval, DEBUG: 0 for instant testing
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      // Initial fetch
      await _remoteConfig.fetchAndActivate();

      // Clear cache to ensure fresh data after fetch
      _cachedJson = null;

      // 🔥 REAL-TIME: Listen for config updates while the app is running
      _remoteConfig.onConfigUpdated.listen((event) async {
        await _remoteConfig.activate();
        _cachedJson = null; // Reset cache on update
        debugPrint('🔥 RemoteConfig: Real-time update activated');
      });

      debugPrint('🔥 RemoteConfig: Initialized successfully');
    } catch (e) {
      debugPrint('🔥 RemoteConfig: Init failed: $e');
    }
  }

  static Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _cachedJson = null; // Clear cache on manual refresh
    } catch (e) {
      debugPrint('🔥 RemoteConfig: Refresh failed: $e');
    }
  }

  /// Private helper to get decoded JSON with caching logic
  static Map<String, dynamic> _json() {
    if (_cachedJson != null) return _cachedJson!;

    try {
      final String jsonString = _remoteConfig.getString('v1_home_decor');
      if (jsonString.isEmpty) return {};

      _cachedJson = jsonDecode(jsonString);
      return _cachedJson!;
    } catch (e) {
      debugPrint('🔥 RemoteConfig parse error: $e');
      return {};
    }
  }

  // 📱 AD IDs
  static String getNativeAdId() => _json()['nativeAd_id']?.toString() ?? '';
  static String getInterstitialAdId() => _json()['interstitialAd_id']?.toString() ?? '';
  static String getRewardedAdId() => _json()['rewardAd_id']?.toString() ?? '';

  static bool isAdsGloballyDisabled() {
    final config = _json();
    final nativeId = config['nativeAd_id']?.toString();
    final interstitialId = config['interstitialAd_id']?.toString();

    // Check for '11' flag or explicit disabled boolean if you add it later
    return nativeId == '11' || interstitialId == '11';
  }

  // 📊 AD FREQUENCY
  static int getInterstitialFrequency() => _json()['interstitial_frequency'] ?? 1;

  // 🛠️ API KEYS
  static String getKieApiKey() {
    final topLevel = _remoteConfig.getString('kie_api_key');
    if (topLevel.isNotEmpty) return topLevel;
    return _json()['kie_api_key']?.toString() ?? '';
  }

  static String getInteriorProviderSelection() {
    final topLevel = _remoteConfig.getString('interior_provider_selection');
    if (topLevel.isNotEmpty) return topLevel;
    return _json()['interior_provider_selection']?.toString() ?? 'apifree';
  }
  
  static String getApiFreeKey() => _json()['apifree_key']?.toString() ?? '';

  static String getMaintenanceMode() {
    final topLevel = _remoteConfig.getString('maintenance_mode');
    if (topLevel.isNotEmpty) return topLevel;

    return _json()['maintenance_mode']?.toString() ?? 'off';
  }

  // 🪙 DAILY CREDIT
  static int getDailyCredit() => _json()['daily_credit'] ?? 0;
}