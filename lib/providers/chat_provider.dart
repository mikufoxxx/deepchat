import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../screens/chat_screen.dart';
import '../screens/settings_screen.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';
import '../models/user_info.dart';

class ChatProvider with ChangeNotifier {
  late final ApiService _apiService;
  final StorageService _storage;
  List<ChatSession> _sessions = [];
  int _currentSessionId = 0;
  List<ChatMessage> _favoriteMessages = [];
  double _temperature = 0.7;
  String _apiKey = '';
  bool _isStreaming = false;
  ChatMessage? _messageToScrollTo;
  String _selectedModel = 'siliconflow';  // 默认使用硅基流动
  String _baseUrl = ApiConfig.siliconFlowUrl;  // 默认使用硅基流动的 URL
  bool _isDeepThinking = false;
  String _deepseekApiKey = '';
  String _siliconflowApiKey = '';
  Map<String, int> _thinkingDurations = {};
  StreamSubscription<String>? _streamSubscription;
  String _lastUsedModel = 'siliconflow';  // 默认使用硅基流动
  bool _isPro = false;
  String _modelVersion = 'v3'; // 'v3' 或 'r1'
  final Map<String, bool> _completedMessages = {};

  ChatProvider(this._storage) {
    _apiService = ApiService();
    _loadData();
    _apiService.updateBaseUrl(_baseUrl);
    _apiService.updateModel(currentModel);
  }

  // Getters
  List<ChatSession> get sessions => _sessions;
  int get currentSessionId => _currentSessionId;
  List<ChatMessage> get favoriteMessages => _favoriteMessages;
  double get temperature => _temperature;
  String get apiKey => _apiKey;
  bool get isStreaming => _isStreaming;
  bool _isInitialScroll = true;  // 添加标记，用于控制初始滚动

  // 获取要滚动到的消息
  ChatMessage? get messageToScrollTo => _messageToScrollTo;

  // 获取是否是初始滚动
  bool get isInitialScroll => _isInitialScroll;
  
  // 获取当前会话
  ChatSession? get currentSession {
    if (_sessions.isEmpty) return null;
    return _sessions.firstWhere(
      (session) => session.id == _currentSessionId,
      orElse: () => _sessions.last,
    );
  }

  // 获取当前会话的消息
  List<ChatMessage> get currentMessages => currentSession?.messages ?? [];

  // 加载保存的数据
  void _loadData() async {
    _sessions = _storage.loadSessions();
    _favoriteMessages = _storage.loadFavoriteMessages();
    _apiKey = await _storage.getApiKey() ?? '';
    _deepseekApiKey = _apiKey;
    _siliconflowApiKey = _apiKey;
    _lastUsedModel = await _storage.getLastUsedModel() ?? 'siliconflow';
    _selectedModel = _lastUsedModel;
    _apiService.updateModel(currentModel);
    _apiService.updateApiKey(_apiKey);
    
    // 检查最新的会话是否为空
    if (_sessions.isNotEmpty) {
      final latestSession = _sessions.last;
      if (latestSession.messages.isEmpty) {
        _sessions.removeLast();
      }
    }
    
    // 如果没有会话，创建新会话
    if (_sessions.isEmpty) {
      newChat();
    } else {
      _currentSessionId = _sessions.last.id;
    }
    
    notifyListeners();
  }

  // 保存会话
  Future<void> _saveSessions() async {
    await _storage.saveSessions(_sessions);
  }

  // 保存收藏消息
  Future<void> _saveFavoriteMessages() async {
    await _storage.saveFavoriteMessages(_favoriteMessages);
  }

  // 选择会话
  @override
  void selectSession(int id) {
    if (_sessions.any((session) => session.id == id)) {
      _streamSubscription?.cancel();
      _isStreaming = false;
      _currentSessionId = id;
      notifyListeners();
    }
  }

