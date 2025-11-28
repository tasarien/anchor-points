import 'package:anchor_point_app/data/models/final_ap_segment.dart';
import 'package:anchor_point_app/data/models/recording_state.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


class AudioRecorderScreen extends StatefulWidget {
  final List<FinalAPSegment> segments;
  final String supabaseBucket;

  const AudioRecorderScreen({
    Key? key,
    required this.segments,
    this.supabaseBucket = 'audio-recordings',
  }) : super(key: key);

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  late PageController _pageController;
  late RecorderController _recorderController;
  
  int _currentPage = 0;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isUploading = false;
  
  Map<int, RecordingState> _recordingStates = {};
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeRecordingStates();
    _initializeRecorder();
  }

  void _initializeRecordingStates() {
    for (int i = 0; i < widget.segments.length; i++) {
      _recordingStates[i] = RecordingState();
    }
  }

  void _initializeRecorder() {
    _recorderController = RecorderController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/recording_$_currentPage\_$timestamp.m4a';
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorderController.checkPermission()) {
        final path = await _getFilePath();
        
        await _recorderController.record(path: path);
        
        setState(() {
          _isRecording = true;
          _isPaused = false;
        });
      } else {
        _showError('Microphone permission denied');
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorderController.pause();
      setState(() => _isPaused = true);
    } catch (e) {
      _showError('Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorderController.record();
      setState(() => _isPaused = false);
    } catch (e) {
      _showError('Failed to resume recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorderController.stop();
      
      if (path != null) {
        final currentState = _recordingStates[_currentPage]!;
        final updatedFiles = [...currentState.recordedFiles, path];
        
        setState(() {
          _recordingStates[_currentPage] = currentState.copyWith(
            filePath: path,
            recordedFiles: updatedFiles,
            isRecorded: true,
          );
          _isRecording = false;
          _isPaused = false;
        });
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _recordMore() async {
    await _startRecording();
  }

  bool _canSubmit() {
    return _recordingStates.values.every((state) => state.isRecorded);
  }

  Future<void> _submitRecordings() async {
    if (!_canSubmit()) return;

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      
      for (int i = 0; i < widget.segments.length; i++) {
        final segment = widget.segments[i];
        final state = _recordingStates[i]!;
        
        for (int fileIndex = 0; fileIndex < state.recordedFiles.length; fileIndex++) {
          final filePath = state.recordedFiles[fileIndex];
          final file = File(filePath);
          
          if (await file.exists()) {
            final fileName = '${segment.segmentData.name}_${fileIndex + 1}.m4a';
            final bytes = await file.readAsBytes();
            
            await supabase.storage
                .from(widget.supabaseBucket)
                .uploadBinary(fileName, bytes);
          }
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All recordings uploaded successfully!')),
        );
      }
    } catch (e) {
      _showError('Failed to upload recordings: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Audio Segments'),
        actions: [
          if (_canSubmit())
            _isUploading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _submitRecordings,
                    tooltip: 'Submit All',
                  ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.segments.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _recordingStates[index]?.isRecorded == true
                        ? Colors.green
                        : index == _currentPage
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          
          // PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.segments.length,
              onPageChanged: (index) {
                if (_isRecording) {
                  _stopRecording();
                }
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildSegmentPage(widget.segments[index], index);
              },
            ),
          ),
          
          // Recording controls
          _buildRecordingControls(),
        ],
      ),
    );
  }

  Widget _buildSegmentPage(FinalAPSegment segment, int index) {
    final isRecorded = _recordingStates[index]?.isRecorded ?? false;
    final recordedCount = _recordingStates[index]?.recordedFiles.length ?? 0;
    final isCurrentPage = index == _currentPage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Segment info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  segment.segmentData.symbol,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      segment.segmentData.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (isRecorded)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$recordedCount recording${recordedCount > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Text to read
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              segment.text!,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Waveform visualization
          if (_isRecording && isCurrentPage)
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AudioWaveforms(
                size: Size(MediaQuery.of(context).size.width - 80, 100),
                recorderController: _recorderController,
                waveStyle: WaveStyle(
                  waveColor: Theme.of(context).primaryColor,
                  showDurationLabel: true,
                  spacing: 8.0,
                  showBottom: true,
                  extendWaveform: true,
                  showMiddleLine: false,
                  waveThickness: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey.shade100,
                ),
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    final isRecorded = _recordingStates[_currentPage]?.isRecorded ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isRecording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                if (isRecorded)
                  OutlinedButton.icon(
                    onPressed: _recordMore,
                    icon: const Icon(Icons.add),
                    label: const Text('Record More'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}