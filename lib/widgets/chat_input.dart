import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import '../models/uploaded_item.dart';
import '../services/document_service.dart';

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
  List<UploadedItem> _uploadedItems = [];
  
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
    final theme = Theme.of(context);
    final provider = context.watch<ChatProvider>();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          color: theme.colorScheme.surface.withOpacity(0.1),
          padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUploadedItems(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _showFeatureMenu(context),
                    constraints: BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 120,
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        minLines: 1,
                        style: TextStyle(fontSize: 14),
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.trim().isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: '输入消息...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: _isFocused
                                  ? theme.colorScheme.primary.withOpacity(0.3)
                                  : theme.colorScheme.outlineVariant.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSendButton(context),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => provider.toggleDeepThinking(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                            size: 16,
                            color: provider.isDeepThinking
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '深度思考',
                            style: TextStyle(
                              fontSize: 13,
                              color: provider.isDeepThinking
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showModelSelectionDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isPro 
                            ? theme.colorScheme.primaryContainer.withOpacity(0.7)
                            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: provider.isPro
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : theme.colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.model_training,
                            size: 16,
                            color: provider.isPro
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.isPro ? 'Pro' : '标准版',
                            style: TextStyle(
                              fontSize: 13,
                              color: provider.isPro
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    final provider = context.watch<ChatProvider>();
    
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: _isComposing 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isComposing
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSend ? () => _handleSend() : null,
          borderRadius: BorderRadius.circular(20),
          child: IconButton(
            onPressed: _canSend ? () => _handleSend() : null,
            icon: provider.isResponding
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isComposing
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: _isComposing
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
            style: IconButton.styleFrom(
              backgroundColor: _isComposing
                  ? theme.colorScheme.primary
                  : null,
              foregroundColor: _isComposing
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSend {
    if (_uploadedItems.any((item) => item.isProcessing)) return false;
    return _isComposing || _uploadedItems.isNotEmpty;
  }

  void _handleSend() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _uploadedItems.isEmpty || !mounted) return;

    setState(() {
      _isComposing = false;
    });
    _controller.clear();
    
    final provider = context.read<ChatProvider>();
    await provider.sendMessage(content);
    
    setState(() {
      _uploadedItems.clear(); // 发送后清空上传列表
    });
  }

  void _showModelSelectionDialog(BuildContext context) {
    Theme.of(context);
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

  void _showFeatureMenu(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '选择上传类型',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.camera_alt,
                    title: '拍照上传',
                    subtitle: '使用相机拍摄照片',
                    onTap: () {
                      Navigator.pop(context);
                      _handleImageUpload(ImageSource.camera);
                    },
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.photo_library,
                    title: '从相册选择',
                    subtitle: '从相册中选择图片',
                    onTap: () {
                      Navigator.pop(context);
                      _handleImageUpload(ImageSource.gallery);
                    },
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.upload_file,
                    title: '上传文件',
                    subtitle: '上传本地文档文件',
                    onTap: () {
                      Navigator.pop(context);
                      _handleFileUpload();
                    },
                    showBorder: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBorder = true,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder ? Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageUpload(ImageSource source) async {
    final uploadService = UploadService();
    final documentService = DocumentService();
    
    try {
      final file = await uploadService.pickImage(source);
      if (file != null) {
        final size = await file.length();
        
        if (size > 10 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片大小不能超过10MB')),
            );
          }
          return;
        }

        // 添加到列表，设置处理状态
        final uploadedItem = UploadedItem(
          file: file,
          name: file.path.split('/').last,
          type: 'image',
          isProcessing: true,
        );
        
        setState(() {
          _uploadedItems.add(uploadedItem);
        });

        // 使用 DocumentService 处理图片OCR
        try {
          print('开始处理图片OCR...');
          final fileType = file.path.split('.').last.toLowerCase();
          final ocrText = await documentService.extractText(file, fileType);
          print('OCR处理完成，文本长度: ${ocrText?.length ?? 0}');
          
          setState(() {
            uploadedItem.ocrText = ocrText;
            uploadedItem.isProcessing = false;
            uploadedItem.processProgress = 1.0;
          });
        } catch (e) {
          print('OCR处理失败: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OCR处理失败: $e')),
            );
          }
          setState(() {
            uploadedItem.isProcessing = false;
            uploadedItem.processProgress = 0.0;
            // 即使OCR失败也保留图片
            uploadedItem.ocrText = '图片OCR处理失败，但您仍可以发送图片。';
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  Future<void> _handleFileUpload() async {
    final uploadService = UploadService();
    final documentService = DocumentService();
    
    try {
      final file = await uploadService.pickFile();
      if (file != null) {
        final size = await file.length();
        
        if (size > 10 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件大小不能超过10MB')),
            );
          }
          return;
        }

        // 添加到列表，设置处理状态
        final uploadedItem = UploadedItem(
          file: file,
          name: file.path.split('/').last,
          type: 'file',
          isProcessing: true,
        );
        
        setState(() {
          _uploadedItems.add(uploadedItem);
        });

        // 使用 DocumentService 处理文件
        try {
          print('开始处理文件...');
          final fileType = file.path.split('.').last.toLowerCase();
          final extractedText = await documentService.extractText(file, fileType);
          print('文件处理完成，文本长度: ${extractedText?.length ?? 0}');
          
          setState(() {
            uploadedItem.ocrText = extractedText;  // 确保这里设置了提取的文本
            uploadedItem.isProcessing = false;
            uploadedItem.processProgress = 1.0;
          });

          // 添加到 Provider 中
          if (context.mounted) {
            context.read<ChatProvider>().addUploadedItem(uploadedItem);  // 确保这里添加了上传项
          }
        } catch (e) {
          print('文件处理失败: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('文件处理失败: $e')),
            );
          }
          setState(() {
            uploadedItem.isProcessing = false;
            uploadedItem.processProgress = 0.0;
            uploadedItem.ocrText = '文件处理失败，但您仍可以发送文件。';
          });
        }
      }
    } catch (e) {
      print('选择文件失败: $e');
    }
  }

  Widget _buildUploadedItems() {
    if (_uploadedItems.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _uploadedItems.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final item = _uploadedItems[index];
          final theme = Theme.of(context);
          
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isProcessing 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.type == 'image')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          item.file,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.insert_drive_file,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (item.isProcessing)
                          Text(
                            '正在处理...',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          Text(
                            '${(item.file.lengthSync() / 1024).toStringAsFixed(1)}KB',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (!item.isProcessing) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _uploadedItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (item.isProcessing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CircularProgressIndicator(
                      value: item.processProgress,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          );
        },
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