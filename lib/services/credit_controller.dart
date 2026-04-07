import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../ads/remote_config_service.dart';

class CreditController extends GetxController {
  static CreditController get to => Get.find<CreditController>();
  final _storage = const FlutterSecureStorage();

  // Storage keys matching existing CreditsManager for backward compatibility
  static const String _coinKey = "archify_user_coins_v1";
  static const String _premiumKey = "is_premium_user";
  static const String _activePlanKey = "active_plan_name";
  static const String _lastResetKey = "daily_credit_last_reset_v1";

  var userCoins = 0.obs;
  var isPremium = false.obs;
  var activePlan = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadData().then((_) {
      // 🔄 Check Daily Reset for Non-Premium
      checkAndResetDailyCredit();
    });
  }

  Future<void> loadData() async {
    try {
      String? coins = await _storage.read(key: _coinKey);
      userCoins.value = coins != null ? int.parse(coins) : 0;

      String? premium = await _storage.read(key: _premiumKey);
      isPremium.value = premium == "true";

      String? plan = await _storage.read(key: _activePlanKey);
      activePlan.value = plan ?? "";

      log("------------------------------------------");
      log("[CreditController]: Init Loaded. Premium: ${isPremium.value}, Coins: ${userCoins.value}");
      log("------------------------------------------");
    } catch (e) {
      log("[CreditController] Error loading storage: $e");
    }
  }

  /// 🔄 DAILY CREDIT: Only for Non-Premium users
  Future<void> checkAndResetDailyCredit() async {
    if (isPremium.value) {
      log("[DailyCredit]: User is Premium. Skipping Daily Credit.");
      return;
    }

    try {
      final now = DateTime.now();
      String? lastResetStr = await _storage.read(key: _lastResetKey);
      
      if (lastResetStr == null) {
        await _performDailyReset(now);
        return;
      }

      final lastReset = DateTime.parse(lastResetStr);
      if (now.difference(lastReset).inHours >= 24) {
        await _performDailyReset(now);
      } else {
        log("[DailyCredit]: Already reset within 24h. Remaining: ${userCoins.value}");
      }
    } catch (e) {
      log("[DailyCredit] Error checking reset: $e");
    }
  }

  Future<void> _performDailyReset(DateTime now) async {
    // 🪙 Logic: Reset per Remote Config (don't stack)
    final int dailyAllotment = RemoteConfigService.getDailyCredit(); 
    userCoins.value = dailyAllotment;
    
    await _storage.write(key: _coinKey, value: userCoins.value.toString());
    await _storage.write(key: _lastResetKey, value: now.toIso8601String());
    
    log("[DailyCredit]: Reset to $dailyAllotment credits.");
    update(['premium_status']);
  }

  /// 🪙 CONSUME: Centralized consumption
  Future<bool> consumeCredit({int amount = 1}) async {
    if (isPremium.value) {
      log("[CreditController]: Premium user. No credits consumed.");
      return true;
    }

    if (userCoins.value < amount) {
      log("[CreditController]: Insufficient credits ($userCoins / $amount)");
      return false;
    }

    userCoins.value -= amount;
    await _storage.write(key: _coinKey, value: userCoins.value.toString());
    update(['premium_status']);
    return true;
  }

  /// ➕ ADD: Centralized addition
  Future<void> addCredits(int amount) async {
    userCoins.value += amount;
    await _storage.write(key: _coinKey, value: userCoins.value.toString());
    log("[CreditController]: Added $amount credits. Total: ${userCoins.value}");
    update(['premium_status']);
  }

  // Alias for backward compatibility
  Future<void> addCoins(int amount) => addCredits(amount);

  /// ➕ Purchase Success
  Future<void> updatePremiumStatus(bool status, {int? addCoins, String? plan}) async {
    isPremium.value = status;
    if (addCoins != null) userCoins.value += addCoins;
    activePlan.value = plan ?? "";

    await _storage.write(key: _premiumKey, value: status.toString());
    await _storage.write(key: _coinKey, value: userCoins.value.toString());
    if (plan != null) await _storage.write(key: _activePlanKey, value: plan);
    
    update(['premium_status']);
  }

  var isTesterBypass = false;

  Future<void> refundCredit(int amount) async {
    if (isPremium.value) return;
    await addCredits(amount);
  }

  Future<void> setPremium(bool value) async {
    await updatePremiumStatus(value);
  }
}
