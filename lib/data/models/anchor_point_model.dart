import 'package:anchor_point_app/data/models/final_ap_segment.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/data/models/segment_prompt_model.dart';
import 'package:anchor_point_app/data/sources/request_source.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/anchor_point_widget.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/anchor_point_widget_small.dart';
import 'package:flutter/widgets.dart';

class AnchorPoint {
  final int id;
  final String ownerId;
  final String? name;
  final String? description;
  final AnchorPointStatus status;
  final String? imageUrl;
  final List<SegmentPrompt>? segmentPrompts;
  final List<FinalAPSegment>? finalSegments;
  final RequestModel? request;

  AnchorPoint({
    required this.id,
    required this.ownerId,
    this.name,
    this.description,
    required this.status,
    this.imageUrl,
    this.segmentPrompts,
    this.finalSegments,
    this.request,
  });

  static Future<AnchorPoint> fromJsonAsync(Map<String, dynamic> json) async {
    final requestSource = SupabaseRequestSource();

    final RequestModel? req = json['request_id'] != null
        ? RequestModel.fromJson(
            await requestSource.getRequest(json['request_id']),
          )
        : null;

    List<SegmentPrompt>? segmentPrompts =
        (json['segment_prompts'] as List<dynamic>?)
            ?.map((segment) => SegmentPrompt.fromJson(segment))
            .toList();

    List<FinalAPSegment>? makeFinalSegments() {
      List<FinalAPSegment> finalSegments = [];
      if (segmentPrompts != null) {
        int index = 0;
        for (SegmentPrompt segmentPrompt in segmentPrompts) {
          finalSegments.add(
            FinalAPSegment(
              segmentData: segmentPrompt.segmentData,
              text: json['segments_text'] != null
                  ? json['segments_text'][index]
                  : null,
              audioUrl: json['segments_audio'] != null
                  ? json['segments_audio'][index]
                  : null,
            ),
          );
          index++;
        }
      }
      return finalSegments;
    }

    return AnchorPoint(
      id: json['id'] as int,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      status: AnchorPointStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => AnchorPointStatus.created,
      ),
      imageUrl: json['image_url'] as String?,
      segmentPrompts: segmentPrompts,
      finalSegments: makeFinalSegments(),
      request: req,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'status': status.name,
      'image_url': imageUrl,
      'segment_prompts': segmentPrompts?.map((s) => s.toJson()).toList(),
    };
  }

  AnchorPointWidgetSmall buildAPWidgetSmall() {
    return AnchorPointWidgetSmall(anchorPoint: this);
  }

  AnchorPoint copyWith({
    int? id,
    String? ownerId,
    String? name,
    String? description,
    AnchorPointStatus? status,
    String? imageUrl,
    List<SegmentPrompt>? segmentPrompts,
    List<FinalAPSegment>? finalSegments,
    RequestModel? request,
  }) {
    return AnchorPoint(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      segmentPrompts: segmentPrompts ?? this.segmentPrompts,
      finalSegments: finalSegments ?? this.finalSegments,
      request: request ?? this.request,
    );
  }
}

enum AnchorPointStatus { created, drafted, crafted, archived }
