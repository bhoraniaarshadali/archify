import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

import '../app_state.dart';

class NativeAdHelper extends ChangeNotifier {
  final String Function() unitIdGetter;
  NativeAdHelper({required this.unitIdGetter});

  NativeAd? nativeAd;
  bool isAdLoaded = false;
  bool isAdLoading = false;
  String? lastError;

  void loadAd(VoidCallback? onLoaded) {
    if (isAdLoaded || nativeAd != null || isAdLoading) {
       if (isAdLoaded && onLoaded != null) onLoaded();
       return;
    }

    final unitId = unitIdGetter();
    if (unitId.isEmpty || unitId == "11") {
      debugPrint('📢 NativeAdHelper: Loading skipped (ID disabled or empty)');
      return;
    }

    isAdLoading = true;
    AppState.adLoadAttempted = true;

    nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId: 'listTile',
      customOptions: {'layoutType': 'intro'},
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

  /// 🔄 Safe Reload: Clears current ad and requests a new one for next impression
  void reloadAd() {
    debugPrint('🔄 NativeAdHelper: Reloading ad for next impression...');
    // We don't call clearAd() immediately to avoid UI flickering if still visible,
    // but in this 1-impression-per-visit strategy, we can safely clear and reload.
    clearAd();
    loadAd(null);
  }

  /// 🧹 Clear current ad to prepare for a new one without disposing the whole helper
  void clearAd() {
    nativeAd?.dispose();
    nativeAd = null;
    isAdLoaded = false;
    isAdLoading = false;
    lastError = null;
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
