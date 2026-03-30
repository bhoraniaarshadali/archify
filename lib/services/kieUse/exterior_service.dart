import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../../ads/remote_config_service.dart';
import '../../prompts/exterior_prompts.dart';

class ExteriorService {
  static String get _apiKey => RemoteConfigService.getKieApiKey(FeatureType.exterior);
  static const String _baseUrl = 'https://api.kie.ai/api/v1';
  static const String _model = 'flux-2/pro-image-to-image';

  // 🔹 MOCK FLOW
  static const bool TESTING_MODE = false;

  /// Derive API aspect_ratio string from original image file.
  /// Returns one of: '1:1', '16:9', '9:16', '4:3', '3:4', '3:2', '2:3', 'auto'
  static Future<String> _getAspectRatioFromFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return 'auto';
      final w = decoded.width;
      final h = decoded.height;
      debugPrint('🖼️ Original image dimensions: ${w}x${h}');
      final ratio = w / h;
      
      // Match to nearest standard ratio
      if ((ratio - 1.0).abs() < 0.05) return '1:1';
      if ((ratio - 16 / 9).abs() < 0.08) return '16:9';
      if ((ratio - 9 / 16).abs() < 0.08) return '9:16';
      if ((ratio - 4 / 3).abs() < 0.08) return '4:3';
      if ((ratio - 3 / 4).abs() < 0.08) return '3:4';
      if ((ratio - 3 / 2).abs() < 0.08) return '3:2';
      if ((ratio - 2 / 3).abs() < 0.08) return '2:3';
      
      return 'auto';
    } catch (e) {
      debugPrint('⚠️ Could not read image dimensions: $e');
      return 'auto';
    }
  }

  /// Create Exterior Design Task: Image-to-Image with Style Reference or Single Image
  static Future<String?> createExteriorTask({
    required String userImageUrl,
    File? originalImageFile, // Pass original file for dimension detection
    String? styleReferenceUrl, // Optional: if null, use Single Image mode
    required String styleName,
    required String buildingType,
    String? colorPalette,
  }) async {
    try {
      debugPrint('🚀 Creating Exterior Design Task...');
      debugPrint('📷 User image: $userImageUrl');
      debugPrint('🏛️ Building type: $buildingType');
      debugPrint('🎨 Style name: $styleName');

      // Determine original image aspect ratio for size-matched output
      String aspectRatio = 'auto';
      if (originalImageFile != null) {
        aspectRatio = await _getAspectRatioFromFile(originalImageFile);
      }
      debugPrint('📐 Using aspect_ratio: $aspectRatio');

      String prompt;
      List<String> inputUrls;

      if (styleReferenceUrl != null) {
        // Two Images Mode
        debugPrint('🎨 Style reference: $styleReferenceUrl');
        prompt = ExteriorPrompts.buildPrompt(styleName, buildingType, colorPalette);
        inputUrls = [userImageUrl, styleReferenceUrl];
      } else {
        // Single Image Mode
        debugPrint('🎨 Single Image Mode');
        prompt = ExteriorPrompts.buildPromptSingleImage(
          styleName,
          buildingType,
          colorPalette,
        );
        inputUrls = [userImageUrl];
      }

      debugPrint('📝 Prompt: $prompt');

      if (TESTING_MODE) {
        debugPrint('🚧 TESTING MODE: Simulating Task Creation...');
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
            'input_urls': inputUrls,
            'prompt': prompt,
            'aspect_ratio': aspectRatio,
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
          debugPrint("❌ API error: ${data['msg']}");
          return null;
        }
      } else {
        debugPrint('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating exterior task: $e');
      return null;
    }
  }
}
