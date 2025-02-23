import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import 'chat_bubble.dart';
import 'dart:async';

class MessageList extends StatefulWidget {
  final ScrollController? scrollController;

  const MessageList({
    super.key,
    this.scrollController,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != null && 
        widget.scrollController != _scrollController) {
      _scrollController = widget.scrollController!;
    }
    _checkForTargetMessage();
  }

  void _checkForTargetMessage() {
    final provider = context.read<ChatProvider>();
    if (provider.isStreaming) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final messages = provider.currentMessages;
    final theme = Theme.of(context);

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ciallo，我是DeepChat',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '快来聊天吧~',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      padding: EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final message = messages[index];
        return ChatBubble(
          message: message,
          onFavorite: provider.toggleFavorite,
          isFavorited: provider.isFavorited(message),
          onRegenerate: () => provider.regenerateMessage(),
        );
      },
    );
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
} 