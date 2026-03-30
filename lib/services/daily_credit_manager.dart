import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ads/app_state.dart';
import '../ads/remote_config_service.dart';
import '../ads/ad_manager.dart';
import 'premium/premium_validation_service.dart';

class DailyCreditManager {
  static const String _keyCredits = 'daily_free_credits';
  static const String _keyLastReset = 'daily_credit_last_reset_timestamp';

  static final ValueNotifier<int> creditsNotifier = ValueNotifier<int>(0);

  /// Initialize the credit system
  static Future<void> init() async {
    // Initialize for everyone now, as even paid tiers might have credit limits
    await checkAndResetDailyCredit();
  }

  /// Check if 24 hours passed or if user is cheating with clock
  static Future<void> checkAndResetDailyCredit() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastResetStr = prefs.getString(_keyLastReset) ?? '';
    
    // Load current credits from local storage
    creditsNotifier.value = prefs.getInt(_keyCredits) ?? 0;

    if (lastResetStr.isEmpty) {
      // First time user: initialize
      await _resetCredits(prefs, now);
      return;
    }

    final lastReset = DateTime.parse(lastResetStr);

    // 🕵️ Cheat Check: Clock went backwards
    if (now.isBefore(lastReset)) {
      debugPrint('⚠️ DailyCredit: CHEAT DETECTED! Current time is before last reset.');
      // Optionally show a toast/dialog here if needed
      return;
    }

    // 🔄 24 Hour Logic: Non-stacking
    if (now.difference(lastReset).inHours >= 24) {
      await _resetCredits(prefs, now);
    } else {
      debugPrint('🪙 Daily Credit Loaded: ${creditsNotifier.value} (Next reset in ${24 - now.difference(lastReset).inHours}h)');
    }
  }

  /// Reset credits to RemoteConfig value (does not stack)
  static Future<void> _resetCredits(SharedPreferences prefs, DateTime now) async {
    final remoteCreditValue = RemoteConfigService.getDailyCredit();
    await prefs.setInt(_keyCredits, remoteCreditValue);
    await prefs.setString(_keyLastReset, now.toIso8601String());
    
    creditsNotifier.value = remoteCreditValue;
    debugPrint('🔄 Daily Credit Reset: $remoteCreditValue allotted. (ISO: ${now.toIso8601String()})');
  }


  /// Consume generic amount of credits
  static Future<void> useCredits(int amount) async {
    if (AppState.planTier == PlanTier.architect) return;
    if (amount <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    int current = creditsNotifier.value;
    int newValue = (current - amount).clamp(0, 999999);
    
    await prefs.setInt(_keyCredits, newValue);
    creditsNotifier.value = newValue;
    debugPrint('➖ Credits Used: $amount. Remaining: $newValue');
  }

  /// Add credits manually (e.g. from purchase)
  static Future<void> addCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = creditsNotifier.value + amount;
    await prefs.setInt(_keyCredits, newValue);
    creditsNotifier.value = newValue;
    debugPrint('➕ Credits Added: $amount. Total: $newValue');
  }

  /// Refund credits back to user (e.g. on failed generation)
  static Future<void> refundCredit(int amount) async {
    if (amount <= 0) return;
    if (AppState.planTier == PlanTier.architect) return; // Architect doesn't need refunds
    
    await addCredits(amount);
    debugPrint('🔄 Credits Refunded: $amount');
  }

  /// Check if user can proceed with generation (without consuming)
  static Future<bool> checkCreditOnly(BuildContext context) async {
    return await PremiumValidationService.canGenerateImage(context);
  }

  /// Check and consume credit with UI feedback
  /// Returns true if execution should continue
  static Future<bool> checkAndConsume(BuildContext context) async {
    final canProceed = await checkCreditOnly(context);
    if (canProceed) {
      return await consumeCredit();
    }
    return false;
  }

  /// Silently consume credit (1 credit)
  static Future<bool> consumeCredit() async {
    final credits = getRemainingCredit();
    if (AppState.planTier == PlanTier.architect) return true;
    if (credits <= 0) return false;

    final prefs = await SharedPreferences.getInstance();
    final newValue = credits - 1;
    await prefs.setInt(_keyCredits, newValue);
    creditsNotifier.value = newValue;
    debugPrint('🪙 Credit Consumed. Remaining: $newValue');
    return true;
  }

  /// Show a dialog when credits are exhausted
  static Future<bool> showNoCreditDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✨ Out of Credits'),
        content: const Text(
          'You have used all your daily free credits. '
          'Watch a short video to get 1 extra generation for free!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'showAd'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Watch Ad', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == 'showAd') {
      debugPrint('🎬 Showing Rewarded Ad for credit...');
      final bool userEarnedReward = await AdsManager.showRewardedAd();
      if (userEarnedReward) {
        debugPrint('🎁 User earned reward! Proceeding with generation.');
        return true;
      } else {
        debugPrint('❌ Ad dismissed or failed. No reward.');
      }
    }
    
    return false;
  }

  /// Get current remaining credits
  static int getRemainingCredit() {
    if (AppState.planTier == PlanTier.architect) return 999; // Visual representation for Architect
    return creditsNotifier.value;
  }

}
