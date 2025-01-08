import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../utils/error_handler.dart';
import 'dart:ui';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: const Text(
          'AI Chat',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showApiKeyDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE9E0FF).withOpacity(0.5),
              const Color(0xFFFFFFFF),
              const Color(0xFFE0F0FF).withOpacity(0.5),
            ],
          ),
        ),
        child: Column(
          children: const [
            Expanded(
              child: MessageList(),
            ),
            ChatInput(),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final currentKey = storageService.getApiKey() ?? '';
    
    final controller = TextEditingController(text: currentKey);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置 API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '请输入您的 Deepseek API Key',
                helperText: '在 Deepseek 官网获取 API Key',
              ),
              obscureText: true, // 密码形式显示
            ),
            const SizedBox(height: 8),
            if (currentKey.isNotEmpty)
              const Text(
                '已设置 API Key',
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                try {
                  // 保存 API Key
                  await storageService.saveApiKey(newKey);
                  
                  // 更新 ApiService
                  if (context.mounted) {
                    // 重新创建 ApiService 实例
                    final apiService = ApiService(apiKey: newKey);
                    
                    // 更新 ChatProvider
                    final chatProvider = Provider.of<ChatProvider>(
                      context, 
                      listen: false
                    );
                    chatProvider.updateApiService(apiService);
                    
                    ErrorHandler.showError(
                      context, 
                      'API Key 设置成功！'
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ErrorHandler.showError(
                      context, 
                      '保存 API Key 失败: ${e.toString()}'
                    );
                  }
                }
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
} 