class ObjectRemovalPrompts {
  static String getGeneralRemovalPrompt() {
    return '''Strictly remove ONLY the objects, people, or items covered by the BLUE MASK in the provided image.
The blue area indicates where content must be erased.

1. REMOVE: Completely erase everything inside the blue masked region.
2. INPAINT: Fill the erased area with a natural background that matches the surrounding environment (floor, wall, nature, etc.).
3. CONSISTENCY: Ensure the filled area blends perfectly with the original lighting, shadows, and perspective.
4. PRESERVATION: Do NOT modify any part of the image outside the blue mask.

The final output should look like the object never existed. Ensure a realistic and seamless removal.''';
  }

  static String getAccurateRemovalPrompt() {
    return '''Role: Expert Image Editor / Inpainter.
Task: Remove the object defined by the mask in Image 2 from Image 1.
Mask Definition: The BLACK area in Image 2 represents the object to be removed. The WHITE area is the protected background.

Instructions:
1. Analyze the context surrounding the masked area (lighting, texture, perspective).
2. Completely remove the object within the BLACK MASKED area.
3. Fill the empty space with a seamless background that matches the surroundings (wall, floor, nature, etc.).
4. Maintain high-frequency details, noise, and lighting consistency.
5. No artifacts, no blur, no remaining chunks of the object.

Result: A fully restored image where the object never existed.''';
  }
}
