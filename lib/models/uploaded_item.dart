import 'dart:io';

class UploadedItem {
  final File file;
  final String name;
  final String type; // 'image' 或 'file'
  final String? thumbnail; // 图片的缩略图路径

  UploadedItem({
    required this.file,
    required this.name,
    required this.type,
    this.thumbnail,
  });
} 