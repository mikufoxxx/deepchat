import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';

class ChatProvider with ChangeNotifier {
  ApiService _apiService;
  final StorageService _storageService;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentStreamMessage = '';
  String? _error;

  ChatProvider({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService {
    _loadMessages();
  }

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String get currentStreamMessage => _currentStreamMessage;
  String? get error => _error;

  Future<void> sendMessage(String content) async {
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        role: 'system',
        content: ApiConfig.defaultSystemPrompt,
      ));
    }

    final userMessage = ChatMessage(role: 'user', content: content);
    _messages.add(userMessage);
    _isLoading = true;
    _currentStreamMessage = '';
    _error = null;
    notifyListeners();

    try {
      await for (final chunk in _apiService.sendMessageStream(_messages)) {
        _currentStreamMessage += chunk;
        notifyListeners();
      }

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: _currentStreamMessage,
      );
      _messages.add(assistantMessage);
      _currentStreamMessage = '';
      await _storageService.saveMessages(_messages);
    } catch (e) {
      _error = '发送消息失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMessages() async {
    _messages = await _storageService.loadMessages();
    notifyListeners();
  }

  void updateApiService(ApiService newApiService) {
    _apiService = newApiService;
    notifyListeners();
  }
} 