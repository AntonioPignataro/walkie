import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact.dart';
import '../models/contact_request.dart';
import '../models/profile.dart';

class ContactService {
  final SupabaseClient _client;

  ContactService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  // ─── Contacts ──────────────────────────────────────────

  /// Get all contacts for the current user (with profiles joined)
  Future<List<Contact>> getContacts() async {
    final response = await _client
        .from('contacts')
        .select('id, nickname, created_at, contact_id, profiles:contact_id(*)');

    return (response as List).map((json) {
      // Supabase returns the joined profile under the alias 'profiles'
      return Contact(
        id: json['id'] as String,
        profile: Profile.fromJson(json['profiles'] as Map<String, dynamic>),
        nickname: json['nickname'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    }).toList();
  }

  /// Remove a contact (removes both directions)
  /// Uses a SECURITY DEFINER function so both rows can be deleted.
  Future<void> removeContact(String contactUserId) async {
    await _client.rpc('remove_contact', params: {
      'contact_user_id': contactUserId,
    });
  }

  // ─── Contact Requests ──────────────────────────────────

  /// Send a contact request to another user
  Future<void> sendRequest(String toUserId) async {
    await _client.from('contact_requests').insert({
      'from_user_id': _userId,
      'to_user_id': toUserId,
      'status': 'pending',
    });
  }

  /// Get pending requests received by the current user
  Future<List<ContactRequest>> getIncomingRequests() async {
    final response = await _client
        .from('contact_requests')
        .select(
          'id, status, created_at, from_user_id, to_user_id, '
          'from_profile:from_user_id(*),'
          'to_profile:to_user_id(*)',
        )
        .eq('to_user_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ContactRequest.fromJson(json))
        .toList();
  }

  /// Get pending requests sent by the current user
  Future<List<ContactRequest>> getSentRequests() async {
    final response = await _client
        .from('contact_requests')
        .select(
          'id, status, created_at, from_user_id, to_user_id, '
          'from_profile:from_user_id(*),'
          'to_profile:to_user_id(*)',
        )
        .eq('from_user_id', _userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ContactRequest.fromJson(json))
        .toList();
  }

  /// Accept a contact request — creates bidirectional contact rows
  /// Uses a SECURITY DEFINER function so both rows can be inserted.
  Future<void> acceptRequest(String requestId, String fromUserId) async {
    await _client.rpc('accept_contact_request', params: {
      'request_id': requestId,
    });
  }

  /// Reject a contact request
  Future<void> rejectRequest(String requestId) async {
    await _client
        .from('contact_requests')
        .update({'status': 'rejected'})
        .eq('id', requestId);
  }

  // ─── Search ────────────────────────────────────────────

  /// Search users by username or walkie ID
  Future<List<Profile>> searchUsers(String query) async {
    // Try by walkie ID first (exact match without dash)
    final cleanQuery = query.replaceAll('-', '').trim();

    if (cleanQuery.length == 6 && RegExp(r'^\d{6}$').hasMatch(cleanQuery)) {
      final byWalkieId = await _client
          .from('profiles')
          .select()
          .eq('walkie_id', cleanQuery)
          .neq('id', _userId);

      if ((byWalkieId as List).isNotEmpty) {
        return byWalkieId.map((j) => Profile.fromJson(j)).toList();
      }
    }

    // Search by username (partial match)
    final response = await _client
        .from('profiles')
        .select()
        .ilike('username', '%${query.trim()}%')
        .neq('id', _userId)
        .limit(20);

    return (response as List)
        .map((json) => Profile.fromJson(json))
        .toList();
  }
}
