import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;
  final bool isFavorited;
  final bool isComplete;
  final bool isStreaming;
  final Function(ChatMessage) onFavorite;
  final VoidCallback onRegenerate;

  const ChatBubble({
    super.key,
    required this.message,
    this.isLast = false,
    this.isFavorited = false,
    this.isComplete = true,
    this.isStreaming = false,
    required this.onFavorite,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: message.role == 'user' 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          if (message.role == 'user')
            _buildUserMessage(context)
          else
            _buildAssistantMessage(context),
        ],
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: MarkdownBody(
        data: message.content,
        selectable: true,
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ChatProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.isDeepThinking && message.thoughtProcess != null)
          ThinkingSection(message: message),
        if (!message.isThinking)
          Container(
            width: MediaQuery.of(context).size.width * 0.95,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  message.content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (!message.isUser)
                  _buildMessageActions(context),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMessageActions(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              size: 16,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => onFavorite(message),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: () => _copyToClipboard(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: onRegenerate,
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final textToCopy = message.thoughtProcess != null ? 
                    '思考过程：\n${message.thoughtProcess}\n\n回答：\n${message.content}' : 
                    message.content;
    
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制到剪贴板'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}

class CustomCodeBlockBuilder extends MarkdownElementBuilder {
  final TextStyle? textStyle;

  CustomCodeBlockBuilder({this.textStyle});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: textStyle?.backgroundColor,
        ),
        child: SelectableText(
          element.children?.map((e) => e.textContent).join('\n') ?? '',
          style: textStyle,
        ),
      ),
    );
  }
}

class ThinkingStatus extends StatelessWidget {
  final bool isThinking;
  final ChatMessage message;

  const ThinkingStatus({
    Key? key,
    required this.isThinking,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ChatProvider>();
    final thinkingDuration = provider.getThinkingDuration(message.id);
    
    return Row(
      children: [
        if (isThinking)
          SizedBox(
            width: 10,
            height: 10,
            child: RepaintBoundary(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.outline,
                ),
              ),
            ),
          )
        else
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: theme.colorScheme.outline,
          ),
        SizedBox(width: 6),
        Text(
          isThinking ? '思考中...（用时${thinkingDuration}秒）' : 
          '思考完毕（用时${thinkingDuration}秒）',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class ThinkingSection extends StatefulWidget {
  final ChatMessage message;

  const ThinkingSection({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<ThinkingSection> createState() => _ThinkingSectionState();
}

class _ThinkingSectionState extends State<ThinkingSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (widget.message.isThinking)
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: RepaintBoundary(
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.check_circle_outline,
                          size: 12,
                          color: theme.colorScheme.outline,
                        ),
                      SizedBox(width: 6),
                      Text(
                        widget.message.isThinking ? 
                          '思考中（用时${context.watch<ChatProvider>().getThinkingDuration(widget.message.id)}秒）' : 
                          '思考完毕（用时${context.watch<ChatProvider>().getThinkingDuration(widget.message.id)}秒）',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.message.thoughtProcess?.isNotEmpty == true)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
              ],
            ),
          ),
          if (_isExpanded && widget.message.thoughtProcess?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(
                widget.message.thoughtProcess!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.4,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}