import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/remote_config_controller.dart';
import '../core/logger.dart'; // Import central logger
import '../ads/app_state.dart';
import '../utils/app_constant.dart';

class SplashScreenController extends GetxController {
  // Use the central entitlement key from AppConstant
  static const String entitlementKey = AppConstant.entitlementKey; 

  Future<void> fetchPurchase() async {
    // Use instance of controllers
    SplashScreenController splashScreenController = Get.find<SplashScreenController>();
    
    try {
      // Get customer subscription details using RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();

      // Access the entitlement info using your entitlement key
      final entitlement = customerInfo.entitlements.all[entitlementKey];
      showLog("<><><><><><>${entitlement?.productIdentifier}");

      // If the user has an active subscription
      if (entitlement != null && entitlement.isActive) {
        AdsVariable.isPurchase = true;
        AppState.isPremiumUser = true; // Sync AppState
        AdsVariable.resetAdIds();
        splashScreenController.update(["full"]);
      } else {
        // Subscription is not active
        AdsVariable.isPurchase = false;
        AppState.isPremiumUser = false; // Sync AppState
        splashScreenController.update(["full"]);
      }
    } catch (e) {
      // Handle any errors in fetching or processing purchase data
      showLog("PURCHASE_ERROR >> ${e.toString()}");
    }
  }
}
