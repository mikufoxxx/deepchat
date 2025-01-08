import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import 'package:markdown/markdown.dart' as md;

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;
  final Function(ChatMessage)? onFavorite;
  final bool isFavorited;
  final bool isComplete;
  final bool isStreaming;

  const ChatBubble({
    super.key,
    required this.message,
    this.isLast = false,
    this.onFavorite,
    this.isFavorited = false,
    this.isComplete = true,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    Widget messageContent;
    if (isUser) {
      messageContent = SelectableText(
        message.content,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
      );
    } else {
      messageContent = MarkdownBody(
        data: message.content,
        selectable: true,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 15,
            height: 1.4,
          ),
          code: TextStyle(
            backgroundColor: theme.colorScheme.surfaceVariant,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
          codeblockPadding: const EdgeInsets.all(8),
          codeblockDecoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquote: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontSize: 15,
            height: 1.4,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 4,
              ),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(
            left: 16,
            top: 8,
            bottom: 8,
          ),
        ),
        builders: {
          'code': CustomCodeBlockBuilder(
            textStyle: TextStyle(
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        },
        onTapLink: (text, href, title) async {
          if (href != null) {
            final url = Uri.parse(href);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          }
        },
      );
    }

    return Align(
      alignment: isUser ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(
              left: isUser ? 64 : 16,
              right: isUser ? 16 : 64,
              top: 4,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              color: isUser 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: !isUser ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1.0,
              ) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: messageContent,
            ),
          ),
          if (!isUser && isComplete && !isStreaming) ...[
            Positioned(
              right: 24,
              bottom: 44,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.surface.withOpacity(0.8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _copyToClipboard(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 8,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.surface.withOpacity(0.8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onFavorite!(message),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        size: 24,
                        color: isFavorited ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message.content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
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