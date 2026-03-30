import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';

class TextToImageZImageService {
  static String get _apiKey => RemoteConfigService.getKieApiKey(FeatureType.imageGeneration);
  static const String _baseUrl = 'https://api.kie.ai/api/v1';
  static const String _model = 'z-image';

  /// Create Text-to-Image Task (z-image)
  static Future<String?> createZImageTask({
    required String prompt,
    required String aspectRatio,
  }) async {
    try {
      debugPrint('🚀 Creating Text-to-Image Task (z-image)...');
      debugPrint('📝 Prompt: $prompt');
      debugPrint('📐 Aspect Ratio: $aspectRatio');

      final response = await http.post(
        Uri.parse('$_baseUrl/jobs/createTask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'input': {
            'prompt': prompt,
            'aspect_ratio': aspectRatio,
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
          debugPrint('❌ API error: ${data['msg'] ?? data}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        debugPrint('❌ Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating task: $e');
      return null;
    }
  }

  /// Poll for Result
  static Future<String?> pollZImageTask(String taskId) async {
    int attempts = 0;
    const maxAttempts = 30; // 30 * 4s = 120s timeout

    while (attempts < maxAttempts) {
      attempts++;
      debugPrint('⏳ Polling Text-to-Image Result... attempt $attempts');

      try {
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
                // Parse the nested JSON string
                final resultData = json.decode(resultJson);
                final resultUrls = resultData['resultUrls'] as List?;
                
                if (resultUrls != null && resultUrls.isNotEmpty) {
                  final imageUrl = resultUrls[0] as String;
                  debugPrint('✅ Generation successful: $imageUrl');
                  return imageUrl;
                }
              }
            } else if (state == 'failed') {
               debugPrint('❌ Generation failed state');
               return null;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Polling error: $e');
      }

      await Future.delayed(const Duration(seconds: 4));
    }
    return null;
  }
}
