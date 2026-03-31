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

enum FeatureType {
  interior('interior'),
  exterior('exterior'),
  garden('garden'),
  chatbot('chatbot'),
  objectRemove('object_remove'),
  objectReplace('object_replace'),
  object2dTo3d('object_2d_to_3d'),
  styleTransfer('style_transfer'),
  floorPlan('floor_plan'),
  videoGeneration('video_generation'),
  imageGeneration('image_generation');

  final String suffix;
  const FeatureType(this.suffix);

  String get kieKey => 'kie_api_key_$suffix';
  String get apiFreeKey => 'apifree_key_$suffix';
  String get enabledKey => '${suffix}_enabled';
}

class RemoteConfigService {
  static FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;

  static Map<String, dynamic>? _cachedJson;

  static Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      await _remoteConfig.fetchAndActivate();
      _cachedJson = null;

      _remoteConfig.onConfigUpdated.listen((event) async {
        await _remoteConfig.activate();
        _cachedJson = null;
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
      _cachedJson = null;
    } catch (e) {
      debugPrint('🔥 RemoteConfig: Refresh failed: $e');
    }
  }

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

  // 🛠️ FEATURE STATUS & ENABLING
  static String getFeatureStatus(FeatureType feature) {
    final key = feature.enabledKey;
    final topLevel = _remoteConfig.getString(key);
    if (topLevel.isNotEmpty) return topLevel;
    return _json()[key]?.toString() ?? '1';
  }

  static bool isFeatureEnabled(FeatureType feature) {
    final status = getFeatureStatus(feature);
    // "11" means hidden/disabled, everything else (especially "1") is enabled
    return status != '11';
  }

  // 🛠️ API KEYS (New Methods)
  static String getKieApiKey(FeatureType feature) {
    final key = feature.kieKey;
    final topLevel = _remoteConfig.getString(key);
    if (topLevel.isNotEmpty) return topLevel;
    return _json()[key]?.toString() ?? _json()['kie_api_key']?.toString() ?? '';
  }

  static String getApiFreeKey(FeatureType feature) {
    final key = feature.apiFreeKey;
    final topLevel = _remoteConfig.getString(key);
    if (topLevel.isNotEmpty) return topLevel;
    return _json()[key]?.toString() ?? _json()['apifree_key']?.toString() ?? '';
  }

  // 📱 AD IDs
  static String getNativeAdId() => _json()['nativeAd_id']?.toString() ?? '';
  static String getInterstitialAdId() => _json()['interstitialAd_id']?.toString() ?? '';
  static String getRewardedAdId() => _json()['rewardAd_id']?.toString() ?? '';
  static String getCollapsiveBannerAdId() {
    final topLevel = _remoteConfig.getString('collapsive_bannerAd_id');
    if (topLevel.isNotEmpty) return topLevel;
    return _json()['collapsive_bannerAd_id']?.toString() ?? '';
  }

  // 📺 REEL ADS
  static String getNativeReelAdId() {
    final adId = _json()['nativeAd_reelAd_id']?.toString() ?? '';
    // Use test id if not defined, unless "11" (disabled)
    if (adId.isEmpty) return "11";
    return adId;
  }

  static int getReelAdFrequency() {
    return _json()['native_reel_frequency'] ?? 2;
  }

  static bool isAdsGloballyDisabled() {
    final config = _json();
    return config['nativeAd_id']?.toString() == '11' || config['interstitialAd_id']?.toString() == '11';
  }

  static bool isReelAdsDisabled() {
    return getNativeReelAdId() == "11";
  }

  // 📊 AD FREQUENCY
  static int getInterstitialFrequency() => _json()['interstitial_frequency'] ?? 1;

  static String getInteriorProviderSelection() {
    final topLevel = _remoteConfig.getString('interior_provider_selection');
    if (topLevel.isNotEmpty) return topLevel;
    return _json()['interior_provider_selection']?.toString() ?? 'apifree';
  }

  static String getMaintenanceMode() {
    final topLevel = _remoteConfig.getString('maintenance_mode');
    if (topLevel.isNotEmpty) return topLevel;
    return _json()['maintenance_mode']?.toString() ?? 'off';
  }

  // 🪙 DAILY CREDIT
  static int getDailyCredit() => _json()['daily_credit'] ?? 0;
}
