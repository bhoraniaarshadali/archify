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

  static Future<void> useCredits(int amount) async {
    await CreditController.to.consumeCredit(amount: amount);
  }

  static Future<void> addCredits(int amount) async {
    await CreditController.to.addCredits(amount);
  }

  static Future<void> refundCredit(int amount) async {
    await CreditController.to.refundCredit(amount);
  }

  static Future<bool> checkCreditOnly(BuildContext context) async {
    // 1. If we have credits, proceed immediately
    if (getRemainingCredit() > 0) return true;

    // 2. No credits -> Redirect to Pro Screen for purchase or Tester Login
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProScreen(
          from: 'insufficient_coins', 
          isFromInsufficientCoins: true
        ),
      ),
    );

    return success == true;
  }

  static Future<bool> consumeCredit() async {
    return await CreditController.to.consumeCredit();
  }

  static int getRemainingCredit() {
    return CreditController.to.userCoins.value;
  }
}
