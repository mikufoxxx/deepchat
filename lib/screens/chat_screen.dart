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
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    final chatDrawer = ChatDrawer(
      chatSessions: provider.sessions,
      currentSessionId: currentSession?.id,
      onSessionSelected: (id) => provider.selectSession(id),
      onNewChat: () => provider.newChat(),
      isWideScreen: isWideScreen,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSession?.title ?? '新对话'),
        leading: isWideScreen ? null : Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.model_training),
            onPressed: () => _showModelSelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWideScreen)
            SizedBox(
              width: 280,
              child: chatDrawer,
            ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: MessageList(),
                ),
                const ChatInput(),
              ],
            ),
          ),
        ],
      ),
      drawer: isWideScreen ? null : chatDrawer,
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

  void _showModelSelectionDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择模型'),
        contentPadding: const EdgeInsets.fromLTRB(8, 20, 8, 24),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('DeepSeek 官方 API'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '暂不可用',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                leading: Radio<String>(
                  value: 'deepseek',
                  groupValue: context.watch<ChatProvider>().selectedModel,
                  onChanged: null,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('硅基流动 API'),
                subtitle: Text(
                  '推荐使用',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
                leading: Radio<String>(
                  value: 'siliconflow',
                  groupValue: context.watch<ChatProvider>().selectedModel,
                  onChanged: (value) {
                    try {
                      context.read<ChatProvider>().setModel(value!);
                      Navigator.pop(context);
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          behavior: SnackBarBehavior.floating,
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
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
} 