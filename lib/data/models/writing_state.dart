class WritingState {
  final String text;
  final bool isComplete;
  final int wordCount;

  WritingState({
    this.text = '',
    this.isComplete = false,
    this.wordCount = 0,
  });

  WritingState copyWith({
    String? text,
    bool? isComplete,
    int? wordCount,
  }) {
    return WritingState(
      text: text ?? this.text,
      isComplete: isComplete ?? this.isComplete,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}