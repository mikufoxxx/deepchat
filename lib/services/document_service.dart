import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentService {
  // 创建不同语言的识别器
  final _textRecognizerLatin = TextRecognizer(script: TextRecognitionScript.latin);
  final _textRecognizerChinese = TextRecognizer(script: TextRecognitionScript.chinese);
  final _textRecognizerJapanese = TextRecognizer(script: TextRecognitionScript.japanese);
  final _textRecognizerKorean = TextRecognizer(script: TextRecognitionScript.korean);
  final _textRecognizerDevanagari = TextRecognizer(script: TextRecognitionScript.devanagiri);

  // 自动检测语言并进行OCR
  Future<String?> _detectLanguageAndRecognize(InputImage inputImage) async {
    String? result;
    double maxScore = 0;
    Map<String, RecognitionResult> allResults = {};

    final recognizers = {
      '拉丁文': _textRecognizerLatin,
      '中文': _textRecognizerChinese,
      '日文': _textRecognizerJapanese,
      '韩文': _textRecognizerKorean,
      '天城文': _textRecognizerDevanagari,
    };

    // 定义语言特征正则表达式
    final languagePatterns = {
      '中文': RegExp(r'[\u4e00-\u9fa5]'),
      '日文': RegExp(r'[\u3040-\u309f\u30a0-\u30ff]'),
      '韩文': RegExp(r'[\uac00-\ud7af\u1100-\u11ff]'),
      '拉丁文': RegExp(r'[a-zA-Z]'),
      '天城文': RegExp(r'[\u0900-\u097f]'),
    };

    // 计算文本的语言特征得分
    double calculateLanguageScore(String text, String language) {
      if (text.isEmpty) return 0;
      
      final pattern = languagePatterns[language];
      if (pattern == null) return 0;
      
      final matches = pattern.allMatches(text);
      final matchCount = matches.length;
      
      // 计算该语言字符占比
      double languageRatio = matchCount / text.length;
      
      // 计算有效字符比例（排除空格和特殊字符）
      double validCharRatio = text.trim().length / text.length;
      
      // 综合评分：语言特征 * 0.7 + 有效字符比例 * 0.3
      return (languageRatio * 0.7 + validCharRatio * 0.3) * text.length;
    }

    for (var entry in recognizers.entries) {
      try {
        print('尝试使用${entry.key}识别器...');
        final recognizedText = await entry.value.processImage(inputImage);
        final text = recognizedText.text.trim();
        
        if (text.isNotEmpty) {
          final score = calculateLanguageScore(text, entry.key);
          
          allResults[entry.key] = RecognitionResult(
            text: text,
            score: score,
            length: text.length,
          );

          print('\n${entry.key}识别结果:');
          print('文本长度: ${text.length}');
          print('识别评分: $score');
          print('识别内容:\n$text\n');
          print('------------------------');

          if (score > maxScore) {
            maxScore = score;
            result = text;
          }
        }
      } catch (e) {
        print('${entry.key}识别失败: $e');
      }
    }

    // 打印最终选择的结果
    if (result != null) {
      final selectedLanguage = allResults.entries
          .firstWhere((e) => e.value.text == result)
          .key;
      print('\n最终选择: $selectedLanguage (评分: $maxScore)');
      print('最终识别结果:\n$result');
    } else {
      print('\n所有识别器均未返回有效结果');
    }
    print('------------------------\n');

    return result;
  }

  Future<String?> extractText(File file, String fileType) async {
    try {
      final extension = fileType.toLowerCase();
      
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        print('开始处理图片OCR...');
        final inputImage = InputImage.fromFile(file);
        print('图片加载完成，开始识别...');
        final recognizedText = await _detectLanguageAndRecognize(inputImage);
        print('OCR识别完成');
        return recognizedText;
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
    _textRecognizerLatin.close();
    _textRecognizerChinese.close();
    _textRecognizerJapanese.close();
    _textRecognizerKorean.close();
    _textRecognizerDevanagari.close();
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

// 添加一个结果类来存储识别信息
class RecognitionResult {
  final String text;
  final double score;
  final int length;

  RecognitionResult({
    required this.text,
    required this.score,
    required this.length,
  });
} 