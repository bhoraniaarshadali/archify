import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';
import '../utils/app_constant.dart';
import '../ads/remote_config_service.dart';

class AdsVariable {
  static bool isConfigured = false;

  static Future<bool> isInternetConnected() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  static String get selectedCreditPlan {
    final fromConfig = RemoteConfigController.to.selectedCreditPlanId.value;
    return fromConfig.isNotEmpty ? fromConfig : AppConstant.firstCoinIdentifier;
  }

  static String get selectedPremiumPlan {
    final fromConfig = RemoteConfigController.to.selectedPremiumPlanId.value;
    return fromConfig.isNotEmpty ? fromConfig : AppConstant.yearlyIdentifier;
  }

  static bool get isShowIAmTester => RemoteConfigController.to.isShowIAmTester.value;

  static bool _manualPurchaseStatus = false;

  static bool get isPurchase {
    // If manual purchase status is true (e.g. from successful login or real purchase)
    return _manualPurchaseStatus;
  }

  static set isPurchase(bool value) {
    _manualPurchaseStatus = value;
  }

  static void resetAdIds() {
    // Placeholder for resetting ad IDs if needed
  }

  static String? get testEmail {
    final email = RemoteConfigController.to.testEmail.value;
    return email.isNotEmpty ? email : null;
  }

  static String? get testPassword {
    final pass = RemoteConfigController.to.testPassword.value;
    return pass.isNotEmpty ? pass : null;
  }

  static String get weeklyBonusCredit =>
      RemoteConfigService.getPlanCredits('weekly_plan', 199).toString();

  static String get yearlyBonusCredit =>
      RemoteConfigService.getPlanCredits('yearly_plan', 799).toString();

  static String get firstCoinPlan =>
      RemoteConfigService.getPlanCredits('credit_1_plan', 11).toString();

  static String get secondCoinPlan =>
      RemoteConfigService.getPlanCredits('credit_2_plan', 31).toString();

  static String get thirdCoinPlan =>
      RemoteConfigService.getPlanCredits('credit_3_plan', 71).toString();

  static String get fourthCoinPlan =>
      RemoteConfigService.getPlanCredits('credit_4_plan', 166).toString();

  static String get fifthCoinPlan =>
      RemoteConfigService.getPlanCredits('credit_5_plan', 401).toString();

  static String get sixthCoinPlan =>
      RemoteConfigService.getPlanCredits('credit_6_plan', 861).toString();
}

class RemoteConfigController extends GetxController {
  static RemoteConfigController get to => Get.find<RemoteConfigController>();

  final isInitialized = false.obs;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  StreamSubscription? _updateSubscription;

  // Reactive Variables
  var isShowIAmTester = false.obs;
  var selectedCreditPlanId = "".obs;
  var selectedPremiumPlanId = "".obs;
  var testEmail = "".obs;
  var testPassword = "".obs;
  var premium = <String, dynamic>{}.obs;
  var reelsUrls = <String>[].obs;
  var interiorStyles = [].obs;

  @override
  void onInit() {
    super.onInit();
    // 💡 No setupRemoteConfig needed here anymore, as main.dart already calls RemoteConfigService.init()
    _updateDataFromConfig();
    _listenToUpdates();
  }

  @override
  void onClose() {
    _updateSubscription?.cancel();
    super.onClose();
  }

  void _listenToUpdates() {
    _updateSubscription = _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();
      debugPrint('🔥 RemoteConfigController: Received real-time update');
      _updateDataFromConfig();
    });
  }

  void _updateDataFromConfig() {
    try {
      AdsVariable.isConfigured = true;
      
      // Use RemoteConfigService getters for unified JSON parsing
      isShowIAmTester.value = RemoteConfigService.getString("isShowIAmTester") == "true" || _remoteConfig.getBool("isShowIAmTester");
      selectedCreditPlanId.value = RemoteConfigService.getString("selectedCreditPlan");
      selectedPremiumPlanId.value = RemoteConfigService.getString("selectedPremiumPlan");
      // Support both camelCase and snake_case for flexibility
      testEmail.value = RemoteConfigService.getString("testEmail").isNotEmpty 
          ? RemoteConfigService.getString("testEmail") 
          : RemoteConfigService.getString("test_email");
          
      testPassword.value = RemoteConfigService.getString("testPassword").isNotEmpty 
          ? RemoteConfigService.getString("testPassword") 
          : RemoteConfigService.getString("test_password");

      debugPrint('🔥 RemoteConfig Login: Current email from config is "${testEmail.value}"');

      // 🔍 Debug log for the source of the main blob
      final blobVal = _remoteConfig.getValue('v1_home_decor');
      debugPrint('🔥 RemoteConfig [v1_home_decor] Source: ${blobVal.source}');

      // Populate premium map from service logic
      // No need to manually parse here as getPlanCredits handles it, 
      // but if other code uses 'controller.premium', we update it:
      final premiumMap = RemoteConfigService.getPlanCredits('credit_1_plan', -1);
      if (premiumMap != -1) {
         // Re-parsing for controller's reactive map
         try {
           final jsonString = _remoteConfig.getString('v1_home_decor');
           final map = jsonDecode(jsonString);
           if (map['premium'] != null) premium.value = map['premium'];
         } catch(_) {}
      }

      // Handle Reels and Interior Json (Might be in big blob OR separate)
      void updateLists(String key, RxList list) {
         String jsonStr = RemoteConfigService.getString(key);
         if (jsonStr.isEmpty) {
           jsonStr = _remoteConfig.getString(key);
           debugPrint('🔍 RemoteConfig: Fallback to top-level for [$key]. Result length: ${jsonStr.length}');
         } else {
           debugPrint('🔍 RemoteConfig: Found [$key] in main JSON blob. Result length: ${jsonStr.length}');
         }
         
         if (jsonStr.isNotEmpty) {
           try {
             var decoded = jsonDecode(jsonStr);
             debugPrint('🔥 RemoteConfig [$key] Decoded Type: ${decoded.runtimeType}');
             
             if (decoded is List) {
               // Safely convert all elements to the required Type (String for reelsUrls)
               final items = decoded.map((e) => e.toString()).toList();
               list.assignAll(items);
               debugPrint('✅ RemoteConfig: Updated list [$key] with ${items.length} items');
             } else {
               debugPrint('⚠️ RemoteConfig: Decoded JSON for [$key] is NOT a List! Raw: $decoded');
             }
           } catch (e) {
             debugPrint('❌ RemoteConfig: Failed to decode list [$key]: $e');
           }
         } else {
           debugPrint('⚠️ RemoteConfig: No content found for key [$key]');
         }
      }

      updateLists("v1_home_decor_reels", reelsUrls);
      updateLists("v1_home_decor_interior_json", interiorStyles);
      
      isInitialized.value = true;
    } catch (e) {
      debugPrint('❌ Error updating logic from config: $e');
      isInitialized.value = true;
    }
  }

  // Compatibility layer for existing code
  AdsVariableLegacy get adsVariable => AdsVariableLegacy(this);
}

class AdsVariableLegacy {
  final RemoteConfigController _controller;
  AdsVariableLegacy(this._controller);

  AdsVariableLegacy get value => this; // Compatibility for .value access

  List<String> get reelsUrls => _controller.reelsUrls;
  List<dynamic> get interiorStyles => _controller.interiorStyles;
  bool get isShowIAmTester => _controller.isShowIAmTester.value;
}


