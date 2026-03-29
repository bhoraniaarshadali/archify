import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/remote_config_controller.dart';
import 'home_screen_controller.dart';
import '../core/logger.dart'; // Import central logger

class SplashScreenController extends GetxController {
  // Use a real entitlement key from RevenueCat dashboard
  static const String entitlementKey = 'premium'; 

  Future<void> fetchPurchase() async {
    // Get instance of controllers
    SplashScreenController splashScreenController = Get.find<SplashScreenController>();
    
    // Check if HomeScreenController is registered, if not register it
    if (!Get.isRegistered<HomeScreenController>()) {
      Get.put(HomeScreenController());
    }
    HomeScreenController homeScreenController = Get.find<HomeScreenController>();

    try {
      // Get customer subscription details using RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();

      // Access the entitlement info using your entitlement key
      final entitlement = customerInfo.entitlements.all[entitlementKey];
      showLog("<><><><><><>${entitlement?.productIdentifier}");

      // If the user has an active subscription
      if (entitlement != null && entitlement.isActive) {
        AdsVariable.isPurchase = true;
        AdsVariable.resetAdIds();
        homeScreenController.update(["full"]);
        splashScreenController.update(["full"]);
      } else {
        // Subscription is not active
        AdsVariable.isPurchase = false;
        homeScreenController.update(["full"]);
        splashScreenController.update(["full"]);
      }
    } catch (e) {
      // Handle any errors in fetching or processing purchase data
      showLog("PURCHASE_ERROR >> ${e.toString()}");
    }
  }
}
