import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';

/// Experimental Interior Service using JSON-based styles
/// This is isolated and does NOT affect existing interior flows
class InteriorExperimentService {
  static String get _apiKey => RemoteConfigService.getApiFreeKey(FeatureType.interior);
  static const String _baseUrl = 'https://api.apifree.ai/v1';
  static const String _model = 'openai/gpt-image-1.5/edit';

  /// Create Interior Edit Task using JSON prompt
  static Future<String?> createTask({
    required String imageUrl,
    required String finalPrompt,
    int? width,
    int? height,
  }) async {
    if (imageUrl.isEmpty) {
      debugPrint('❌ [Experiment] Request blocked: Image URL is missing');
      return null;
    }

    try {
      debugPrint('🧪 [Experiment] Creating Interior Edit task...');
      debugPrint('📷 Input Image: $imageUrl');
      debugPrint('💬 Final Prompt: $finalPrompt');
      debugPrint('🤖 Model: $_model');

      // Determine size based on aspect ratio
      String size = '1024x1024';
      if (width != null && height != null) {
        double ratio = width / height;
        if (ratio > 1.2) {
          size = '1536x1024'; // Landscape
        } else if (ratio < 0.8) {
          size = '1024x1536'; // Portrait
        }
      }
      debugPrint('📏 Selected size: $size');

      final requestBody = {
        "image": imageUrl,
        "model": _model,
        "num_images": 1,
        "prompt": finalPrompt,
        "quality": "low",
        "size": size,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/image/submit'),
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
          final requestId = data['resp_data']['request_id'];
          debugPrint('✅ Experiment Task created: $requestId');
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
      debugPrint('❌ Error creating experiment task: $e');
      return null;
    }
  }

  /// Poll for result
  static Future<String?> pollResult(String requestId) async {
    int attempts = 0;
    const maxAttempts = 30;

    while (attempts < maxAttempts) {
      attempts++;
      debugPrint('⏳ [Experiment] Polling... attempt $attempts');

      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/image/$requestId/result'),
          headers: {'Authorization': 'Bearer $_apiKey'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 200) {
            final status = data['resp_data']?['status'];
            if (status == 'success') {
              final imageList = data['resp_data']?['image_list'] as List?;
              if (imageList != null && imageList.isNotEmpty) {
                final finalImageUrl = imageList[0] as String;
                debugPrint('✅ [Experiment] Result ready: $finalImageUrl');
                return finalImageUrl;
              }
            } else if (status == 'failed' || status == 'error') {
              debugPrint('❌ [Experiment] Task failed');
              return null;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ [Experiment] Polling error: $e');
      }

      await Future.delayed(const Duration(seconds: 5));
    }

    debugPrint('❌ [Experiment] Polling timeout');
    return null;
  }
}
