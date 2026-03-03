import 'package:equatable/equatable.dart';

enum MessageType { text, system }

class ChatMessage extends Equatable {
  final String id;
  final String clubId;
  final String? userId;
  final MessageType messageType;
  final String content;
  final bool isSpoiler;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.clubId,
    this.userId,
    this.messageType = MessageType.text,
    required this.content,
    this.isSpoiler = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String?,
      messageType: json['message_type'] == 'system'
          ? MessageType.system
          : MessageType.text,
      content: json['content'] as String,
      isSpoiler: json['is_spoiler'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'user_id': userId,
      'message_type': messageType == MessageType.system ? 'system' : 'text',
      'content': content,
      'is_spoiler': isSpoiler,
    };
  }

  bool get isSystemMessage => messageType == MessageType.system;

  @override
  List<Object?> get props => [id, clubId, userId, content, createdAt];
}
