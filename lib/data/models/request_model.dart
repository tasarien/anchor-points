import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class RequestModel {
  final String requesterId;
  final String type; // 'text' or 'audio'
  final SourceType requestedFor; // 'you', 'companion', or 'ai'
  final String status; // 'pending', 'completed', 'declined'
  final String? companionId;
  final String? invitationCode;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String anchorPointId;
  final String id;

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
  });

  // Factory constructor to create from JSON
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      requesterId: json['requester_id'] as String,
      type: json['type'] as String,
      requestedFor: SourceType.values.byName(json['requested_for'] as String),
      status: json['status'] as String,
      companionId: json['companion_id'] as String?,
      invitationCode: json['invitation_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      anchorPointId: json['anchor_point_id'].toString(),
      id: json['id'].toString(),
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
    };
  }
}

enum SourceType {you, ai, companion}