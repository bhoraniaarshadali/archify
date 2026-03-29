import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';

class ItemReplacementService {
  static String get _apiKey => RemoteConfigService.getKieApiKey();
  static const String _baseUrl = 'https://api.kie.ai/api/v1';
  static const String _modelIdeogramV3 = 'ideogram/v3-edit';

  static const bool TESTING_MODE = false;

  static const String _modelFluxPro = 'flux-2/pro-image-to-image';

  /// Create ITEM REPLACEMENT Task (Flux-2 Pro / Image-to-Image)
  ///
  /// ✅ Uses flux-2/pro-image-to-image
  /// ✅ Requires Input URLs list: [Original, Mask, Reference]
  static Future<String?> createFluxReplacementTask({
    required String originalImageUrl,
    required String maskImageUrl,
    required String referenceImageUrl,
    required String prompt,
  }) async {
      // 🔹 MOCK FLOW
    if (TESTING_MODE) {
      debugPrint(
        '🚧 TESTING MODE: Simulating Object Replacement (Flux Service)...',
      );
      await Future.delayed(const Duration(seconds: 1));
      return "fake_task_result_start_flux-$originalImageUrl";
    }

    try {
      debugPrint('✨ Creating FLUX REPLACEMENT task (Flux-2 Pro Image-to-Image)...');
      debugPrint('📷 Input URLs: [$originalImageUrl, $maskImageUrl, $referenceImageUrl]');
      debugPrint('📝 Prompt: $prompt');

      final requestBody = {
        'model': _modelFluxPro,
        'input': {
          'prompt': prompt,
          'input_urls': [originalImageUrl, maskImageUrl, referenceImageUrl],
          'aspect_ratio': 'auto',
          'resolution': '1K',
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/jobs/createTask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(requestBody),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final taskId = data['data']['taskId'];
          debugPrint('✅ Flux Replacement Task created: $taskId');
          return taskId;
        } else {
          debugPrint('❌ API error: ${data['msg']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        debugPrint('❌ HTTP body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating flux replacement task: $e');
      return null;
    }
  }

  /// Create ITEM REPLACEMENT Task (Ideogram V3 Edit)
  ///
  /// ✅ Uses ideogram/v3-edit
  /// ✅ Requires Original Image + Mask Image + Prompt
  static Future<String?> createItemReplacementTask({
    required String originalImageUrl,
    required String maskImageUrl,
    required String prompt,
    String renderingSpeed = 'TURBO',
    bool expandPrompt = true,
  }) async {
    // 🔹 MOCK FLOW
    if (TESTING_MODE) {
      debugPrint(
        '🚧 TESTING MODE: Simulating Object Replacement (Ideogram Service)...',
      );
      await Future.delayed(const Duration(seconds: 1));
      return "fake_task_result_start-$originalImageUrl";
    }

    try {
      debugPrint('✨ Creating ITEM REPLACEMENT task (Ideogram V3)...');
      debugPrint('📷 Image: $originalImageUrl');
      debugPrint('🎭 Mask: $maskImageUrl');
      debugPrint('📝 Prompt: $prompt');

      final requestBody = {
        'model': _modelIdeogramV3,
        'input': {
          'prompt': prompt,
          'image_url': originalImageUrl,
          'mask_url': maskImageUrl,
          'rendering_speed': renderingSpeed,
          'expand_prompt': expandPrompt,
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/jobs/createTask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(requestBody),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final taskId = data['data']['taskId'];
          debugPrint('✅ Item Replacement Task created: $taskId');
          return taskId;
        } else {
          debugPrint('❌ API error: ${data['msg']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        debugPrint('❌ HTTP body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating item replacement task: $e');
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
      debugPrint('⏳ Polling Item Replacement Result... attempt $attempts');

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
