class SegmentPrompt {
  String name;
  String prompt;
  String symbol;

  SegmentPrompt({
    required this.name,
    required this.prompt,
    required this.symbol,
  });


factory SegmentPrompt.fromJson(Map<String, dynamic> json) {
    return SegmentPrompt(
      name: json['name'],
      prompt: json['prompt'],
      symbol: json['symbol']
    );
  }
}