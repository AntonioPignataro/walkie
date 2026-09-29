import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks online/offline status using Supabase Realtime Presence.
///
/// Each user joins a shared presence channel on app open or when
/// they have an active connection. They leave when the app closes
/// AND they have no active connection.
///
/// The channel broadcasts user IDs of online users.
class PresenceService {
  final SupabaseClient _client;
  RealtimeChannel? _presenceChannel;

  /// Set of currently online user IDs.
  final Set<String> _onlineUserIds = {};

  /// Stream that emits whenever the online set changes.
  final _onlineUsersController = StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get onOnlineUsersChanged =>
      _onlineUsersController.stream;

  Set<String> get onlineUserIds => Set.unmodifiable(_onlineUserIds);

  PresenceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Join the global presence channel. Call on app start after auth.
  void join(String userId) {

    _presenceChannel = _client.channel(
      'presence:online',
      opts: const RealtimeChannelConfig(self: true),
    );

    _presenceChannel!
        .onPresenceSync((payload) {
          _syncPresence();
        })
        .onPresenceJoin((payload) {
          debugPrint('[Presence] Join: ${payload.newPresences}');
          _syncPresence();
        })
        .onPresenceLeave((payload) {
          debugPrint('[Presence] Leave: ${payload.leftPresences}');
          _syncPresence();
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Track this user as online
            await _presenceChannel!.track({
              'user_id': userId,
              'online_at': DateTime.now().toIso8601String(),
            });
            debugPrint('[Presence] Joined as $userId');
          }
        });
  }

  /// Sync the online user set from presence state.
  void _syncPresence() {
    if (_presenceChannel == null) return;

    final presenceState = _presenceChannel!.presenceState();
    _onlineUserIds.clear();

    for (final state in presenceState) {
      for (final presence in state.presences) {
        final userId = presence.payload['user_id'] as String?;
        if (userId != null) {
          _onlineUserIds.add(userId);
        }
      }
    }

    debugPrint('[Presence] Online users: ${_onlineUserIds.length}');
    _onlineUsersController.add(Set.unmodifiable(_onlineUserIds));
  }

  /// Check if a specific user is online.
  bool isUserOnline(String userId) => _onlineUserIds.contains(userId);

  /// Leave the presence channel (call on sign out).
  Future<void> leave() async {
    if (_presenceChannel != null) {
      await _presenceChannel!.untrack();
      await _client.removeChannel(_presenceChannel!);
      _presenceChannel = null;
    }
    _onlineUserIds.clear();
    _onlineUsersController.add(Set.unmodifiable(_onlineUserIds));
    debugPrint('[Presence] Left');
  }

  void dispose() {
    leave();
    _onlineUsersController.close();
  }
}
