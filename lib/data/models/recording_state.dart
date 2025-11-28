class RecordingState {
  final String? filePath;
  final List<String> recordedFiles;
  final bool isRecorded;

  RecordingState({
    this.filePath,
    this.recordedFiles = const [],
    this.isRecorded = false,
  });

  RecordingState copyWith({
    String? filePath,
    List<String>? recordedFiles,
    bool? isRecorded,
  }) {
    return RecordingState(
      filePath: filePath ?? this.filePath,
      recordedFiles: recordedFiles ?? this.recordedFiles,
      isRecorded: isRecorded ?? this.isRecorded,
    );
  }
}