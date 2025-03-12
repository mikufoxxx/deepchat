import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/uploaded_item.dart';
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
  DateTime _lastNotifyTime = DateTime.now();
  bool _isResponding = false;
  bool _shouldScrollToBottom = false;
  UserInfo? _cachedUserInfo;
  bool _isBalanceRefreshing = false;
  List<UploadedItem> _uploadedItems = [];

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
    
    // 加载用户设置
    _isDeepThinking = await _storage.getIsDeepThinking() ?? false;
    _isPro = await _storage.getIsPro() ?? false;
    _modelVersion = _isDeepThinking ? 'r1' : 'v3';
    
    // 检查最新的会话是否为空
    if (_sessions.isNotEmpty) {
      final latestSession = _sessions.last;
      if (latestSession.messages.isEmpty) {
        _sessions.removeLast();
      }
    }
    
    // 无论是否有其他会话，都创建新会话
    final newSessionId = DateTime.now().millisecondsSinceEpoch;
    final newSession = ChatSession(
      id: newSessionId,
      title: '新对话',
      messages: [],
    );
    _sessions.add(newSession);
    _currentSessionId = newSession.id;
    
    _apiService.updateModel(currentModel);
    _apiService.updateApiKey(_apiKey);
    
    _saveSessions();
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
    if (!canInteract) {
      // 通知UI显示提示
      notifyListeners();
      return;
    }
    if (_sessions.any((session) => session.id == id)) {
      _streamSubscription?.cancel();
      _isStreaming = false;
      _currentSessionId = id;
      _shouldScrollToBottom = true;
      notifyListeners();
    }
  }

  // 新建会话
  void newChat() {
    if (!canInteract) {
      notifyListeners();
      return;
    }
    
    final newSessionId = DateTime.now().millisecondsSinceEpoch;
    final newSession = ChatSession(
      id: newSessionId,
      title: '新对话',
      messages: [],
      documentContext: [], // 新会话的文档上下文为空
    );
    
    _sessions.add(newSession);
    _currentSessionId = newSession.id;
    _uploadedItems.clear(); // 清空当前上传列表
    _saveSessions();
    notifyListeners();
  }

  // 发送消息
  Future<void> sendMessage(String content) async {
    if (_isStreaming || (content.trim().isEmpty && _uploadedItems.isEmpty)) return;
    
    final session = currentSession;
    if (session == null) return;
    
    _isStreaming = true;
    _isResponding = true;
    notifyListeners();
    
    try {
      String fullContent = '';
      
      // 使用当前会话的文档上下文
      for (var item in session.documentContext) {
        if (item.ocrText != null && item.ocrText!.isNotEmpty) {
          fullContent += '用户之前上传的${item.type == 'image' ? '图片' : '文件'}${item.name}的内容为：${item.ocrText}\n\n';
        }
      }
      
      // 添加当前上传的文件内容
      if (_uploadedItems.isNotEmpty) {
        for (var item in _uploadedItems) {
          if (item.ocrText != null && item.ocrText!.isNotEmpty) {
            fullContent += '用户刚刚上传了一个${item.type == 'image' ? '图片' : '文件'}${item.name}，内容为：${item.ocrText}\n\n';
          }
        }
        
        // 将当前上传的文件添加到当前会话的上下文中
        final updatedSession = session.copyWith(
          documentContext: [...session.documentContext, ..._uploadedItems],
        );
        _sessions = _sessions.map((s) => 
          s.id == session.id ? updatedSession : s
        ).toList();
        _saveSessions();
      }
      
      fullContent += content;

      // 创建消息对象
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: content,
        sessionId: session.id,
        attachments: List.from(_uploadedItems),
      );

      _addMessage(userMessage);
      _uploadedItems.clear();
      
      // 使用完整内容发送请求
      var thoughtProcess = '';
      var response = '';
      final startTime = DateTime.now();
      
      _streamSubscription = _apiService
          .getChatCompletionStream(
            [...currentMessages, 
              ChatMessage(
                id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                role: 'user',
                content: fullContent,
                sessionId: _currentSessionId,
                timestamp: DateTime.now(),
              )
            ],
            _siliconflowApiKey, 
            _temperature
          )
          .listen(
        (chunk) {
          if (DateTime.now().difference(_lastNotifyTime).inMilliseconds > 100) {
            notifyListeners();
            _lastNotifyTime = DateTime.now();
          }
          
          if (chunk.startsWith('思考过程：')) {
            thoughtProcess += chunk.substring(5);
            final aiMessage = ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: thoughtProcess,
              isThinking: true,
              sessionId: _currentSessionId,
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
              sessionId: _currentSessionId,
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
              sessionId: _currentSessionId,
              timestamp: startTime,
              thoughtProcess: thoughtProcess,
            );
            _updateLastMessage(aiMessage);
          }
        },
        onDone: () async {
          // 标记最后一条消息为完成状态
          final lastMessage = currentSession?.messages.last;
          if (lastMessage != null) {
            _completedMessages[lastMessage.id] = true;
            notifyListeners();
          }
          
          final session = currentSession;
          if (session != null && _isFirstRoundComplete(session)) {
            await _generateTitle(session);
          }
          _isResponding = false;
          notifyListeners();
        },
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: '抱歉，发生了错误：$e',
        sessionId: _currentSessionId,
      );
      _addMessage(errorMessage);
      _isResponding = false;
      notifyListeners();
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
        id: _currentSessionId,
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
    final messageWithModel = message.copyWith(
      model: _modelVersion,
      thoughtProcess: _modelVersion == 'r1' ? message.thoughtProcess : null,
    );

    _sessions = _sessions.map((session) {
      if (session.id == _currentSessionId) {
        final messages = List<ChatMessage>.from(session.messages);
        if (messages.isNotEmpty && messages.last.role == 'assistant') {
          messages[messages.length - 1] = messageWithModel;
        } else {
          messages.add(messageWithModel);
        }
        return session.copyWith(messages: messages);
      }
      return session;
    }).toList();

    _saveSessions();
    _shouldScrollToBottom = true;
    notifyListeners();
  }


  bool _shouldGenerateTitle(ChatSession session) {
    return session.messages.length >= 2 && 
           session.title == '新对话' &&
           session.messages[0].role == 'user' &&
           session.messages[1].role == 'assistant' &&
           !session.messages[1].isThinking;
  }

  Future<void> _generateTitle(ChatSession session) async {
    if (!_shouldGenerateTitle(session)) return;

    // 构建用于生成标题的消息
    final titleMessages = [
      ChatMessage(
        id: 'system_${DateTime.now().millisecondsSinceEpoch}',
        role: 'system',
        content: '请根据用户的问题和AI的回答生成一个对话主题（不超过10个字），直接返回标题就行，不要添加任何解释，注释，说明或标点符号，也不要markdown，就纯文本就行。',
        sessionId: _currentSessionId,
        timestamp: DateTime.now(),
      ),
      session.messages[0], // 用户的问题
      session.messages[1], // AI的回答
    ];

    try {
      var title = '';
      // 临时保存当前模型设置
      final originalModel = _apiService.currentModel;
      
      // 强制使用标准版 v3 模型
      _apiService.updateModel(ApiConfig.models['siliconflow']!);
      
      await for (final chunk in _apiService.getChatCompletionStream(
        titleMessages,
        _siliconflowApiKey,
        0.5,
      )) {
        if (!chunk.startsWith('思考过程：')) {
          title += chunk;
        }
      }
      
      // 恢复原来的模型设置
      _apiService.updateModel(originalModel);
      
      // 如果生成的标题为空，使用默认标题
      final finalTitle = title.trim().isEmpty ? '日常对话交流' : title.trim();
      
      // 更新会话标题
      renameSession(_currentSessionId, finalTitle);
    } catch (e) {
      print('生成标题失败: $e');
      // 发生错误时使用默认标题
      renameSession(_currentSessionId, '日常对话交流');
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
    if (!canInteract) {
      notifyListeners();
      return;
    }
    _isDeepThinking = !_isDeepThinking;
    _modelVersion = _isDeepThinking ? 'r1' : 'v3';
    _storage.saveIsDeepThinking(_isDeepThinking);  // 保存设置
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
    if (_isStreaming) return;
    
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

  Future<UserInfo> getUserInfo({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUserInfo != null) {
      return _cachedUserInfo!;
    }
    
    if (_siliconflowApiKey.isEmpty) {
      throw Exception('请先配置 API Key');
    }
    
    _isBalanceRefreshing = true;
    
    try {
      _cachedUserInfo = await _apiService.getUserInfo();
      return _cachedUserInfo!;
    } finally {
      _isBalanceRefreshing = false;
      notifyListeners();  // 只在最后通知一次
    }
  }

  bool get isPro => _isPro;
  String get modelVersion => _modelVersion;
  
  void togglePro() {
    if (!canInteract) {
      notifyListeners();
      return;
    }
    _isPro = !_isPro;
    _storage.saveIsPro(_isPro);  // 保存设置
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

  void refreshCurrentSession() {
    if (currentSession != null) {
      _currentSessionId = currentSession!.id;
      notifyListeners();
    }
  }

  bool _isFirstRoundComplete(ChatSession session) {
    return session.messages.length == 2 && 
           session.title == '新对话' &&
           session.messages[0].role == 'user' &&
           session.messages[1].role == 'assistant' &&
           !session.messages[1].isThinking;
  }

  bool get isResponding => _isResponding;

  bool get shouldScrollToBottom => _shouldScrollToBottom;

  void setShouldScrollToBottom(bool value) {
    _shouldScrollToBottom = value;
    notifyListeners();
  }

  bool get canInteract => !_isStreaming && !_isResponding;

  void showStreamingWarning(BuildContext context) {
    if (!canInteract) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请等待对话完成喵~'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void showSettings(BuildContext context) {
    if (!canInteract) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text('请等待对话完成喵~'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            right: 20,
            left: 20,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      );
    }
  }

  bool get isBalanceRefreshing => _isBalanceRefreshing;

  Future<void> handleFileUpload(File file) async {
    if (_isStreaming) return;
    
    try {
      final content = await file.readAsString();
      await sendMessage('以下是文件内容，请帮我分析：\n\n$content');
    } catch (e) {
      if (currentSession != null) {
        final errorMessage = ChatMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: '读取文件失败：$e',
          sessionId: _currentSessionId,
        );
        _addMessage(errorMessage);
        notifyListeners();
      }
    }
  }

  Future<void> handleImageUpload(File image) async {
    if (_isStreaming) return;
    
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      await sendMessage('这是一张图片，请帮我分析：\n![image]($base64Image)');
    } catch (e) {
      if (currentSession != null) {
        final errorMessage = ChatMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          role: 'assistant',
          content: '处理图片失败：$e',
          sessionId: _currentSessionId,
        );
        _addMessage(errorMessage);
        notifyListeners();
      }
    }
  }

  void addUploadedItem(UploadedItem item) {
    _uploadedItems.add(item);
    notifyListeners();
  }

  void removeUploadedItem(UploadedItem item) {
    _uploadedItems.remove(item);
    
    if (currentSession != null) {
      // 创建一个新的可修改列表
      final updatedContext = List<UploadedItem>.from(currentSession!.documentContext)
        ..removeWhere((i) => i.name == item.name && i.type == item.type);
      
      // 使用 copyWith 创建新的 session
      final updatedSession = currentSession!.copyWith(
        documentContext: updatedContext,
      );
      
      // 更新 sessions 列表
      _sessions = _sessions.map((s) => 
        s.id == currentSession!.id ? updatedSession : s
      ).toList();
      
      // 更新当前 session
      _currentSessionId = updatedSession.id;
    }
    
    _saveSessions();
    notifyListeners();
  }
}