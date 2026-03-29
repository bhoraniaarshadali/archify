import 'interior_transformation_mapper.dart';

class InteriorDesignPipeline {
  static String buildPrompt({
    required String styleName,
    required String stylePrompt,
    required List<String> selectedColors,
    required int progress,
    String? roomType,
  }) {
    final transformation = InteriorTransformationMapper.fromProgress(progress);
    final room = (roomType != null && roomType.isNotEmpty) ? roomType : 'room';

    final colorInstruction = selectedColors.isEmpty
        ? 'Choose the most fitting color palette for $styleName style.'
        : 'Apply ONLY these colors: ${selectedColors.join(', ')}. Use them on walls, ceiling, furniture surfaces, and decor. Do not use any other colors.';

    return '''You are an expert interior designer AI.

TASK: Redesign this $room using $styleName interior design style.
Transformation level: $transformation.

STYLE DETAILS:
$stylePrompt

STRICT STRUCTURE RULES — NON-NEGOTIABLE:
• Keep the exact room layout, dimensions, and architecture unchanged.
• Keep all doors, windows, and walls in their original positions.
• Keep the camera angle and perspective exactly the same.
• Do NOT add or remove walls, windows, or doors.
• Do NOT change the room geometry or spatial layout.

WHAT TO CHANGE:
• Replace furniture appearance, upholstery, and finishes to match $styleName style.
• Update wall treatments, flooring, and ceiling finishes.
• Apply $styleName-appropriate lighting fixtures and decor.
• Apply style-appropriate textures and materials throughout.

COLOR INSTRUCTIONS:
$colorInstruction

OUTPUT: Photorealistic interior render, 8K quality, natural lighting, professional photography style, no watermarks, no artifacts.

NEGATIVE PROMPT:
No structural changes, no layout modification, no perspective change, no added rooms, no removed walls, no cartoon style, no painting style, realistic only.''';
  }
}
