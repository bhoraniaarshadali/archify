import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../ads/remote_config_service.dart';
import '../../models/chat_message.dart';

class KieApiService {
  static const String _baseUrl = 'https://api.kie.ai/gemini-2.5-flash/v1/chat/completions';

  /// Sends a chat request and returns a stream of responses
  Stream<Map<String, dynamic>> streamChat(List<ChatMessage> messages) async* {
    final String apiKey = RemoteConfigService.getKieApiKey(FeatureType.chatbot);
    if (apiKey.isEmpty) {
      debugPrint('[KieAI Error]: API Key not found');
      yield {'error': 'Kie API Key (kie_api_key) not found in Remote Config'};
      return;
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // Filter messages to only include role and content for API
    final apiMessages = messages.map((m) => {
      'role': m.role,
      'content': m.text,
    }).toList();
    final payload = {
      'messages': apiMessages,
      'stream': true,
      'include_thoughts': false, // Enabled to match the new ChatGPT-style reasoning UI
    };

    debugPrint('[KieAI Request]: URL=$_baseUrl');
    debugPrint('[KieAI Request]: Payload=${jsonEncode(payload)}');

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll(headers);
    request.body = jsonEncode(payload);

    try {
      final client = http.Client();
      final response = await client.send(request);

      debugPrint('[KieAI Response]: Status=${response.statusCode}');

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('[KieAI Error]: Status=${response.statusCode}, Body=$errorBody');
        yield {'error': 'API Error ${response.statusCode}: $errorBody'};
        client.close();
        return;
      }

      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        debugPrint('[KieAI Line]: $line');
        if (line.trim().isEmpty) continue;
        
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          debugPrint('[KieAI Data]: $data');
          
          if (data == '[DONE]') {
            debugPrint('[KieAI Response]: Stream Finished [DONE]');
            break;
          }

          try {
            final json = jsonDecode(data);
            if (json.containsKey('credits_consumed')) {
              debugPrint('[KieAI Usage]: Credits consumed: ${json['credits_consumed']}');
            }
            yield json;
          } catch (e) {
            debugPrint('[KieAI Parse Warning]: Failed to decode as single JSON, trying complex mode...');
            for (final json in _handleComplexData(data)) {
              yield json;
            }
          }
        }
      }
      client.close();
    } catch (e) {
      debugPrint('[KieAI Connection Error]: $e');
      yield {'error': 'Connection failed: $e'};
    }
  }

  /// Helper to handle cases where multiple JSON objects are in one chunk or fragments occur
  List<Map<String, dynamic>> _handleComplexData(String data) {
    final List<Map<String, dynamic>> results = [];
    int braceCount = 0;
    int start = -1;

    for (int i = 0; i < data.length; i++) {
      if (data[i] == '{') {
        if (braceCount == 0) start = i;
        braceCount++;
      } else if (data[i] == '}') {
        braceCount--;
        if (braceCount == 0 && start != -1) {
          final jsonStr = data.substring(start, i + 1);
          try {
            results.add(jsonDecode(jsonStr));
          } catch (_) {}
          start = -1;
        }
      }
    }
    return results;
  }
}
