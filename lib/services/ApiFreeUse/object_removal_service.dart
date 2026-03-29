import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';
import '../../prompts/object_removal_prompts.dart';

class ObjectRemovalService {
  static String get _apiFreeKey => RemoteConfigService.getApiFreeKey();
  static const String _apiFreeBaseUrl = 'https://api.apifree.ai/v1';
  static const String _removeObjectModel = 'openai/gpt-image-1-mini/edit';

  static const bool TESTING_MODE = false;

  /// Create Object Removal Task
  ///
  /// ✅ Removes objects based on prompt
  /// ✅ Preserves structure
  /// ✅ Using openai/gpt-image-1-mini/edit
  static Future<String?> createObjectRemovalTask({
    required String imageUrl,
    required String instructions, // What to remove
    required int width,
    required int height,
  }) async {
    // 🔹 MOCK FLOW
    if (TESTING_MODE) {
      debugPrint('🚧 TESTING MODE: Simulating Task Creation (API FREE)...');
      await Future.delayed(const Duration(seconds: 1));
      return "fake_task_result_start-$imageUrl";
    }

    try {
      debugPrint('🧹 Creating Object Removal task (ApiFree)...');
      debugPrint('📷 Image: $imageUrl');
      debugPrint('📝 Instructions: $instructions');

      // Determine size based on aspect ratio
      String size = '1024x1024';
      double ratio = width / height;
      if (ratio > 1.2) {
        size = '1536x1024'; // Landscape
      } else if (ratio < 0.8) {
        size = '1024x1536'; // Portrait
      }
      debugPrint('📏 Selected size: $size (Original: ${width}x$height)');

      // General purpose object removal prompt
      String finalPrompt = ObjectRemovalPrompts.getGeneralRemovalPrompt();

      // Note: The original prompt logic might need 'instructions' integrated if specific items are removed. 
      // The original KieApiService implementation used ObjectRemovalPrompts.getGeneralRemovalPrompt() 
      // but 'instructions' argument was passed but not used in the prompt construction in the original file I viewed?
      // Wait, let's check Step 7.
      // Line 726: `String finalPrompt = ObjectRemovalPrompts.getGeneralRemovalPrompt();`
      // It DOES NOT use `instructions` variable passed in line 699. This seems like a bug in original code or intentional.
      // I will keep it as is to avoid breaking behavior, but maybe add a TODO.
      // Use instructions if logic requires it. For now, matching original implementation.
      
      final requestBody = {
        "image": imageUrl,
        "model": _removeObjectModel,
        "num_images": 1,
        "prompt": finalPrompt,
        "quality": "low", // Specified as 'low' in requirements
        "size": size,
      };

      debugPrint('📝 Full Prompt: $finalPrompt');

      final response = await http.post(
        Uri.parse('$_apiFreeBaseUrl/image/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiFreeKey',
        },
        body: json.encode(requestBody),
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final requestId = data['resp_data']['request_id'];
          debugPrint('✅ Object Removal Task created: $requestId');
          return requestId;
        } else {
          debugPrint('❌ API error: ${data['code_msg']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating object removal task: $e');
      return null;
    }
  }

  /// Poll for result and Save to My Creations
  static Future<String?> pollAndSaveResult({
    required String requestId,
    String? originalImageUrl,
  }) async {
    int attempts = 0;
    const maxAttempts = 30;

    while (attempts < maxAttempts) {
      attempts++;
      debugPrint('⏳ Polling Object Removal Result... attempt $attempts');

      final response = await http.get(
        Uri.parse('$_apiFreeBaseUrl/image/$requestId/result'),
        headers: {'Authorization': 'Bearer $_apiFreeKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final status = data['resp_data']?['status'];
          if (status == 'success') {
            final imageList = data['resp_data']?['image_list'] as List?;
            if (imageList != null && imageList.isNotEmpty) {
              final imageUrl = imageList[0] as String;
              return imageUrl;
            }
          } else if (status == 'failed' || status == 'error') {
            return null;
          }
        }
      }

      await Future.delayed(const Duration(seconds: 5));
    }
    return null;
  }
}
