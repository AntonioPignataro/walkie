import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' show ConnectionState;
import '../models/peer_connection_state.dart';
import '../models/active_connection.dart';
import '../models/profile.dart';
import 'livekit_service.dart';
import 'background_service.dart';
import 'call_notification_service.dart';
import 'database_service.dart';

/// Orchestrates LiveKit connections, background service, DB state, and notifications.
///
/// Flow:
/// 1. User taps Connect → [connectToContact] or [connectToGroup]
/// 2. If already connected → auto-disconnect first
/// 3. Get LiveKit token via Edge Function → join room
/// 4. Insert active_connections row in DB
/// 5. Start foreground service (Android) / background audio (iOS)
/// 6. Send notification to target via Supabase Realtime broadcast
///
/// Disconnect:
/// 1. Leave LiveKit room
/// 2. Delete active_connections row
/// 3. Stop foreground service
/// 4. Log call history
class ConnectionService {
  final LiveKitService _livekit;
  final BackgroundService _background;
  final CallNotificationService _callNotification;
  final DatabaseService _database;

  final _stateController = StreamController<PeerConnectionState>.broadcast();
  Stream<PeerConnectionState> get onStateChanged => _stateController.stream;

  PeerConnectionState _state = const PeerConnectionState();
  PeerConnectionState get state => _state;

  Profile? _myProfile;
  String? _currentCallHistoryId;
  DateTime? _callStartTime;
  Timer? _reconnectTimer;

  /// Max time to wait for reconnection before giving up.
  static const _reconnectTimeout = Duration(seconds: 30);

  StreamSubscription? _livekitConnectionSub;
  StreamSubscription? _livekitParticipantsSub;
  StreamSubscription? _livekitSpeakersSub;
  StreamSubscription? _incomingConnectionSub;

  ConnectionService({
    LiveKitService? livekitService,
    BackgroundService? backgroundService,
    CallNotificationService? callNotificationService,
    DatabaseService? databaseService,
  })  : _livekit = livekitService ?? LiveKitService(),
        _background = backgroundService ?? BackgroundService(),
        _callNotification = callNotificationService ?? CallNotificationService(),
        _database = databaseService ?? DatabaseService();

  LiveKitService get livekit => _livekit;
  BackgroundService get background => _background;
  CallNotificationService get callNotification => _callNotification;

  /// Initialize the connection service.
  Future<void> initialize(Profile myProfile) async {
    _myProfile = myProfile;

    // Initialize background service
    await _background.init();

    // Start listening for incoming connection requests
    _callNotification.startListening();

    // Listen to LiveKit connection state changes
    _livekitConnectionSub =
        _livekit.onConnectionStateChanged.listen(_handleLiveKitState);

    // Listen to participant changes
    _livekitParticipantsSub =
        _livekit.onParticipantsChanged.listen((_) => _updateParticipants());

    // Listen to active speakers
    _livekitSpeakersSub =
        _livekit.onActiveSpeakersChanged.listen((_) => _updateParticipants());

    // Check for stale active_connections from a previous session
    await _cleanupStaleConnection();

    debugPrint('[ConnectionService] Initialized');
  }

  /// Clean up any stale active_connections row from a previous crash/kill.
  Future<void> _cleanupStaleConnection() async {
    final existing = await _database.getMyActiveConnection();
    if (existing != null) {
      debugPrint('[ConnectionService] Cleaning up stale connection');
      await _database.clearActiveConnection();
    }
  }

  // ─── Connect ─────────────────────────────────────────

  /// Connect to a contact (1-on-1 direct call).
  Future<void> connectToContact({
    required String contactId,
    required String contactName,
  }) async {
    if (_myProfile == null) return;

    // Auto-disconnect from current connection if any
    if (!_state.isDisconnected) {
      await disconnect(autoSwitch: true);
    }

    final roomName =
        ActiveConnection.directRoomName(_myProfile!.id, contactId);

    _updateState(PeerConnectionState(
      status: PeerConnectionStatus.connecting,
      targetId: contactId,
      targetName: contactName,
      targetType: 'direct',
      roomName: roomName,
    ));

    try {
      // Join LiveKit room
      await _livekit.connect(roomName);

      // Ensure speaker output
      await _livekit.setSpeakerOn(true);

      // Insert active_connections row
      await _database.setActiveConnection(
        targetType: 'direct',
        targetId: contactId,
        roomName: roomName,
      );

      // Start background service
      await _background.startService(contactName);

      // Log call start
      _callStartTime = DateTime.now();
      _currentCallHistoryId = await _database.logCallStart(
        callType: 'direct',
        peerId: contactId,
      );

      // Send connection notification to target
      await _callNotification.sendConnectionRequest(
        targetUserId: contactId,
        myProfile: _myProfile!,
        roomName: roomName,
        type: 'direct',
      );

      _updateState(PeerConnectionState(
        status: PeerConnectionStatus.connected,
        targetId: contactId,
        targetName: contactName,
        targetType: 'direct',
        roomName: roomName,
        participants: _buildParticipantList(),
      ));

      debugPrint('[ConnectionService] Connected to contact: $contactName');
    } catch (e) {
      debugPrint('[ConnectionService] Connection failed: $e');
      _updateState(PeerConnectionState(
        status: PeerConnectionStatus.error,
        targetId: contactId,
        targetName: contactName,
        targetType: 'direct',
        errorMessage: 'Connection failed. Please try again.',
      ));
      // Clean up on failure
      await _livekit.disconnect();
      await _database.clearActiveConnection();
    }
  }

