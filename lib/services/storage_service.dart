import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _messageKey = 'chat_messages';
  static const String _apiKeyKey = 'api_key';
  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  // 保存消息历史
  Future<void> saveMessages(List<ChatMessage> messages) async {
    final List<Map<String, dynamic>> messageList = messages.map((message) => {
          'content': message.content,
          'role': message.role,
          'timestamp': message.timestamp.toIso8601String(),
        }).toList();

    await _prefs.setString(_messageKey, jsonEncode(messageList));
  }

  // 加载消息历史
  Future<List<ChatMessage>> loadMessages() async {
    final String? messagesJson = _prefs.getString(_messageKey);
    if (messagesJson == null) return [];

    try {
      final List<dynamic> messageList = jsonDecode(messagesJson);
      return messageList.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      print('加载消息历史失败: $e');
      return [];
    }
  }

  // 保存 API Key
  Future<void> saveApiKey(String apiKey) async {
    await _prefs.setString(_apiKeyKey, apiKey);
  }

  // 获取 API Key
  String? getApiKey() {
    return _prefs.getString(_apiKeyKey);
  }

  // 清除所有消息历史
  Future<void> clearMessages() async {
    await _prefs.remove(_messageKey);
  }

  // 清除 API Key
  Future<void> clearApiKey() async {
    await _prefs.remove(_apiKeyKey);
  }

  // 清除所有数据
  Future<void> clearAll() async {
    await _prefs.clear();
  }
} 