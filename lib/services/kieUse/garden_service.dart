import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';
import '../../prompts/garden_prompts.dart';

class GardenService {
  static String get _apiKey => RemoteConfigService.getKieApiKey();
  static const String _baseUrl = 'https://api.kie.ai/api/v1';
  static const String _model = 'flux-2/pro-image-to-image';
  
  static const bool TESTING_MODE = false;

  /// Create Garden Design Task
  static Future<String?> createGardenTask({
    required String userImageUrl,
    required String gardenStyle,
    String? colorPalette,
  }) async {
    try {
      debugPrint('🌿 Creating Garden Design Task (Flux-2 Pro)...');
      debugPrint('📷 Image: $userImageUrl');
      debugPrint('🌸 Style: $gardenStyle');

      String prompt = GardenPrompts.buildPrompt(gardenStyle, colorPalette);
      debugPrint('📝 Prompt: $prompt');

      if (TESTING_MODE) {
         await Future.delayed(const Duration(seconds: 1));
         return "fake_task_result_start-$userImageUrl";
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/jobs/createTask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'input': {
            'input_urls': [userImageUrl], // Flux-2 schema
            'prompt': prompt,
            'aspect_ratio': 'auto',
            'resolution': '1K',
          },
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
      debugPrint('❌ Error creating garden task: $e');
      return null;
    }
  }

  /// Poll for result and Save to My Creations
  static Future<String?> pollAndSaveResult({
    required String taskId,
    String? originalImageUrl,
  }) async {
    int attempts = 0;
    const maxAttempts = 30;

    while (attempts < maxAttempts) {
      attempts++;
      debugPrint('⏳ Polling Garden Design Result... attempt $attempts');

      final response = await http.get(
        Uri.parse('$_baseUrl/jobs/recordInfo?taskId=$taskId'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final state = data['data']?['state'];
          if (state == 'success') {
            final resultJson = data['data']?['resultJson'];
            if (resultJson != null) {
              final resultData = json.decode(resultJson);
              final resultUrls = resultData['resultUrls'] as List?;
              if (resultUrls != null && resultUrls.isNotEmpty) {
                final imageUrl = resultUrls[0] as String;
                return imageUrl;
              }
            }
          } else if (state == 'failed') {
            return null;
          }
        }
      }

      await Future.delayed(const Duration(seconds: 5));
    }
    return null;
  }
}
