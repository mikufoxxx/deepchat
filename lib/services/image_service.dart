import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/api_config.dart';

class ImageService {
  final String apiKey;
  final String baseUrl;
  final _picker = ImagePicker();

  ImageService({
    required this.apiKey,
    required this.baseUrl,
  });

  Future<String?> pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return null;

      // 上传图片到 API
      final response = await http.post(
        Uri.parse('$baseUrl/vision/text'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
        body: {
          'image': await File(image.path).readAsBytes(),
        },
      );

      if (response.statusCode == 200) {
        return '图片已上传并处理';
      } else {
        throw Exception('上传失败: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
} 