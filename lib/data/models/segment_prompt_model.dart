import 'package:anchor_point_app/data/models/segment_data.dart';

class SegmentPrompt {
  SegmentData segmentData;
  String prompt;

  SegmentPrompt({required this.segmentData, required this.prompt});

  factory SegmentPrompt.fromJson(Map<String, dynamic> json) {
    SegmentData segmentData = json['segmentData'] != null
        ? SegmentData.fromJson(json['segmentData'])
        : SegmentData(name: json['name'], symbol: json['symbol']);
    return SegmentPrompt(segmentData: segmentData, prompt: json['prompt']);
  }

  Map<String, dynamic> toJson() {
    return {'segmentData': segmentData, 'prompt': prompt};
  }
}
