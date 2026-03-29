/// Provides local asset images for different architectural styles
class StyleReferenceImages {
  static String? getStyleImage(String styleName) {
    final styleMap = {
      'Modern': 'assets/images/styles/exterior/modern.jpg',
      'Victorian': 'assets/images/styles/exterior/victorian.jpg',
      'Industrial': 'assets/images/styles/exterior/industrial.jpg',
      'Minimalist': 'assets/images/styles/exterior/minimalist.jpg',
      'Rustic': 'assets/images/styles/exterior/rustic.jpg',
      'Luxury': 'assets/images/styles/exterior/luxury.jpg',
      // 'Surprise Me' returns null to show icon instead of image
    };

    return styleMap[styleName]; // Returns null for 'Surprise Me' and unknown styles
  }
}
