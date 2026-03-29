import 'prompt_utils.dart';

// Professional prompts based on successful competitor app analysis
// These prompts ensure structure preservation while allowing realistic cosmetic upgrades

final List<String> stylePrompts = [
  // 1. Default - Modern Luxury Upgrade
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
CRITICAL - DO NOT MODIFY: footprint, dimensions, floors, window/door positions, roof shape.
COSMETIC UPGRADES ONLY:
• Exterior walls: Premium beige, cream, or warm gray.
• Accents: Wood-tone panels, charcoal frames, matte black railings.
• Lighting: Modern wall-mounted sconces, LED strips.
• Result: Premium modern makeover, neutral elegant colors.''',

  // 2. Modern Minimalist
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Walls: Pure white or light gray.
• Contrast: Charcoal or matte black frames.
• Materials: Ultra-smooth matte finish, glass railings with slim frames.
• Result: Ultra-clean, monochromatic, minimalist aesthetic.''',

  // 3. Victorian Elegance
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Colors: Rich burgundy, forest green, or navy blue with cream trim.
• Details: Traditional lantern-style fixtures, ornamental paint on fascia.
• Landscaping: English garden style, brick pathways.
• Result: Rich traditional colors, elegant classic look.''',

  // 4. Industrial Modern
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Walls: Concrete gray, textured cement, or dark charcoal.
• Accents: Rust brown, oxidized metal, or matte black steel.
• Lighting: Edison bulbs, metal cage fixtures.
• Result: Raw urban loft aesthetic, moody industrial vibe.''',

  // 5. NEW: Mediterranean / Spanish Revival
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Walls: Smooth white stucco, off-white, or light sandy beige.
• Roof: Terracotta red clay tiles (maintain existing shape).
• Accents: Wrought iron grilles, turquoise or royal blue door accents.
• Details: Arched motifs in paint, decorative mosaic tiles near entrance.
• Result: Warm, sun-drenched coastal aesthetic, Mediterranean charm.''',

  // 6. NEW: Modern Farmhouse
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Walls: White board and batten siding or vertical slats.
• Contrast: Stark matte black window frames and gables.
• Materials: Natural light oak wood porch/beams, galvanized metal accents.
• Landscaping: Simple greenery, lavender, and gravel paths.
• Result: Trendy high-contrast rustic-modern look, cozy yet clean.''',

  // 7. NEW: Scandinavian / Nordic
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Walls: Light ash wood, pale pine, or soft white.
• Colors: Monochromatic light palette (whites, very light grays).
• Accents: Large glass panes, minimalist black hardware.
• Result: Hygge aesthetic, bright, airy, and functional Nordic design.''',

  // 8. NEW: Tudor / Classic Brick & Stone
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Walls: Exposed red or brown brick, or decorative half-timbering patterns.
• Accents: Dark brown wood trim, leaded glass window effects.
• Materials: Natural heavy stone foundation, slate-colored roof.
• Result: Timeless European charm, sturdy and prestigious appearance.''',

  // 9. NEW: Mid-Century Modern
  '''ARCHITECTURAL EXTERIOR RENOVATION - STRUCTURE PRESERVATION MANDATORY
COSMETIC UPGRADES ONLY:
• Walls: Mustard yellow, teal, or muted orange accent sections.
• Main Color: Warm gray or walnut wood siding.
• Details: Atomic-era lighting, geometric patterns on doors.
• Result: Retro-chic 1950s aesthetic, bold colors with organic shapes.''',
];

