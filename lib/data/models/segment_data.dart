class SegmentData {
 
  String name;
  String symbol;

  SegmentData({
 
    required this.name,
    required this.symbol,
  });

  factory SegmentData.fromJson(Map<String, dynamic> json) {
    return SegmentData(
      name: json['name'],
      symbol: json['symbol'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'symbol': symbol};
  }
}
