import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../screens/assistants/assistants_screen.dart';
import '../daily_credit_manager.dart';
import '../database/chat_database.dart';
import 'kie_api_service.dart';

class ChatProvider extends ChangeNotifier {
  static final ChatProvider _instance = ChatProvider._internal();
  factory ChatProvider() => _instance;
  ChatProvider._internal();

  final Map<String, List<ChatMessage>> _assistantChats = {};
  final KieApiService _apiService = KieApiService();
  final ChatDatabase _db = ChatDatabase.instance;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  List<ChatMessage> getMessages(String assistantName) {
    return _assistantChats[assistantName] ?? [];
  }

  Future<void> initChat(Assistant assistant) async {
    if (_assistantChats.containsKey(assistant.name)) return;

    // Try to load from DB
    final history = await _db.getMessages(assistant.name);
    
    if (history.isNotEmpty) {
      _assistantChats[assistant.name] = history;
    } else {
      // First time: Add developer and welcome message
      final devMsg = ChatMessage(
        role: 'developer',
        text: 'You are an AI assistant named ${assistant.name}. ${assistant.welcomeMessage} '
            'IMPORTANT: Provide highly useful, concise, and meaningful answers. '
            'Keep your responses short and avoid long-winded explanations unless explicitly asked. '
            'Focus on high-quality advice for home decoration and design.',
        isMe: false,
        time: DateTime.now(),
      );
      final welcomeMsg = ChatMessage(
        role: 'assistant',
        text: assistant.welcomeMessage,
        isMe: false,
        time: DateTime.now(),
      );
      
      _assistantChats[assistant.name] = [devMsg, welcomeMsg];
      
      // Save initial messages to DB
      await _db.saveMessage(assistant.name, devMsg);
      await _db.saveMessage(assistant.name, welcomeMsg);
    }
    notifyListeners();
  }

  Future<void> sendMessage(String assistantName, String text) async {
    if (text.trim().isEmpty || _isStreaming) return;

    final chat = _assistantChats[assistantName];
    if (chat == null) return;

    // 1. Add and Save User Message
    final userMsg = ChatMessage(
      role: 'user',
      text: text,
      isMe: true,
      time: DateTime.now(),
    );
    chat.add(userMsg);
    await _db.saveMessage(assistantName, userMsg);
    
    // 2. Add placeholder Assistant Message
    final aiResponse = ChatMessage(
      role: 'assistant',
      text: '',
      isMe: false,
      time: DateTime.now(),
      isThinking: true,
    );
    chat.add(aiResponse);
    
    _isStreaming = true;
    notifyListeners();

    try {
      // Send last 10 messages for context (excluding the empty placeholder we just added)
      final contextMessages = chat.length > 11 
          ? chat.sublist(chat.length - 11, chat.length - 1) 
          : chat.sublist(0, chat.length - 1);

      await for (final chunk in _apiService.streamChat(contextMessages)) {
        if (chunk.containsKey('error')) {
          aiResponse.text += '\nError: ${chunk['error']}';
          aiResponse.isThinking = false;
          break;
        }

        final choices = chunk['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0];
          final delta = choice['delta'] as Map?;
          final message = choice['message'] as Map?;
          
          // 1. Extract Content
          final content = delta?['content'] ?? message?['content'] ?? choice['text'] ?? '';
          if (content.toString().isNotEmpty) {
            if (aiResponse.isThinking) aiResponse.isThinking = false;
            aiResponse.text += content.toString();
          }

          // 2. Extract Reasoning
          final reasoning = delta?['reasoning_content'] ?? delta?['reasoning'] ?? '';
          if (reasoning.toString().isNotEmpty) {
            aiResponse.reasoning = (aiResponse.reasoning ?? '') + reasoning.toString();
          }
        }

        // Capture credits (inside stream)
        if (chunk.containsKey('credits_consumed')) {
          final double credits = (chunk['credits_consumed'] as num).toDouble();
          DailyCreditManager.useCredits(credits.ceil());
        }
        
        notifyListeners();
      }
      
      // Save AI result to database AFTER stream completes
      if (aiResponse.text.isNotEmpty) {
        await _db.saveMessage(assistantName, aiResponse);
      }
      
    } catch (e) {
      aiResponse.text += '\nStream interrupted: $e';
    } finally {
      aiResponse.isThinking = false;
      _isStreaming = false;
      notifyListeners();
    }
  }

  Future<void> clearChat(String assistantName) async {
    await _db.clearHistory(assistantName);
    _assistantChats.remove(assistantName);
    notifyListeners();
  }
  
  Future<List<Map<String, dynamic>>> getChatHistorySessions() async {
    return await _db.getChatSessions();
  }
}
