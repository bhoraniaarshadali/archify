import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../remote_config_service.dart';
import '../app_state.dart';

class ReelNativeAdHelper extends ChangeNotifier {
  NativeAd? nativeAd;
  bool isAdLoaded = false;
  bool isAdLoading = false;
  String? lastError;

  void loadAd(VoidCallback? onLoaded) {
    if (isAdLoaded || nativeAd != null || isAdLoading) return;

    if (RemoteConfigService.isReelAdsDisabled()) {
      debugPrint('⚠️ ReelNativeAdHelper: Reel Ads are disabled remotely.');
      return;
    }

    final unitId = RemoteConfigService.getNativeReelAdId();
    if (unitId.isEmpty) {
      debugPrint('⚠️ ReelNativeAdHelper: Ad Unit ID is empty.');
      return;
    }

    if (!AppState.canLoadAds) {
      debugPrint('⚠️ ReelNativeAdHelper: canLoadAds is false.');
      return;
    }

    isAdLoading = true;
    AppState.adLoadAttempted = true;

    nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId: 'reelsAd',
      customOptions: {'layoutType': 'reel'},
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ ReelNativeAdHelper: Ad Loaded Successfully');
          isAdLoaded = true;
          isAdLoading = false;
          AppState.adLoadFailed = false;
          lastError = null;
          if (onLoaded != null) onLoaded();
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '❌ ReelNativeAdHelper: Ad Failed to Load: ${error.message}',
          );
          ad.dispose();
          nativeAd = null;
          isAdLoaded = false;
          isAdLoading = false;
          AppState.adLoadFailed = true;
          lastError = error.message;
          notifyListeners();
        },
      ),
    );

    nativeAd!.load();
    notifyListeners();
  }

  @override
  void dispose() {
    nativeAd?.dispose();
    nativeAd = null;
    isAdLoaded = false;
    super.dispose();
  }
}
