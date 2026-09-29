enum PeerConnectionStatus {
  disconnected,
  connecting,
  connected,
  ringing, // incoming connection request
  reconnecting,
  error,
}

class PeerConnectionState {
  final PeerConnectionStatus status;
  final String? targetId; // contact userId or groupId
  final String? targetName; // display name of contact or group
  final String? targetType; // 'direct' or 'group'
  final String? roomName;
  final String? errorMessage;
  final List<ParticipantInfo> participants;

  const PeerConnectionState({
    this.status = PeerConnectionStatus.disconnected,
    this.targetId,
    this.targetName,
    this.targetType,
    this.roomName,
    this.errorMessage,
    this.participants = const [],
  });

  PeerConnectionState copyWith({
    PeerConnectionStatus? status,
    String? targetId,
    String? targetName,
    String? targetType,
    String? roomName,
    String? errorMessage,
    List<ParticipantInfo>? participants,
  }) {
    return PeerConnectionState(
      status: status ?? this.status,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetType: targetType ?? this.targetType,
      roomName: roomName ?? this.roomName,
      errorMessage: errorMessage ?? this.errorMessage,
      participants: participants ?? this.participants,
    );
  }

  bool get isConnected => status == PeerConnectionStatus.connected;
  bool get isConnecting => status == PeerConnectionStatus.connecting;
  bool get isDisconnected => status == PeerConnectionStatus.disconnected;
  bool get isReconnecting => status == PeerConnectionStatus.reconnecting;
  bool get isDirect => targetType == 'direct';
  bool get isGroup => targetType == 'group';

  /// Clear state back to disconnected.
  static const disconnected = PeerConnectionState();
}

/// Info about a participant in the current room.
class ParticipantInfo {
  final String id; // LiveKit participant identity (= user UUID)
  final String name;
  final bool isSpeaking;

  const ParticipantInfo({
    required this.id,
    required this.name,
    this.isSpeaking = false,
  });

  ParticipantInfo copyWith({
    String? id,
    String? name,
    bool? isSpeaking,
  }) {
    return ParticipantInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}
