import 'profile.dart';

class CallRecord {
  final String id;
  final String userId;
  final String? peerId;
  final String? groupId;
  final String callType; // 'direct' or 'group'
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  // Enriched fields (from joins)
  final Profile? peerProfile;
  final String? groupName;

  const CallRecord({
    required this.id,
    required this.userId,
    this.peerId,
    this.groupId,
    required this.callType,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.peerProfile,
    this.groupName,
  });

  bool get isDirect => callType == 'direct';
  bool get isGroup => callType == 'group';

  /// Human-readable duration
  String get formattedDuration {
    if (durationSeconds == null) return 'In progress';
    final d = Duration(seconds: durationSeconds!);
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  /// Display name: peer name or group name
  String get displayName {
    if (isDirect) {
      return peerProfile?.name ?? 'Unknown';
    }
    return groupName ?? 'Unknown Group';
  }

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    Profile? peerProfile;
    if (json['peer_profile'] != null) {
      peerProfile = Profile.fromJson(
          json['peer_profile'] as Map<String, dynamic>);
    }

    String? groupName;
    if (json['group'] != null) {
      groupName = (json['group'] as Map<String, dynamic>)['name'] as String?;
    }

    return CallRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      peerId: json['peer_id'] as String?,
      groupId: json['group_id'] as String?,
      callType: json['call_type'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      peerProfile: peerProfile,
      groupName: groupName,
    );
  }
}
