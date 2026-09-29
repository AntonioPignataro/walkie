import 'profile.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final int maxMembers;
  final DateTime createdAt;
  final List<GroupMember> members;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.maxMembers = 20,
    required this.createdAt,
    this.members = const [],
  });

  /// Number of members currently connected to this group's call
  int get connectedCount => members.where((m) => m.isConnected).length;

  /// Whether I'm the admin of this group
  bool isAdmin(String userId) =>
      members.any((m) => m.profile.id == userId && m.role == 'admin');

  factory Group.fromJson(Map<String, dynamic> json, {
    List<GroupMember>? members,
  }) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      maxMembers: json['max_members'] as int? ?? 20,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: members ?? [],
    );
  }

  Group copyWith({
    String? name,
    String? description,
    List<GroupMember>? members,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy,
      maxMembers: maxMembers,
      createdAt: createdAt,
      members: members ?? this.members,
    );
  }
}

class GroupMember {
  final Profile profile;
  final String role; // admin, member
  final DateTime joinedAt;
  final bool isConnected; // is this member in the group call right now?

  const GroupMember({
    required this.profile,
    required this.role,
    required this.joinedAt,
    this.isConnected = false,
  });

  bool get isAdmin => role == 'admin';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      profile: Profile.fromJson(json['profiles'] ?? json['profile'] ?? json),
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  GroupMember copyWith({bool? isConnected}) {
    return GroupMember(
      profile: profile,
      role: role,
      joinedAt: joinedAt,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
