import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

import 'app_state.dart';
import 'nativeAds/native_ad_helper.dart';
import 'remote_config_service.dart';

class AdsManager {
  AdsManager._();

  static final AdsManager instance = AdsManager._();

  // ================= NATIVE ADS =================
  final NativeAdHelper nativeIntroAd = NativeAdHelper();
  bool initialized = false;

  // ================= INTERSTITIAL ADS =================
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  RewardedAd? _rewardedAd;
  bool _rewardedAdLoading = false;

  void _loadRewardedAd() {
    if (_rewardedAdLoading || _rewardedAd != null) return;
    
    // Check if we can load ads
    if (!AppState.canLoadAds) return;

    final adId = RemoteConfigService.getRewardedAdId(); 
    
    // Using a safe string for now if remote config is empty, will use test id.
    final String effectiveAdId = adId.isNotEmpty ? adId : "ca-app-pub-3940256099942544/5224354917"; // Android Test Rewarded ID

    _rewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: effectiveAdId, 
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
    final Completer<bool> completer = Completer<bool>();
    
    if (instance._rewardedAd == null) {
      instance._loadRewardedAd();
      debugPrint("⚠️ Rewarded Ad not ready");
      return false;
    }

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
        if (!completer.isCompleted) completer.complete(false);
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

    // SINGLE SOURCE OF TRUTH
    if (AppState.canLoadAds) {
      // 🔹 Native intro ad
      nativeIntroAd.loadAd(() {
        debugPrint("✅ Intro Native Ad Ready");
      });

      // 🔹 Preload interstitial
      _loadInterstitial();
      
      // 🔹 Preload Rewarded
      _loadRewardedAd();
    }

    initialized = true;
    debugPrint("🔥 AdsManager initialized");
  }


  // ================= INTERSTITIAL LOAD =================

  void _loadInterstitial() {
    if (_interstitialLoading || _interstitialAd != null) return;
    
    // Check if we can load ads
    if (!AppState.canLoadAds) return;

    final adId = RemoteConfigService.getInterstitialAdId();
    if (adId.isEmpty) return;

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

  // ================= DISPOSE =================

  void dispose() {
    nativeIntroAd.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose(); // Dispose Rewarded
    _interstitialAd = null;
    _rewardedAd = null;
    _interstitialLoading = false;
    _rewardedAdLoading = false;
    initialized = false;
  }
}
