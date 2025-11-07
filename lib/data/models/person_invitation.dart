class PersonInvitation {
  final int? id;
  final String? name;
  final String? token;
  final String status;
  final DateTime expireDate;
  final String userInvitingId;

  PersonInvitation({
    required this.id,
    required this.name,
    required this.token,
    required this.status,
    required this.expireDate,
    required this.userInvitingId,
  });

  factory PersonInvitation.fromJson(Map<String, dynamic> json) {
    final expireRaw = json['expireDate'] ?? json['expire_date'];
    late final DateTime parsedExpireDate;

    if (expireRaw is String) {
      parsedExpireDate = DateTime.parse(expireRaw);
    } else if (expireRaw is int) {
      // Accept seconds or milliseconds
      parsedExpireDate = DateTime.fromMillisecondsSinceEpoch(
        expireRaw > 1000000000000 ? expireRaw : expireRaw * 1000,
      );
    } else if (expireRaw is DateTime) {
      parsedExpireDate = expireRaw;
    } else {
      throw FormatException('Invalid or missing expireDate');
    }

    final userInvitingId =
        (json['userInvitingId'] ?? json['user_inviting_id']) as String?;
    if (userInvitingId == null) {
      throw FormatException('Missing userInvitingId');
    }

    return PersonInvitation(
      id: json['id'] as int?,
      name: json['name'] as String?,
      token: json['token'] as String?,
      status: json['status'] as String,
      expireDate: parsedExpireDate,
      userInvitingId: userInvitingId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'token': token,
      'status': status,
      'expireDate': expireDate.toIso8601String(),
      'userInvitingId': userInvitingId,
    };
  }
}