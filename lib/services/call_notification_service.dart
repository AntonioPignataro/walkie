import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

/// Payload for an incoming connection request.
class IncomingConnectionRequest {
  final Profile fromProfile;
  final String roomName;
  final String type; // 'direct' or 'group'
  final String? groupName;

  const IncomingConnectionRequest({
    required this.fromProfile,
    required this.roomName,
    required this.type,
    this.groupName,
  });
}

/// Uses Supabase Realtime broadcast to send/receive connection notifications.
///
/// Each user listens on channel `call:{myUserId}`.
/// When someone wants to connect, they broadcast on `call:{targetUserId}`.
class CallNotificationService {
  final SupabaseClient _client;
  RealtimeChannel? _myChannel;
  final _incomingController =
      StreamController<IncomingConnectionRequest>.broadcast();

  Stream<IncomingConnectionRequest> get onIncomingConnection =>
      _incomingController.stream;

  CallNotificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Start listening for incoming connection requests.
  void startListening() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Clean up any existing channel
    if (_myChannel != null) {
      _client.removeChannel(_myChannel!);
      _myChannel = null;
    }

    final channelName = 'call:$userId';
    debugPrint('[CallNotification] Subscribing to $channelName');

    _myChannel = _client.channel(
      channelName,
      opts: const RealtimeChannelConfig(
        ack: true, // Require server acknowledgement for reliability
      ),
    );

    _myChannel!
        .onBroadcast(
          event: 'connect_request',
          callback: (payload) {
            debugPrint('[CallNotification] Received: $payload');
            _handleIncomingRequest(payload);
          },
        )
        .subscribe((status, [error]) {
      debugPrint('[CallNotification] Channel status: $status (error: $error)');
    });
  }

  void _handleIncomingRequest(Map<String, dynamic> payload) {
    try {
      final fromProfile = Profile.fromJson(
        payload['from_profile'] as Map<String, dynamic>,
      );
      final roomName = payload['room_name'] as String;
      final type = payload['type'] as String? ?? 'direct';
      final groupName = payload['group_name'] as String?;

      _incomingController.add(IncomingConnectionRequest(
        fromProfile: fromProfile,
        roomName: roomName,
        type: type,
        groupName: groupName,
      ));
    } catch (e) {
      debugPrint('[CallNotification] Error parsing request: $e');
    }
  }

  /// Send a connection request to a target user.
  Future<void> sendConnectionRequest({
    required String targetUserId,
    required Profile myProfile,
    required String roomName,
    String type = 'direct',
    String? groupName,
  }) async {
    final channelName = 'call:$targetUserId';
    debugPrint('[CallNotification] Sending request on $channelName');

    final channel = _client.channel(
      channelName,
      opts: const RealtimeChannelConfig(
        ack: true,
      ),
    );

    // Wait for the subscription to be fully established
    final completer = Completer<void>();
    channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (!completer.isCompleted) completer.complete();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        if (!completer.isCompleted) {
          completer.completeError('Channel subscription failed: $status');
        }
      }
    });

    // Wait for subscription with a timeout
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('[CallNotification] Subscribe timed out, sending anyway');
      },
    );

    // Send the broadcast message
    await channel.sendBroadcastMessage(
      event: 'connect_request',
      payload: {
        'from_profile': myProfile.toJson(),
        'room_name': roomName,
        'type': type,
        if (groupName != null) 'group_name': groupName,
      },
    );

    debugPrint('[CallNotification] Broadcast sent on $channelName');

    // Small delay to ensure the message is delivered before we unsubscribe
    await Future.delayed(const Duration(milliseconds: 200));

    // Unsubscribe after sending — we only needed the channel to send
    await _client.removeChannel(channel);
  }

  /// Stop listening and clean up.
  void stopListening() {
    if (_myChannel != null) {
      _client.removeChannel(_myChannel!);
      _myChannel = null;
    }
    debugPrint('[CallNotification] Stopped listening');
  }

  void dispose() {
    stopListening();
    _incomingController.close();
  }
}
