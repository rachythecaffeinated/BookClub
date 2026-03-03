import 'package:equatable/equatable.dart';

enum MessageType { text, system, prompt }

enum PromptStatus { pending, approved, dismissed }

class ChatMessage extends Equatable {
  final String id;
  final String clubId;
  final String? userId;
  final MessageType messageType;
  final String content;
  final bool isSpoiler;
  final DateTime createdAt;
  final String? parentId;
  final PromptStatus? promptStatus;
  final int replyCount;

  const ChatMessage({
    required this.id,
    required this.clubId,
    this.userId,
    this.messageType = MessageType.text,
    required this.content,
    this.isSpoiler = false,
    required this.createdAt,
    this.parentId,
    this.promptStatus,
    this.replyCount = 0,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String?,
      messageType: _parseMessageType(json['message_type'] as String?),
      content: json['content'] as String,
      isSpoiler: json['is_spoiler'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      parentId: json['parent_id'] as String?,
      promptStatus: _parsePromptStatus(json['prompt_status'] as String?),
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'user_id': userId,
      'message_type': messageType.name,
      'content': content,
      'is_spoiler': isSpoiler,
      if (parentId != null) 'parent_id': parentId,
      if (promptStatus != null) 'prompt_status': promptStatus!.name,
      'reply_count': replyCount,
    };
  }

  bool get isSystemMessage => messageType == MessageType.system;
  bool get isPrompt => messageType == MessageType.prompt;
  bool get isReply => parentId != null;
  bool get isPendingPrompt =>
      isPrompt && promptStatus == PromptStatus.pending;
  bool get isApprovedPrompt =>
      isPrompt && promptStatus == PromptStatus.approved;

  static MessageType _parseMessageType(String? value) {
    switch (value) {
      case 'system':
        return MessageType.system;
      case 'prompt':
        return MessageType.prompt;
      default:
        return MessageType.text;
    }
  }

  static PromptStatus? _parsePromptStatus(String? value) {
    switch (value) {
      case 'pending':
        return PromptStatus.pending;
      case 'approved':
        return PromptStatus.approved;
      case 'dismissed':
        return PromptStatus.dismissed;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props =>
      [id, clubId, userId, content, createdAt, parentId, promptStatus];
}
