class TextToImagePrompts {
  static String enhancePrompt(String prompt) {
    return '''$prompt
      
High quality, photorealistic, 8K, professional photography, highly detailed, dramatic lighting, sharp focus.''';
  }
}
