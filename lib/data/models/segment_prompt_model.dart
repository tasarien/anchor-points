import 'package:anchor_point_app/data/models/segment_data.dart';

class SegmentPrompt {
  SegmentData segmentData;
  String prompt;

  SegmentPrompt({
    required this.segmentData,
    required this.prompt,
  });

  factory SegmentPrompt.fromJson(Map<String, dynamic> json) {
    return SegmentPrompt(
      segmentData: SegmentData.fromJson(json),
      prompt: json['prompt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'segmentData': segmentData, 'prompt': prompt, };
  }
}
