import 'dart:math';

/// Loading Tips Provider
///
/// Provides rotating tips and messages to keep users engaged during loading
class LoadingTipsProvider {
  static final List<Map<String, String>> _tips = [
    {
      'icon': '💡',
      'title': 'Pro Tip',
      'message': 'Better lighting in photos\nleads to better results!',
    },
    {
      'icon': '🏠',
      'title': 'Did you know?',
      'message': 'Our AI preserves your\nhouse structure perfectly!',
    },
    {
      'icon': '🎨',
      'title': 'Fun Fact',
      'message': 'You can try multiple styles\nfor the same house!',
    },
    {
      'icon': '⚡',
      'title': 'Speed Tip',
      'message': 'Pre-uploaded images\ngenerate 3x faster!',
    },
    {
      'icon': '🌟',
      'title': 'Quality Tip',
      'message': 'Clear, well-lit photos\ngive stunning results!',
    },
    {
      'icon': '🔄',
      'title': 'Pro Tip',
      'message': 'Try different color palettes\nfor unique looks!',
    },
    {
      'icon': '📸',
      'title': 'Photo Tip',
      'message': 'Capture your house from\nthe front for best results!',
    },
    {
      'icon': '✨',
      'title': 'Magic Happening',
      'message': 'AI is analyzing your\nhouse structure...',
    },
  ];

  static final Random _random = Random();

  /// Get a random tip
  static Map<String, String> getRandomTip() {
    return _tips[_random.nextInt(_tips.length)];
  }

  /// Get tip by index
  static Map<String, String> getTip(int index) {
    return _tips[index % _tips.length];
  }

  /// Get total number of tips
  static int get tipCount => _tips.length;
}
