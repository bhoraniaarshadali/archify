class GardenPrompts {
  static const String mainPrompt = '''You are an expert Landscape Architect AI.

TASK: Transform ONLY the ground/garden area in the uploaded photo into a professional garden design.

STRICT PRESERVATION RULES — NON-NEGOTIABLE:
• Keep ALL buildings, walls, fences, structures, and background EXACTLY as they are.
• Keep the camera angle, perspective, and field of view completely unchanged.
• Keep the overall spatial layout and boundaries of the garden area identical.
• Do NOT move, resize, or alter any non-ground elements.
• Do NOT change the sky, horizon, or any architectural elements.

WHAT TO TRANSFORM:
• Replace only the ground surface and plant life within the existing garden boundaries.
• Fill empty soil, dirt, or plain land with lush landscape elements.
• Add plants, grass, pathways, and decor ONLY within the existing ground footprint.
• Scale all plants and elements to match the perspective of the original photo.

OUTPUT QUALITY:
• Photorealistic, 8K quality, professional landscape photography style.
• Natural sunlight, soft shadows, high-resolution textures.
• The garden must look established and mature, not newly planted.

''';

  static const String style1Prompt = '''STYLE TO APPLY — Modern Minimalist:
• Clean geometric layout with straight-edged lawn sections.
• Natural stone or concrete paving with precise, clean joints.
• Minimal planting — low ornamental grasses, trimmed hedges, simple shrubs.
• Open green lawn areas with uncluttered, breathing space.
• No dense flower beds, no wild planting, no rustic elements.
• Calm, ordered, and low-maintenance aesthetic.
• Color palette: greens, grays, stone whites, natural wood tones.

''';

  static const String style2Prompt = '''STYLE TO APPLY — Lush Natural:
• Soft green lawn with natural organic edges.
• Natural stepping-stone pathway winding through the space.
• Layered planting: ground cover → shrubs → small trees.
• Warm ambient feel with varied greens and subtle flowering plants.
• Optional: wooden or natural-finish seating element if space allows.
• Rich, full, and inviting — not wild or overgrown.
• Color palette: deep greens, warm browns, soft whites, earthy tones.

''';

  static const String style3Prompt = '''STYLE TO APPLY — Zen:
• Raked gravel or fine stone ground treatment in sections.
• Carefully placed large decorative rocks or boulders.
• Minimal, intentional planting — bamboo, moss, ornamental grass, or bonsai-style shrubs.
• Strong sense of calm, balance, and empty space.
• No colorful flowers, no dense planting, no busy elements.
• Clean lines, natural materials, meditative atmosphere.
• Color palette: stone grays, moss greens, sand beige, deep earthy tones.

''';

  static const String style4Prompt = '''STYLE TO APPLY — Diwali Festive Garden:
• Strings of warm golden and orange fairy lights draped across plants and pathways.
• Marigold flowers (yellow and orange) planted in clusters and borders.
• Clay diyas placed along pathways and garden edges with warm glowing light.
• Rangoli-inspired decorative patterns near the entrance using colored flowers or stones.
• Lush green base with vibrant pops of saffron, gold, and deep orange throughout.
• Warm, celebratory, and richly decorated atmosphere.
• Color palette: saffron orange, marigold yellow, deep gold, warm white lights, rich greens.

''';

  static const String style5Prompt = '''STYLE TO APPLY — Christmas Festive Garden:
• Snow-dusted ground with subtle frost effect on grass and plants.
• Pine trees or evergreen shrubs decorated with red berries and fairy lights.
• Red and white poinsettia plants placed as focal points near pathways.
• String lights (warm white or multicolor) draped across trees and fence lines.
• Pinecones and holly berry clusters as ground-level decorative accents.
• Festive, magical, and cozy winter atmosphere.
• Color palette: snow white, deep pine green, holly red, warm golden light, midnight blue sky tones.

''';

  static String buildPrompt(String style, [String? colorPalette]) {
    String stylePrompt;
    switch (style) {
      case 'Modern Minimalist':
        stylePrompt = style1Prompt;
        break;
      case 'Lush Natural':
        stylePrompt = style2Prompt;
        break;
      case 'Zen':
        stylePrompt = style3Prompt;
        break;
      case 'Diwali':
        stylePrompt = style4Prompt;
        break;
      case 'Christmas':
        stylePrompt = style5Prompt;
        break;
      default:
        stylePrompt = style1Prompt;
    }
    return mainPrompt + stylePrompt;
  }
}
