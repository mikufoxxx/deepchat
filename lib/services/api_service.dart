import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/chat_message.dart';
import '../config/api_config.dart';

class ApiService {
  final String apiKey;
  
  ApiService({required this.apiKey});

  Stream<String> sendMessageStream(List<ChatMessage> messages) async* {
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/chat/completions'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });

      // 根据官方文档格式构造请求体
      request.body = jsonEncode({
        'model': 'deepseek-chat',  // 使用最新的 DeepSeek-V3 模型
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': true,
        'temperature': 0.7,  // 可选：控制随机性
      });

      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk
              .split('\n')
              .where((line) => line.isNotEmpty)
              .where((line) => line.startsWith('data: '))
              .map((line) => line.substring(6));

          for (final line in lines) {
            if (line == '[DONE]') continue;
            try {
              final data = jsonDecode(line);
              final content = data['choices'][0]['delta']['content'] ?? '';
              if (content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              print('Error parsing JSON: $e');
              continue;
            }
          }
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('请求失败: $e');
    } finally {
      client.close();
    }
  }
} 