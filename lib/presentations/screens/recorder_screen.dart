import 'dart:io';
import 'dart:typed_data';

import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/final_ap_segment.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:audio_waveforms/audio_waveforms.dart' as waveforms;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AudioRecorderScreen extends StatefulWidget {
  final int anchorPointId;
  final String supabaseBucket;

  const AudioRecorderScreen({
    super.key,
    required this.anchorPointId,
    this.supabaseBucket = 'audio-recordings',
  });

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final PageController _pageController = PageController();
  final Uuid _uuid = const Uuid();

  late AnchorPoint anchorPoint;
  List<FinalAPSegment> segments = [];
  List<SegmentDataLocal> _segmentsLocal = [];

  waveforms.RecorderController? _recorderController;

  bool _isLoading = true;
  bool _isRecorderReady = false;
  bool _isRecording = false;
  bool _isUploading = false;

  int _currentPage = 0;

  double _uploadProgress = 0;
  String _uploadStatusMessage = '';

  // ---------- Page helpers (MATCHES WritingScreen) ----------

  bool get _isSegmentPage =>
      _currentPage > 0 && _currentPage <= _segmentsLocal.length;

  int get _segmentIndex => _currentPage - 1;

  bool get _isSubmitPage => _currentPage == _segmentsLocal.length + 1;

  bool get _canSubmit => _segmentsLocal.every((s) => s.audioPath != null);

  int get _completedCount =>
      _segmentsLocal.where((s) => s.audioPath != null).length;

  // ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recorderController?.dispose();
    for (final seg in _segmentsLocal) {
      seg.playerController?.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    await _fetchAnchorPoint();
    await _checkPermissions();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAnchorPoint() async {
    final ap = await AnchorPoint.fromJsonAsync(
      await SupabaseAnchorPointSource().getAnchorPoint(widget.anchorPointId),
    );

    setState(() {
      anchorPoint = ap;
      segments = ap.finalSegments ?? [];
      _segmentsLocal = segments.map((s) {
        return SegmentDataLocal(
          id: _uuid.v4(),
          original: s,
          text: s.text ?? 'No text provided',
        );
      }).toList();
    });
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;

    if (Platform.isAndroid) {
      await Permission.storage.request();
    }

    setState(() => _isRecorderReady = true);
  }

  // ---------- Recording ----------

  Future<String> _tempFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${_uuid.v4()}.m4a';
  }

  Future<void> _startRecording() async {
    if (!_isSegmentPage || !_isRecorderReady) return;

    final seg = _segmentsLocal[_segmentIndex];
    _deleteRecordingInternal(seg);

    _recorderController?.dispose();
    _recorderController = waveforms.RecorderController();

    final path = await _tempFilePath();
    await _recorderController!.record(path: path);

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || !_isSegmentPage) return;

    final path = await _recorderController!.stop();
    _recorderController?.dispose();
    _recorderController = null;

    if (path == null) return;

    final seg = _segmentsLocal[_segmentIndex];
    seg.audioPath = path;
    await _preparePlayer(seg);

    setState(() => _isRecording = false);
  }

  Future<void> _preparePlayer(SegmentDataLocal seg) async {
    seg.playerController?.dispose();
    seg.playerController = waveforms.PlayerController();

    await seg.playerController!.preparePlayer(
      path: seg.audioPath!,
      shouldExtractWaveform: true,
    );

    seg.playerController!.onPlayerStateChanged.listen((state) {
      setState(() {
        seg.isPlaying = state == waveforms.PlayerState.playing;
      });
    });
  }

  void _deleteRecordingInternal(SegmentDataLocal seg) {
    seg.playerController?.dispose();
    seg.playerController = null;

    if (seg.audioPath != null) {
      File(seg.audioPath!).deleteSync();
      seg.audioPath = null;
    }
  }

  // ---------- Upload ----------

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    final client = Supabase.instance.client;
    final user = client.auth.currentUser!;
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    for (int i = 0; i < _segmentsLocal.length; i++) {
      final seg = _segmentsLocal[i];
      final bytes = await File(seg.audioPath!).readAsBytes();

      await client.storage
          .from(widget.supabaseBucket)
          .uploadBinary('${user.id}/$ts-$i.m4a', bytes);

      setState(() => _uploadProgress = (i + 1) / _segmentsLocal.length);
    }

    Navigator.pop(context, true);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context).translate;

    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('record_screen_title')),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$_completedCount/${_segmentsLocal.length}'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicators (MATCHES WritingScreen)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 5,
              children: List.generate(_segmentsLocal.length + 2, (i) {
                if (i == 0) {
                  return Icon(
                    FontAwesomeIcons.circle,
                    color: _currentPage == 0
                        ? colorScheme.onSurface
                        : colorScheme.tertiary,
                    size: 12,
                  );
                } else if (i == _segmentsLocal.length + 1) {
                  return Icon(
                    FontAwesomeIcons.paperPlane,
                    color: _currentPage == i
                        ? colorScheme.onSurface
                        : colorScheme.tertiary,
                    size: 12,
                  );
                } else {
                  final seg = _segmentsLocal[i - 1];
                  return Icon(
                    seg.audioPath != null
                        ? FontAwesomeIcons.solidSquare
                        : FontAwesomeIcons.square,
                    color: _currentPage == i
                        ? colorScheme.onSurface
                        : seg.audioPath != null
                        ? colorScheme.secondary
                        : colorScheme.primary,
                  );
                }
              }),
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _segmentsLocal.length + 2,
              onPageChanged: (i) async {
                if (_isRecording) await _stopRecording();
                setState(() => _currentPage = i);
              },
              itemBuilder: (_, i) {
                if (i == 0) return const SizedBox();
                if (i == _segmentsLocal.length + 1) {
                  return _buildSubmitPage();
                }
                return _buildSegmentPage(_segmentsLocal[i - 1]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isSegmentPage ? _buildControls() : null,
    );
  }

  Widget _buildSegmentPage(SegmentDataLocal seg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WholeSymbol(symbol: seg.original.segmentData.symbol),
              const SizedBox(width: 16),
              Text(seg.original.segmentData.name),
            ],
          ),
          const SizedBox(height: 24),
          Text(seg.text),
          const SizedBox(height: 24),
          if (_isRecording)
            waveforms.AudioWaveforms(
              recorderController: _recorderController!,
              size: const Size(double.infinity, 80),
            )
          else if (seg.playerController != null)
            waveforms.AudioFileWaveforms(
              playerController: seg.playerController!,
              size: const Size(double.infinity, 80),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final seg = _segmentsLocal[_segmentIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          WholeButton(
            icon: _isRecording
                ? FontAwesomeIcons.stop
                : FontAwesomeIcons.microphone,
            text: _isRecording ? 'Stop' : 'Record',
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          WholeButton(
            icon: FontAwesomeIcons.play,
            onPressed: seg.playerController != null
                ? seg.playerController!.startPlayer
                : null,
          ),
          WholeButton(
            icon: FontAwesomeIcons.trash,
            onPressed: seg.audioPath != null
                ? () => setState(() => _deleteRecordingInternal(seg))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitPage() {
    return Center(
      child: _isUploading
          ? LinearProgressIndicator(value: _uploadProgress)
          : ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Submit'),
            ),
    );
  }
}

// ---------- Model ----------

class SegmentDataLocal {
  final String id;
  final FinalAPSegment original;
  final String text;

  String? audioPath;
  waveforms.PlayerController? playerController;
  bool isPlaying = false;

  SegmentDataLocal({
    required this.id,
    required this.original,
    required this.text,
  });
}
