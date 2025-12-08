import 'dart:io';
import 'dart:typed_data';

import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:audio_waveforms/audio_waveforms.dart' as waveforms;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:anchor_point_app/data/models/final_ap_segment.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';

class SegmentDataLocal {
  final String id;
  final FinalAPSegment original;
  String text;
  String? audioPath;
  String? audioUrl;
  waveforms.PlayerController? playerController;
  bool isPlaying = false;
  bool isPlayerPrepared = false;

  SegmentDataLocal({
    required this.id,
    required this.original,
    required this.text,
    this.audioPath,
    this.audioUrl,
  });
}

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
  final PageController _pageController = PageController();
  final Uuid _uuid = const Uuid();

  waveforms.RecorderController? _recorderController;

  List<SegmentDataLocal> _segmentsLocal = [];
  bool _isRecorderReady = false;
  bool _isRecording = false;
  bool _isLoading = true;
  int _currentSegmentIndex = 0;
  bool _isUploading = false;

  // upload visuals
  double _uploadProgress = 0.0;
  String _uploadStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeFromWidgetSegments();
    _checkPermissionAndPrepare();
  }

  @override
  void dispose() {
    _recorderController?.dispose();
    _pageController.dispose();
    for (var seg in _segmentsLocal) {
      seg.playerController?.dispose();
    }
    super.dispose();
  }

  void _initializeFromWidgetSegments() {
    _segmentsLocal = widget.segments.map((s) {
      final text = (s.text != null && s.text!.isNotEmpty)
          ? s.text!
          : "No text provided";
      return SegmentDataLocal(id: _uuid.v4(), original: s, text: text);
    }).toList();
  }

  Future<void> _checkPermissionAndPrepare() async {
    setState(() => _isLoading = true);
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showError('Microphone permission is required to record.');
      setState(() => _isLoading = false);
      return;
    }
    _isRecorderReady = true;
    setState(() => _isLoading = false);
  }

  Future<String> _tempFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/rec_${_uuid.v4()}_$ts.mp3';
  }

  Future<void> _startRecording() async {
    if (!_isRecorderReady || _isRecording) return;
    final current = _segmentsLocal[_currentSegmentIndex];

    _deleteRecordingInternal(_currentSegmentIndex, deleteFile: true);
    current.isPlayerPrepared = false;

    _recorderController = waveforms.RecorderController();

    final path = await _tempFilePath();
    try {
      await _recorderController!.record(path: path);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showError('Error starting recording: $e');
      _recorderController?.dispose();
      _recorderController = null;
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _recorderController == null) return;
    final current = _segmentsLocal[_currentSegmentIndex];
    try {
      final recordedPath = await _recorderController!.stop();
      _recorderController!.dispose();
      _recorderController = null;

      if (recordedPath != null && recordedPath.isNotEmpty) {
        final file = File(recordedPath);
        if (await file.exists() && await file.length() > 100) {
          current.audioPath = recordedPath;
          await _preparePlayerController(_currentSegmentIndex);
        } else {
          _showError(
            'Failed to save recording for ${current.original.segmentData.name}',
          );
        }
      } else {
        _showError('Failed to finalize recording.');
      }
    } catch (e) {
      _showError('Error stopping recording: $e');
    } finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _preparePlayerController(int index) async {
    final seg = _segmentsLocal[index];
    final path = seg.audioPath;
    if (path == null) return;

    seg.playerController?.dispose();
    seg.playerController = waveforms.PlayerController();
    seg.isPlayerPrepared = false;
    if (mounted) setState(() {});

    try {
      final player = seg.playerController!;
      await player.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );
      seg.isPlayerPrepared = true;

      player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            seg.isPlaying = state == waveforms.PlayerState.playing;
          });
        }
      });
    } catch (e) {
      _showError(
        'Error preparing playback for ${seg.original.segmentData.name}: $e',
      );
      seg.playerController = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayPause() async {
    final seg = _segmentsLocal[_currentSegmentIndex];
    final player = seg.playerController;
    if (player == null || !seg.isPlayerPrepared) return;

    if (player.playerState == waveforms.PlayerState.playing) {
      await player.pausePlayer();
    } else {
      await player.startPlayer();
    }
  }

  void _deleteRecordingInternal(int index, {bool deleteFile = true}) {
    final seg = _segmentsLocal[index];
    seg.playerController?.dispose();
    seg.playerController = null;
    seg.isPlayerPrepared = false;
    seg.isPlaying = false;
    if (deleteFile && seg.audioPath != null) {
      try {
        final file = File(seg.audioPath!);
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
    seg.audioPath = null;
  }

  void _deleteRecording() {
    _deleteRecordingInternal(_currentSegmentIndex, deleteFile: true);
    if (mounted) setState(() {});
  }

  bool get _canSubmit {
    return _segmentsLocal.every(
      (s) => s.audioPath != null && s.audioPath!.isNotEmpty,
    );
  }

  int get _completedCount {
    return _segmentsLocal
        .where((s) => s.audioPath != null && s.audioPath!.isNotEmpty)
        .length;
  }

  Future<void> _submitRecordings() async {
    if (!_canSubmit || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatusMessage = 'Preparing upload...';
    });

    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      _showError('User not authenticated.');
      setState(() => _isUploading = false);
      return;
    }

    try {
      final List<String> audioUrls = [];
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      for (int i = 0; i < _segmentsLocal.length; i++) {
        final seg = _segmentsLocal[i];
        final audioFile = File(seg.audioPath!);
        final fileName = '${timestamp}_segment_${i + 1}.mp3';
        final storagePath = '${currentUser.id}/$fileName';

        setState(() {
          _uploadStatusMessage =
              'Uploading segment ${i + 1} of ${_segmentsLocal.length}...';
          _uploadProgress = (i / _segmentsLocal.length);
        });

        final Uint8List bytes = await audioFile.readAsBytes();

        await supabase.storage
            .from(widget.supabaseBucket)
            .uploadBinary(storagePath, bytes);

        final publicUrl = supabase.storage
            .from(widget.supabaseBucket)
            .getPublicUrl(storagePath);
        audioUrls.add(publicUrl);
      }

      setState(() {
        _uploadStatusMessage = 'Finalizing...';
        _uploadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All recordings uploaded successfully!'),
          ),
        );
        Navigator.of(context).pop(audioUrls);
      }
    } catch (e) {
      _showError('Failed to upload recordings: $e');
    } finally {
      if (mounted)
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatusMessage = '';
        });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Audio Segments'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_completedCount/${_segmentsLocal.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // page indicators with arrow for submit page
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_segmentsLocal.length + 1, (index) {
                if (index == _segmentsLocal.length) {
                  // Submit page arrow
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: FaIcon(
                      FontAwesomeIcons.arrowRight,
                      size: 12,
                      color: _currentSegmentIndex == index
                          ? colorScheme.onSurface
                          : _canSubmit
                          ? colorScheme.secondary
                          : colorScheme.primary.withOpacity(0.3),
                    ),
                  );
                } else {
                  // Segment circles
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _segmentsLocal[index].audioPath != null
                          ? colorScheme.secondary
                          : index == _currentSegmentIndex
                          ? colorScheme.onSurface
                          : colorScheme.tertiary,
                    ),
                  );
                }
              }),
            ),
          ),

          // page view
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _segmentsLocal.length + 1, // +1 for submit page
              physics: _isRecording || _isUploading
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              onPageChanged: (index) async {
                if (_isRecording) {
                  await _stopRecording();
                }
                setState(() => _currentSegmentIndex = index);
              },
              itemBuilder: (context, index) {
                if (index == _segmentsLocal.length) {
                  return _buildSubmitPage();
                }
                return _buildSegmentPage(index);
              },
            ),
          ),

          // controls - only show for recording pages, not submit page
          if (_currentSegmentIndex < _segmentsLocal.length)
            _buildRecordingControls(),
        ],
      ),
    );
  }

  Widget _buildSubmitPage() {
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Completion icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _canSubmit
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
            ),
            child: Icon(
              _canSubmit ? Icons.check_circle : Icons.pending,
              size: 60,
              color: _canSubmit ? Colors.green : Colors.orange,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            _canSubmit ? 'Ready to Submit' : 'Almost There!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            _canSubmit
                ? 'All segments have been recorded. Review your recordings and submit when ready.'
                : 'Please complete all audio recordings before submitting.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Summary card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    Icons.mic,
                    'Total Segments',
                    '${_segmentsLocal.length}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.check_circle,
                    'Recordings Completed',
                    '$_completedCount/${_segmentsLocal.length}',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // List of segments with status
                  ...List.generate(_segmentsLocal.length, (index) {
                    final seg = _segmentsLocal[index];
                    final hasRecording = seg.audioPath != null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            hasRecording
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: hasRecording ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              seg.original.segmentData.name,
                              style: TextStyle(
                                fontSize: 15,
                                color: hasRecording
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (!hasRecording)
                            TextButton(
                              onPressed: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Text('Record'),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Action buttons
          if (_isUploading) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatusMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            if (_canSubmit)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRecordings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload),
                      SizedBox(width: 8),
                      Text(
                        'Submit All Recordings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to first incomplete segment
                    for (int i = 0; i < _segmentsLocal.length; i++) {
                      if (_segmentsLocal[i].audioPath == null) {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        break;
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mic),
                      SizedBox(width: 8),
                      Text(
                        'Continue Recording',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Back button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  if (_currentSegmentIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Recordings',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSegmentPage(int index) {
    final seg = _segmentsLocal[index];
    final hasRecording = seg.audioPath != null && seg.audioPath!.isNotEmpty;
    final isCurrent = index == _currentSegmentIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WholeSymbol(symbol: seg.original.segmentData.symbol),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seg.original.segmentData.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (hasRecording)
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '1 recording',
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
          Card(
            child: Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              child: Text(
                seg.text,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // waveform area
          if (_isRecording && isCurrent && _recorderController != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: waveforms.AudioWaveforms(
                  size: Size(MediaQuery.of(context).size.width - 80, 100),
                  recorderController: _recorderController!,
                  waveStyle: waveforms.WaveStyle(
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
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            )
          else if (hasRecording && seg.playerController != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: waveforms.AudioFileWaveforms(
                  size: Size(MediaQuery.of(context).size.width - 80, 100),
                  playerController: seg.playerController!,
                  enableSeekGesture: true,
                  waveformType: waveforms.WaveformType.long,
                  playerWaveStyle: const waveforms.PlayerWaveStyle(
                    fixedWaveColor: Colors.grey,
                    liveWaveColor: Colors.red,
                    spacing: 6.0,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 92),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    final seg = _segmentsLocal[_currentSegmentIndex];
    final hasRecording = seg.audioPath != null && seg.audioPath!.isNotEmpty;
    final canPlay =
        hasRecording && seg.playerController != null && seg.isPlayerPrepared;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
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
                  onPressed: null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                WholeButton(
                  onPressed: _isRecorderReady
                      ? (_isRecording ? _stopRecording : _startRecording)
                      : null,
                  icon: _isRecording
                      ? FontAwesomeIcons.stop
                      : FontAwesomeIcons.microphoneLines,
                  text: _isRecording ? 'Stop' : 'Record',
                  wide: true,
                ),
                WholeButton(
                  onPressed: canPlay ? _togglePlayPause : null,
                  disabled: !canPlay,
                  icon: seg.isPlaying
                      ? FontAwesomeIcons.pause
                      : FontAwesomeIcons.play,
                ),
                WholeButton(
                  icon: FontAwesomeIcons.trash,
                  suggested: false,
                  disabled: !hasRecording,
                  onPressed: hasRecording ? _deleteRecording : null,
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: WholeButton(
                  wide: true,
                  onPressed: _currentSegmentIndex > 0
                      ? _goToPreviousSegment
                      : null,
                  icon: FontAwesomeIcons.chevronLeft,
                  disabled: _currentSegmentIndex == 0,
                  text: "Previous",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WholeButton(
                  onPressed: _goToNextSegment,
                  icon: FontAwesomeIcons.chevronRight,
                  text: _currentSegmentIndex == _segmentsLocal.length - 1
                      ? "Review"
                      : "Next",
                  wide: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToNextSegment() {
    if (_currentSegmentIndex < _segmentsLocal.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousSegment() {
    if (_currentSegmentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
