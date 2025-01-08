import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import 'chat_bubble.dart';
import 'dart:async';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _isNavigatingToMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForTargetMessage();
    });
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForTargetMessage();
  }

  void _checkForTargetMessage() {
    if (!mounted) return;
    
    final provider = context.read<ChatProvider>();
    final targetMessage = provider.messageToScrollTo;
    
    if (targetMessage != null && !_isNavigatingToMessage) {
      print('检测到目标消息: ${targetMessage.id}');
      _isNavigatingToMessage = true;
      
      // 确保UI已经构建完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToTarget(targetMessage);
        }
      });
    } else if (!_isNavigatingToMessage && provider.isStreaming) {
      // 处理流式响应的滚动
      _scrollToBottom();
    }
  }

  void _scrollToTarget(ChatMessage targetMessage) {
    if (!mounted || !_scrollController.hasClients) {
      _isNavigatingToMessage = false;
      return;
    }

    final messages = context.read<ChatProvider>().currentMessages;
    final index = messages.indexWhere((m) => m.id == targetMessage.id);
    
    print('滚动到消息，索引: $index');
    
    if (index != -1) {
      final targetOffset = index * 100.0;
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).then((_) {
        if (mounted) {
          _isNavigatingToMessage = false;
          context.read<ChatProvider>().clearScrollTarget();
        }
      });
    } else {
      _isNavigatingToMessage = false;
      context.read<ChatProvider>().clearScrollTarget();
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: context.watch<ChatProvider>().currentMessages.length,
      itemBuilder: (context, index) {
        final message = context.watch<ChatProvider>().currentMessages[index];
        final isLast = index == context.watch<ChatProvider>().currentMessages.length - 1;
        
        return ChatBubble(
          key: ValueKey('message_${message.id}'),
          message: message,
          isLast: isLast,
          isFavorited: context.watch<ChatProvider>().isFavorited(message),
          onFavorite: (message) {
            context.read<ChatProvider>().toggleFavorite(message);
          },
          isComplete: !context.watch<ChatProvider>().isStreaming || !isLast,
          isStreaming: context.watch<ChatProvider>().isStreaming && isLast,
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
} 