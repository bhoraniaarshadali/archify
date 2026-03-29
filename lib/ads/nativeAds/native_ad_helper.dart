import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import '../remote_config_service.dart';

import '../app_state.dart';

class NativeAdHelper extends ChangeNotifier {
  NativeAd? nativeAd;
  bool isAdLoaded = false;
  bool isAdLoading = false;
  String? lastError;

  void loadAd(VoidCallback? onLoaded) {
    if (isAdLoaded || nativeAd != null || isAdLoading) return;

    final unitId = RemoteConfigService.getNativeAdId();
    if (unitId.isEmpty) {
      debugPrint(
        '⚠️ NativeAdHelper: Ad Unit ID is empty. Check Remote Config.',
      );
      return;
    }

    if (!AppState.canLoadAds) {
      debugPrint('⚠️ NativeAdHelper: canLoadAds is false. Check AppState.');
      return;
    }

    isAdLoading = true;
    AppState.adLoadAttempted = true;

    nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ NativeAdHelper: Ad Loaded Successfully');
          isAdLoaded = true;
          isAdLoading = false;
          AppState.adLoadFailed = false;
          lastError = null;
          if (onLoaded != null) onLoaded();
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ NativeAdHelper: Ad Failed to Load: ${error.message}');
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
