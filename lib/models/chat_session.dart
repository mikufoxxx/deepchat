import 'chat_message.dart';

class ChatSession {
  final int id;
  final String title;
  final List<ChatMessage> messages;
  
  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });

  ChatSession copyWith({
    int? id,
    String? title,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as int,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList(),
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