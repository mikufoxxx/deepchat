import 'package:deepchat/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../utils/error_handler.dart';
import '../widgets/chat_drawer.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final currentSession = provider.currentSession;
    
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentSession?.title ?? '新对话'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: ChatDrawer(
          chatSessions: provider.sessions,
          currentSessionId: currentSession?.id,
          onSessionSelected: provider.selectSession,
          onNewChat: () {
            provider.newChat();
            Navigator.pop(context);
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: MessageList(
                key: ValueKey(currentSession?.id ?? 'new'),
              ),
            ),
            const ChatInput(),
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
                    chatProvider.updateApiService(apiService as String);
                    
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