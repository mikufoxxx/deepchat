import 'package:deepchat/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
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