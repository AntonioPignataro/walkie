class ActiveConnection {
  final String userId;
  final String targetType; // 'direct' or 'group'
  final String targetId; // contact's user_id or group_id
  final String roomName;
  final DateTime connectedAt;

  const ActiveConnection({
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.roomName,
    required this.connectedAt,
  });

  bool get isDirect => targetType == 'direct';
  bool get isGroup => targetType == 'group';

  factory ActiveConnection.fromJson(Map<String, dynamic> json) {
    return ActiveConnection(
      userId: json['user_id'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String,
      roomName: json['room_name'] as String,
      connectedAt: DateTime.parse(json['connected_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'target_type': targetType,
        'target_id': targetId,
        'room_name': roomName,
      };

  ActiveConnection copyWith({
    String? userId,
    String? targetType,
    String? targetId,
    String? roomName,
    DateTime? connectedAt,
  }) {
    return ActiveConnection(
      userId: userId ?? this.userId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      roomName: roomName ?? this.roomName,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  /// Generate a deterministic room name for direct calls.
  /// Both users compute the same name by sorting their IDs.
  static String directRoomName(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return 'direct_${sorted[0]}_${sorted[1]}';
  }

  /// Generate a room name for group calls.
  static String groupRoomName(String groupId) {
    return 'group_$groupId';
  }
}
