import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages LiveKit room connections, audio tracks, and PTT.
class LiveKitService {
  Room? _room;
  LocalAudioTrack? _localAudioTrack;
  EventsListener<RoomEvent>? _roomListener;

  // Stream controllers for events
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final _participantsController =
      StreamController<List<RemoteParticipant>>.broadcast();
  final _activeSpeakersController =
      StreamController<List<Participant>>.broadcast();

  Stream<ConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;
  Stream<List<RemoteParticipant>> get onParticipantsChanged =>
      _participantsController.stream;
  Stream<List<Participant>> get onActiveSpeakersChanged =>
      _activeSpeakersController.stream;

  Room? get room => _room;
  bool get isConnected => _room?.connectionState == ConnectionState.connected;
  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? [];

  /// Request a room token from the `live-kit` Supabase Edge Function.
  /// The LiveKit API secret lives only in the function's environment, never
  /// in the app. supabase_flutter sends the user's session JWT automatically,
  /// and the function verifies it before signing the token.
  Future<({String token, String url})> _fetchConnectionDetails(
      String roomName) async {
    final response = await Supabase.instance.client.functions.invoke(
      'live-kit',
      body: {'roomName': roomName},
    );
    final data = response.data;
    if (data is! Map || data['token'] is! String || data['url'] is! String) {
      throw Exception('Invalid response from live-kit: $data');
    }
    return (token: data['token'] as String, url: data['url'] as String);
  }

  /// Connect to a LiveKit room.
  /// Audio starts muted (PTT model — unmute when talking).
  Future<void> connect(String roomName) async {
    // Disconnect from any existing room first
    if (_room != null) {
      await disconnect();
    }

    // Get a room token from the Edge Function (LiveKit secret stays server-side)
    final details = await _fetchConnectionDetails(roomName);

    // Create room with audio-optimized settings
    _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: AudioPublishOptions(
          audioBitrate: AudioPreset.speech,
        ),
        defaultAudioOutputOptions: AudioOutputOptions(
          speakerOn: true, // Route to speaker by default
        ),
      ),
    );

    // Set up room event listener
    _roomListener = _room!.createListener();
    _setupRoomListeners();

    // Connect to the room
    await _room!.connect(details.url, details.token);

    // Publish audio track (muted initially for PTT)
    await _publishAudioTrack();
    await setMuted(true); // Start muted — PTT model

    debugPrint('[LiveKit] Connected to room: $roomName');
  }

  /// Publish local audio track.
  Future<void> _publishAudioTrack() async {
    if (_room == null) return;

    _localAudioTrack = await LocalAudioTrack.create(
      const AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      ),
    );

    await _room!.localParticipant?.publishAudioTrack(
      _localAudioTrack!,
      publishOptions: const AudioPublishOptions(
        audioBitrate: AudioPreset.speech,
      ),
    );
  }

  /// Set up event listeners for the room.
  void _setupRoomListeners() {
    _roomListener
      ?..on<RoomDisconnectedEvent>((event) {
        debugPrint('[LiveKit] Room disconnected');
        _connectionStateController.add(ConnectionState.disconnected);
      })
      ..on<RoomReconnectingEvent>((event) {
        debugPrint('[LiveKit] Room reconnecting...');
        _connectionStateController.add(ConnectionState.reconnecting);
      })
      ..on<RoomReconnectedEvent>((event) {
        debugPrint('[LiveKit] Room reconnected');
        _connectionStateController.add(ConnectionState.connected);
      })
      ..on<ParticipantConnectedEvent>((event) {
        debugPrint(
            '[LiveKit] Participant joined: ${event.participant.identity}');
        _emitParticipants();
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        debugPrint('[LiveKit] Participant left: ${event.participant.identity}');
        _emitParticipants();
      })
      ..on<ActiveSpeakersChangedEvent>((event) {
        _activeSpeakersController.add(event.speakers);
      })
      ..on<TrackSubscribedEvent>((event) {
        debugPrint(
            '[LiveKit] Track subscribed from ${event.participant.identity}');
        // Remote audio tracks are automatically played by LiveKit
      });
  }

  void _emitParticipants() {
    if (_room != null) {
      _participantsController
          .add(_room!.remoteParticipants.values.toList());
    }
  }

  /// Mute/unmute local audio (PTT control).
  Future<void> setMuted(bool muted) async {
    if (_localAudioTrack == null) return;

    await _room?.localParticipant?.setMicrophoneEnabled(!muted);
  }

  /// Disconnect from the current room.
  Future<void> disconnect() async {
    debugPrint('[LiveKit] Disconnecting...');

    _roomListener?.dispose();
    _roomListener = null;

    if (_localAudioTrack != null) {
      await _localAudioTrack!.stop();
      _localAudioTrack = null;
    }

    await _room?.disconnect();
    await _room?.dispose();
    _room = null;

    _connectionStateController.add(ConnectionState.disconnected);
    debugPrint('[LiveKit] Disconnected');
  }

  /// Ensure audio output goes to speaker (not earpiece).
  Future<void> setSpeakerOn(bool speakerOn) async {
    await _room?.setSpeakerOn(speakerOn);
  }

  Future<void> dispose() async {
    await disconnect();
    _connectionStateController.close();
    _participantsController.close();
    _activeSpeakersController.close();
  }
}
