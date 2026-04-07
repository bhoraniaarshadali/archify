import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../ads/remote_config_service.dart';
import '../helper/my_creations_service.dart';

class VideoGenerationService {
  static String get _apiKey => RemoteConfigService.getKieApiKey(FeatureType.videoGeneration);
  static const String _baseUrl = 'https://api.kie.ai/api/v1';
  static const String _model = 'grok-imagine/image-to-video';

  /// POST /api/v1/jobs/createTask
  static Future<String?> submitVideoRequest({
    required String imageUrl,
    required String category,
    int duration = 8,
    String? userPrompt,
  }) async {
    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        debugPrint('❌ KieAI Error: API Key is empty. Check Remote Config.');
        return null;
      }
      debugPrint('🎬 Submitting KieAI Video Generation (Key Length: ${apiKey.length})');

      String durationStr = duration.toString();

      String positivePrompt = userPrompt ?? _getPositivePrompt(category);

      final response = await http.post(
        Uri.parse('$_baseUrl/jobs/createTask'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'input': {
            'image_urls': [imageUrl],
            'prompt': positivePrompt,
            'mode': 'normal',
            'duration': durationStr,
            'resolution': '480p',
            'aspect_ratio': '16:9',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          // KieAI format: {"code": 200, "data": {"taskId": "..."}}
          return data['data']?['taskId'] as String?;
        }
      }
      debugPrint('❌ KieAI Submit Error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ KieAI Video Submit Error: $e');
      return null;
    }
  }

  /// KieAI polling is handled by TaskPollingService.queryKieTask
  /// which uses GET /api/v1/jobs/recordInfo?taskId={taskId}

  static String _getPositivePrompt(String category) {
    if (category == 'Interior') {
      return """
A premium, ultra-realistic interior showcase video generated strictly from the uploaded image. The camera starts from the original viewpoint of the image, preserving the exact room layout, furniture placement, proportions, and design style. The camera performs a slow, smooth cinematic movement — a gentle push-in combined with a subtle side or orbital motion — creating depth while keeping the same perspective and composition. The interior space remains 100% unchanged: walls, furniture, decor, lighting fixtures, textures, and colors stay exactly as in the image. Realistic interior lighting gently shifts to add life: – soft daylight variation through windows – subtle reflections on surfaces – calm shadow movement for depth. No objects move, no furniture rearranges, no doors open, no people appear.
""";
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
      default:
        return CreationCategory.interior;
    }
  }
}
