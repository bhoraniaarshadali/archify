class FloorPlanPrompts {
  static String getConversionPrompt() {
    return '''You are an expert architectural visualization AI.

TASK: Convert the uploaded 2D floor plan drawing into a photorealistic 3D rendered floor plan.

STRICT RULES:
• Follow ONLY the rooms, walls, and layout shown in the uploaded drawing exactly.
• Do NOT add rooms, furniture, or elements that are not in the original drawing.
• Do NOT change room positions, sizes, or proportions.
• Keep all structural walls and boundaries identical to the input.

RENDERING REQUIREMENTS:
• Top-down isometric perspective (slight angle, not flat top-down).
• Realistic materials: wooden flooring, white walls, subtle shadows.
• Add appropriate furniture only where rooms clearly indicate it (bedroom → bed, kitchen → counter).
• Natural soft lighting with realistic shadows.
• Remove all text, labels, and dimension lines from the final render.
• Clean, neutral background.

OUTPUT: Photorealistic architectural 3D floor plan, 8K quality, professional visualization style.''';
  }
}

// class FloorPlanPrompts {
//   static String getConversionPrompt({String style = 'Modern Industrial'}) {
//     return '''
//       Photorealistic detailed 3D floor plan rendering, isometric perspective, white background.
//       Style: $style with high-end materials like polished concrete and oak wood.
//       Strictly follow the uploaded 2D layout for structural boundaries.
//       Do NOT add extra rooms. Render exact furniture placement as per the drawing.
//       Architectural visualization, realistic sun lighting through windows, soft shadows, 8k resolution, Unreal Engine 5 render style. add doors where designed.
//     ''';
//   }
// }