import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ApiService {
  static const String baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  String? _apiKey;

  ApiService({String? apiKey}) : _apiKey = apiKey;

  void updateApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  Stream<String> getChatCompletionStream(
    List<ChatMessage> messages,
    String apiKey,
    double temperature,
  ) async* {
    try {
      final request = http.Request('POST', Uri.parse(baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $apiKey',
      });
      
      final jsonBody = jsonEncode({
        'model': 'deepseek-chat',
        'messages': messages.map((msg) => {
          'role': msg.role,
          'content': msg.content,
        }).toList(),
        'temperature': temperature,
        'stream': true,
      });
      
      request.body = jsonBody;

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final error = await response.stream.bytesToString();
        throw Exception('API调用失败: ${response.statusCode} - $error');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map((line) => line.startsWith('data: ') ? line.substring(6) : line);

        for (final line in lines) {
          if (line == '[DONE]') continue;
          try {
            final data = jsonDecode(line);
            if (data['choices']?[0]?['delta']?['content'] != null) {
              yield data['choices'][0]['delta']['content'] as String;
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      throw Exception('API调用错误: $e');
    }
  }

  Future<String> generateTitle(List<ChatMessage> messages, String apiKey) async {
    try {
      final jsonBody = jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个标题生成助手。请根据对话内容生成一个简短的主题（不超过15个汉字），直接返回主题文本，不要添加任何解释、标点符号或额外内容。例如用户询问Flutter相关问题，你应该直接返回"Flutter开发指南"这样的标题。',
          },
          ...messages.map((msg) => {
            'role': msg.role,
            'content': msg.content,
          }).toList(),
        ],
        'temperature': 0.7,
        'stream': false,
      });

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String title = data['choices'][0]['message']['content'].toString().trim();
        
        // 清理可能的多余内容
        title = title.replaceAll(RegExp(r'["""「」\n]'), '');
        title = title.replaceAll(RegExp(r'[:：]$'), '');
        
        return title;
      } else {
        throw Exception('生成主题失败');
      }
    } catch (e) {
      throw Exception('生成主题错误: $e');
    }
  }
} 