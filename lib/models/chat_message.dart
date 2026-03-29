class ChatMessage {
  String text;
  final bool isMe;
  final DateTime time;
  final String role; // 'user', 'assistant', 'developer'
  String? reasoning; // For thinking process
  bool isThinking;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.role,
    this.reasoning,
    this.isThinking = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': text,
    };
  }
}