class ExteriorPrompts {
  static String buildPrompt(String styleName, String buildingType, String? colorPalette) {
    final colorInstruction = _getColorInstruction(styleName, colorPalette);
    final styleKeywords = getSimpleExteriorKeywords(styleName);
    final styleDescription = getStyleDescription(styleName);

    return '''
### ROLE: Professional Architectural Exterior Visualizer

### PRIMARY GOAL:
Perform a photorealistic image-to-image renovation of the uploaded $buildingType into the $styleName style.

### 🏠 CORE STRUCTURE PRESERVATION (STRICT):
- **LAYOUT LOCK**: The building's layout, number of floors, and original footprint MUST NOT change.
- **POSITIONAL LOCK**: Windows and doors MUST remain in their exact current locations and maintain their original counts.
- **GEOMETRY LOCK**: Do not add new wings, balconies, or floors. Do not remove any existing structural parts. Keep the original roof angle and silhouette.
- **PERSPECTIVE LOCK**: Maintain the exact same camera angle, zoom, and perspective as the original photo.

### ✨ HIGH-END VISUAL RENOVATION (NOT JUST PAINT):
- **WINDOWS**: Upgrade the design of all windows. Replace frames with $styleName-appropriate materials (e.g., sleek black metal for Modern, ornate wood for Victorian). Keep original sizes and positions but fully upgrade the glass and frame design.
- **DOORS**: Replace existing doors with high-design versions matching the $styleName aesthetic.
- **ROOFING**: Fully transform the roof surface. Swap the material for $styleName-appropriate textures (e.g., Terracotta barrel tiles for Mediterranean, Standing seam metal for Modern). Keep the *original shape* but upgrade the material.
- **FACADE**: Apply rich textures and premium materials (Natural stone, vertical wood siding, smooth stucco, or brick) as per the $styleName style.
- **LIGHTING & ACCENTS**: Integrate style-appropriate exterior lighting and trim.

### 🏛️ STYLE DEFINITION: $styleName
$styleDescription
Keywords: $styleKeywords

### 🎨 COLOR PALETTE:
$colorInstruction

### 🛠️ TECHNICAL SPECIFICATIONS:
- High-resolution 8K architectural rendering.
- Professional photography lighting (Golden hour or clean daylight).
- Realistic shadows, depth, and weather-appropriate reflections.
- No watermarks, text, or AI artifacts.
- No cartoon or illustrative looks; must be indistinguishable from a real photo.

### 🚫 ABSOLUTE NEGATIVES (STRICTLY FORBIDDEN):
- No change in building geometry or footprint.
- No addition or removal of floors.
- No moving or resizing of windows/doors.
- No camera angle changes.
- No flat, low-quality "painted over" looks; materials must have realistic 3D depth.
''';
  }

  static String buildPromptSingleImage(
    String styleName,
    String buildingType,
    String? colorPalette,
  ) {
    return buildPrompt(styleName, buildingType, colorPalette);
  }

  static String getSimpleExteriorKeywords(String? style) {
    switch (style) {
      case 'Modern': return 'Modern materials, large black-framed glass, charcoal wood panels, clean textures, metal accents';
      case 'Victorian': return 'Craftsman style, horizontal lap siding, stone accents, decorative trim, earth tones';
      case 'Industrial': return 'Raw concrete, dark gray stucco, black steel frames, urban industrial materials, moody tones';
      case 'Minimalist': return 'Pure white smooth stucco, large frameless glass, minimal textures, zen aesthetic';
      case 'Rustic': return 'Natural stacked stone, weathered wood, timber beams, iron hardware, warm browns';
      case 'Luxury': return 'Fine white stone, classical columns, ornate moldings, iron balustrades, premium marble finish';
      case 'Mediterranean': return 'White stucco, terracotta roof tiles, wrought iron, warm coastal colors, arched motifs';
      case 'Modern Farmhouse': return 'White vertical siding, matte black accents, natural wood timber, gabled roof details, high contrast';
      case 'Scandinavian': return 'Light wood cladding, soft whites, large glass, minimalist hardware, Nordic look';
      case 'Tudor': return 'Dark half-timbering, red brick, European traditional textures, classic appeal';
      case 'Mid-Century': return 'Horizontal color blocks, walnut wood, geometric patterns, atomic-age details';
      default: return 'Contemporary premium materials, clean textures, elegant design';
    }
  }

