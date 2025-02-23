class ChatMessage {
  final String id;
  final String role;
  final String content;
  final int sessionId;
  final String? thoughtProcess;
  final bool isThinking;
  final DateTime timestamp;

  bool get isUser => role == 'user';

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.sessionId,
    this.thoughtProcess,
    this.isThinking = false,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'sessionId': sessionId,
      'thoughtProcess': thoughtProcess,
      'isThinking': isThinking,
      'timestamp': timestamp.toIso8601String(),
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
    );
  }

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    int? sessionId,
    String? thoughtProcess,
    bool? isThinking,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      sessionId: sessionId ?? this.sessionId,
      thoughtProcess: thoughtProcess ?? this.thoughtProcess,
      isThinking: isThinking ?? this.isThinking,
      timestamp: timestamp ?? this.timestamp,
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