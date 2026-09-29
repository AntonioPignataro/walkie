class Profile {
  final String id;
  final String username;
  final String? displayName;
  final String walkieId;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.username,
    this.displayName,
    required this.walkieId,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// User-friendly display: displayName if set, otherwise username
  String get name => displayName ?? username;

  /// Format walkie ID for display (e.g., "123-456")
  String get displayWalkieId {
    if (walkieId.length == 6) {
      return '${walkieId.substring(0, 3)}-${walkieId.substring(3)}';
    }
    return walkieId;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      walkieId: json['walkie_id'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'walkie_id': walkieId,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      walkieId: walkieId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
