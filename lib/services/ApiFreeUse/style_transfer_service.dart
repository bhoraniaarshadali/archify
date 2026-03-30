import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';
import '../../prompts/style_transfer_prompts.dart';

class StyleTransferService {
  static String get _apiKey => RemoteConfigService.getApiFreeKey(FeatureType.styleTransfer);
  static const String _baseUrl = 'https://api.apifree.ai/v1';
  static const String _model = 'black-forest-labs/flux-2-pro/edit';

  static const bool TESTING_MODE = false;

  /// Create Style Transfer Task
  static Future<String?> createStyleTransferTask({
    required String originalImageUrl,
    required String referenceImageUrl,
    required int width,
    required int height,
  }) async {
    try {
      debugPrint('🎨 Creating Style Transfer Task (ApiFree)...');
      debugPrint('📷 Original: $originalImageUrl');
      debugPrint('🖼️ Reference: $referenceImageUrl');

      String prompt = StyleTransferPrompts.getTransferPrompt();
      debugPrint('📝 Prompt: $prompt');

       if (TESTING_MODE) {
         await Future.delayed(const Duration(seconds: 1));
         return "fake_task_result_start-$originalImageUrl";
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/image/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'image_urls': [originalImageUrl, referenceImageUrl],
          'prompt': prompt,
          'num_images': 1,
          'num_inference_steps': 28,
          'width': width,
          'height': height,
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final taskId = data['resp_data']['request_id'];
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
      debugPrint('❌ Error creating style transfer task: $e');
      return null;
    }
  }
}
