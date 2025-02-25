import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:mime/mime.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentService {
  final _textRecognizer = TextRecognizer();

  Future<String?> extractText(File file, String type) async {
    try {
      print('开始处理文件: ${file.path}');
      print('文件类型: $type');
      final mimeType = lookupMimeType(file.path);
      print('MIME类型: $mimeType');
      
      switch (type.toLowerCase()) {
        case 'pdf':
          print('开始处理PDF文件...');
          final bytes = await file.readAsBytes();
          print('PDF文件读取完成，大小: ${bytes.length} 字节');
          PdfDocument document = PdfDocument(inputBytes: bytes);
          print('PDF文档加载完成，开始提取文本...');
          PdfTextExtractor extractor = PdfTextExtractor(document);
          String text = extractor.extractText();
          print('PDF文本提取完成，文本长度: ${text.length}');
          document.dispose();
          return text;
          
        case 'doc':
        case 'docx':
          print('不支持的Word文档格式');
          return '抱歉，暂不支持直接读取Word文档内容，建议将文档另存为PDF或文本格式后上传。';
          
        case 'png':
        case 'jpg':
        case 'jpeg':
          print('开始处理图片OCR...');
          final inputImage = InputImage.fromFile(file);
          print('图片加载完成，开始识别...');
          final recognizedText = await _textRecognizer.processImage(inputImage);
          print('图片OCR完成，识别文本长度: ${recognizedText.text.length}');
          return recognizedText.text;
          
        case 'txt':
        case 'md':
        case 'json':
        case 'yaml':
        case 'xml':
        case 'ini':
        case 'log':
        case 'csv':
          print('开始读取文本文件...');
          final content = await file.readAsString();
          print('文本文件读取完成，长度: ${content.length}');
          return content;
          
        // 代码文件处理
        case 'js':
        case 'ts':
        case 'py':
        case 'java':
        case 'cpp':
        case 'c':
        case 'cs':
        case 'html':
        case 'css':
        case 'dart':
        case 'sql':
        case 'sh':
        case 'bat':
          print('开始读取代码文件...');
          final content = await file.readAsString();
          print('代码文件读取完成，长度: ${content.length}');
          return '```$type\n$content\n```';
          
        default:
          if (mimeType?.startsWith('text/') ?? false) {
            print('开始读取未知文本类型文件...');
            final content = await file.readAsString();
            print('未知类型文件读取完成，长度: ${content.length}');
            return content;
          }
          print('不支持的文件类型');
          return '不支持的文件类型，请转换为PDF或文本格式后重试。';
      }
    } catch (e) {
      print('文档处理失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      return '文件处理失败：$e';
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