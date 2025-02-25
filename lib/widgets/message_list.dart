import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_bubble.dart';

class MessageList extends StatefulWidget {
  final ScrollController? scrollController;

  const MessageList({
    super.key,
    this.scrollController,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provider = context.read<ChatProvider>();
    
    if (provider.shouldScrollToBottom || provider.isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        if (provider.shouldScrollToBottom) {
          provider.setShouldScrollToBottom(false);
        }
      });
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
        final isLast = index == messages.length - 1;
        return ChatBubble(
          message: message,
          isLast: isLast,
          onFavorite: provider.toggleFavorite,
          isFavorited: provider.isFavorited(message),
          onRegenerate: () => provider.retryMessage(),
          isComplete: provider.isMessageCompleted(message.id),
          isStreaming: provider.isStreaming && isLast,
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