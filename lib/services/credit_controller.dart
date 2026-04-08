import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../ads/remote_config_service.dart';
import '../utils/network_time_utils.dart';

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
    log("---------------- [DailyCredit Check] ----------------");
    
    // 1. Premium users get NO daily credits
    if (isPremium.value) {
      log("ℹ️ [DailyCredit]: User is PREMIUM. Skipping daily credit allocation.");
      return;
    }

    // 2. Check Remote Config if system is "off"
    final String configValue = RemoteConfigService.getDailyCreditRaw();
    log("ℹ️ [DailyCredit]: Remote Config Value = '$configValue'");
    
    if (configValue.toLowerCase() == "off") {
      log("🚫 [DailyCredit]: System is 'OFF' via Remote Config. No one gets daily credits.");
      return;
    }

    try {
      // 3. Get Reliable Network Time to prevent device time cheating
      final now = await NetworkTimeUtils.getNetworkTime();
      
      String? lastResetStr = await _storage.read(key: _lastResetKey);
      
      if (lastResetStr == null) {
        log("✅ [DailyCredit]: First time user detected. Allocating initial credits.");
        await _performDailyReset(now);
        return;
      }

      final lastReset = DateTime.parse(lastResetStr);
      final difference = now.difference(lastReset);

      // 4. Strict 24-hour gap
      if (difference.inHours >= 24) {
        log("✅ [DailyCredit]: 24 hours passed since last reset ($lastReset). Allocating new credits.");
        await _performDailyReset(now);
      } else {
        int remainingHours = 24 - difference.inHours;
        log("⏳ [DailyCredit]: Already received today. Next allocation in ~$remainingHours hours.");
      }
    } catch (e) {
      log("❌ [DailyCredit]: Error during check: $e");
    }
    log("-----------------------------------------------------");
  }

  Future<void> _performDailyReset(DateTime now) async {
    final int dailyAllotment = RemoteConfigService.getDailyCredit(); 
    
    // Setting value directly ensures it doesn't accumulate
    userCoins.value = dailyAllotment;
    
    await _storage.write(key: _coinKey, value: userCoins.value.toString());
    await _storage.write(key: _lastResetKey, value: now.toIso8601String());
    
    log("💰 [DailyCredit]: SUCCESS! reset to $dailyAllotment credits at $now.");
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

  /// 💎 Set as Premium and add optional coins
  Future<void> updatePremiumStatus(bool status, {int? addCoins, String? plan}) async {
    isPremium.value = status;
    
    // When becoming premium, daily credits stop automatically because 
    // checkAndResetDailyCredit returns early if isPremium is true.
    
    if (addCoins != null) {
      userCoins.value += addCoins;
    }
    
    activePlan.value = plan ?? "";

    await _storage.write(key: _premiumKey, value: status.toString());
    await _storage.write(key: _coinKey, value: userCoins.value.toString());
    if (plan != null) await _storage.write(key: _activePlanKey, value: plan);
    
    log("[CreditController]: Updated Premium Status: $status, Plan: ${activePlan.value}, Total Coins: ${userCoins.value}");
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
