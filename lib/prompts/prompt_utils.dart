class PromptUtils {
  static String getColorPaletteDescription(String? colorPalette) {
    if (colorPalette == null || colorPalette == 'Surprise Me') {
      return 'Premium off-white stone (#F5F1E8) with matte black (#1A1A1A) window frames and subtle metallic accents';
    }

    switch (colorPalette) {
      case 'Warm':
        return 'Warm beige (#E8D5C4), cream (#F5F0E8), and soft brown (#A67C52) tones with natural wood accents in honey oak or walnut finish';
      case 'Cool':
        return 'Cool light gray (#D3D8DC), crisp white (#F8F9FA), and soft blue-gray (#B8C5D0) tones with brushed silver or chrome accents';
      case 'Bold':
        return 'Bold deep burgundy (#7A2E2E), navy blue (#1A3A52), and forest green (#2C5530) with brushed gold or brass accents';
      case 'Neutral':
        return 'Neutral palette: pure white (#FFFFFF), medium gray (#808080), and matte black (#1A1A1A) in a sophisticated monochrome scheme';
      case 'Natural':
        return 'Natural earth tones: sandstone beige (#D4C5B0), terracotta (#C87855), natural wood browns, and stone gray textures';
      default:
        return 'Premium off-white stone (#F5F1E8) with matte black (#1A1A1A) window frames and subtle metallic accents';
    }
  }
}