  /// Connect to a group call.
  Future<void> connectToGroup({
    required String groupId,
    required String groupName,
  }) async {
    if (_myProfile == null) return;

    // Auto-disconnect from current connection if any
    if (!_state.isDisconnected) {
      await disconnect(autoSwitch: true);
    }

    final roomName = ActiveConnection.groupRoomName(groupId);

    _updateState(PeerConnectionState(
      status: PeerConnectionStatus.connecting,
      targetId: groupId,
      targetName: groupName,
      targetType: 'group',
      roomName: roomName,
    ));

    try {
      // Join LiveKit room
      await _livekit.connect(roomName);

      // Ensure speaker output
      await _livekit.setSpeakerOn(true);

      // Insert active_connections row
      await _database.setActiveConnection(
        targetType: 'group',
        targetId: groupId,
        roomName: roomName,
      );

      // Start background service
      await _background.startService(groupName);

      // Log call start
      _callStartTime = DateTime.now();
      _currentCallHistoryId = await _database.logCallStart(
        callType: 'group',
        groupId: groupId,
      );

      _updateState(PeerConnectionState(
        status: PeerConnectionStatus.connected,
        targetId: groupId,
        targetName: groupName,
        targetType: 'group',
        roomName: roomName,
        participants: _buildParticipantList(),
      ));

      debugPrint('[ConnectionService] Connected to group: $groupName');
    } catch (e) {
      debugPrint('[ConnectionService] Group connection failed: $e');
      _updateState(PeerConnectionState(
        status: PeerConnectionStatus.error,
        targetId: groupId,
        targetName: groupName,
        targetType: 'group',
        errorMessage: 'Connection failed. Please try again.',
      ));
      await _livekit.disconnect();
      await _database.clearActiveConnection();
    }
  }

  /// Accept an incoming connection request.
  Future<void> acceptIncoming(IncomingConnectionRequest request) async {
    if (_myProfile == null) return;

    // Auto-disconnect from current connection if any
    if (!_state.isDisconnected) {
      await disconnect(autoSwitch: true);
    }

    final targetName = request.type == 'group'
        ? (request.groupName ?? 'Group')
        : request.fromProfile.name;
    final targetId = request.type == 'group'
        ? request.roomName.replaceFirst('group_', '')
        : request.fromProfile.id;

    _updateState(PeerConnectionState(
      status: PeerConnectionStatus.connecting,
      targetId: targetId,
      targetName: targetName,
      targetType: request.type,
      roomName: request.roomName,
    ));

    try {
      await _livekit.connect(request.roomName);
      await _livekit.setSpeakerOn(true);

      await _database.setActiveConnection(
        targetType: request.type,
        targetId: targetId,
        roomName: request.roomName,
      );

      await _background.startService(targetName);

      _callStartTime = DateTime.now();
      _currentCallHistoryId = await _database.logCallStart(
        callType: request.type,
        peerId: request.type == 'direct' ? request.fromProfile.id : null,
        groupId: request.type == 'group' ? targetId : null,
      );

      _updateState(PeerConnectionState(
        status: PeerConnectionStatus.connected,
        targetId: targetId,
        targetName: targetName,
        targetType: request.type,
        roomName: request.roomName,
        participants: _buildParticipantList(),
      ));

      debugPrint('[ConnectionService] Accepted connection: $targetName');
    } catch (e) {
      debugPrint('[ConnectionService] Accept failed: $e');
      _updateState(PeerConnectionState(
        status: PeerConnectionStatus.error,
        errorMessage: 'Failed to join. Please try again.',
      ));
      await _livekit.disconnect();
      await _database.clearActiveConnection();
    }
  }

  // ─── Disconnect ──────────────────────────────────────

