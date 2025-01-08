class ApiConfig {
  // 根据官方文档更新 base_url
  static const String baseUrl = 'https://api.deepseek.com';
  
  // API 相关配置
  static const int timeout = 30;
  static const int maxRetries = 3;
  
  // 模型配置
  static const String modelName = 'deepseek-chat';  // DeepSeek-V3
  static const double defaultTemperature = 0.7;
  
  // 消息相关配置
  static const int maxMessageLength = 2000;
  static const int maxHistoryMessages = 50;
  
  // 系统提示语
  static const String defaultSystemPrompt = 
      'You are a helpful assistant.';
} 