import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../screens/chat_screen.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage;
  List<ChatSession> _sessions = [];
  int _currentSessionId = 0;
  List<ChatMessage> _favoriteMessages = [];
  double _temperature = 0.7;
  String _apiKey = '';
  bool _isStreaming = false;
  ChatMessage? _messageToScrollTo;

  ChatProvider(this._storage) {
    _loadData();
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
      orElse: () => _sessions.first,
    );
  }

  // 获取当前会话的消息
  List<ChatMessage> get currentMessages => currentSession?.messages ?? [];

  // 加载保存的数据
  Future<void> _loadData() async {
    _sessions = _storage.loadSessions();
    _favoriteMessages = _storage.loadFavoriteMessages();
    _apiKey = _storage.getApiKey() ?? '';
    
    if (_sessions.isEmpty) {
      newChat();
    } else {
      _currentSessionId = _sessions.first.id;
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
  void selectSession(int id) {
    _currentSessionId = id;
    notifyListeners();
  }

  // 新建会话
  void newChat() {
    final newSessionId = DateTime.now().millisecondsSinceEpoch;
    final newSession = ChatSession(
      id: newSessionId,
      title: '新对话',
      messages: [
        ChatMessage(
          id: 'welcome_$newSessionId',
          role: 'assistant',
          content: '你好！很高兴见到你。有什么我可以帮忙的吗？',
          sessionId: newSessionId,
        ),
      ],
    );
    
    _sessions.add(newSession);
    _currentSessionId = newSession.id;
    _saveSessions();
    notifyListeners();
  }

  // 发送消息
  Future<void> sendMessage(String content) async {
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
      String accumulatedResponse = '';
      var session = currentSession;  // 使用 var 而不是 final
      if (session == null) return;
      
      final messages = [...session.messages];
      
      await for (final chunk in _apiService.getChatCompletionStream(
        messages, 
        _apiKey ?? '', 
        _temperature,
      )) {
        accumulatedResponse += chunk;
        final aiMessage = ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: accumulatedResponse,
          sessionId: _currentSessionId!,
        );
        _updateLastMessage(aiMessage);
        notifyListeners();
      }

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
    // 删除收藏消息
    _favoriteMessages.removeWhere((message) => message.sessionId == sessionId);
    
    // 删除会话
    _sessions.removeWhere((session) => session.id == sessionId);
    
    // 如果删除的是当前会话
    if (currentSession?.id == sessionId) {
      if (_sessions.isNotEmpty) {
        // 如果还有其他会话，选择最后一个会话
        selectSession(_sessions.last.id);
      } else {
        // 如果没有任何会话了，创建新会话
        newChat();
      }
    }
    
    // 保存更新
    _saveFavoriteMessages();
    _saveSessions();
    
    notifyListeners();
  }

  // 添加删除收藏消息的方法
  void deleteFavoriteMessage(ChatMessage message) {
    _favoriteMessages.removeWhere((m) => m.id == message.id);
    _saveFavoriteMessages();
    notifyListeners();
  }

  // 重命名会话
  void renameSession(int id, String newTitle) {
    final index = _sessions.indexWhere((session) => session.id == id);
    if (index >= 0) {
      _sessions[index] = _sessions[index].copyWith(title: newTitle);
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
    print('_updateLastMessage - 当前会话ID: $_currentSessionId'); // 调试日志
    final session = _sessions.firstWhere(
      (s) => s.id == _currentSessionId,
    );

    final updatedMessages = [...session.messages];
    print('_updateLastMessage - 更新前消息数: ${updatedMessages.length}'); // 调试日志

    if (updatedMessages.length >= 2) {
      // 保留用户消息，只更新AI回复
      final lastMessage = updatedMessages[updatedMessages.length - 1];
      if (lastMessage.role == 'assistant') {
        updatedMessages[updatedMessages.length - 1] = message;
      } else {
        updatedMessages.add(message);
      }
    } else {
      updatedMessages.add(message);
    }

    print('_updateLastMessage - 更新后消息数: ${updatedMessages.length}'); // 调试日志
    final updatedSession = session.copyWith(messages: updatedMessages);

    _sessions = _sessions.map((s) => 
      s.id == session.id ? updatedSession : s
    ).toList();

    _saveSessions();
    notifyListeners();
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
}