  // 新建会话
  void newChat() {
    // 检查当前会话是否为空
    final currentSession = _sessions.firstWhere(
      (session) => session.id == _currentSessionId,
      orElse: () => ChatSession(id: -1, title: '', messages: []),
    );
    
    // 如果当前会话没有消息，直接删除它
    if (currentSession.messages.isEmpty && currentSession.id != -1) {
      _sessions.removeWhere((session) => session.id == currentSession.id);
    }

    final newSessionId = DateTime.now().millisecondsSinceEpoch;
    final newSession = ChatSession(
      id: newSessionId,
      title: '新对话',
      messages: [],
    );
    
    _sessions.add(newSession);
    _currentSessionId = newSession.id;
    _saveSessions();
    notifyListeners();
  }

  // 发送消息
  Future<void> sendMessage(String content) async {
    _streamSubscription?.cancel();
    if (_currentSessionId == null) return;

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      sessionId: _currentSessionId!,
    );

    _addMessage(userMessage);
    _isStreaming = true;
    notifyListeners();

    try {
      String thoughtProcess = '';
      String response = '';
      final startTime = DateTime.now();
      var session = currentSession;
      if (session == null) return;
      
      final messages = [...session.messages];
      bool isThinkingMode = _isDeepThinking;
      
      var lastNotifyTime = DateTime.now();
      
      _streamSubscription = _apiService.getChatCompletionStream(
        messages, 
        _apiKey ?? '', 
        _temperature,
      ).listen(
        (chunk) {
          if (DateTime.now().difference(lastNotifyTime).inMilliseconds > 100) {
            notifyListeners();
            lastNotifyTime = DateTime.now();
          }
          
          if (chunk.startsWith('思考过程：')) {
            thoughtProcess += chunk.substring(5);
            final aiMessage = ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: thoughtProcess,
              isThinking: true,
              sessionId: _currentSessionId!,
              timestamp: startTime,
              thoughtProcess: thoughtProcess,
            );
            _updateLastMessage(aiMessage);
          } else if (chunk == '\n\n回答：') {
            response = '';
            final aiMessage = ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: '',
              isThinking: false,
              sessionId: _currentSessionId!,
              timestamp: startTime,
              thoughtProcess: thoughtProcess,
            );
            _updateLastMessage(aiMessage);
          } else {
            response += chunk;
            final aiMessage = ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: response,
              isThinking: false,
              sessionId: _currentSessionId!,
              timestamp: startTime,
              thoughtProcess: thoughtProcess,
            );
            _updateLastMessage(aiMessage);
          }
        },
        onDone: () {
          // 标记最后一条消息为完成状态
          final lastMessage = currentSession?.messages.last;
          if (lastMessage != null) {
            _completedMessages[lastMessage.id] = true;
            notifyListeners();
          }
        },
      );

      // 重新获取当前会话
      session = _sessions.firstWhere(
        (s) => s.id == _currentSessionId,
      );
      
      // AI 回复完成后生成标题
      if (session.title == '新对话') {
        await _generateTitle(session);
      }

    } catch (e) {
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: '抱歉，发生了错误：$e',
        sessionId: _currentSessionId!,
      );
      _addMessage(errorMessage);
    }

    _isStreaming = false;
    notifyListeners();
  }

  // 收藏/取消收藏消息
  void toggleFavorite(ChatMessage message) {
    final index = _favoriteMessages.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      _favoriteMessages.removeAt(index);
    } else {
      _favoriteMessages.add(message.copyWith());
    }
    _saveFavoriteMessages();
    notifyListeners();
  }

  bool isFavorited(ChatMessage message) {
    return _favoriteMessages.any((m) => m.id == message.id);
  }

  // 设置温度
  void setTemperature(double value) {
    _temperature = value;
    notifyListeners();
  }

  // 设置 API Key
  void setApiKey(String value) {
    _apiKey = value;
    _storage.saveApiKey(value);
    _apiService.updateApiKey(value);
    notifyListeners();
  }
  // 添加一个别名方法，保持向后兼容
  void updateApiService(String value) => setApiKey(value);

  void deleteSession(int sessionId) {
    // 如果删除的是当前会话，先找到要切换的会话
    if (_currentSessionId == sessionId) {
      final remainingSessions = _sessions.where((s) => s.id != sessionId).toList();
      if (remainingSessions.isNotEmpty) {
        _currentSessionId = remainingSessions.last.id;
      } else {
        // 如果没有其他会话，先创建一个新会话
        final newSession = ChatSession(
          id: DateTime.now().millisecondsSinceEpoch,
          title: '新对话',
          messages: [],
        );
        _sessions.add(newSession);
        _currentSessionId = newSession.id;
      }
    }

    // 删除收藏消息
    _favoriteMessages.removeWhere((message) => message.sessionId == sessionId);
    
    // 删除会话
    _sessions.removeWhere((session) => session.id == sessionId);
    
    _saveSessions();
    _saveFavoriteMessages();
    notifyListeners();
  }

  // 添加删除收藏消息的方法
  void deleteFavoriteMessage(ChatMessage message) {
    _favoriteMessages.removeWhere((m) => m.id == message.id);
    _saveFavoriteMessages();
    notifyListeners();
  }

  // 重命名会话
  void renameSession(int sessionId, String newTitle) {
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    if (index != -1) {
      final updatedSession = _sessions[index].copyWith(title: newTitle);
      _sessions[index] = updatedSession;
      _saveSessions();
      notifyListeners();
    }
  }

  // 跳转到指定消息
   Future<void> navigateToMessage(ChatMessage message, BuildContext context) async {
    print('开始导航到消息: ${message.id}, sessionId: ${message.sessionId}');
    
    // 清除之前的滚动目标
    _messageToScrollTo = null;
    
    // 如果不在目标会话中，先切换会话
    if (currentSession?.id != message.sessionId) {
      selectSession(message.sessionId);
      
      if (context.mounted) {
        // 使用 pushReplacement 而不是 popUntil
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatScreen(),
          ),
        );
      }
    }
    
    // 设置滚动目标并通知更新
    _messageToScrollTo = message;
    notifyListeners();
    
    // 确保状态更新后再次通知
    Future.microtask(() {
      if (_messageToScrollTo != null) {
        notifyListeners();
      }
    });
  }

  void clearScrollTarget() {
    if (_messageToScrollTo != null) {
      _messageToScrollTo = null;
      notifyListeners();
    }
  }

  void _addMessage(ChatMessage message) {
    print('_addMessage - 当前会话ID: $_currentSessionId'); // 调试日志
    final session = _sessions.firstWhere(
      (s) => s.id == _currentSessionId,
      orElse: () => ChatSession(
        id: _currentSessionId!,
        title: '新对话',
        messages: [],
      ),
    );

    print('_addMessage - 当前会话消息数: ${session.messages.length}'); // 调试日志
    final updatedMessages = [...session.messages, message];
    final updatedSession = session.copyWith(messages: updatedMessages);

    _sessions = _sessions.map((s) => 
      s.id == session.id ? updatedSession : s
    ).toList();

    print('_addMessage - 更新后消息数: ${updatedSession.messages.length}'); // 调试日志
    _saveSessions();
    notifyListeners();
  }

  void _updateLastMessage(ChatMessage message) {
    if (_currentSessionId == null) return;

    // 计算当前思考时间
    if (message.thoughtProcess != null) {
      final currentDuration = DateTime.now().difference(message.timestamp).inSeconds;
      
      // 如果是思考中，持续更新时间
      if (message.isThinking) {
        _thinkingDurations[message.id] = currentDuration;
      } 
      // 如果思考完毕且没有记录最终时间，记录最终时间
      else if (!_thinkingDurations.containsKey(message.id)) {
        _thinkingDurations[message.id] = currentDuration;
      }
    }

    _sessions = _sessions.map((session) {
      if (session.id == _currentSessionId) {
        final messages = List<ChatMessage>.from(session.messages);
        if (messages.isNotEmpty && messages.last.role == 'assistant') {
          messages[messages.length - 1] = message;
        } else {
          messages.add(message);
        }
        return session.copyWith(messages: messages);
      }
      return session;
    }).toList();

    _saveSessions();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    await _saveSessions();
  }

  Future<void> _generateTitle(ChatSession session) async {
    if (session.messages.isEmpty) return;

    try {
      final title = await _apiService.generateTitle(session.messages, _apiKey ?? '');
      
      final updatedSession = session.copyWith(title: title);
      _sessions = _sessions.map((s) => 
        s.id == session.id ? updatedSession : s
      ).toList();
      
      _saveSessions();
      notifyListeners();
      
      print('生成标题成功: $title'); // 调试日志
    } catch (e) {
      print('生成标题失败: $e'); // 调试日志
    }
  }

  String get selectedModel => _selectedModel;
  String get baseUrl => _baseUrl;
  
  void setModel(String model) {
    _selectedModel = model;
    _lastUsedModel = model;
    _storage.saveLastUsedModel(model);
    _apiService.updateModel(currentModel);
    notifyListeners();
  }

  bool get isDeepThinking => _isDeepThinking;
  
  void toggleDeepThinking() {
    _isDeepThinking = !_isDeepThinking;
    _apiService.updateModel(currentModel);
    notifyListeners();
  }
  
  String get currentModel {
    final baseModel = _isDeepThinking 
        ? 'deepseek-ai/DeepSeek-R1'    // 深度思考模式使用 R1
        : 'deepseek-ai/DeepSeek-V3';   // 普通模式使用 V3
    
    return _isPro 
        ? 'Pro/$baseModel'   // 专业版添加 Pro 前缀
        : baseModel;         // 标准版直接使用基础模型
  }

  String get deepseekApiKey => _deepseekApiKey;
  String get siliconflowApiKey => _siliconflowApiKey;
  
  void updateDeepseekApiKey(String key) {
    _deepseekApiKey = key;
    if (_selectedModel == 'deepseek') {
      _apiService.updateApiKey(key);
    }
    _storage.saveApiKey(key);
    notifyListeners();
  }
  
  void updateSiliconflowApiKey(String key) {
    _siliconflowApiKey = key;
    if (_selectedModel == 'siliconflow') {
      _apiService.updateApiKey(key);
    }
    _storage.saveApiKey(key);
    notifyListeners();
  }

  bool get hasValidApiKey => _siliconflowApiKey.isNotEmpty;

  void checkAndShowApiKeyReminder(BuildContext context) {
    if (_siliconflowApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先配置硅基流动 API Key'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '去设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> retryMessage() async {
    if (_currentSessionId == null || _isStreaming) return;
    
    final session = currentSession;
    if (session == null || session.messages.isEmpty) return;
    
    // 移除最后一条AI消息和对应的用户消息
    final lastMessage = session.messages.last;
    if (lastMessage.role != 'assistant') return;
    
    _sessions = _sessions.map((s) {
      if (s.id == _currentSessionId) {
        // 删除最后两条消息（用户消息和AI回复）
        return s.copyWith(
          messages: s.messages.sublist(0, s.messages.length - 2),
        );
      }
      return s;
    }).toList();
    
    notifyListeners();
    
    // 重新发送最后一条用户消息
    final lastUserMessage = session.messages[session.messages.length - 2];
    await sendMessage(lastUserMessage.content);
  }

  int getThinkingDuration(String messageId) => _thinkingDurations[messageId] ?? 0;

  Future<UserInfo> getUserInfo() async {
    if (_siliconflowApiKey.isEmpty) {
      throw Exception('请先配置 API Key');
    }
    return await _apiService.getUserInfo();
  }

  bool get isPro => _isPro;
  String get modelVersion => _modelVersion;
  
  void togglePro() {
    _isPro = !_isPro;
    _apiService.updateModel(currentModel);
    notifyListeners();
  }
  
  void setModelVersion(String version) {
    _modelVersion = version;
    _apiService.updateModel(currentModel);
    notifyListeners();
  }

  bool isMessageCompleted(String messageId) {
    return _completedMessages[messageId] ?? false;
  }

  void resetMessageCompletion(String messageId) {
    _completedMessages.remove(messageId);
    notifyListeners();
  }
}