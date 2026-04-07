import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../services/remote_config_controller.dart';

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
  String get costKey => '${suffix}_cost';
}

class RemoteConfigService {
  static FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;
  static Map<String, dynamic> _configData = {};

  static Future<void> init() async {
    try {
      debugPrint('🔥 RemoteConfig: Starting initialization...');
      
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      // 1. Set Defaults
      await _remoteConfig.setDefaults({
        "v1_home_decor": jsonEncode({
          "maintenance_mode": "off",
          "daily_credit": 1,
          "interstitial_frequency": 5,
          "native_reel_frequency": 4,
          "nativeAd_introAd_id": "ca-app-pub-3940256099942544/2247696110",
          "interstitialAd_id": "ca-app-pub-3940256099942544/1033173712",
          "rewardAd_id": "ca-app-pub-3940256099942544/5224354917",
          "collapsive_bannerAd_id": "ca-app-pub-3940256099942544/9214589741",
          "premium": {
            "credit_1_plan": 31,
            "credit_2_plan": 71,
            "credit_3_plan": 166,
            "credit_4_plan": 401,
            "credit_5_plan": 861,
            "credit_6_plan": 901,
            "weekly_plan": 299,
            "yearly_plan": 899
          }
        }),
      });

      // 2. Initial Fetch
      await _remoteConfig.fetchAndActivate();
      _parseConfig();

      // 3. Fallback Retry if important keys are still default (valueSource check)
      if (_remoteConfig.getValue('v1_home_decor').source == ValueSource.valueDefault) {
        debugPrint('⚠️ v1_home_decor still Default. Retrying forced fetch...');
        await Future.delayed(const Duration(seconds: 2));
        await _remoteConfig.fetchAndActivate();
        _parseConfig();
      }

      final source = _remoteConfig.getValue('v1_home_decor').source;
      debugPrint('🔥 RemoteConfig: Initialized. Source of [v1_home_decor]: $source');

      _remoteConfig.onConfigUpdated.listen((event) async {
        await _remoteConfig.activate();
        _parseConfig();
        debugPrint('🔥 RemoteConfig: Real-time update activated and parsed');
      });

    } catch (e) {
      debugPrint('🔥 RemoteConfig: Init failed: $e');
    }
  }

  static void _parseConfig() {
    try {
      final jsonString = _remoteConfig.getString('v1_home_decor');
      debugPrint('🔥 RemoteConfig [v1_home_decor] raw string: $jsonString');
      if (jsonString.isNotEmpty) {
        _configData = jsonDecode(jsonString);
        debugPrint('🔥 RemoteConfig: Successfully parsed v1_home_decor keys: ${_configData.keys.toList()}');
      } else {
        debugPrint('⚠️ RemoteConfig: v1_home_decor is EMPTY!');
      }
    } catch (e) {
      debugPrint('❌ RemoteConfig: Failed to parse v1_home_decor: $e');
    }
  }

  static Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _parseConfig();
    } catch (e) {
      debugPrint('🔥 RemoteConfig: Refresh failed: $e');
    }
  }

  // 🛠️ GENERIC GETTERS (Support Nested JSON Structure)
  static dynamic _get(String key) => _configData[key];

  static String getString(String key, {String defaultValue = ''}) {
    final val = _get(key);
    // 💡 ONLY return from blob if it exists AND is not an empty string
    if (val != null && val.toString().isNotEmpty) return val.toString();
    
    // Fallback to top-level individual key if exists
    final topLevel = _remoteConfig.getString(key);
    return topLevel.isNotEmpty ? topLevel : defaultValue;
  }

  static int getInt(String key, {int defaultValue = 0}) {
    final val = _get(key);
    if (val != null) {
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? defaultValue;
    }
    final topLevel = _remoteConfig.getInt(key);
    if (topLevel != 0) return topLevel;
    return int.tryParse(_remoteConfig.getString(key)) ?? defaultValue;
  }

  static double getDouble(String key, {double defaultValue = 0.0}) {
    final val = _get(key);
    if (val != null) {
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? defaultValue;
    }
    final topLevel = _remoteConfig.getDouble(key);
    if (topLevel != 0.0) return topLevel;
    return double.tryParse(_remoteConfig.getString(key)) ?? defaultValue;
  }

  // 🛠️ FEATURE STATUS & ENABLING
  static bool isFeatureEnabled(FeatureType feature) {
    final val = getString(feature.enabledKey);
    return val != '11' && val != '0' && val.isNotEmpty;
  }

  static double getFeatureCost(FeatureType feature) {
    return getDouble(feature.costKey, defaultValue: 1.0);
  }

  // 🛠️ API KEYS
  static String getKieApiKey(FeatureType feature) {
    return getString(feature.kieKey, defaultValue: getString('kie_api_key_video_generate'));
  }

  static String getApiFreeKey(FeatureType feature) {
    return getString(feature.apiFreeKey);
  }

  // 📱 AD IDs
  static String getNativeAdId() => getString('nativeAd_introAd_id');
  static String getHomeNativeAdId() => getString('nativeAd_homeAd_id');
  static String getAssistNativeAdId() => getString('nativeAd_assistAd_id');

  static String getInterstitialAdId() => getString('interstitialAd_id');
  static String getRewardedAdId() => getString('rewardAd_id');
  static String getCollapsiveBannerAdId() => getString('collapsive_bannerAd_id');
  static String getNativeReelAdId() => getString('nativeAd_reelAd_id', defaultValue: getString('nativeAd_id'));

  // 📊 AD FREQUENCY
  static int getInterstitialFrequency() => getInt('interstitial_frequency', defaultValue: 5);
  static int getReelAdFrequency() => getInt('native_reel_frequency', defaultValue: 4);

  static bool isAdsGloballyDisabled() {
    return !shouldShowAdsGlobally() || !shouldShowAd(getNativeAdId()) || !shouldShowAd(getInterstitialAdId());
  }

  static bool isReelAdsDisabled() {
    if (!shouldShowAdsGlobally()) return true;
    return !shouldShowAd(getNativeReelAdId());
  }

  static bool shouldShowAd(String id) {
    return id.isNotEmpty && id != "11";
  }

  static bool shouldShowAdsGlobally() {
    if (AdsVariable.isPurchase) return false;
    return true;
  }

  static String getInteriorProviderSelection() => getString('interior_provider_selection', defaultValue: 'apifree');

  /// 💰 Retrieves credit plan values from the "premium" map inside the JSON.
  static int getPlanCredits(String planKey, int defaultValue) {
    try {
      final premiumMap = _get('premium');
      if (premiumMap != null && premiumMap is Map) {
        final val = premiumMap[planKey];
        if (val != null) {
          if (val is int) return val;
          return int.tryParse(val.toString()) ?? defaultValue;
        }
      }
    } catch (e) {
      debugPrint('⚠️ RemoteConfig Error ($planKey): $e');
    }
    return defaultValue;
  }

  static String getMaintenanceMode() => getString('maintenance_mode', defaultValue: 'off');
  
  static int getDailyCredit() => getInt('daily_credit', defaultValue: 1);
}
