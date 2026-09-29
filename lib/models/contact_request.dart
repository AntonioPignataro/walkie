import 'profile.dart';

class ContactRequest {
  final String id;
  final Profile fromProfile;
  final Profile toProfile;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  const ContactRequest({
    required this.id,
    required this.fromProfile,
    required this.toProfile,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory ContactRequest.fromJson(Map<String, dynamic> json) {
    return ContactRequest(
      id: json['id'] as String,
      fromProfile: Profile.fromJson(
        json['from_profile'] as Map<String, dynamic>,
      ),
      toProfile: Profile.fromJson(
        json['to_profile'] as Map<String, dynamic>,
      ),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
