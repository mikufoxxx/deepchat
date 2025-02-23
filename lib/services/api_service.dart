import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../config/api_config.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';

class ApiService {
  String _baseUrl = ApiConfig.deepseekUrl;
  String? _apiKey;
  String _currentModel = ApiConfig.models['deepseek']!;

  ApiService({String? apiKey}) : _apiKey = apiKey;

  void updateApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void updateBaseUrl(String url) {
    _baseUrl = url;
  }

  void updateModel(String model) {
    _currentModel = model;
  }

  Stream<String> getChatCompletionStream(
    List<ChatMessage> messages,
    String apiKey,
    double temperature,
  ) async* {
    final endpoint = '$_baseUrl/chat/completions';
    bool isThinking = false;
    String thoughtBuffer = '';
    
    try {
      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers.addAll({
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'Bearer $apiKey',
      });
      
      final jsonBody = jsonEncode({
        'model': _currentModel,
        'messages': messages.map((msg) => {
          'role': msg.role,
          'content': msg.content,
        }).toList(),
        'temperature': temperature,
        'stream': true,
      });
      
      print('请求参数: $jsonBody');
      request.body = jsonBody;
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final error = await response.stream.bytesToString();
        print('API错误响应: $error');
        throw Exception('API调用失败: ${response.statusCode} - $error');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        print('原始响应块: $chunk');
        
        final lines = chunk
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map((line) => line.startsWith('data: ') ? line.substring(6) : line);

        for (final line in lines) {
          if (line == '[DONE]') continue;
          try {
            final data = jsonDecode(line);
            print('解析后的数据: $data');
            
            final content = data['choices']?[0]?['delta']?['content'] as String?;
            final reasoningContent = data['choices']?[0]?['delta']?['reasoning_content'] as String?;

            if (reasoningContent != null) {
              print('思考内容: $reasoningContent');
              yield '思考过程：$reasoningContent';
              continue;
            }

            if (content != null) {
              print('回答内容: $content');
              if (isThinking) {
                yield '\n\n回答：';
                isThinking = false;
              }
              yield content;
            }
          } catch (e) {
            print('解析错误: $e');
            continue;
          }
        }
      }
    } catch (e) {
      print('流处理错误: $e');
      throw Exception('API调用错误: $e');
    }
  }

  Future<String> generateTitle(List<ChatMessage> messages, String apiKey) async {
    try {
      final jsonBody = jsonEncode({
        'model': ApiConfig.models['siliconflow'],
        'messages': [
          {
            'role': 'system',
            'content': '请根据对话内容生成一个简短的主题（不超过15个字），直接返回主题文本，不要添加任何解释或标点符号。',
          },
          ...messages.map((msg) => {
            'role': msg.role,
            'content': msg.content,
          }).toList(),
        ],
        'temperature': 0.7,
        'stream': false,
      });

      print('标题生成请求: $jsonBody');

      final response = await http.post(
        Uri.parse('${ApiConfig.siliconFlowUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonBody,
      );

      print('标题响应状态码: ${response.statusCode}');
      print('标题响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['choices'][0]['message']['content'].trim();
        print('生成的标题: $title');
        return title;
      } else {
        throw Exception('生成标题失败: ${response.statusCode}');
      }
    } catch (e) {
      print('标题生成错误: $e');
      throw Exception('生成标题错误: $e');
    }
  }
} 