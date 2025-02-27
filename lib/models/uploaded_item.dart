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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'thumbnail': thumbnail,
      'ocrText': ocrText,
      'isProcessing': isProcessing,
      'processProgress': processProgress,
    };
  }

  factory UploadedItem.fromJson(Map<String, dynamic> json) {
    return UploadedItem(
      file: File(''), // 从 JSON 恢复时文件引用会丢失
      name: json['name'] as String,
      type: json['type'] as String,
      thumbnail: json['thumbnail'] as String?,
      ocrText: json['ocrText'] as String?,
      isProcessing: json['isProcessing'] as bool? ?? false,
      processProgress: json['processProgress'] as double? ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadedItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ type.hashCode;
} 