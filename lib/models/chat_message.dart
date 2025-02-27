import 'dart:io';
import 'package:deepchat/models/uploaded_item.dart';

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final int sessionId;
  final DateTime timestamp;
  final String? thoughtProcess;
  final bool isThinking;
  final String model;
  final List<UploadedItem>? attachments;

  bool get isUser => role == 'user';

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.sessionId,
    DateTime? timestamp,
    this.thoughtProcess,
    this.isThinking = false,
    this.model = '',
    this.attachments,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'sessionId': sessionId,
      'thoughtProcess': thoughtProcess,
      'isThinking': isThinking,
      'timestamp': timestamp.toIso8601String(),
      'model': model,
      'attachments': attachments?.map((item) => {
        'name': item.name,
        'type': item.type,
        'ocrText': item.ocrText,
      }).toList(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      sessionId: json['sessionId'],
      thoughtProcess: json['thoughtProcess'],
      isThinking: json['isThinking'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      model: json['model'] ?? '',
      attachments: (json['attachments'] as List<dynamic>?)?.map((item) => 
        UploadedItem(
          file: File(''), // 注意：从JSON恢复时文件引用会丢失
          name: item['name'] as String,
          type: item['type'] as String,
          ocrText: item['ocrText'] as String?,
        )
      ).toList(),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    int? sessionId,
    DateTime? timestamp,
    String? thoughtProcess,
    bool? isThinking,
    String? model,
    List<UploadedItem>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      thoughtProcess: thoughtProcess ?? this.thoughtProcess,
      isThinking: isThinking ?? this.isThinking,
      model: model ?? this.model,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 