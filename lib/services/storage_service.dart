import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _sessionsKey = 'chat_sessions';
  static const String _apiKeyKey = 'api_key';
  static const String _favoriteMessagesKey = 'favorite_messages';
  static const String _lastUsedModelKey = 'last_used_model';
  static const String _isDeepThinkingKey = 'is_deep_thinking';
  static const String _isProKey = 'is_pro';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // 初始化
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // 保存会话列表
  Future<void> saveSessions(List<ChatSession> sessions) async {
    final sessionsJson = sessions.map((session) => session.toJson()).toList();
    await _prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
  }

  // 读取会话列表
  List<ChatSession> loadSessions() {
    final String? sessionsJson = _prefs.getString(_sessionsKey);
    if (sessionsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(sessionsJson);
      return decoded.map((json) => ChatSession.fromJson(json)).toList();
    } catch (e) {
      print('加载会话失败: $e');
      return [];
    }
  }

  // 保存 API Key
  Future<void> saveApiKey(String apiKey) async {
    await _prefs.setString(_apiKeyKey, apiKey);
  }

  // 读取 API Key
  String? getApiKey() {
    return _prefs.getString(_apiKeyKey);
  }

  // 保存收藏消息
  Future<void> saveFavoriteMessages(List<ChatMessage> messages) async {
    final messagesJson = messages.map((msg) => msg.toJson()).toList();
    await _prefs.setString(_favoriteMessagesKey, jsonEncode(messagesJson));
  }

  // 读取收藏消息
  List<ChatMessage> loadFavoriteMessages() {
    final String? messagesJson = _prefs.getString(_favoriteMessagesKey);
    if (messagesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(messagesJson);
      return decoded.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('加载收藏消息失败: $e');
      return [];
    }
  }

  Future<String?> getLastUsedModel() async {
    return _prefs.getString(_lastUsedModelKey);
  }

  Future<void> saveLastUsedModel(String model) async {
    await _prefs.setString(_lastUsedModelKey, model);
  }

  Future<bool?> getIsDeepThinking() async {
    return _prefs.getBool(_isDeepThinkingKey);
  }

  Future<void> saveIsDeepThinking(bool value) async {
    await _prefs.setBool(_isDeepThinkingKey, value);
  }

  Future<bool?> getIsPro() async {
    return _prefs.getBool(_isProKey);
  }

  Future<void> saveIsPro(bool value) async {
    await _prefs.setBool(_isProKey, value);
  }
} 