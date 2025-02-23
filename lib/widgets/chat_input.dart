import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: theme.colorScheme.surface.withOpacity(0.8),
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isFocused
                            ? theme.colorScheme.primary.withOpacity(0.3)
                            : theme.colorScheme.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => provider.toggleDeepThinking(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isDeepThinking 
                            ? theme.colorScheme.primaryContainer.withOpacity(0.7)
                            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: provider.isDeepThinking
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : theme.colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 14,
                            color: provider.isDeepThinking
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '深度思考',
                            style: TextStyle(
                              fontSize: 12,
                              color: provider.isDeepThinking
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showModelSelectionDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isPro 
                            ? theme.colorScheme.tertiaryContainer.withOpacity(0.7)
                            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: provider.isPro
                              ? theme.colorScheme.tertiary.withOpacity(0.3)
                              : theme.colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.model_training,
                            size: 14,
                            color: provider.isPro
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.isPro ? 'Pro' : '标准版',
                            style: TextStyle(
                              fontSize: 12,
                              color: provider.isPro
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildSendButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: _isComposing 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isComposing ? _handleSubmit : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.send,
                  size: 14,
                  color: _isComposing 
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '发送',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isComposing 
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(text);
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  void _showModelSelectionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<ChatProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择模型版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Text('标准版'),
              subtitle: const Text('使用免费和付费额度'),
              value: false,
              groupValue: provider.isPro,
              onChanged: (value) {
                provider.togglePro();
                Navigator.pop(context);
              },
            ),
            RadioListTile<bool>(
              title: const Text('专业版'),
              subtitle: const Text('仅消耗付费额度'),
              value: true, 
              groupValue: provider.isPro,
              onChanged: (value) {
                provider.togglePro();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
} 