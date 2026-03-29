class InteriorStyle {
  final String templateId;
  final String styleName;
  final String prompt;
  final String exampleImage;

  InteriorStyle({
    required this.templateId,
    required this.styleName,
    required this.prompt,
    required this.exampleImage,
  });

  factory InteriorStyle.fromJson(Map<String, dynamic> json) {
    return InteriorStyle(
      templateId: json['template_id'],
      styleName: json['style_name'],
      prompt: json['prompt'],
      exampleImage: json['example_image'],
    );
  }
}
