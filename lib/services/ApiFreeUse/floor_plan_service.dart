import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';
import '../../prompts/floor_plan_prompts.dart';

class FloorPlanService {
  static String get _apiFreeKey => RemoteConfigService.getApiFreeKey(FeatureType.floorPlan);
  static const String _apiFreeBaseUrl = 'https://api.apifree.ai/v1';
  static const String _modelApiFree = 'black-forest-labs/flux-2-dev/edit';  // cost inr0.90 dollar 0.00996

  static const bool TESTING_MODE = false;

  /// Create 2D to 3D Floor Plan Task
  static Future<String?> createFloorPlanTask({
    required String floorPlanUrl,
    int width = 1024,
    int height = 1024,
  }) async {
    try {
      debugPrint('📐 Creating Floor Plan Task...');
      debugPrint('📏 Dimensions: ${width}x$height');

      final prompt = FloorPlanPrompts.getConversionPrompt();
      debugPrint('📝 Prompt: $prompt');

      if (TESTING_MODE) {
        await Future.delayed(const Duration(seconds: 1));
        return "fake_task_result_start-$floorPlanUrl";
      }

      final requestBody = {
        "height": height,
        "image_urls": [floorPlanUrl],
        "model": _modelApiFree,
        "num_images": 1,
        "num_inference_steps": 28,
        "prompt": prompt,
        "width": width
      };

      final response = await http.post(
        Uri.parse('$_apiFreeBaseUrl/image/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiFreeKey',
        },
        body: json.encode(requestBody),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final requestId = data['resp_data']['request_id'];
          debugPrint('✅ Task created: $requestId');
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
      debugPrint('❌ Error creating floor plan task: $e');
      return null;
    }
  }
}
