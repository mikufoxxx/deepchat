import 'dart:io';

class UploadedItem {
  final File file;
  final String name;
  final String type; // 'image' 或 'file'
  final String? thumbnail; // 图片的缩略图路径
  String? ocrText;  // 添加这个字段存储OCR结果
  bool isProcessing;  // 添加处理状态
  double processProgress;  // 添加处理进度

  UploadedItem({
    required this.file,
    required this.name,
    required this.type,
    this.thumbnail,
    this.ocrText,
    this.isProcessing = false,
    this.processProgress = 0.0,
  });
} 