import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../screens/settings_screen.dart';
import '../models/chat_session.dart';
import 'shader_logo.dart';

class ChatDrawer extends StatelessWidget {
  final List<ChatSession> chatSessions;
  final int? currentSessionId;
  final Function(int) onSessionSelected;
  final Function() onNewChat;

  const ChatDrawer({
    super.key,
    required this.chatSessions,
    required this.currentSessionId,
    required this.onSessionSelected,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ShaderLogo(),
            Expanded(
              child: ListView.builder(
                itemCount: chatSessions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('新对话'),
                      onTap: () {
                        context.read<ChatProvider>().newChat();
                        Navigator.pop(context);
                      },
                    );
                  }

                  final session = chatSessions[index - 1];
                  final isSelected = session.id == currentSessionId;

                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('删除对话'),
                            content: const Text('确定要删除这个对话吗？这将同时删除该对话中的所有收藏消息。'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final provider = context.read<ChatProvider>();
                                  
                                  if (provider.sessions.length == 1) {
                                    provider.newChat();
                                    Future.delayed(const Duration(milliseconds: 100), () {
                                      provider.deleteSession(session.id);
                                    });
                                  } else {
                                    provider.deleteSession(session.id);
                                  }
                                  
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      if (!isSelected) {
                        onSessionSelected(session.id);
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8), // 底部留白
          ],
        ),
      ),
    );
  }
}