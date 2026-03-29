import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/app_constant.dart';
import 'premium/store_config.dart';
import '../core/logger.dart';
import 'remote_config_controller.dart';

class AppConfig {
  static void premiumInit() {
    if (Platform.isIOS || Platform.isMacOS) {
      StoreConfig(
        store: Store.appStore, 
        apiKey: AppConstant.appleApiKey
      );
    } else if (Platform.isAndroid) {
      const useAmazon = bool.fromEnvironment("amazon");
      StoreConfig(
        store: useAmazon ? Store.amazon : Store.playStore, 
        apiKey: useAmazon ? AppConstant.amazonApiKey : AppConstant.googleApiKey
      );
    }
  }

  static Future<void> configureSDK() async {
    await Purchases.setLogLevel(LogLevel.debug);
    showLog('==========setLogLevel=============');
    
    PurchasesConfiguration configuration;
    if (StoreConfig.isForAmazonAppstore()) {
      configuration = AmazonConfiguration(StoreConfig.instance.apiKey);
    } else {
      configuration = PurchasesConfiguration(StoreConfig.instance.apiKey);
    }
    
    configuration.entitlementVerificationMode = EntitlementVerificationMode.informational;
    await Purchases.configure(configuration);
    await Purchases.enableAdServicesAttributionTokenCollection();
    
    showLog('==========configure=============');
    AdsVariable.isConfigured = true;
    showLog('====configured==${AdsVariable.isConfigured}===========');
  }
}
