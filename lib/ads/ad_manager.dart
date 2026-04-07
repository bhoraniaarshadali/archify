import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:get/get.dart';

import 'nativeAds/native_ad_helper.dart';
import 'remote_config_service.dart';

class AdsManager {
  AdsManager._();

  static final AdsManager instance = AdsManager._();

  // ================= NATIVE ADS =================
  final NativeAdHelper nativeIntroAd = NativeAdHelper(unitIdGetter: () => RemoteConfigService.getNativeAdId());
  final NativeAdHelper nativeDashboardAd = NativeAdHelper(unitIdGetter: () => RemoteConfigService.getHomeNativeAdId());
  final NativeAdHelper nativeAssistAd = NativeAdHelper(unitIdGetter: () => RemoteConfigService.getAssistNativeAdId());
  bool initialized = false;

  // ================= COLLAPSIBLE BANNER =================
  BannerAd? _collapsibleBannerAd; // Internal reference
  bool _collapsibleBannerLoading = false;
  final ValueNotifier<BannerAd?> collapsibleBannerAd = ValueNotifier<BannerAd?>(null);
  
  // Backward compatibility getter for the notifier status
  ValueNotifier<bool> get collapsibleBannerAdLoaded => _collapsibleBannerAdLoadedNotifier;
  final ValueNotifier<bool> _collapsibleBannerAdLoadedNotifier = ValueNotifier<bool>(false);

  // ================= INTERSTITIAL ADS =================
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  RewardedAd? _rewardedAd;
  bool _rewardedAdLoading = false;