  /// Disconnect from the current connection.
  /// [autoSwitch] = true when disconnecting to switch to another connection.
  Future<void> disconnect({bool autoSwitch = false}) async {
    debugPrint('[ConnectionService] Disconnecting (autoSwitch: $autoSwitch)');

    // Log call end
    if (_currentCallHistoryId != null && _callStartTime != null) {
      final duration =
          DateTime.now().difference(_callStartTime!).inSeconds;
      try {
        await _database.logCallEnd(_currentCallHistoryId!, duration);
      } catch (e) {
        debugPrint('[ConnectionService] Failed to log call end: $e');
      }
    }
    _currentCallHistoryId = null;
    _callStartTime = null;

    // Leave LiveKit room
    await _livekit.disconnect();

    // Clear active_connections in DB
    try {
      await _database.clearActiveConnection();
    } catch (e) {
      debugPrint('[ConnectionService] Failed to clear connection: $e');
    }

    // Stop background service (unless switching — will restart)
    if (!autoSwitch) {
      await _background.stopService();
    }

    _updateState(const PeerConnectionState(
      status: PeerConnectionStatus.disconnected,
    ));
  }

  // ─── PTT ─────────────────────────────────────────────

  /// Start transmitting (unmute mic).
  Future<void> startTalking() async {
    await _livekit.setMuted(false);
  }

  /// Stop transmitting (mute mic).
  Future<void> stopTalking() async {
    await _livekit.setMuted(true);
  }

  // ─── LiveKit Event Handling ──────────────────────────

  void _handleLiveKitState(ConnectionState livekitState) {
    switch (livekitState) {
      case ConnectionState.disconnected:
        // Only update if we think we're still connected
        // (avoids double-disconnect from manual disconnect)
        if (_state.isConnected || _state.isReconnecting) {
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          _updateState(_state.copyWith(
            status: PeerConnectionStatus.disconnected,
            errorMessage: 'Connection lost',
          ));
          _background.stopService();
          _database.clearActiveConnection();
          // Log call end
          if (_currentCallHistoryId != null && _callStartTime != null) {
            final duration =
                DateTime.now().difference(_callStartTime!).inSeconds;
            _database.logCallEnd(_currentCallHistoryId!, duration);
            _currentCallHistoryId = null;
            _callStartTime = null;
          }
        }
        break;
      case ConnectionState.reconnecting:
        if (_state.isConnected) {
          _updateState(_state.copyWith(
            status: PeerConnectionStatus.reconnecting,
          ));
          // Start reconnection timeout
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(_reconnectTimeout, () {
            debugPrint('[ConnectionService] Reconnect timed out');
            if (_state.isReconnecting) {
              disconnect();
              _updateState(_state.copyWith(
                status: PeerConnectionStatus.error,
                errorMessage:
                    'Connection lost. Could not reconnect.',
              ));
            }
          });
        }
        break;
      case ConnectionState.connected:
        if (_state.isReconnecting) {
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          _updateState(_state.copyWith(
            status: PeerConnectionStatus.connected,
          ));
          debugPrint('[ConnectionService] Successfully reconnected');
        }
        break;
      default:
        break;
    }
  }

  void _updateParticipants() {
    if (_state.isConnected || _state.isReconnecting) {
      _updateState(_state.copyWith(
        participants: _buildParticipantList(),
      ));
    }
  }

  List<ParticipantInfo> _buildParticipantList() {
    final remote = _livekit.remoteParticipants;
    final activeSpeakers = _livekit.room?.activeSpeakers ?? [];
    final speakerIds =
        activeSpeakers.map((s) => s.identity).toSet();

    return remote.map((p) {
      return ParticipantInfo(
        id: p.identity.toString(),
        name: p.name.isNotEmpty ? p.name : p.identity.toString(),
        isSpeaking: speakerIds.contains(p.identity),
      );
    }).toList();
  }

  // ─── State Management ────────────────────────────────

  void _updateState(PeerConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Get the stream of incoming connection requests.
  Stream<IncomingConnectionRequest> get onIncomingConnection =>
      _callNotification.onIncomingConnection;

  /// Clean shutdown — only called on sign-out, NOT on app background.
  /// For app background/swipe-away, the foreground service keeps everything alive.
  Future<void> shutdown() async {
    _reconnectTimer?.cancel();
    _livekitConnectionSub?.cancel();
    _livekitParticipantsSub?.cancel();
    _livekitSpeakersSub?.cancel();
    _incomingConnectionSub?.cancel();

    // Disconnect the active call if any
    if (!_state.isDisconnected) {
      await disconnect();
    }

    _stateController.close();
    _livekit.dispose();
    _callNotification.dispose();
  }

  /// Cancel stream subscriptions without killing LiveKit.
  /// Called when widget tree disposes but we want audio to keep playing.
  void disposeListeners() {
    _livekitConnectionSub?.cancel();
    _livekitParticipantsSub?.cancel();
    _livekitSpeakersSub?.cancel();
    _incomingConnectionSub?.cancel();
  }
}
