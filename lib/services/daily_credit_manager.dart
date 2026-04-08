import 'package:flutter/material.dart';
import 'credit_controller.dart';
import '../screens/premium/pro_screen.dart';

/// 🌉 BRIDGE: This class now delegates all logic to CreditController.to
/// to maintain a single central place for all credits in the app.
class DailyCreditManager {
  
  static Future<void> init() async {
    // Initial check is now handled in CreditController.onInit
  }

  static Future<void> checkAndResetDailyCredit() async {
    await CreditController.to.checkAndResetDailyCredit();
  }

  static bool _testerBypassActive = false;

  static Future<bool> useCredits(int amount) async {
    if (_testerBypassActive) {
      _testerBypassActive = false;
      debugPrint("🛠️ Tester Bypass: Skipping credit consumption for this call.");
      return true;
    }
    return await CreditController.to.consumeCredit(amount: amount);
  }

  static Future<void> addCredits(int amount) async {
    await CreditController.to.addCredits(amount);
  }

  static Future<void> refundCredit(int amount) async {
    await CreditController.to.refundCredit(amount);
  }

  static Future<bool> checkCreditOnly(BuildContext context, {int amount = 1}) async {
    // 1. If we have enough credits, proceed immediately
    if (getRemainingCredit() >= amount) return true;

    // 2. Not enough credits -> Redirect to Pro Screen
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProScreen(
            from: 'insufficient_coins',
            isFromInsufficientCoins: true,
            initialTabIndex: 0
        ),
      ),
    );

    // If returning from ProScreen with success (e.g. valid Tester login or successful purchase)
    if (success == true) {
      if (getRemainingCredit() < amount) {
        _testerBypassActive = true; // Enable bypass for the next useCredits call
      }
      return true;
    }

    return false;
  }

  static Future<bool> consumeCredit() async {
    if (_testerBypassActive) {
      _testerBypassActive = false;
      return true;
    }
    return await CreditController.to.consumeCredit();
  }

  static int getRemainingCredit() {
    return CreditController.to.userCoins.value;
  }
}
