import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';

class AdsVariable {
  static bool isConfigured = false;
  bool isSendAppInMaintenance = false;
  bool isShowIAmTester = false;
  static bool isPurchase = false; // Add static isPurchase for global access
  String selectedCreditPlan = "coins_plan_1";
  String selectedPremiumPlan = "weekly_premium";
  String testEmail = "test@example.com";
  String testPassword = "password123";
  
  String firstCoinPlan = "coins_plan_1";
  String secondCoinPlan = "coins_plan_2";
  String thirdCoinPlan = "coins_plan_3";
  String fourthCoinPlan = "coins_plan_4";
  String fifthCoinPlan = "coins_plan_5";
  String sixthCoinPlan = "coins_plan_6";
  
  String weeklyBonusCredit = "50";
  String yearlyBonusCredit = "500";
  List<String> reelsUrls = [];
  List<dynamic> interiorStyles = [];

  static void resetAdIds() {
    // Implement reset logic here if needed, for now it's a placeholder as requested
    debugPrint("AdsVariable: resetAdIds called");
  }

  static Future<bool> isInternetConnected() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}

class RemoteConfigController extends GetxController {
  final adsVariable = AdsVariable().obs;
  final isInitialized = false.obs;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  StreamSubscription? _updateSubscription;

  @override
  void onInit() {
    super.onInit();
    setupRemoteConfig();
    _listenToUpdates();
  }

  @override
  void onClose() {
    _updateSubscription?.cancel();
    super.onClose();
  }

  Future<void> setupRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.setDefaults({
        "isSendAppInMaintenance": false,
        "isShowIAmTester": false,
        "selectedCreditPlan": "coins_plan_1",
        "selectedPremiumPlan": "weekly_premium",
        "testEmail": "test@example.com",
        "testPassword": "password123",
        "firstCoinPlan": "coins_plan_1",
        "secondCoinPlan": "coins_plan_2",
        "thirdCoinPlan": "coins_plan_3",
        "fourthCoinPlan": "coins_plan_4",
        "fifthCoinPlan": "coins_plan_5",
        "sixthCoinPlan": "coins_plan_6",
        "weeklyBonusCredit": "50",
        "yearlyBonusCredit": "500",
        "v1_home_decor_reels": "[]",
        "v1_home_decor_interior_json": "[]",
      });

      await _remoteConfig.fetchAndActivate();
      updateAdsVariable();
      isInitialized.value = true;
    } catch (e) {
      print("Remote Config error: $e");
      isInitialized.value = true; // Still set to true so splash doesn't hang
    }
  }

  void _listenToUpdates() {
    _updateSubscription = _remoteConfig.onConfigUpdated.listen((event) async {
      await _remoteConfig.activate();
      updateAdsVariable();
      print("Remote Config updated in real-time");
    });
  }

  void updateAdsVariable() {
    adsVariable.update((val) {
      if (val != null) {
        AdsVariable.isConfigured = true;
        val.isSendAppInMaintenance = _remoteConfig.getBool("isSendAppInMaintenance");
        val.isShowIAmTester = _remoteConfig.getBool("isShowIAmTester");
        val.selectedCreditPlan = _remoteConfig.getString("selectedCreditPlan");
        val.selectedPremiumPlan = _remoteConfig.getString("selectedPremiumPlan");
        val.testEmail = _remoteConfig.getString("testEmail");
        val.testPassword = _remoteConfig.getString("testPassword");
        val.firstCoinPlan = _remoteConfig.getString("firstCoinPlan");
        val.secondCoinPlan = _remoteConfig.getString("secondCoinPlan");
        val.thirdCoinPlan = _remoteConfig.getString("thirdCoinPlan");
        val.fourthCoinPlan = _remoteConfig.getString("fourthCoinPlan");
        val.fifthCoinPlan = _remoteConfig.getString("fifthCoinPlan");
        val.sixthCoinPlan = _remoteConfig.getString("sixthCoinPlan");
        val.weeklyBonusCredit = _remoteConfig.getString("weeklyBonusCredit");
        val.yearlyBonusCredit = _remoteConfig.getString("yearlyBonusCredit");
        
        String reelsJson = _remoteConfig.getString("v1_home_decor_reels");
        try {
          var decoded = jsonDecode(reelsJson);
          if (decoded is List) {
            val.reelsUrls = List<String>.from(decoded);
          }
        } catch (e) {
          print("Error parsing v1_home_decor_reels: $e");
        }

        String interiorJson = _remoteConfig.getString("v1_home_decor_interior_json");
        try {
          var decoded = jsonDecode(interiorJson);
          if (decoded is List) {
            val.interiorStyles = decoded;
          }
        } catch (e) {
          print("Error parsing v1_home_decor_interior_json: $e");
        }
      }
    });
  }
}
