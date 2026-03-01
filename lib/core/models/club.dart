import 'package:equatable/equatable.dart';

class Club extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? currentBookId;
  final String? inviteCode;
  final String? inviteLinkToken;
  final DateTime? inviteExpiresAt;
  final String createdBy;
  final DateTime createdAt;

  const Club({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.currentBookId,
    this.inviteCode,
    this.inviteLinkToken,
    this.inviteExpiresAt,
    required this.createdBy,
    required this.createdAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      currentBookId: json['current_book_id'] as String?,
      inviteCode: json['invite_code'] as String?,
      inviteLinkToken: json['invite_link_token'] as String?,
      inviteExpiresAt: json['invite_expires_at'] != null
          ? DateTime.parse(json['invite_expires_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'current_book_id': currentBookId,
      'invite_code': inviteCode,
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [id, name, currentBookId, createdBy];
}
