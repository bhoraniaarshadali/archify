import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';
import '../../prompts/text_to_image_prompts.dart';

class ImageGenerationService {
  static String get _apiKey => RemoteConfigService.getKieApiKey();
  static const String _baseUrl = 'https://api.kie.ai/api/v1';

  static const bool TESTING_MODE = false;

  /// Create Text-to-Image Task
  static Future<String?> createTextToImageTask({
    required String prompt,
    String aspectRatio = '1:1',
  }) async {
    try {
      debugPrint('🚀 Creating Text-to-Image Task...');

      final enhancedPrompt = TextToImagePrompts.enhancePrompt(prompt);
      debugPrint('📝 Original: $prompt');
      debugPrint('✨ Enhanced: $enhancedPrompt');

      if (TESTING_MODE) {
        await Future.delayed(const Duration(seconds: 3));
        return "fake_task_result_start-placeholder";
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/jobs/createTask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'z-image',
          'input': {'prompt': enhancedPrompt, 'aspect_ratio': aspectRatio},
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final taskId = data['data']['taskId'];
          debugPrint('✅ Task created: $taskId');
          return taskId;
        } else {
          debugPrint('❌ API error: ${data['msg']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating text-to-image task: $e');
      return null;
    }
  }
}
