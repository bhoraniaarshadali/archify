import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';

/// Unified Service for Interior Image Generation.
/// Orchestrates between KIE AI (Nano Banana) and APIFree (GPT-1.5)
/// based on Remote Config.
class InteriorImageService {
  static String get _kieApiKey => RemoteConfigService.getKieApiKey();
  static String get _apiFreeKey => RemoteConfigService.getApiFreeKey();
  
  static const String _kieBaseUrl = 'https://api.kie.ai/api/v1';
  static const String _apiFreeBaseUrl = 'https://api.apifree.ai/v1';

  /// Primary interface for interior image editing.
  /// 
  /// Logic:
  /// 1. Fetches 'interior_provider_selection' from Remote Config.
  /// 2. If 'kie', uses Nano Banana Edit (Async logic with Job ID).
  /// 3. If 'apifree' (or default), uses the existing GPT-1.5/Edit model.
  static Future<String?> editInteriorImage({
    required String imageUrl,
    required String prompt,
    int? width,
    int? height,
  }) async {
    final provider = RemoteConfigService.getInteriorProviderSelection();
    debugPrint('🏡 [InteriorService] Selection: $provider');

    // Use provider logic
    if (provider == 'kie') {
      return _editWithKie(imageUrl, prompt, width, height);
    } else {
      return _editWithApiFree(imageUrl, prompt, width, height);
    }
  }

  // ==================== KIE AI LOGIC (google/nano-banana-edit) ====================

  static Future<String?> _editWithKie(String imageUrl, String prompt, int? width, int? height) async {
    try {
      debugPrint('🚀 [KIE] Starting Nano Banana Edit Task...');
      debugPrint('📷 Image: $imageUrl');
      debugPrint('💬 Prompt: $prompt');

      final body = {
        "model": "google/nano-banana-edit",
        "input": {
          "prompt": prompt,
          "image_urls": [imageUrl],
          "output_format": "png",
          "image_size": "auto",
        }
      };

      debugPrint('📡 [KIE] Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$_kieBaseUrl/jobs/createTask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_kieApiKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 [KIE] Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('❌ [KIE] HTTP Error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['code'] != 200) {
        debugPrint('❌ [KIE] API Error: ${data['message']} (code: ${data['code']})');
        return null;
      }

      final String taskId = data['data']['taskId'];
      debugPrint('✅ [KIE] Task Created Success! taskId: $taskId');

      // Return taskId. The UI or background manager will handle polling.
      return taskId;
    } catch (e) {
      debugPrint('❌ [KIE] Critical Error: $e');
      return null;
    }
  }

  // ==================== APIFREE LOGIC (openai/gpt-image-1.5/edit) ====================

  static Future<String?> _editWithApiFree(String imageUrl, String prompt, int? width, int? height) async {
    try {
      debugPrint('🚀 [APIFree] Starting GPT-1.5 Edit Task...');
      debugPrint('📷 Image: $imageUrl');
      
      final body = {
        "image": imageUrl,
        "model": "openai/gpt-image-1.5/edit",
        "num_images": 1,
        "prompt": prompt,
        "quality": "low",
        "size": _getApiFreeSize(width, height),
      };

      final response = await http.post(
        Uri.parse('$_apiFreeBaseUrl/image/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiFreeKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 [APIFree] Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('❌ [APIFree] HTTP Error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      if (data['code'] != 200) {
        debugPrint('❌ [APIFree] API Error: ${data['code_msg']}');
        return null;
      }

      final String requestId = data['resp_data']['request_id'];
      debugPrint('✅ [APIFree] Task Created! requestId: $requestId');

      return requestId;
    } catch (e) {
      debugPrint('❌ [APIFree] Error: $e');
      return null;
    }
  }

  // ==================== UTILS ====================


  static String _getApiFreeSize(int? width, int? height) {
    if (width == null || height == null) return "1024x1024";
    double ratio = width / height;
    if (ratio > 1.2) return "1536x1024";
    if (ratio < 0.8) return "1024x1536";
    return "1024x1024";
  }

}
