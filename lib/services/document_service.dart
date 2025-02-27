import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  Future<String?> extractText(File file, String fileType) async {
    try {
      final extension = fileType.toLowerCase();
      
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        print('开始处理图片OCR...');
        final inputImage = InputImage.fromFile(file);
        print('图片加载完成，开始识别...');
        final recognizedText = await _textRecognizer.processImage(inputImage);
        print('OCR识别完成');
        return recognizedText.text;
      } else if (extension == 'pdf') {
        print('开始处理PDF文件...');
        try {
          final bytes = await file.readAsBytes();
          final document = PdfDocument(inputBytes: bytes);
          final PdfTextExtractor extractor = PdfTextExtractor(document);
          String text = '';
          
          // 获取PDF页数
          final pageCount = document.pages.count;
          print('PDF页数: $pageCount');
          
          // 提取所有页面的文本
          for (int i = 0; i < pageCount; i++) {
            final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
            text += pageText + '\n';
            print('已处理第 ${i + 1} 页');
          }
          
          document.dispose();
          print('PDF处理完成，文本长度: ${text.length}');
          
          // 只打印前300个字符用于预览
          if (text.length > 300) {
            print('文本预览：\n${text.substring(0, 300)}...');
          } else {
            print('文本预览：\n$text');
          }
          
          return text;  // 返回完整文本
        } catch (e) {
          print('PDF处理失败: $e');
          rethrow;
        }
      } else {
        try {
          return await file.readAsString();
        } catch (e) {
          print('文本文件读取失败，尝试使用UTF-8解码: $e');
          final bytes = await file.readAsBytes();
          return String.fromCharCodes(bytes);
        }
      }
    } catch (e) {
      print('文档处理失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      rethrow;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }

  String getFileDescription(String fileName, String type) {
    final extension = type.toLowerCase();
    if (['js', 'ts', 'py', 'java', 'cpp', 'c', 'cs', 'html', 'css', 'dart', 'sql', 'sh', 'bat'].contains(extension)) {
      return '代码文件';
    } else if (['doc', 'docx', 'pdf', 'rtf'].contains(extension)) {
      return '文档';
    } else if (['txt', 'md'].contains(extension)) {
      return '文本文件';
    } else if (['json', 'yaml', 'xml'].contains(extension)) {
      return '配置文件';
    } else {
      return '文件';
    }
  }
} 