import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/active_connection.dart';
import '../models/call_record.dart';

class DatabaseService {
  final SupabaseClient _client;

  DatabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Current authenticated user ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  // ─── Profile Operations ─────────────────────────────────

  /// Get the current user's profile
  Future<Profile?> getMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return getProfile(userId);
  }

  /// Get a profile by user ID
  Future<Profile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Get a profile by username
  Future<Profile?> getProfileByUsername(String username) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('username', username)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Get a profile by walkie ID
  Future<Profile?> getProfileByWalkieId(String walkieId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('walkie_id', walkieId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// Search profiles by username (partial match)
  Future<List<Profile>> searchProfiles(String query) async {
    final userId = _client.auth.currentUser?.id;
    final response = await _client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .neq('id', userId ?? '')
        .limit(20);

    return (response as List)
        .map((json) => Profile.fromJson(json))
        .toList();
  }

  /// Update the current user's profile
  Future<Profile> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null) updates['username'] = username;
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    final response = await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(response);
  }

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    return response == null;
  }

  // ─── Active Connections ─────────────────────────────────

  /// Get the current user's active connection (if any)
  Future<ActiveConnection?> getMyActiveConnection() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('active_connections')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ActiveConnection.fromJson(response);
  }

  /// Set the current user's active connection.
  /// Uses upsert — replaces any existing connection.
  Future<void> setActiveConnection({
    required String targetType,
    required String targetId,
    required String roomName,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('active_connections').upsert({
      'user_id': userId,
      'target_type': targetType,
      'target_id': targetId,
      'room_name': roomName,
      'connected_at': DateTime.now().toIso8601String(),
    });
  }

  /// Clear the current user's active connection.
  Future<void> clearActiveConnection() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('active_connections')
        .delete()
        .eq('user_id', userId);
  }

  /// Check if a specific contact is connected to me (direct).
  Future<bool> isContactConnectedToMe(String contactId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final roomName = ActiveConnection.directRoomName(userId, contactId);
    final response = await _client
        .from('active_connections')
        .select('user_id')
        .eq('user_id', contactId)
        .eq('room_name', roomName)
        .maybeSingle();

    return response != null;
  }

  /// Get all users connected to a specific group.
  Future<List<String>> getGroupConnectedUserIds(String groupId) async {
    final roomName = ActiveConnection.groupRoomName(groupId);
    final response = await _client
        .from('active_connections')
        .select('user_id')
        .eq('room_name', roomName);

    return (response as List)
        .map((row) => row['user_id'] as String)
        .toList();
  }

  /// Get active connections for a list of user IDs (for contact status).
  Future<List<ActiveConnection>> getActiveConnectionsForUsers(
      List<String> userIds) async {
    if (userIds.isEmpty) return [];

    final response = await _client
        .from('active_connections')
        .select()
        .inFilter('user_id', userIds);

    return (response as List)
        .map((json) => ActiveConnection.fromJson(json))
        .toList();
  }

  // ─── Call History ─────────────────────────────────────

  /// Log a call start
  Future<String> logCallStart({
    required String callType,
    String? peerId,
    String? groupId,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('call_history')
        .insert({
          'user_id': userId,
          'call_type': callType,
          'peer_id': peerId,
          'group_id': groupId,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Log a call end
  Future<void> logCallEnd(String callId, int durationSeconds) async {
    await _client.from('call_history').update({
      'ended_at': DateTime.now().toIso8601String(),
      'duration_seconds': durationSeconds,
    }).eq('id', callId);
  }

  /// Get recent call history for the current user.
  Future<List<CallRecord>> getCallHistory({int limit = 20}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Fetch call history with peer profile joined
    final response = await _client
        .from('call_history')
        .select('''
          *,
          peer_profile:profiles!call_history_peer_id_fkey(
            id, username, display_name, walkie_id, avatar_url, created_at, updated_at
          ),
          group:groups!call_history_group_id_fkey(
            name
          )
        ''')
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => CallRecord.fromJson(json))
        .toList();
  }
}
