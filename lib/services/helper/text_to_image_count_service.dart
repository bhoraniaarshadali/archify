import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ads/app_state.dart';
class TextToImageUsageService {
  static const String _keyLastResetDate = 'text_to_image_last_reset_date';
  static const String _keyGenerationCount = 'text_to_image_generation_count';
  static const int _freeUserDailyLimit = 10;

  /// Check if user can generate image
  static Future<bool> canGenerate() async {
    if (AppState.isPremiumUser) {
      return true; // Premium users have unlimited access
    }

    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetIfNeeded(prefs);

    final count = prefs.getInt(_keyGenerationCount) ?? 0;
    return count < _freeUserDailyLimit;
  }

  /// Get remaining generations for free users
  static Future<int> getRemainingGenerations() async {
    if (AppState.isPremiumUser) {
      return -1; // -1 indicates unlimited
    }

    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetIfNeeded(prefs);

    final count = prefs.getInt(_keyGenerationCount) ?? 0;
    return (_freeUserDailyLimit - count).clamp(0, _freeUserDailyLimit);
  }

  /// Increment generation count (call ONLY on successful generation)
  static Future<void> incrementGenerationCount() async {
    if (AppState.isPremiumUser) {
      return; // Don't track for premium users
    }

    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetIfNeeded(prefs);

    final count = prefs.getInt(_keyGenerationCount) ?? 0;
    await prefs.setInt(_keyGenerationCount, count + 1);

    debugPrint('📊 Text-to-Image usage: ${count + 1}/$_freeUserDailyLimit');
  }

  /// Check if reset is needed and reset if necessary
  static Future<void> _checkAndResetIfNeeded(SharedPreferences prefs) async {
    final lastResetDateStr = prefs.getString(_keyLastResetDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastResetDateStr == null) {
      // First time setup
      await prefs.setString(_keyLastResetDate, today.toIso8601String());
      await prefs.setInt(_keyGenerationCount, 0);
      return;
    }

    final lastResetDate = DateTime.parse(lastResetDateStr);
    final lastResetDay = DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);

    if (today.isAfter(lastResetDay)) {
      // New day, reset counter
      await prefs.setString(_keyLastResetDate, today.toIso8601String());
      await prefs.setInt(_keyGenerationCount, 0);
      debugPrint('🔄 Text-to-Image usage counter reset for new day');
    }
  }

  /// Get current usage count (for debugging/display)
  static Future<int> getCurrentCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkAndResetIfNeeded(prefs);
    return prefs.getInt(_keyGenerationCount) ?? 0;
  }
}
