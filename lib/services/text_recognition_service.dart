import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

Future<String> extractTextFromImage(String imagePath) async {
  try {
    // 支持中英文识别
    final String text = await FlutterTesseractOcr.extractText(
      imagePath,
      language: 'chi_sim+eng', // 简体中文+英文
      args: {
        "preserve_interword_spaces": "1",
      },
    );
    return text;
  } catch (e) {
    print('Text recognition error: $e');
    return '';
  }
} 