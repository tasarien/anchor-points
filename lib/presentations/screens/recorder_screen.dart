import 'dart:io';
import 'dart:typed_data';

import 'package:action_slider/action_slider.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/final_ap_segment.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/data/sources/request_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/crafting_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/page_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/record_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/section_tab.dart';
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
import 'dart:async'; // Added for StreamSubscription

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

  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  static const int _maxRecordingSeconds = 35;

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
    _recordingTimer?.cancel(); // Add this line
    for (final seg in _segmentsLocal) {
      seg.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    await _fetchAnchorPoint();
    debugPrint('here');
    await _checkPermissions();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAnchorPoint() async {
    final ap = await AnchorPoint.fromJsonAsync(
      await SupabaseAnchorPointSource().getAnchorPoint(widget.anchorPointId),
    );

    if (mounted) {
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
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.request();
    debugPrint('Microphone permission: ${mic.isGranted}');

    if (!mic.isGranted) {
      if (mic.isDenied) {
        debugPrint('❌ Microphone permission denied');
        _showPermissionDialog(
          'Microphone',
          'This app needs microphone access to record audio.',
        );
      } else if (mic.isPermanentlyDenied) {
        debugPrint('❌ Microphone permission permanently denied');
        _showPermissionDialog(
          'Microphone',
          'Microphone permission is permanently denied. Please enable it in app settings.',
          openSettings: true,
        );
      }
      return;
    }

    if (Platform.isAndroid) {
      final storage = await Permission.storage.request();
      if (!storage.isGranted) {
        if (storage.isDenied) {
          debugPrint('❌ Storage permission denied');
          _showPermissionDialog(
            'Storage',
            'This app needs storage access to save recordings.',
          );
        } else if (storage.isPermanentlyDenied) {
          debugPrint('❌ Storage permission permanently denied');
          _showPermissionDialog(
            'Storage',
            'Storage permission is permanently denied. Please enable it in app settings.',
            openSettings: true,
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _isRecorderReady = true);
    }
  }

  void _showPermissionDialog(
    String title,
    String message, {
    bool openSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (openSettings)
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  // ---------- Recording ----------

  Future<String> _tempFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${_uuid.v4()}.m4a';
  }

  Future<void> _startRecording() async {
    debugPrint('🎙 Record button pressed');

    if (!_isSegmentPage) {
      debugPrint('❌ Not on segment page');
      return;
    }

    if (!_isRecorderReady) {
      debugPrint('❌ Recorder not ready');
      return;
    }

    final seg = _segmentsLocal[_segmentIndex];
    _deleteRecordingInternal(seg);

    _recorderController?.dispose();
    _recorderController = waveforms.RecorderController();

    final path = await _tempFilePath();
    await _recorderController!.record(path: path);

    // Start timer
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }

      // Auto-stop at 35 seconds
      if (_recordingSeconds >= _maxRecordingSeconds) {
        _stopRecording();
      }
    });

    if (mounted) {
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || !_isSegmentPage) return;

    // Cancel timer
    _recordingTimer?.cancel();
    _recordingTimer = null;

    final path = await _recorderController!.stop();
    _recorderController?.dispose();
    _recorderController = null;

    if (path == null) return;

    final seg = _segmentsLocal[_segmentIndex];
    seg.audioPath = path;
    await _preparePlayer(seg);

    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
    }
  }

  Future<void> _preparePlayer(SegmentDataLocal seg) async {
    seg.playerController?.dispose();
    seg.playerSubscription?.cancel();

    seg.playerController = waveforms.PlayerController();

    await seg.playerController!.preparePlayer(
      path: seg.audioPath!,
      shouldExtractWaveform: true,
    );

    // Store subscription and check mounted before setState
    seg.playerSubscription = seg.playerController!.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          seg.isPlaying = state == waveforms.PlayerState.playing;
        });
      }
    });
  }

  void _deleteRecordingInternal(SegmentDataLocal seg) {
    seg.playerSubscription?.cancel();
    seg.playerController?.dispose();
    seg.playerController = null;

    if (seg.audioPath != null) {
      File(seg.audioPath!).deleteSync();
      seg.audioPath = null;
    }
  }

  bool _isAllSegmentsReady() {
    return _segmentsLocal.every((segment) => segment.audioPath != null);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final getText = AppLocalizations.of(context).translate;
    final DataProvider appData = context.watch<DataProvider>();

    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 20,
          children: [
            IconButton(
              onPressed: () async {
                Navigator.pop(context);
                await Future.delayed(Duration(milliseconds: 300));
                appData.changeTabVisibility(true);
              },
              icon: FaIcon(FontAwesomeIcons.chevronLeft, size: 18),
            ),
            Text(getText("record_screen_title")),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$_completedCount/${_segmentsLocal.length}'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: PageIndicator(
              segmentsLength: segments.length,
              currentPage: _currentPage,
              canSubmit: _canSubmit,
              completed: _segmentsLocal
                  .map((segment) => segment.audioPath != null)
                  .toList(),
            ),
          ),

          Expanded(
            child: PageView.builder(
              physics: _isRecording
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              controller: _pageController,
              itemCount: _segmentsLocal.length + 2,
              onPageChanged: (i) async {
                if (_isRecording) await _stopRecording();
                if (mounted) {
                  setState(() => _currentPage = i);
                }
              },
              itemBuilder: (_, i) {
                if (i == 0) return _buildRequestPage();
                if (i == _segmentsLocal.length + 1) {
                  return _buildSubmitPage();
                }
                return _buildSegmentPage(_segmentsLocal[i - 1]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final getText = AppLocalizations.of(context).translate;
    final request = anchorPoint.request;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: Icon(
                FontAwesomeIcons.microphone,
                size: 36,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            getText("audio_recording_request"),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Request information card
          if (request != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getText("request_details"),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      FontAwesomeIcons.user,
                      getText("requested_by"),
                      request.audioRequest.companionType == CompanionType.you
                          ? getText('yourself')
                          : request.audioRequest.companionUsername ??
                                getText("unknown"),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      FontAwesomeIcons.calendar,
                      getText("created_at"),
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(request.audioRequest.createdAt),
                    ),
                    if (request.audioRequest.message != null &&
                        request.audioRequest.message!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        getText("message"),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.audioRequest.message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Get started button
          SizedBox(
            width: double.infinity,
            child: WholeButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: Durations.medium1,
                  curve: Curves.easeIn,
                );
              },
              icon: FontAwesomeIcons.arrowRight,
              text: getText("get_started"),
              wide: true,
            ),
          ),

          const SizedBox(height: 30),

          // Instructions
          SectionTab(
            text: getText('record_request_info'),
            content: Column(
              children: [
                Text(
                  getText("how_to_record"),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildInstructionItem("1", getText("swipe_through_segments")),
                _buildInstructionItem(
                  "2",
                  getText("tap_record_button_instruction"),
                ),
                _buildInstructionItem("3", getText("recording_auto_stops")),
                _buildInstructionItem("4", getText("review_and_rerecord")),
                _buildInstructionItem("5", getText("submit_all_recordings")),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPage(SegmentDataLocal seg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(10),
                child: Text(seg.text, style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 24),

              // Add timer display
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.clock,
                      size: 16,
                      color: _recordingSeconds > 30 ? Colors.red : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_recordingSeconds}s / ${_maxRecordingSeconds}s',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _recordingSeconds > 30 ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          _buildControls(seg),
        ],
      ),
    );
  }

  Widget _buildControls(SegmentDataLocal seg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RecordButton(
            isRecording: _isRecording,
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              WholeButton(
                icon: FontAwesomeIcons.trash,
                text: 'delete',
                disabled: seg.playerController == null,
                onPressed: seg.audioPath != null
                    ? () {
                        if (mounted) {
                          setState(() => _deleteRecordingInternal(seg));
                        }
                      }
                    : null,
              ),
              WholeButton(
                icon: FontAwesomeIcons.play,
                text: 'play',
                disabled: seg.playerController == null,
                onPressed: seg.playerController != null
                    ? seg.playerController!.startPlayer
                    : null,
              ),
              WholeButton(
                wide: seg.audioPath != null,
                suggested: seg.audioPath != null,
                onPressed: () {
                  _pageController.nextPage(
                    duration: Durations.long4,
                    curve: Curves.ease,
                  );
                },
                text: seg.audioPath != null ? "next" : null,
                icon: FontAwesomeIcons.arrowRight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitPage() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final DataProvider appData = context.watch<DataProvider>();
    bool _canSubmit() {
      return false;
    }

    List<Widget> _buildSummaryItems() {
      return _segmentsLocal.map((seg) {
        final hasRecording = seg.audioPath != null;
        final isUploaded = seg.uploaded;

        final color = isUploaded
            ? Colors.green
            : hasRecording
            ? Colors.orange
            : Colors.red;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isUploaded
                        ? FontAwesomeIcons.checkCircle
                        : hasRecording
                        ? FontAwesomeIcons.circle
                        : FontAwesomeIcons.exclamationCircle,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      seg.original.segmentData.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isUploaded ? 1.0 : (hasRecording ? 0.5 : 0.0),
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList();
    }

    return Center(
      child: _isUploading
          ? LinearProgressIndicator(value: _uploadProgress)
          : Column(
              children: [
                const SizedBox(height: 40),

                // Completion icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _canSubmit()
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                  ),
                  child: Icon(
                    _canSubmit() ? Icons.check_circle : Icons.pending,
                    size: 60,
                    color: _canSubmit() ? Colors.green : Colors.orange,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  _canSubmit() ? 'Upload recordings.' : 'Not ready yet.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  _canSubmit()
                      ? 'All records can be submitted now.'
                      : 'Not all segments are recorded. ',
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
                      children: _buildSummaryItems(),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                ActionSlider.standard(
                  child: Text("submit_ap_audio"),
                  loadingIcon: CircularProgressIndicator(),
                  toggleColor: colorScheme.tertiary,
                  rolling: true,
                  icon: FaIcon(
                    AnchorPointIcons.anchor_point_step3,
                    color: colorScheme.onSurface,
                    size: 40,
                  ),
                  successIcon: FaIcon(FontAwesomeIcons.check),
                  failureIcon: FaIcon(FontAwesomeIcons.xmark),
                  action: (controller) async {
                    controller.loading();
                    await Future.delayed(Durations.extralong4);
                    if (_isAllSegmentsReady()) {
                      List<String> allUrls = [];
                      for (int i = 0; i < _segmentsLocal.length; i++) {
                        final segment = _segmentsLocal[i];
                        try {
                          String segmentUrl = await SupabaseAnchorPointSource()
                              .uploadAudioFile(
                                segment.audioPath!,
                                anchorPoint.id.toString(),
                                '${i}_${segment.original.segmentData.name}',
                              );
                          if (mounted) {
                            setState(() {
                              _segmentsLocal[i].uploaded = true;
                            });
                          }
                          allUrls.add(segmentUrl);
                        } catch (e) {
                          debugPrint(e.toString());
                        }
                      }

                      await anchorPoint.request!.changeStatus(
                        RequestStatus.completed,
                        RequestType.audio,
                      );

                      SupabaseAnchorPointSource().updateAnchorPoint(
                        anchorPoint.id,
                        {'segments_audio': allUrls, 'status': 'crafted'},
                      );

                      controller.success();

                      await Future.delayed(Durations.extralong1);
                      if (mounted) {
                        appData.refreshAnchorPoint(anchorPoint.id);
                        Navigator.pop(context);
                        appData.changeTabVisibility(true);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("success_in_saving_text")),
                        );
                      }
                    } else {
                      controller.failure();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("not_all_segments_recorded")),
                      );
                      await Future.delayed(Duration(seconds: 4));
                      controller.reset();
                    }
                  },
                ),
              ],
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
  StreamSubscription? playerSubscription; // Added to track subscription
  bool isPlaying = false;
  bool uploaded = false;

  SegmentDataLocal({
    required this.id,
    required this.original,
    required this.text,
  });

  // Added dispose method to clean up resources
  void dispose() {
    playerSubscription?.cancel();
    playerController?.dispose();
  }
}
