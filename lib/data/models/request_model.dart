import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/data/sources/user_info_source.dart';
import 'package:anchor_point_app/presentations/screens/crafting_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class RequestModel {
  final String requesterId;
  final String type; // 'text' or 'audio'
  final CompanionType requestedFor; // 'you', 'companion', or 'ai'
  final RequestStatus status; // 'created, pending', 'completed', 'declined'
  final String? companionId;
  final String? invitationCode;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int anchorPointId;
  final String id;
  final String? message;
  String? companionUsername;

  RequestModel({
    required this.requesterId,
    required this.type,
    required this.requestedFor,
    required this.status,
    this.companionId,
    this.invitationCode,
    required this.createdAt,
    this.completedAt,
    required this.anchorPointId,
    required this.id,
    this.message,
  });

  // Factory constructor to create from JSON
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      requesterId: json['requester_id'] as String,
      type: json['type'] as String,
      requestedFor: CompanionType.values.byName(
        json['requested_for'] as String,
      ),
      status: RequestStatus.values.byName(json['status'] as String),
      companionId: json['companion_id'] as String?,
      invitationCode: json['invitation_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      anchorPointId: json['anchor_point_id'] as int,
      id: json['id'].toString(),
      message: json['message'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'requester_id': requesterId,
      'type': type,
      'requested_for': requestedFor.name,
      'status': status,
      'companion_id': companionId,
      'invitation_code': invitationCode,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'anchor_point_id': anchorPointId,
      'id': id,
      'message': message,
    };
  }

  Future<void> getUserName() async {
    if (companionId == null) return null;
    UserProfile? profile = await userFromId(companionId!);
    if (profile != null) {
      companionUsername = profile.username;
    }
  }

  Color getStatusColor() {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.created:
        return Colors.yellow;
      case RequestStatus.declined:
        return Colors.red;
      case RequestStatus.completed:
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String getStatusLabel() {
    return 'request_type_' + status.name;
  }
}

enum RequestStatus { created, pending, completed, declined }
