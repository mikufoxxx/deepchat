import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../config/api_config.dart';
import '../models/user_info.dart';

class ApiService {
  String _baseUrl = ApiConfig.deepseekUrl;
  String? _apiKey;
  String _currentModel = ApiConfig.models['deepseek'] ?? '';
  final _httpClient = http.Client();

  ApiService({String? apiKey}) {
    _apiKey = apiKey;
  }

  void updateApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void updateBaseUrl(String url) {
    _baseUrl = url;
  }

  void updateModel(String model) {
    _currentModel = model;
  }

  String get currentModel => _currentModel;

  Stream<String> getChatCompletionStream(
    List<ChatMessage> messages,
    String apiKey,
    double temperature,
  ) async* {
    final endpoint = '$_baseUrl/chat/completions';
    bool isThinking = false;
    
    try {
      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers.addAll({
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'Bearer $apiKey',
      });
      
      final messageHistory = messages.map((msg) => {
        'role': msg.role,
        'content': msg.content,
      }).toList();
      
      final jsonBody = jsonEncode({
        'model': _currentModel,
        'messages': messageHistory,
        'temperature': temperature,
        'stream': true,
      });
      
      print('请求参数: $jsonBody');
      request.body = jsonBody;
      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        print('API错误响应: ${await response.stream.bytesToString()}');
        yield '抱歉，我现在有点累，请稍后再试~';
        return;
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
              } else {
                yield content;
              }
            }
          } catch (e) {
            print('解析错误: $e');
            continue;
          }
        }
      }
    } catch (e) {
      print('流处理错误: $e');
      yield '抱歉，我遇到了一点小问题，请稍后再试~';
    }
  }

  Future<String> generateTitle(List<ChatMessage> messages, String apiKey) async {
    try {
      final jsonBody = jsonEncode({
        'model': ApiConfig.models['siliconflow'],
        'messages': [
          {
            'role': 'system',
            'content': '请根据用户的问题和AI的回答生成一个简短的对话主题（不超过15个字），直接返回主题文本，不要添加任何解释或标点符号。',
          },
          ...messages.map((msg) => {
            'role': msg.role,
            'content': msg.content,
          }).toList(),
        ],
        'temperature': 0.3,
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

  Future<UserInfo> getUserInfo() async {
    final endpoint = '$_baseUrl/user/info';
    final client = http.Client();
    
    try {
      final response = await client.get(
        Uri.parse(endpoint),
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('用户信息响应: $data');
        
        if (data['is_subscribed'] is bool) {
          data['is_subscribed'] = data['is_subscribed'].toString();
        }
        
        return UserInfo.fromJson(data);
      } else {
        print('获取用户信息失败: ${response.body}');
        throw Exception('获取用户信息失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取用户信息错误: $e');
      throw Exception('获取用户信息失败，请检查网络连接');
    } finally {
      client.close();
    }
  }

  void dispose() {
    _httpClient.close();
  }
} 