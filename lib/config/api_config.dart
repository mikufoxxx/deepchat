class ApiConfig {
  // 基础 URL 配置
  static const String deepseekUrl = 'https://api.deepseek.com';
  static const String siliconFlowUrl = 'https://api.siliconflow.cn/v1';
  
  // 模型配置
  static const Map<String, String> models = {
    'deepseek': 'deepseek-chat',
    'siliconflow': 'deepseek-ai/DeepSeek-V3',
    'siliconflow_r1': 'deepseek-ai/DeepSeek-R1',
  };
  
  // API 相关配置
  static const int timeout = 30;
  static const int maxRetries = 3;
  
  // 默认温度
  static const double defaultTemperature = 0.7;
  
  // 消息相关配置
  static const int maxMessageLength = 2000;
  static const int maxHistoryMessages = 50;
  
  // 系统提示语
  static const String defaultSystemPrompt = 
      'You are a helpful assistant.';
} 