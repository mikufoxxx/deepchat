import 'package:flutter/material.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return '发生未知错误';
  }

  static Future<T> handleFutureError<T>({
    required Future<T> Function() future,
    required BuildContext context,
    String? customErrorMessage,
  }) async {
    try {
      return await future();
    } catch (e) {
      final message = customErrorMessage ?? getErrorMessage(e);
      showError(context, message);
      rethrow;
    }
  }

  static void logError(String message, dynamic error, StackTrace? stackTrace) {
    // 这里可以添加错误日志记录逻辑
    print('Error: $message');
    print('Details: $error');
    if (stackTrace != null) {
      print('StackTrace: $stackTrace');
    }
  }
} 