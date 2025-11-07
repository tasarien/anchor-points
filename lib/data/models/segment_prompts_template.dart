import 'package:anchor_point_app/data/models/segment_prompt_model.dart';

class SegmentPromptsTemplate {
  String name;
  String? description;
  List<SegmentPrompt> template;
  String? imageUrl;

  SegmentPromptsTemplate({
    required this.name,
    required this.template,
    this.description,
    this.imageUrl,
  });

  factory SegmentPromptsTemplate.fromJson(Map<String, dynamic> json) {
    return SegmentPromptsTemplate(
      name: json['name'],
      description: json['description'],
      template: (json['template'] as List<dynamic>)
          .map((segment) => SegmentPrompt.fromJson(segment))
          .toList(),
      imageUrl: json['image_url'],
    );
  }
}