  void _loadRewardedAd() {
    if (_rewardedAdLoading || _rewardedAd != null) return;
    
    // 💡 Always allow background loading, but use IDs from Remote Config
    final adId = RemoteConfigService.getRewardedAdId(); 
    if (adId.isEmpty || adId == '11') {
      debugPrint("📢 Rewarded Loading Skipped: ID is $adId");
      return;
    }

    _rewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: adId, 
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAdLoading = false;
          debugPrint("✅ Rewarded Ad Loaded");
        },
        onAdFailedToLoad: (error) {
          _rewardedAdLoading = false;
          _rewardedAd = null;
          debugPrint("❌ Rewarded Ad failed to load: ${error.message}");
        },
      ),
    );
  }

  static Future<bool> showRewardedAd() async {
    final adId = RemoteConfigService.getRewardedAdId();
    
    // 🛡️ GATEKEEPER: Check if allowed to show
    if (!RemoteConfigService.shouldShowAdsGlobally() || !RemoteConfigService.shouldShowAd(adId)) {
      debugPrint("🚫 Rewarded Blocked by Remote Config (ID: $adId)");
      return true; // Return success to allow app flow
    }

    if (instance._rewardedAd == null) {
      instance._loadRewardedAd();
      debugPrint("⚠️ Rewarded Ad not ready");
      return true; // Still allow flow
    }

    final Completer<bool> completer = Completer<bool>();
    bool userEarnedReward = false;

    instance._rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        instance._rewardedAd = null;
        instance._loadRewardedAd();
        if (!completer.isCompleted) completer.complete(userEarnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        instance._rewardedAd = null;
        instance._loadRewardedAd();
        if (!completer.isCompleted) completer.complete(true); // Allow flow on failure
      },
    );

    instance._rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      userEarnedReward = true;
    });

    return completer.future;
  }

  /// Smart ad fallback:
  /// 1. Rewarded ready → show it → return true on reward earned
  /// 2. Rewarded not ready → try loading → wait up to 2 seconds
  /// 3. If loaded in time → show rewarded → return true on reward
  /// 4. If not loaded in 2s → show interstitial if available → return true
  /// 5. Nothing available → return true (allow download gracefully)
  static Future<bool> showRewardedOrFallback(BuildContext context) async {
    // Case 1: Rewarded already loaded
    if (instance._rewardedAd != null) {
      return await showRewardedAd();
    }

    // Case 2: Not loaded — trigger load and wait up to 2 seconds
    instance._loadRewardedAd();

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Poll every 200ms for up to 2 seconds
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (instance._rewardedAd != null) break;
    }

    // Dismiss loading indicator
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    // Case 3: Rewarded loaded in time
    if (instance._rewardedAd != null) {
      return await showRewardedAd();
    }

    // Case 4: Rewarded failed — try interstitial
    if (instance._interstitialAd != null) {
      instance.showInterstitialIfAvailable();
      return true; // Allow download after interstitial
    }

    // Case 5: Nothing available — allow download gracefully
    return true;
  }

  // Update init to include rewarded load
  Future<void> init() async {
    if (initialized) return;

    await MobileAds.instance.initialize();

    // 💡 ALWAYS trigger background preloading as requested.
    // Display is controlled via gatekeepers in show/widget methods.
    
    // 🔹 Native intro ad
    nativeIntroAd.loadAd(() {
      debugPrint("✅ Intro Native Ad Ready");
    });

    // 🔹 Native dashboard ad
    nativeDashboardAd.loadAd(() {
      debugPrint("✅ Dashboard Native Ad Ready");
    });

    // 🔹 Native assist ad
    nativeAssistAd.loadAd(() {
      debugPrint("✅ Assist Native Ad Ready");
    });

    // 🔹 Preload interstitial
    _loadInterstitial();
    
    // 🔹 Preload Rewarded
    _loadRewardedAd();

    // 🔹 Preload Collapsible Banner
    _loadCollapsibleBannerAd();

    _startBackgroundKeepReadyTimer();

    initialized = true;
    debugPrint("🔥 AdsManager initialized");
  }

  /// 🛡️ Keep background ads ready at all times by checking state periodically
  void _startBackgroundKeepReadyTimer() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      // 🏘️ Home Dashboard Ad
      if (!nativeDashboardAd.isAdLoaded && !nativeDashboardAd.isAdLoading) {
        debugPrint("🔋 AdsManager: Background-refreshing Home Dashboard Ad...");
        nativeDashboardAd.loadAd(null);
      }

      // 🤖 Assist Screen Ad
      if (!nativeAssistAd.isAdLoaded && !nativeAssistAd.isAdLoading) {
        debugPrint("🔋 AdsManager: Background-refreshing Assist Screen Ad...");
        nativeAssistAd.loadAd(null);
      }

      // 🎥 Intro Native Ad
      if (!nativeIntroAd.isAdLoaded && !nativeIntroAd.isAdLoading) {
        nativeIntroAd.loadAd(null);
      }
    });
  }

  /// 🔄 Force refresh the dashboard ad to get a new impression
  void refreshDashboardAd() {
    debugPrint("🔄 AdsManager: Refreshing Dashboard Native Ad for new impression...");
    nativeDashboardAd.clearAd(); // Safe reset without disposing helper
    nativeDashboardAd.loadAd(() {
      debugPrint("✅ Dashboard Native Ad REFRESHED");
    });
  }

  /// 🔄 Force refresh the assist ad to get a new impression
  void refreshAssistAd() {
    debugPrint("🔄 AdsManager: Refreshing Assist Native Ad for new impression...");
    nativeAssistAd.clearAd(); // Safe reset without disposing helper
    nativeAssistAd.loadAd(() {
      debugPrint("✅ Assist Native Ad REFRESHED");
    });
  }


  // ================= INTERSTITIAL LOAD =================

  void _loadInterstitial() {
    if (_interstitialLoading || _interstitialAd != null) return;
    
    final adId = RemoteConfigService.getInterstitialAdId();
    if (adId.isEmpty || adId == '11') {
      debugPrint("📢 Interstitial Loading Skipped: ID is $adId");
      return;
    }

    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: adId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
          debugPrint("✅ Interstitial Ad Loaded");
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          _interstitialAd = null;
          debugPrint("❌ Interstitial failed: ${error.message}");
        },
      ),
    );
  }

  // ================= INTERSTITIAL SHOW =================

  /// Call this ONLY after checking:
  /// AppState.shouldShowInterstitialOnNavigation()
  void showInterstitialIfAvailable() {
    final adId = RemoteConfigService.getInterstitialAdId();
    
    // 🛡️ GATEKEEPER: Check if allowed to show
    if (!RemoteConfigService.shouldShowAdsGlobally() || !RemoteConfigService.shouldShowAd(adId)) {
      debugPrint("🚫 Interstitial Blocked by Remote Config");
      return;
    }

    if (_interstitialAd == null) {
      _loadInterstitial();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;

        // 🔁 Preload next
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ================= COLLAPSIBLE BANNER LOAD =================

  void _loadCollapsibleBannerAd() {
    if (_collapsibleBannerLoading || _collapsibleBannerAd != null) return;

    final adId = RemoteConfigService.getCollapsiveBannerAdId();
    if (adId.isEmpty || adId == '11') return;

    _collapsibleBannerLoading = true;

    // Use a safe width calculation
    final int width = (Get.width > 0) ? Get.width.toInt() : 320;
    
    AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width).then((size) {
      final effectiveSize = size ?? AdSize.banner;

      _collapsibleBannerAd = BannerAd(
        adUnitId: adId,
        size: effectiveSize,
        request: const AdRequest(
          extras: {'collapsible': 'bottom'},
        ),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _collapsibleBannerLoading = false;
            collapsibleBannerAd.value = ad as BannerAd;
            _collapsibleBannerAdLoadedNotifier.value = true;
            debugPrint("✅ Collapsible Banner Loaded (Size: $effectiveSize)");
          },
          onAdFailedToLoad: (ad, error) {
            _collapsibleBannerLoading = false;
            collapsibleBannerAd.value = null;
            _collapsibleBannerAdLoadedNotifier.value = false;
            ad.dispose();
            _collapsibleBannerAd = null;
            debugPrint("❌ Collapsible Banner failed: ${error.message}");
          },
        ),
      )..load();
    }).catchError((e) {
      _collapsibleBannerLoading = false;
      debugPrint("❌ Error calculating adaptive size: $e");
    });
  }

  BannerAd? getCollapsibleBannerAd() {
    if (_collapsibleBannerAd == null) {
      _loadCollapsibleBannerAd();
    }
    return _collapsibleBannerAd;
  }
  
  void refreshCollapsibleBannerAd() {
    _collapsibleBannerAd?.dispose();
    _collapsibleBannerAd = null;
    _collapsibleBannerLoading = false;
    collapsibleBannerAd.value = null;
    _collapsibleBannerAdLoadedNotifier.value = false;
    
    _loadCollapsibleBannerAd();
  }

  // ================= DISPOSE =================

  void dispose() {
    nativeIntroAd.dispose();
    nativeDashboardAd.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose(); // Dispose Rewarded
    _collapsibleBannerAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _collapsibleBannerAd = null;
    collapsibleBannerAd.value = null;
    _interstitialLoading = false;
    _rewardedAdLoading = false;
    _collapsibleBannerLoading = false;
    _collapsibleBannerAdLoadedNotifier.value = false;
    initialized = false;
  }
}
