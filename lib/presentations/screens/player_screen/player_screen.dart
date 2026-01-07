import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/final_ap_segment.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:anchor_point_app/presentations/widgets/utilities/show_intro_circles.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class PlayerScreen extends StatefulWidget {
  final AnchorPoint anchorPoint;
  final DataProvider appData;

  const PlayerScreen({
    Key? key,
    required this.anchorPoint,
    required this.appData,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late PageController _pageController;

  int _currentSegmentIndex = 0;
  bool _isPlaying = false;
  bool _hasStartedPlaying = false;
  bool _isLoadingAudio = false;
  String? _errorMessage;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();
    _pageController = PageController();

    // Set Darwin-specific audio configuration
    _configureAudioPlayer();
    _setupAudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.appData.changeTabVisibility(false);
      await showIntroCircles(context);
      // Auto-play first segment after intro circles
      _startPlayback();
    });
  }

  // Start playback of first segment
  Future<void> _startPlayback() async {
    if (widget.anchorPoint.finalSegments != null &&
        widget.anchorPoint.finalSegments!.isNotEmpty &&
        !_hasStartedPlaying) {
      _hasStartedPlaying = true;
      await playAudioFor(0);
    }
  }

  // Configure audio player for Darwin (iOS/macOS) platforms
  Future<void> _configureAudioPlayer() async {
    try {
      // Set audio context for iOS - allows playback with silent switch on
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      // Set release mode to stop after completion
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      print('Error configuring audio player: $e');
    }
  }

  // Audio setup
  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          // Clear loading state when playing or paused
          if (state == PlayerState.playing || state == PlayerState.paused) {
            _isLoadingAudio = false;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) async {
      // Check if there's a next segment
      if (_currentSegmentIndex < widget.anchorPoint.finalSegments!.length - 1) {
        // Auto-advance to next segment
        await goToSegment(_currentSegmentIndex + 1);
      } else {
        // Last segment completed - show dialog
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
          _showCompletionDialog();
        }
      }
    });
  }

  Future<void> playAudioFor(int index) async {
    final segment = widget.anchorPoint.finalSegments![index];

    // Check if audio URL exists
    if (segment.audioUrl == null || segment.audioUrl!.isEmpty) {
      print('No audio URL for segment $index');
      _showError('No audio available for this segment');
      return;
    }

    setState(() {
      _isLoadingAudio = true;
      _errorMessage = null;
    });

    try {
      // Stop current playback
      await _audioPlayer.stop();

      // Small delay to ensure audio session is ready (Darwin fix)
      await Future.delayed(const Duration(milliseconds: 100));

      // Play new audio
      await _audioPlayer.play(UrlSource(segment.audioUrl!));

      setState(() {
        _isLoadingAudio = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('Error playing audio for segment $index: $e');

      String errorMsg = 'Failed to play audio';

      // Handle specific Darwin audio errors
      if (e.toString().contains('AVAudioSession')) {
        errorMsg = 'Audio session error. Please restart the app.';
      } else if (e.toString().contains('interrupted')) {
        errorMsg = 'Audio interrupted. Retrying...';
        // Attempt to retry after interruption
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await _audioPlayer.play(UrlSource(segment.audioUrl!));
          setState(() {
            _isLoadingAudio = false;
            _errorMessage = null;
          });
          return;
        } catch (retryError) {
          errorMsg = 'Failed to resume audio after interruption';
        }
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMsg = 'Network error. Check your internet connection.';
      } else if (e.toString().contains('format') ||
          e.toString().contains('codec')) {
        errorMsg = 'Audio format not supported';
      }

      _showError(errorMsg);

      setState(() {
        _isLoadingAudio = false;
        _errorMessage = errorMsg;
        _isPlaying = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            playAudioFor(_currentSegmentIndex);
          },
        ),
      ),
    );
  }

  Future<void> togglePlayPause() async {
    if (_isLoadingAudio) return; // Prevent toggle while loading

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (!_hasStartedPlaying) {
          _hasStartedPlaying = true;
          await playAudioFor(_currentSegmentIndex);
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      _showError('Failed to ${_isPlaying ? 'pause' : 'play'} audio');

      // If resume fails, try to restart the segment
      if (!_isPlaying) {
        await playAudioFor(_currentSegmentIndex);
      }
    }
  }

  Future<void> goToSegment(int index) async {
    if (index < 0 || index >= widget.anchorPoint.finalSegments!.length) return;

    setState(() {
      _currentSegmentIndex = index;
      _currentPosition = Duration.zero;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    await playAudioFor(index);
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking to position: $e');
      // On Darwin, seeking can fail if audio isn't ready
      // Silently fail as this is usually not critical
    }
  }

  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context).translate('playback_complete') ??
                'Playback Complete',
          ),
          content: Text(
            AppLocalizations.of(context).translate('all_segments_played') ??
                'You have completed all segments of this anchor point.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                goToSegment(0); // Restart from beginning
              },
              child: Text(
                AppLocalizations.of(context).translate('replay') ?? 'Replay',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit player screen
                widget.appData.changeTabVisibility(true);
              },
              child: Text(
                AppLocalizations.of(context).translate('close') ?? 'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _pageController.dispose();
    widget.appData.changeTabVisibility(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    DataProvider appData = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                appData.changeTabVisibility(true);
              },
              icon: FaIcon(FontAwesomeIcons.chevronLeft),
            ),
            Row(
              spacing: 10,
              children: [
                SizedBox(width: 20),
                FaIcon(AnchorPointIcons.anchor_point_icon),
                Text(widget.anchorPoint.name ?? ''),
              ],
            ),
          ],
        ),
      ),
      body:
          widget.anchorPoint.finalSegments == null ||
              widget.anchorPoint.finalSegments!.isEmpty
          ? Center(
              child: Text(
                getText('no_segments_available') ?? 'No segments available',
              ),
            )
          : Column(
              spacing: 10,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.anchorPoint.finalSegments!.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentSegmentIndex = index;
                      });
                      playAudioFor(index);
                    },
                    itemBuilder: (context, index) {
                      final seg = widget.anchorPoint.finalSegments![index];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 10,
                            children: [
                              // text
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  clipBehavior: Clip.hardEdge,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      seg.text ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),

                              // Slider
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                child: Column(
                                  children: [
                                    // Show loading indicator or error message
                                    if (_isLoadingAudio)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 8.0),
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    else if (_errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    SliderTheme(
                                      data: SliderTheme.of(
                                        context,
                                      ).copyWith(trackHeight: 3),
                                      child: Slider(
                                        value: _currentPosition.inSeconds
                                            .toDouble(),
                                        max:
                                            _totalDuration.inSeconds
                                                    .toDouble() >
                                                0
                                            ? _totalDuration.inSeconds
                                                  .toDouble()
                                            : 1.0,
                                        onChanged: _isLoadingAudio
                                            ? null
                                            : (value) {
                                                seekTo(
                                                  Duration(
                                                    seconds: value.toInt(),
                                                  ),
                                                );
                                              },
                                      ),
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatDuration(_currentPosition),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        Text(
                                          formatDuration(_totalDuration),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Segment Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Card(
                    child: SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: ScrollController(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            spacing: 5,
                            children: List.generate(
                              widget.anchorPoint.finalSegments!.length,
                              (i) {
                                final seg = widget
                                    .anchorPoint
                                    .finalSegments![i]
                                    .segmentData;

                                return GestureDetector(
                                  onTap: () => goToSegment(i),
                                  child: Column(
                                    children: [
                                      WholeSymbol(
                                        symbol: seg.symbol,
                                        selected: _currentSegmentIndex == i,
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          seg.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight:
                                                _currentSegmentIndex == i
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          WholeButton(
                            onPressed:
                                _currentSegmentIndex > 0 && !_isLoadingAudio
                                ? () => goToSegment(_currentSegmentIndex - 1)
                                : null,
                            icon: FontAwesomeIcons.leftLong,
                          ),
                          WholeButton(
                            onPressed: _isLoadingAudio ? null : togglePlayPause,
                            icon: _isLoadingAudio
                                ? Icons.hourglass_empty
                                : (_isPlaying ? Icons.pause : Icons.play_arrow),
                          ),
                          WholeButton(
                            onPressed:
                                _currentSegmentIndex <
                                        widget
                                                .anchorPoint
                                                .finalSegments!
                                                .length -
                                            1 &&
                                    !_isLoadingAudio
                                ? () => goToSegment(_currentSegmentIndex + 1)
                                : null,
                            icon: FontAwesomeIcons.rightLong,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
