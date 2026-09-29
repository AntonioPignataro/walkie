import 'profile.dart';

class Contact {
  final String id; // contacts table row id
  final Profile profile;
  final String? nickname;
  final DateTime createdAt;

  // Live status (populated by presence/connection queries)
  final bool isOnline;
  final bool isConnectedToMe;

  const Contact({
    required this.id,
    required this.profile,
    this.nickname,
    required this.createdAt,
    this.isOnline = false,
    this.isConnectedToMe = false,
  });

  /// Display name: nickname if set, otherwise profile name
  String get displayName => nickname ?? profile.name;

  factory Contact.fromJson(Map<String, dynamic> json, {
    bool isOnline = false,
    bool isConnectedToMe = false,
  }) {
    return Contact(
      id: json['id'] as String,
      profile: Profile.fromJson(json['profiles'] ?? json['contact_profile'] ?? json),
      nickname: json['nickname'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isOnline: isOnline,
      isConnectedToMe: isConnectedToMe,
    );
  }

  Contact copyWith({
    bool? isOnline,
    bool? isConnectedToMe,
    String? nickname,
  }) {
    return Contact(
      id: id,
      profile: profile,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt,
      isOnline: isOnline ?? this.isOnline,
      isConnectedToMe: isConnectedToMe ?? this.isConnectedToMe,
    );
  }
}
