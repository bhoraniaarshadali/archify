import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';
import '../helper/my_creations_service.dart';

class VideoGenerationService {
  static String get _apiKey => RemoteConfigService.getApiFreeKey();
  static const String _baseUrl = 'https://api.apifree.ai';
  static const String _model = 'klingai/kling-v2.5-turbo/standard/image-to-video';

  /// POST /v1/video/submit
  static Future<String?> submitVideoRequest({
    required String imageUrl,
    required String category,
    int duration = 5,
  }) async {
    // 🪙 Credit system is now handled at the UI layer

    try {
      debugPrint('🎬 Submitting Video Generation for category: $category');

      // 5️⃣ Duration Rules Enforcement
      int finalDuration = duration;
      if (category == '3D Model') {
        finalDuration = 10; // ONLY 10 sec supported for 3D Model
      }

      // 4️⃣ Category-Based Rules (Prompts Selection)
      String positivePrompt = _getPositivePrompt(category);
      String negativePrompt = "blur, distort, and low quality";

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/video/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'image': imageUrl,
          'prompt': positivePrompt,
          'negative_prompt': negativePrompt,
          'duration': finalDuration,
          'cfg_scale': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          return data['resp_data']?['request_id'] as String?;
        }
      }
      debugPrint('❌ Submit Error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Video Submit Error: $e');
      return null;
    }
  }

  /// GET /v1/video/{request_id}/status
  static Future<String?> getVideoStatus(String requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/video/$requestId/status'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          return data['resp_data']?['status'] as String?;
        }
      }
      return 'error';
    } catch (e) {
      debugPrint('❌ Status Error: $e');
      return 'error';
    }
  }

  /// GET /v1/video/{request_id}/result
  static Future<String?> getVideoResult(String requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/video/$requestId/result'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final videoList = data['resp_data']?['video_list'] as List?;
          if (videoList != null && videoList.isNotEmpty) {
            return videoList[0] as String?;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Result Error: $e');
      return null;
    }
  }

  static String _getPositivePrompt(String category) {
    if (category == '3D Model') {
      return """ A professional architectural showcase video generated strictly from the uploaded 3D floor plan model. The camera starts in a high top-down isometric view, clearly showing the complete house layout from above. The camera then performs a very slow and smooth downward camera movement, transitioning from top view to a slightly lower isometric angle, while keeping the entire house fully visible at all times. After settling into the lower isometric position, the camera begins a slow, continuous 360-degree orbital rotation around the model, maintaining a constant distance, height, and angle. All architectural elements remain 100% unchanged: walls, rooms, furniture placement, stairs, parking area, and proportions stay exactly as in the image. Lighting is clean and neutral with soft global daylight. Subtle shadow and light variation adds realism without distraction. No objects move. No doors open. No people appear. The video style is real estate and architectural presentation quality—calm, premium, and easy to understand for buyers and clients.
""";
    } else if (category == 'Interior') {
      return """
A premium, ultra-realistic interior showcase video generated strictly from the uploaded image. The camera starts from the original viewpoint of the image, preserving the exact room layout, furniture placement, proportions, and design style. The camera performs a slow, smooth cinematic movement — a gentle push-in combined with a subtle side or orbital motion — creating depth while keeping the same perspective and composition. The interior space remains 100% unchanged: walls, furniture, decor, lighting fixtures, textures, and colors stay exactly as in the image. Realistic interior lighting gently shifts to add life: – soft daylight variation through windows – subtle reflections on surfaces – calm shadow movement for depth. No objects move, no furniture rearranges, no doors open, no people appear.
""";
      // Interior
      // Create a high-fidelity, ultra-realistic interior showcase video strictly derived from the uploaded image.
      //
      // The generated video must preserve the scene with absolute accuracy:
      // – Exact room layout and spatial proportions
      // – Identical furniture placement and alignment
      // – Same decor, materials, textures, and color tones
      // – No addition, removal, or modification of any object
      //
      // The camera begins at the exact original image perspective (matching lens angle and framing).
      //
      // Apply a smooth cinematic motion:
      // – Slow dolly-in (2–5% depth progression)
      // – Subtle lateral slide OR gentle orbital movement (maximum 10° arc)
      // – Maintain natural perspective without distortion
      //
      // The camera movement must enhance depth while maintaining compositional integrity.
      //
      // Lighting behavior:
      // – Preserve original lighting setup
      // – Allow only subtle natural light variation (soft daylight intensity shift)
      // – Gentle reflection enhancement on surfaces
      // – Very soft dynamic shadow depth (no dramatic changes)
      //
      // Strict constraints:
      // – No new objects
      // – No object movement
      // – No furniture rearrangement
      // – No structural changes
      // – No people or animals
      // – No animated decor elements
      // – No artificial stylistic filters
      //
      // The output must look like a professional real estate cinematic shot derived 1:1 from the original image, with maximum detail retention and visual fidelity.

    } else {
      // Exterior
      return """
A premium, ultra-realistic architectural exterior showcase video generated strictly from the uploaded image. The camera starts from the original viewpoint of the facade, preserving the exact building structure, landscaping, proportions, and architectural style. The camera performs a slow, smooth cinematic movement — a gentle push-in or a subtle orbital sweep — highlighting the building's depth and facade details. The exterior structure remains 100% unchanged: walls, windows, roof, materials, and colors stay exactly as in the image. Realistic outdoor lighting gently shifts to add life: — subtle shadow movement as if from a passing cloud or moving sun — realistic reflections on glass surfaces — gentle movement in the surrounding vegetation. No parts of the building move, no doors or windows open, no people appear.
""";
    }
  }

  static CreationCategory _getCategoryEnum(String category) {
    switch (category) {
      case 'Interior':
        return CreationCategory.interior;
      case 'Exterior':
        return CreationCategory.exterior;
      case '3D Model':
        return CreationCategory.model3D;
      default:
        return CreationCategory.interior;
    }
  }
}
