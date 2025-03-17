import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../config/api_config.dart';
import '../models/user_info.dart';

class DeepseekApiService {
  String _baseUrl = 'https://api.deepseek.com';  // 确认这个 URL 是正确的
  String? _apiKey;
  String _currentModel = ApiConfig.models['deepseek_v3'] ?? '';
  final _httpClient = http.Client();

  DeepseekApiService({String? apiKey}) {
    _apiKey = apiKey;
  }

  void updateApiKey(String apiKey) {
    _apiKey = apiKey;
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
    final endpoint = '$_baseUrl/v1/chat/completions';
    bool isThinking = false;  // 标记是否在输出思考内容
    
    try {
      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers.addAll({
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'Bearer $apiKey',
      });
      
      // 处理消息历史，确保用户和助手消息交替出现
      List<Map<String, String>> processedMessages = [];
      
      // 如果使用的是 deepseek-reasoner 模型，需要特殊处理
      if (_currentModel == 'deepseek-reasoner') {
        // 确保消息列表不为空
        if (messages.isNotEmpty) {
          // 添加第一条消息
          processedMessages.add({
            'role': messages.first.role,
            'content': messages.first.content,
          });
          
          // 处理剩余消息，确保用户和助手消息交替出现
          for (int i = 1; i < messages.length; i++) {
            final currentMsg = messages[i];
            final prevMsg = processedMessages.last;
            
            // 如果当前消息和上一条消息的角色相同，则合并内容
            if (currentMsg.role == prevMsg['role']) {
              prevMsg['content'] = '${prevMsg['content']}\n\n${currentMsg.content}';
            } else {
              // 角色不同，添加为新消息
              processedMessages.add({
                'role': currentMsg.role,
                'content': currentMsg.content,
              });
            }
          }
        }
      } else {
        // 其他模型使用原始消息列表
        processedMessages = messages.map((msg) => {
          'role': msg.role,
          'content': msg.content,
        }).toList();
      }
      
      final jsonBody = jsonEncode({
        'model': _currentModel,
        'messages': processedMessages,
        'temperature': temperature,
        'stream': true,
      });
      
      print('DeepSeek API 请求参数: $jsonBody');
      request.body = jsonBody;
      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        print('DeepSeek API 错误响应: ${await response.stream.bytesToString()}');
        yield '抱歉，我现在有点累，请稍后再试~';
        return;
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        print('DeepSeek 原始响应块: $chunk');
        
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
            
            // 处理思考内容
            if (reasoningContent != null && reasoningContent.isNotEmpty) {
              print('DeepSeek 思考内容: $reasoningContent');
              // 始终添加前缀，让 ChatProvider 能够识别这是思考内容
              yield '思考过程：$reasoningContent';
              isThinking = true;  // 标记正在输出思考内容
              continue;
            }
            
            // 处理回答内容
            if (content != null) {
              print('DeepSeek 回答内容: $content');
              
              // 如果之前在输出思考内容，现在是第一次输出回答内容
              if (isThinking) {
                // 先输出分隔符，然后再输出内容
                yield '\n\n回答：';
                isThinking = false;  // 重置思考状态
                yield content;  // 单独输出内容
              } else {
                // 继续输出回答内容
                yield content;
              }
            }
          } catch (e) {
            print('DeepSeek 解析错误: $e');
            continue;
          }
        }
      }
    } catch (e) {
      print('DeepSeek 流处理错误: $e');
      yield '抱歉，我遇到了一点小问题，请稍后再试~';
    }
  }

  Future<String> generateTitle(List<ChatMessage> messages, String apiKey) async {
    try {
      final jsonBody = jsonEncode({
        'model': _currentModel,
        'messages': [
          {
            'role': 'user',
            'content': '请根据用户的问题和AI的回答生成一个对话标题（不超过15个字），直接返回标题内容，前面不要加对话主题：这种，直接返回标题就行，不要添加任何解释，注释，说明或标点符号。',
          },
          ...messages.map((msg) => {
            'role': msg.role,
            'content': msg.content,
          }).toList(),
        ],
        'temperature': 0.3,
        'stream': false,
      });

      print('DeepSeek 标题生成请求: $jsonBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonBody,
      );

      print('DeepSeek 标题响应状态码: ${response.statusCode}');
      print('DeepSeek 标题响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['choices'][0]['message']['content'].trim();
        print('DeepSeek 生成的标题: $title');
        return title;
      } else {
        throw Exception('DeepSeek 生成标题失败: ${response.statusCode}');
      }
    } catch (e) {
      print('DeepSeek 标题生成错误: $e');
      throw Exception('DeepSeek 生成标题错误: $e');
    }
  }

  Future<UserInfo> getUserInfo() async {
    final endpoint = '$_baseUrl/v1/user/balance';
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
        print('DeepSeek 用户余额响应: $data');
        
        // 检查是否可用
        final isAvailable = data['is_available'] ?? false;
        if (!isAvailable) {
          throw Exception('DeepSeek API 账户不可用');
        }
        
        // 获取余额信息（默认使用第一个货币信息，通常是 CNY）
        final balanceInfos = data['balance_infos'] as List<dynamic>;
        if (balanceInfos.isEmpty) {
          throw Exception('DeepSeek API 余额信息为空');
        }
        
        final balanceInfo = balanceInfos[0];
        final totalBalance = double.tryParse(balanceInfo['total_balance'] ?? '0.0') ?? 0.0;
        final grantedBalance = double.tryParse(balanceInfo['granted_balance'] ?? '0.0') ?? 0.0;
        final toppedUpBalance = double.tryParse(balanceInfo['topped_up_balance'] ?? '0.0') ?? 0.0;
        
        // 创建一个包含所有必需参数的 UserInfo 对象
        final userInfo = UserInfo(
          id: 'deepseek_user',
          name: 'DeepSeek 用户',
          email: 'deepseek@example.com',
          image: '',
          isAdmin: false,
          status: 'active',
          introduction: '',
          role: 'user',
          totalBalance: toppedUpBalance,
          balance: grantedBalance,         // 免费额度（赠送的）
          chargeBalance: toppedUpBalance,  // 付费额度（充值的）
          category: 0,  // 使用整数值代替字符串
        );
        
        return userInfo;
      } else {
        print('获取 DeepSeek 用户余额失败: ${response.body}');
        throw Exception('获取 DeepSeek 用户余额失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取 DeepSeek 用户余额错误: $e');
      throw Exception('获取 DeepSeek 用户余额失败，请检查网络连接或api设置');
    } finally {
      client.close();
    }
  }

  void dispose() {
    _httpClient.close();
  }
} 