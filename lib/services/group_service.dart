import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/profile.dart';

class GroupService {
  final SupabaseClient _client;

  GroupService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// Get all groups the current user belongs to
  Future<List<Group>> getMyGroups() async {
    // First get the group IDs I belong to
    final memberRows = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', _userId);

    if ((memberRows as List).isEmpty) return [];

    final groupIds = memberRows.map((r) => r['group_id'] as String).toList();

    // Fetch group details
    final groupRows = await _client
        .from('groups')
        .select()
        .inFilter('id', groupIds)
        .order('created_at', ascending: false);

    // Fetch members for all groups
    final allMembers = await _client
        .from('group_members')
        .select('group_id, role, joined_at, user_id, profiles:user_id(*)')
        .inFilter('group_id', groupIds);

    // Build member lists per group
    final membersByGroup = <String, List<GroupMember>>{};
    for (final m in (allMembers as List)) {
      final groupId = m['group_id'] as String;
      membersByGroup.putIfAbsent(groupId, () => []);
      membersByGroup[groupId]!.add(GroupMember(
        profile: Profile.fromJson(m['profiles'] as Map<String, dynamic>),
        role: m['role'] as String? ?? 'member',
        joinedAt: DateTime.parse(m['joined_at'] as String),
      ));
    }

    return (groupRows as List).map((json) {
      final groupId = json['id'] as String;
      return Group.fromJson(json, members: membersByGroup[groupId] ?? []);
    }).toList();
  }

  /// Create a new group and add the creator as admin
  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    // Create the group
    final groupRow = await _client
        .from('groups')
        .insert({
          'name': name,
          'description': description,
          'created_by': _userId,
        })
        .select()
        .single();

    final groupId = groupRow['id'] as String;

    // Add creator as admin
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': _userId,
      'role': 'admin',
    });

    // Fetch the creator's profile for the member list
    final myProfile = await _client
        .from('profiles')
        .select()
        .eq('id', _userId)
        .single();

    return Group.fromJson(groupRow, members: [
      GroupMember(
        profile: Profile.fromJson(myProfile),
        role: 'admin',
        joinedAt: DateTime.now(),
      ),
    ]);
  }

  /// Add a member to a group
  Future<void> addMember(String groupId, String userId) async {
    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', _userId);
  }

  /// Get members of a group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await _client
        .from('group_members')
        .select('group_id, role, joined_at, user_id, profiles:user_id(*)')
        .eq('group_id', groupId);

    return (response as List).map((m) => GroupMember(
      profile: Profile.fromJson(m['profiles'] as Map<String, dynamic>),
      role: m['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(m['joined_at'] as String),
    )).toList();
  }
}
