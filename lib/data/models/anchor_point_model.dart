import 'package:anchor_point_app/data/models/segment_prompt_model.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/anchor_point_widget.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/anchor_point_widget_small.dart';

class AnchorPoint {
  final int id;
  final String ownerId;
  final String? name;
  final String? description;
  final AnchorPointStatus status;
  final String? imageUrl;
  final List<SegmentPrompt>? segmentPrompts;
  final List<String>? doulosText;
  final List<String>? doulosAudio;
  final List<String>? companionText;
  final List<String>? companionAudio;

  AnchorPoint({
    required this.id,
    required this.ownerId,
    this.name,
    this.description,
    required this.status,
    this.imageUrl,
    this.segmentPrompts,
    this.doulosText,
    this.doulosAudio,
    this.companionText,
    this.companionAudio,
  });

  factory AnchorPoint.fromJson(Map<String, dynamic> json) {
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
      segmentPrompts: (json['segment_prompts'] as List<dynamic>?)
          ?.map((segment) => SegmentPrompt.fromJson(segment))
          .toList(),
      doulosText: (json['doulos_text'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      doulosAudio: (json['doulos_audio'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      companionText: (json['companion_text'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      companionAudio: (json['companion_audio'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      'doulos_text': doulosText,
      'doulos_audio': doulosAudio,
      'companion_text': companionText,
      'companion_audio': companionAudio,
    };
  }

  AnchorPointWidgetSmall buildAPWidgetSmall() {
    return AnchorPointWidgetSmall(anchorPoint: this);
  }
}

enum AnchorPointStatus { created, drafted, crafted, archived }
