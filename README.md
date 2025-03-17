# DeepChat 🤖✨

[![Flutter Version](https://img.shields.io/badge/Flutter-3.16.9-blue)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/mikufoxxx/deepchat/pulls)

下一代智能聊天解决方案，融合多模态交互与深度文档分析能力

<p align="center">
  <img src="https://github.com/mikufoxxx/deepchat/blob/dev/img/chatpage.png" width="250" />
  <img src="https://github.com/mikufoxxx/deepchat/blob/dev/img/ocr_demo.gif" width="250" />
  <img src="https://github.com/mikufoxxx/deepchat/blob/dev/img/file_analysis.gif" width="250" />
</p>

## 🌟 核心功能

### 🧠 智能对话
| 功能                | 描述                          |
|---------------------|-----------------------------|
| 多平台API支持        | DeepSeek & Siliconflow 双引擎 |
| 流式响应            | 实时字符流输出，媲美ChatGPT体验 |
| 思考过程可视化       | 查看AI的完整推理链条           |
| 对话记忆            | 长期上下文保持（支持10万token） |

### 📁 多模态交互
```dart
// 文件处理核心逻辑
Future<void> handleFileUpload() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'docx', 'txt', 'png', 'jpg'],
  );
  
  if (result != null) {
    final text = await OCRService.extractText(result.files.first);
    context.read<ChatProvider>().addDocumentContext(text);
  }
}
```
- 支持格式：`PDF` | `Word` | `TXT` | `PNG/JPG`
- OCR识别精度：98.7% (基于Google ML Kit)
- 最大文件尺寸：20MB

### 🛠 开发者友好
```bash
# 运行调试命令
flutter run --dart-define=API_KEY=your_key_here

# 构建发布版
flutter build apk --release
```
- 热重载支持
- 完善的日志系统
- 模块化架构设计

## 🚀 快速开始

### 系统要求
- Flutter 3.16.9+
- Dart 3.0+
- Android Studio / Xcode

### 安装步骤
1. 克隆仓库
```bash
git clone https://github.com/mikufoxxx/deepchat.git
cd deepchat
```

2. 安装依赖
```bash
flutter pub get
```

3. 配置环境
```bash
cp .env.example .env
# 在.env文件中填写API密钥
```

4. 运行应用
```bash
flutter run
```

## 🧩 技术架构

```mermaid
graph TD
    A[用户界面] --> B[业务逻辑]
    B --> C{数据层}
    C --> D[本地存储]
    C --> E[网络请求]
    C --> F[文件系统]
    D --> G[SharedPreferences]
    E --> H[DeepSeek API]
    E --> I[Siliconflow API]
    F --> J[文件解析器]
    J --> K[PDF解析]
    J --> L[OCR引擎]
```

## 🔍 功能演示

### 文档分析流程
1. 上传PDF/Word文件
2. 自动提取文本内容
3. 智能生成摘要
4. 支持追问文档细节

![文档分析流程](https://github.com/mikufoxxx/deepchat/blob/dev/img/doc_analysis_flow.gif)

## 🤝 参与贡献

我们欢迎各种形式的贡献！请阅读[贡献指南](CONTRIBUTING.md)后：
1. Fork项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交修改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送分支 (`git push origin feature/AmazingFeature`)
5. 发起Pull Request

## 📜 开源协议

本项目采用 [MIT License](LICENSE)

---

**由狐狸ox打造** • [问题反馈](https://github.com/mikufoxxx/deepchat/issues) • [赞助支持](https://github.com/sponsors/mikufoxxx)

<p align="center">
  <em>让对话更智能，让知识触手可及</em>
</p>
