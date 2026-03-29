import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/app_constant.dart';

class AppConfig {
  static Future<void> configureSDK() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(AppConstant.googleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(AppConstant.appleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }
}
