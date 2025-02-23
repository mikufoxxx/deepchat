import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';
import '../widgets/favorite_message_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../models/user_info.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设置'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '基本设置'),
              Tab(text: '收藏消息'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _BasicSettingsTab(),
            _FavoriteMessagesTab(),
          ],
        ),
      ),
    );
  }
}

class _FavoriteMessagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favoriteMessages = context.watch<ChatProvider>().favoriteMessages;
    final sessions = context.watch<ChatProvider>().sessions;
    final theme = Theme.of(context);

    if (favoriteMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无收藏消息',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: favoriteMessages.length,
      itemBuilder: (context, index) {
        final message = favoriteMessages[index];
        final session = sessions.firstWhere(
          (s) => s.id == message.sessionId,
          orElse: () => ChatSession(
            id: -1,
            title: '已删除的对话',
            messages: [],
          ),
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _FavoriteMessageDetailDialog(message: message),
              );
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('删除收藏'),
                  content: const Text('确定要删除这条收藏消息吗？'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<ChatProvider>().deleteFavoriteMessage(message);
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.bookmark,
                        size: 16,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteMessageDetailDialog extends StatelessWidget {
  final ChatMessage message;

  const _FavoriteMessageDetailDialog({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: theme.colorScheme.surface,
      elevation: 8,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 800,
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      message.isUser ? Icons.person : Icons.smart_toy,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message.isUser ? '我的消息' : 'AI 回复',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已复制到剪贴板'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: '复制内容',
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 消息内容
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: message.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: theme.colorScheme.onSurface,
                          ),
                          code: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          ),
                          codeblockPadding: const EdgeInsets.all(16),
                          codeblockDecoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          blockquote: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                                width: 4,
                              ),
                            ),
                          ),
                          blockquotePadding: const EdgeInsets.only(left: 20),
                          listBullet: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 16,
                          ),
                          h1: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicSettingsTab extends StatelessWidget {
  const _BasicSettingsTab({super.key});

  Widget _buildApiSection(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ChatProvider>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '账户设置',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<UserInfo>(
            future: provider.getUserInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Column(
                  children: [
                    _buildApiKeyInput(context, provider, theme),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '获取用户信息失败: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                );
              }

              final userInfo = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildApiKeyInput(context, provider, theme),
                  const SizedBox(height: 16),
                  _buildBalanceInfo(userInfo, theme),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyInput(BuildContext context, ChatProvider provider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '硅基流动 API Key',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '在 docs.siliconflow.cn 获取',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: provider.siliconflowApiKey),
          onChanged: provider.updateSiliconflowApiKey,
          decoration: InputDecoration(
            hintText: 'sf-xxxxxx',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTemperatureSlider(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        String description = '';
        if (provider.temperature <= 0.2) {
          description = '当前适合：代码生成、数学解题等高精确度的任务';
        } else if (provider.temperature <= 0.7) {
          description = '当前适合：数据抽取、分析等需要高准确性的任务';
        } else if (provider.temperature <= 1.3) {
          description = '当前适合：通用对话、翻译等较为均衡的任务';
        } else {
          description = '当前适合：创意写作、创作等需要高创造力的任务';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: provider.temperature,
              min: 0.0,
              max: 1.5,
              divisions: 15,
              label: provider.temperature.toStringAsFixed(1),
              onChanged: (value) {
                provider.setTemperature(value);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前温度：${provider.temperature.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final List<Color> themeColors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          _buildThemeItem(
            theme,
            icon: Icons.brightness_auto,
            label: '跟随系统',
            trailing: Switch(
              value: themeProvider.followSystem,
              onChanged: (bool value) {
                themeProvider.setFollowSystem(value);
              },
            ),
          ),
          if (!themeProvider.followSystem)
            _buildThemeItem(
              theme,
              icon: Icons.dark_mode_outlined,
              label: '深色模式',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
          _buildThemeItem(
            theme,
            icon: Icons.palette_outlined,
            label: '主题色',
            trailing: Container(width: 1), // 占位
            isLast: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in themeColors)
                    GestureDetector(
                      onTap: () => themeProvider.setThemeColor(color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeProvider.themeColor == color
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    Widget? trailing,
    Widget? child,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
        if (child != null) child,
        if (!isLast)
          Divider(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            height: 16,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'API 设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildApiSection(context),
        const SizedBox(height: 24),
        const Text(
          '温度设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTemperatureSlider(context),
        const SizedBox(height: 24),
        const Text(
          '主题设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildThemeSection(context),
        const SizedBox(height: 24),
        const Text(
          '关于',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAboutSection(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          _buildAboutItem(
            theme,
            icon: Icons.person_outline,
            label: '作者',
            value: '狐狸ox',
          ),
          _buildAboutItem(
            theme,
            icon: Icons.info_outline,
            label: '版本',
            value: '1.1.0',
          ),
          _buildAboutItem(
            theme,
            icon: Icons.code_rounded,
            label: '项目地址',
            value: '查看源代码',
            onTap: () async {
              const url = 'https://github.com/mikufoxxx/deepchat';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('无法打开链接')),
                  );
                }
              }
            },
          ),
          _buildAboutItem(
            theme,
            icon: Icons.gavel_outlined,
            label: '许可证',
            value: 'MIT License',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    final content = Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }

  Widget _buildBalanceInfo(UserInfo userInfo, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildBalanceCard(
            '免费额度',
            userInfo.balance,
            theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBalanceCard(
            '付费额度',
            userInfo.chargeBalance,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(String title, double amount, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥ ${amount.toStringAsFixed(4)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class TemperatureInfo extends StatelessWidget {
  const TemperatureInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '温度值说明',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildTemperatureItem(
            theme,
            '代码生成/数学解题',
            '0.0',
            '最精确的输出，适合需要准确性的任务',
          ),
          _buildTemperatureItem(
            theme,
            '数据抽取/分析',
            '1.0',
            '保持较高准确性，同时允许适度灵活',
          ),
          _buildTemperatureItem(
            theme,
            '通用对话',
            '1.3',
            '平衡准确性和创造性，适合日常对话',
          ),
          _buildTemperatureItem(
            theme,
            '翻译',
            '1.3',
            '在保持原意的同时允许适当调整以符合目标语言习惯',
          ),
          _buildTemperatureItem(
            theme,
            '创意类写作/诗歌创作',
            '1.5',
            '最大程度发挥创造力，产生多样化的表达',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureItem(
    ThemeData theme,
    String task,
    String temperature,
    String description, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              temperature,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildModelSection(BuildContext context) {
  final theme = Theme.of(context);
  final provider = context.watch<ChatProvider>();
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '模型选择',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        RadioListTile<String>(
          title: const Text('DeepSeek Chat'),
          value: 'deepseek',
          groupValue: provider.selectedModel,
          onChanged: (value) => provider.setModel(value!),
        ),
        RadioListTile<String>(
          title: const Text('DeepSeek V3 (SiliconFlow)'),
          value: 'siliconflow',
          groupValue: provider.selectedModel,
          onChanged: (value) => provider.setModel(value!),
        ),
      ],
    ),
  );
} 