  static String getStyleDescription(String? style) {
    if (style == null || style == 'Other' || style == 'Surprise Me') {
      return 'Contemporary design: use sleek smooth rendering, large glass window panels, and clean modern finishes for a refined architectural look.';
    }

    switch (style) {
      case 'Modern':
        return 'Modern Transformation: Upgrade window frames to sleek black aluminum. Replace facade with dark gray metal panels and vertical light oak slats. Use a high-end standing seam metal roof surface.';
      case 'Victorian':
        return 'Victorian Transformation: Replace window frames with intricate traditional molding. Use horizontal lap siding in earth tones with a stone base foundation. Upgrade the roof with textured slate-look shingles.';
      case 'Industrial':
        return 'Industrial Transformation: Use real concrete textures and dark charcoal brick. Upgrade window frames to thick black steel grids. Use flat matte metal roofing and raw architectural lighting.';
      case 'Minimalist':
        return 'Minimalist Transformation: Use ultra-smooth off-white stucco with hidden seams. Upgrade windows to large frameless glass panels. Hide all ornate details for a pure geometric aesthetic.';
      case 'Rustic':
        return 'Rustic Transformation: Use natural rough-cut fieldstone feature walls and weathered vertical wood planks. Upgrade roof with heavy timber rafters and cedar-look shingles.';
      case 'Luxury':
        return 'Luxury Transformation: Use polished limestone or marble facade panels. Upgrade windows and doors with champagne or gold-tinted finishes. Add ornate classical moldings and a grand entrance feel.';
      case 'Mediterranean':
        return 'Mediterranean Transformation: Swap roofing for red-orange terracotta barrel tiles. Use smooth white sand-stucco. Upgrade to arched window motifs and wrought-iron decorative balconies.';
      case 'Modern Farmhouse':
        return 'Modern Farmhouse Transformation: Use white vertical board-and-batten siding. Upgrade window frames to matte black steel. Integrate natural light-oak timber columns and beams.';
      case 'Scandinavian':
        return 'Scandinavian Transformation: Use light ash wood horizontal cladding and monochromatic whites. Upgrade window frames to minimalist thin-line black frames. Bright, airy atmospheric lighting.';
      case 'Tudor':
        return 'Tudor Transformation: Add dark espresso half-timbering patterns over cream plaster. Use textured red-brown brick for the base. Upgrade windows with leaded or diamond-pane glass looks.';
      case 'Mid-Century':
      case 'Mid-Century Modern':
        return 'Mid-Century Transformation: Use horizontal walnut wood siding with teal and mustard-yellow geometric color blocks. Upgrade the door with an iconic atomic-age wood design and starburst lighting.';
      default:
        return 'Refined architectural transformation: use premium materials and high-end finishes that match the selected style while preserving the original structure.';
    }
  }

  static String _getColorInstruction(String styleName, String? colorPalette) {
    if (colorPalette == null || colorPalette == 'Surprise Me') {
      return _getDefaultColorForStyle(styleName);
    }
    switch (colorPalette) {
      case 'Sandstone Serenity':
        return 'Palette: Sandstone Serenity (Beige #E8D5C4, Cream #F5F0E8, Soft Brown #A67C52).';
      case 'Serene Bloom':
        return 'Palette: Serene Bloom (Cool Gray #D3D8DC, White #F8F9FA, Blue-Gray #B8C5D0).';
      case 'Bold & Noble':
        return 'Palette: Bold & Noble (Burgundy #7A2E2E, Navy #1A3A52, Forest Green #2C5530).';
      case 'Monochrome':
        return 'Palette: Monochrome (White #FFFFFF, Gray #808080, Black #1A1A1A).';
      case 'Milk Tea Alliance':
        return 'Palette: Milk Tea Alliance (Sandstone #D4C5B0, Taupe #A89F91, Wood Brown #8B4513).';
      case 'Mediterranean Sun':
        return 'Palette: Mediterranean Sun (Stucco White #FEF9F3, Terracotta #C06044, Royal Blue #00539C).';
      case 'Farmhouse Contrast':
        return 'Palette: Farmhouse Contrast (White #E8E8E8, Matte Black #232323, Natural Wood).';
      case 'Nordic Minimal':
        return 'Palette: Nordic Minimal (Cotton White, Light Ash Gray, Pale Pine Wood).';
      case 'Vintage Tudor':
        return 'Palette: Vintage Tudor (Deep Brick Red, Dark Walnut, Aged Stone Gray).';
      case 'Retro Mid-Century':
        return 'Palette: Retro Mid-Century (Teal Accent, Mustard yellow, Walnut wood base).';
      default:
        return 'Use this exact color scheme: $colorPalette.';
    }
  }

  static String _getDefaultColorForStyle(String styleName) {
    switch (styleName) {
      case 'Modern': return 'Use charcoal, gray, and white with black metal accents.';
      case 'Victorian': return 'Use warm cream with forest green or burgundy accents.';
      case 'Industrial': return 'Use concrete gray, charcoal, and oxidized rust tones.';
      case 'Minimalist': return 'Use pure white and light gray with minimal black details.';
      case 'Rustic': return 'Use warm browns, fieldstone grays, and natural wood tones.';
      case 'Luxury': return 'Use limestone white, cream, and gold or bronze highlights.';
      case 'Mediterranean': return 'Use sand-white with terracotta and royal blue accents.';
      case 'Modern Farmhouse': return 'Use bright white siding with matte black gables and oak timber.';
      case 'Scandinavian': return 'Use monochromatic whites and light ash-wood textures.';
      case 'Tudor': return 'Use cream walls with dark espresso wood and red brick bases.';
      case 'Mid-Century':
      case 'Mid-Century Modern':
         return 'Use walnut wood with muted teal and mustard yellow color blocks.';
      default: return 'Use high-quality neutral materials: warm whites, light grays, and charcoals.';
    }
  }
}