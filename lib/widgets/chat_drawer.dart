import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_session.dart';
import 'package:collection/collection.dart';

class ChatDrawer extends StatelessWidget {
  final List<ChatSession> chatSessions;
  final int? currentSessionId;
  final Function(int) onSessionSelected;
  final Function() onNewChat;
  final bool isWideScreen;

  const ChatDrawer({
    super.key,
    required this.chatSessions,
    required this.currentSessionId,
    required this.onSessionSelected,
    required this.onNewChat,
    this.isWideScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 对会话按时间分组
    final groupedSessions = groupBy(
      chatSessions.reversed,
      (ChatSession session) {
        final now = DateTime.now();
        final sessionTime = DateTime.fromMillisecondsSinceEpoch(session.id);
        
        // 转换为日期（去掉时间部分）
        final sessionDate = DateTime(sessionTime.year, sessionTime.month, sessionTime.day);
        final today = DateTime(now.year, now.month, now.day);
        
        final difference = today.difference(sessionDate).inDays;

        if (difference == 0) {
          return '今天';
        } else if (difference == 1) {
          return '昨天';
        } else if (difference <= 7) {
          return '最近7天';
        } else if (difference <= 30) {
          return '最近30天';
        } else {
          return '更早';
        }
      },
    );
    
    final drawerContent = Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: groupedSessions.length,
            itemBuilder: (context, index) {
              final entry = groupedSessions.entries.elementAt(index);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontFamily: 'Noto Sans',
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ...entry.value.map((session) {
                    final isSelected = session.id == currentSessionId;
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Noto Sans',
                          color: isSelected ? theme.colorScheme.primary : null,
                          fontWeight: isSelected ? FontWeight.w500 : null,
                        ),
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
                          if (!isWideScreen) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.08),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  '新建对话',
                  style: TextStyle(
                    fontFamily: 'Noto Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  onNewChat();
                  if (!isWideScreen) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );

    return isWideScreen
        ? Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
            ),
            child: drawerContent,
          )
        : Drawer(
            backgroundColor: theme.colorScheme.surface,
            child: SafeArea(child: drawerContent),
          );
  }
}