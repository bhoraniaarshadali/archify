import 'dart:io';

class AppConstant {
  static const String googleApiKey = 'goog_HPKOPYmcSujDUgKtzFpydbwzqDF';
  static const String appleApiKey = 'appl_DKdpofXAZNDpdmfsDnnDlcAEOxf';
  static const String amazonApiKey = 'amazon_placeholder_key'; // Placeholder for amazon
  static const String entitlementKey = "ARDrawProAccess";

  static final String weeklyIdentifier = Platform.isAndroid
      ? "weeklysubscription:weeklysubscription"
      : "sz.exampleallplan.com.oneweek";
      
  static final String yearlyIdentifier = Platform.isAndroid
      ? "yearlysub:yearlysub"
      : "sz.exampleallplan.com.oneyear";

  static final String firstCoinIdentifier = Platform.isAndroid
      ? "ai_appsforcoins_500"
      : "sz.exampleallplan.com.hundredcoin";
      
  static final String secondCoinIdentifier = Platform.isAndroid
      ? "ai_appsforcoins_300"
      : "sz.exampleallplan.com.threehundredcoin";
      
  static final String thirdCoinIdentifier = Platform.isAndroid
      ? "ai_appsforcoins_500"
      : "sz.exampleallplan.com.threehundredcoin";
      
  static final String fourthCoinIdentifier = Platform.isAndroid
      ? "ai_appsforcoins_300"
      : "sz.exampleallplan.com.hundredcoin";
      
  static final String fifthCoinIdentifier = Platform.isAndroid
      ? "ai_appsforcoins_500"
      : "sz.exampleallplan.com.hundredcoin";
      
  static final String sixthCoinIdentifier = Platform.isAndroid
      ? "ai_appsforcoins_300"
      : "sz.exampleallplan.com.hundredcoin";

  static const String kPrivacyPolicyUrl = 'https://www.google.com';
  static const String kTermsOfUseUrl = 'https://www.google.com';
  static const String kPlayStoreSubscriptionsUrl = 'https://play.google.com/store/account/subscriptions';
}
