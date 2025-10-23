import 'package:anchor_point_app/data/models/segment_prompt_model.dart';

class SegmentPromptsTemplate {
  String name;
  List<SegmentPrompt> segmentPrompts;

  SegmentPromptsTemplate({
    required this.name,
    required this.segmentPrompts,
  });


factory SegmentPromptsTemplate.fromJson(Map<String, dynamic> json) {
    return SegmentPromptsTemplate(
      name: json['name'],
      segmentPrompts: (json['prompt'] as List<Map<String, dynamic>>).map((segment) => SegmentPrompt.fromJson(segment)).toList()
    );
  }
}