import 'dart:async';
import 'package:flutter/material.dart';
import '../models/peer_connection_state.dart';
import '../models/profile.dart';
import '../services/connection_service.dart';
import '../services/call_notification_service.dart';

class ConnectionProvider extends ChangeNotifier {
  final ConnectionService _connectionService;

  PeerConnectionState _state = const PeerConnectionState();
  PeerConnectionState get state => _state;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isTalking = false;
  bool get isTalking => _isTalking;

  String? _initError;
  String? get initError => _initError;

  /// The most recent incoming connection request (if not yet consumed by UI).
  IncomingConnectionRequest? _pendingIncoming;
  IncomingConnectionRequest? get pendingIncoming => _pendingIncoming;

  /// Holds the request after it's been shown (consumed) so accept/decline can use it.
  IncomingConnectionRequest? _lastConsumedIncoming;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _incomingSubscription;

  ConnectionProvider({ConnectionService? connectionService})
      : _connectionService = connectionService ?? ConnectionService();

  ConnectionService get service => _connectionService;

  /// Initialize with the current user's profile.
  Future<void> initialize(Profile myProfile) async {
    _initError = null;

    try {
      await _connectionService.initialize(myProfile);

      // Listen to state changes from the service
      _stateSubscription =
          _connectionService.onStateChanged.listen((newState) {
        _state = newState;
        if (newState.isDisconnected) {
          _isTalking = false;
        }
        notifyListeners();
      });

      // Listen for incoming connection requests
      _incomingSubscription =
          _connectionService.onIncomingConnection.listen((request) {
        // Ignore if we're already connected or connecting
        if (_state.isConnected || _state.status == PeerConnectionStatus.connecting) {
          debugPrint('[ConnectionProvider] Ignoring incoming — already in a call');
          return;
        }
        // Ignore if we already have an unhandled pending request
        if (_pendingIncoming != null) {
          debugPrint('[ConnectionProvider] Ignoring duplicate incoming request');
          return;
        }
        _pendingIncoming = request;
        notifyListeners();
      });

      _isInitialized = true;
    } catch (e) {
      _initError = e.toString();
    }
    notifyListeners();
  }

  // ─── Connect / Disconnect ────────────────────────────

  /// Connect to a contact (1-on-1 direct).
  Future<void> connectToContact({
    required String contactId,
    required String contactName,
  }) async {
    await _connectionService.connectToContact(
      contactId: contactId,
      contactName: contactName,
    );
  }

  /// Connect to a group call.
  Future<void> connectToGroup({
    required String groupId,
    required String groupName,
  }) async {
    await _connectionService.connectToGroup(
      groupId: groupId,
      groupName: groupName,
    );
  }

  /// Consume the pending incoming request (marks it as picked up by the UI).
  /// This prevents re-triggering the sheet on subsequent notifyListeners calls.
  /// The actual request is saved so accept/decline can still use it.
  void consumePendingIncoming() {
    _lastConsumedIncoming = _pendingIncoming;
    _pendingIncoming = null;
    // Don't call notifyListeners — this is called FROM a listener callback
  }

  /// Accept an incoming connection request.
  Future<void> acceptIncoming() async {
    if (_lastConsumedIncoming == null) return;
    await _connectionService.acceptIncoming(_lastConsumedIncoming!);
    _lastConsumedIncoming = null;
    notifyListeners();
  }

  /// Decline an incoming connection request.
  void declineIncoming() {
    _lastConsumedIncoming = null;
    notifyListeners();
  }

  /// Disconnect from the current connection.
  Future<void> disconnect() async {
    _isTalking = false;
    await _connectionService.disconnect();
  }

  // ─── PTT ─────────────────────────────────────────────

  void startTalking() {
    if (_state.isConnected) {
      _isTalking = true;
      _connectionService.startTalking();
      notifyListeners();
    }
  }

  void stopTalking() {
    _isTalking = false;
    _connectionService.stopTalking();
    notifyListeners();
  }

  // ─── Error Handling ──────────────────────────────────

  void clearError() {
    if (_state.status == PeerConnectionStatus.error) {
      _state = const PeerConnectionState();
      notifyListeners();
    }
  }

  /// Full shutdown — disconnects everything. Call on sign-out only.
  Future<void> shutdown() async {
    _stateSubscription?.cancel();
    _incomingSubscription?.cancel();
    await _connectionService.shutdown();
  }

  @override
  void dispose() {
    // When the widget tree disposes (app going to background or being killed),
    // we only cancel UI-side subscriptions. The foreground service + LiveKit
    // keep running in the background so audio continues.
    _stateSubscription?.cancel();
    _incomingSubscription?.cancel();
    // Do NOT call _connectionService.shutdown() here — that would kill audio!
    super.dispose();
  }
}
