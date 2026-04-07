import 'package:flutter/foundation.dart';
import '../services/helper/connectivity_service.dart';
import 'premium_service.dart';
import '../services/daily_credit_manager.dart';

enum PlanTier { free, standard, premium, architect }

/// Reactive Global App State
class AppState extends ChangeNotifier {
  // Singleton instance
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Static Getters for backward compatibility (points to singleton)
  static bool get isPremiumUser => _instance.isPremiumActive;
  static PlanTier get planTier => _instance._planTier;
  static bool get adsAllowedManually => _instance._adsAllowedManually;
  static bool get adLoadAttempted => _instance._adLoadAttempted;
  static bool get adLoadFailed => _instance._adLoadFailed;
  static bool get canLoadAds => _instance._canLoadAdsLogic;

  // Static Setters for backward compatibility
  static set planTier(PlanTier value) => _instance.setPlanTier(value);
  static set isPremiumUser(bool value) => _instance.setPremiumStatus(value);
  static set adLoadAttempted(bool value) {
    if (_instance._adLoadAttempted == value) return;
    _instance._adLoadAttempted = value;
    _instance.notifyListeners();
  }
  static set adLoadFailed(bool value) {
    if (_instance._adLoadFailed == value) return;
    _instance._adLoadFailed = value;
    _instance.notifyListeners();
  }

  /// Static delegate for init
  static Future<void> init() => _instance._initLogic();

  /// Static delegate for updating plan tier
  static Future<void> updatePlanTier(PlanTier tier) => _instance.setPlanTier(tier);

  // Private state
  PlanTier _planTier = PlanTier.free;
  bool _adsAllowedManually = true;
  bool _adLoadAttempted = false;
  bool _adLoadFailed = false;
  bool _showBottomNav = true;

  bool get showBottomNav => _showBottomNav;

  void setShowBottomNav(bool show) {
    if (_showBottomNav == show) return;
    _showBottomNav = show;
    notifyListeners();
  }

  bool get isPremiumActive => _planTier != PlanTier.free;

  /// Initialize and load status from persistence
  Future<void> _initLogic() async {
    _planTier = await PremiumService.getPlanTier();
    debugPrint('🚀 AppState: PlanTier Loaded -> $_planTier');
    
    // 🪙 Initialize Daily Credit system
    await DailyCreditManager.init();
    
    notifyListeners();
  }

  /// Update premium status and notify UI
  Future<void> setPremiumStatus(bool status) async {
    final newTier = status ? PlanTier.standard : PlanTier.free;
    await setPlanTier(newTier);
  }

  /// Update plan tier and notify UI
  Future<void> setPlanTier(PlanTier tier) async {
    if (_planTier == tier) return;
    _planTier = tier;
    await PremiumService.setPlanTier(tier); // Persist
    notifyListeners();
    debugPrint('💎 AppState: PlanTier Updated -> $tier');
  }

  /// Toggle ads manually
  void setAdsAllowed(bool allowed) {
    if (_adsAllowedManually == allowed) return;
    _adsAllowedManually = allowed;
    notifyListeners();
  }

  /// Set ad load flags
  void setAdLoadFlags({bool? attempted, bool? failed}) {
    if (attempted != null) _adLoadAttempted = attempted;
    if (failed != null) _adLoadFailed = failed;
    notifyListeners();
  }

  /// Internal logic for checking if ads can be loaded
  bool get _canLoadAdsLogic {
    // Premium users never see ads
    if (isPremiumActive) {
      debugPrint('🚫 Ads Blocked: User is Premium (Tier: $_planTier)');
      return false;
    }

    // Manually disabled
    if (!_adsAllowedManually) {
      debugPrint('🚫 Ads Blocked: Manually disabled by code');
      return false;
    }

    // No internet
    if (!ConnectivityService.instance.currentStatus) {
      debugPrint('🚫 Ads Blocked: No Internet connection');
      return false;
    }

    return true;
  }
}
