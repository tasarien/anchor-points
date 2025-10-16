class UserProfile {
  final String id;
  final String? username;
  final int? pinnedAnchorPointId;

  UserProfile({
    required this.id,
    required this.username,
    this.pinnedAnchorPointId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['user_id'] as String,
      username: json['username'] as String?,
      pinnedAnchorPointId: json['pinned_anchor_point'] as int?,
    );
  }
}
