class StyleTransferPrompts {
  static String getTransferPrompt() {
    return '''You are given two images:
- Image-1: The BASE image (a home/room). This is the structural template. DO NOT change its layout, geometry, furniture positions, walls, ceiling, floor plan, camera angle, or perspective. These must remain 100% identical.
- Image-2: The STYLE REFERENCE image. Extract ONLY its visual design language.

Your task: Repaint and restyle Image-1 using the exact aesthetic of Image-2.

WHAT TO EXTRACT FROM IMAGE-2 AND APPLY TO IMAGE-1:
- Color palette — dominant and accent colors, wall colors, floor tones
- Surface materials — wood type, marble, concrete, fabric, metal finishes
- Textures — rough, smooth, matte, glossy, woven, etc.
- Lighting mood — warm/cool, bright/dim, ambient/dramatic, natural/artificial
- Decorative style — modern, rustic, industrial, luxury, minimalist, etc.
- Furniture finish and upholstery style (keep shapes from Image-1, change surface appearance)

STRICT RULES — MUST FOLLOW:
1. Structure of Image-1 is LOCKED. Same walls, same layout, same furniture silhouettes, same perspective.
2. DO NOT add new furniture, remove existing furniture, or change room geometry.
3. DO NOT change the camera angle or field of view.
4. Color grading and material surface of EVERY element must visually match Image-2's style.
5. The final result must look like: "Image-1 was always built in the style of Image-2."

OUTPUT: Photorealistic, high-resolution render. Natural lighting. No watermarks. No artifacts. 8K quality.''';
  }
}
