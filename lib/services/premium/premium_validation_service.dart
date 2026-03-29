import 'package:flutter/material.dart';
import '../../ads/app_state.dart';
import '../daily_credit_manager.dart';
import '../../screens/premium/premium_module_screen.dart';

class PremiumValidationService {
  /// Check if user can proceed with generation.
  /// If not, route to the appropriate tab in PremiumModuleScreen.
  static Future<bool> canGenerateImage(BuildContext context) async {
    final int currentCredits = DailyCreditManager.getRemainingCredit();
    
    // Architect tier might have different logic, but following the "needs coins" hint:
    if (currentCredits > 0) return true;

    final tier = AppState.planTier;
    
    // Determine which tab to show
    // Tab 0: Subscriptions (for Free and Standard who want more features/unlimited)
    // Tab 1: Credit Purchase (for Premium and Architect who ran out of credits)
    int targetTab = 0;
    if (tier == PlanTier.premium || tier == PlanTier.architect) {
      targetTab = 1;
    }
    
    if (context.mounted) {
      _navigateToPremium(context, targetTab);
    }

    return false;
  }

  static void _navigateToPremium(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumModuleScreen(initialTabIndex: tabIndex),
      ),
    );
  }
}
