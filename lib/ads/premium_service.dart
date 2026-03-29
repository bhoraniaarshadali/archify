import 'package:shared_preferences/shared_preferences.dart';

import 'keys.dart';
import 'app_state.dart';

class PremiumService {
  static Future<PlanTier> getPlanTier() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(kIsPremium) ?? 0;
    if (index < 0 || index >= PlanTier.values.length) return PlanTier.free;
    return PlanTier.values[index];
  }

  static Future<void> setPlanTier(PlanTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kIsPremium, tier.index);
  }

  static Future<bool> isPremium() async {
    final tier = await getPlanTier();
    return tier != PlanTier.free;
  }

  static Future<void> setPremium(bool value) async {
    await setPlanTier(value ? PlanTier.standard : PlanTier.free);
  }
}
