class AppConstants {
  // 应用相关
  static const String appName = 'AI Chat';
  static const String appVersion = '1.0.0';
  
  // 存储相关
  static const String prefsKeyApiKey = 'api_key';
  static const String prefsKeyMessages = 'messages';
  
  // UI相关
  static const double maxBubbleWidth = 0.7; // 气泡最大宽度（屏幕比例）
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // 错误消息
  static const String errorNoApiKey = '请先设置 API Key';
  static const String errorNetworkFailed = '网络连接失败';
  static const String errorApiRequest = 'API 请求失败';
} 