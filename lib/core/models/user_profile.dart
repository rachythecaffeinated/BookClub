import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String timezone;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.timezone = 'UTC',
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'timezone': timezone,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    String? timezone,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, displayName, avatarUrl, timezone, createdAt];
}
