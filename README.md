# DeepChat

一个基于 DeepSeek 的 Flutter 聊天应用。

## 功能特点

- 💬 支持多会话管理
- 🌓 深色/浅色主题切换
- 🎨 自定义主题色
- 📱 响应式设计
- ⭐ 消息收藏功能
- 🔄 流式响应
- 📋 代码块复制
- 🔗 链接预览
- 📝 Markdown 渲染

## 截图


## 开始使用

### 前置要求

- Flutter SDK (>=3.6.0)
- Dart SDK (>=3.0.0)
- DeepSeek API Key

### 安装

1. 克隆仓库
```bash
git clone https://github.com/mikufoxxx/deepchat.git
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

### 配置

在首次使用时，你需要在设置页面配置 DeepSeek API Key。

## 技术栈

- Flutter
- Provider (状态管理)
- SharedPreferences (本地存储)
- flutter_markdown (Markdown 渲染)
- url_launcher (链接处理)

## 项目结构

```
lib/
├── config/         # 配置文件
├── models/         # 数据模型
├── providers/      # 状态管理
├── screens/        # 页面
├── services/       # 服务
└── widgets/        # 组件
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 作者

狐狸ox

## 致谢

- [DeepSeek](https://deepseek.com) - AI 模型支持
- [Flutter](https://flutter.dev) - UI 框架
