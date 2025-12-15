import 'package:anchor_point_app/data/sources/user_info_source.dart';
import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String? username;
  final int? pinnedAnchorPointId;
  final bool premiumAccount;
  final bool superAccess;
  final bool extendedAccount;
  UserProfile({
    required this.id,
    required this.username,
    this.pinnedAnchorPointId,
    required this.premiumAccount,
    required this.superAccess,
    required this.extendedAccount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final bool premiumAccount = json['premium'] ?? false;
    final bool superAccess = json['super_access'] ?? false;

    return UserProfile(
      id: json['user_id'] as String,
      username: json['username'] as String?,
      pinnedAnchorPointId: json['pinned_anchor_point'] as int?,
      premiumAccount: premiumAccount,
      superAccess: superAccess,
      extendedAccount: premiumAccount || superAccess,
    );
  }
}

Future<UserProfile>? userFromId(String id) async {
  return UserProfile.fromJson(
    await SupabaseUserInfoSource().getUserInfobyId(id),
  );
}
