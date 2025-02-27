import 'chat_message.dart';
import 'uploaded_item.dart';

class ChatSession {
  final int id;
  final String title;
  final List<ChatMessage> messages;
  final List<UploadedItem> documentContext;
  
  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    this.documentContext = const [],
  });

  ChatSession copyWith({
    int? id,
    String? title,
    List<ChatMessage>? messages,
    List<UploadedItem>? documentContext,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      documentContext: documentContext ?? this.documentContext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'documentContext': documentContext.map((item) => item.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as int,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList(),
      documentContext: (json['documentContext'] as List?)
          ?.map((item) => UploadedItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  String? get lastMessage {
    if (messages.isEmpty) return null;
    final lastMsg = messages.last;
    return lastMsg.content.length > 50 
        ? '${lastMsg.content.substring(0, 50)}...'
        : lastMsg.content;
  }
} 