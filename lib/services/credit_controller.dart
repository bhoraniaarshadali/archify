import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditController extends GetxController {
  var coins = 0.obs;
  var isPremium = false.obs;
  var activePlan = "".obs;
  var isTesterBypass = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    coins.value = prefs.getInt('user_coins') ?? 0;
    isPremium.value = prefs.getBool('is_premium') ?? false;
    activePlan.value = prefs.getString('active_plan') ?? "";
    isTesterBypass.value = prefs.getBool('is_tester_bypass') ?? false;
  }

  Future<void> addCoins(int amount) async {
    coins.value += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_coins', coins.value);
  }

  Future<void> updatePremiumStatus(bool status, {int? addCoinsAmount, String? plan}) async {
    isPremium.value = status;
    if (plan != null) activePlan.value = plan;
    if (addCoinsAmount != null) coins.value += addCoinsAmount;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', status);
    if (plan != null) await prefs.setString('active_plan', plan);
    if (addCoinsAmount != null) await prefs.setInt('user_coins', coins.value);
  }
  
  Future<void> setTesterBypass(bool status) async {
    isTesterBypass.value = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tester_bypass', status);
  }
}
