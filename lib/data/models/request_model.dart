import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/data/sources/request_source.dart';
import 'package:anchor_point_app/data/sources/user_info_source.dart';
import 'package:anchor_point_app/presentations/screens/crafting_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class HalfRequestModel {
  RequestType type;
  CompanionType companionType;
  RequestStatus status; // 'created, pending', 'completed', 'declined',
  final String? companionId;
  final String? invitationCode;
  final String? message;

  final DateTime createdAt;
  DateTime? completedAt;
  String? companionUsername;
  HalfRequestModel({
    required this.type,
    required this.companionType,
    required this.status,
    this.companionId,
    this.invitationCode,

    required this.createdAt,
    this.completedAt,
    this.message,
  });

  factory HalfRequestModel.fromJson(Map<String, dynamic> json) {
    return HalfRequestModel(
      type: RequestType.values.byName(json['type'] as String),
      companionType: CompanionType.values.byName(
        json['companion_type'] as String,
      ),
      status: RequestStatus.values.byName(json['status'] as String),
      companionId: json['companion_id'] as String?,
      invitationCode: json['invitation_code'] as String?,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
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
      case RequestStatus.waiting:
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

  IconData typeIcon() {
    switch (type) {
      case RequestType.text:
        return FontAwesomeIcons.pencil;
      case RequestType.audio:
        return FontAwesomeIcons.microphone;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'companion_type': companionType.name,
      'status': status.name,
      'companion_id': companionId,
      'invitation_code': invitationCode,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

class RequestModel {
  final HalfRequestModel textRequest;
  final HalfRequestModel audioRequest;
  final int anchorPointId;
  UserProfile? requester;
  AnchorPoint? anchorPoint;
  final int id;

  RequestModel({
    required this.textRequest,
    required this.audioRequest,
    required this.anchorPointId,
    required this.id,
  });

  // Factory constructor to create from JSON
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      textRequest: HalfRequestModel.fromJson(json['text_request']),
      audioRequest: HalfRequestModel.fromJson(json['audio_request']),

      anchorPointId: json['anchor_point_id'] as int,
      id: json['id'] as int,
    );
  }

  Future<void> getRequesterAndAnchorPoint() async {
    await getAnchorPoint();
    await getRequester();
  }

  Future<void> getAnchorPoint() async {
    AnchorPoint? ap = await AnchorPoint.fromJsonAsync(
      await SupabaseAnchorPointSource().getAnchorPoint(anchorPointId),
    );
    if (ap != null) {
      anchorPoint = ap;
    }
  }

  Future<void> getRequester() async {
    if (anchorPoint == null) return null;
    UserProfile? profile = await userFromId(anchorPoint!.ownerId);
    if (profile != null) {
      requester = profile;
    }
  }

  Future<void> changeStatus(RequestStatus newStatus, RequestType type) async {
    switch (type) {
      case RequestType.text:
        textRequest.status = newStatus;
        if (newStatus == RequestStatus.completed) {
          // Set completion date to this moment
          textRequest.completedAt = DateTime.now();

          // Unlock according audio request
          audioRequest.status = RequestStatus.pending;
        }
        SupabaseRequestSource().updateRequest(id, {
          'text_request': textRequest.toJson(),
          'audio_request': audioRequest.toJson(),
        });
        break;
      case RequestType.audio:
        audioRequest.status = newStatus;
        if (newStatus == RequestStatus.completed) {
          // Set completion date to this moment
          audioRequest.completedAt = DateTime.now();
        }
        SupabaseRequestSource().updateRequest(id, {
          'text_request': textRequest.toJson(),
          'audio_request': textRequest.toJson(),
        });
        break;
    }
  }
}

enum RequestStatus { waiting, pending, completed, declined }

enum RequestType { text, audio }

enum RequestTileMode { forRequester, forRequested }
