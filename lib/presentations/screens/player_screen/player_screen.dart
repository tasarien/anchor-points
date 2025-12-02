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

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();
    _pageController = PageController();

    _setupAudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appData.changeTabVisibility(false);
      showIntroCircles(context);
    });
  }

  // Audio setup

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _totalDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _currentPosition = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_currentSegmentIndex < widget.anchorPoint.finalSegments!.length - 1) {
        goToSegment(_currentSegmentIndex + 1);
      } else {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> playAudioFor(int index) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(widget.anchorPoint.finalSegments![index].audioUrl!));
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
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
    await _audioPlayer.seek(position);
  }

  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 10,
          children: [
            SizedBox(width: 20),
            FaIcon(AnchorPointIcons.anchor_point_icon),
            Text(widget.anchorPoint.name!),
          ],
        ),
      ),
      body: Column(
        spacing: 10,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.anchorPoint.finalSegments!.length,
              onPageChanged: (index) {
                _currentSegmentIndex = index;
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
                              border: Border.all(color: colorScheme.primary),
                            ),
                            padding: const EdgeInsets.all(10),
                            clipBehavior: Clip.hardEdge,
                            child: SingleChildScrollView(
                              child: Text(
                                seg.text!,
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
                              SliderTheme(
                                data: SliderTheme.of(
                                  context,
                                ).copyWith(trackHeight: 3),
                                child: Slider(
                                  value: _currentPosition.inSeconds.toDouble(),
                                  max: _totalDuration.inSeconds.toDouble() > 0
                                      ? _totalDuration.inSeconds.toDouble()
                                      : 1.0,
                                  onChanged: (value) {
                                    seekTo(Duration(seconds: value.toInt()));
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    formatDuration(_totalDuration),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 5,
                      children: List.generate(widget.anchorPoint.finalSegments!.length, (i) {
                        final seg = widget.anchorPoint.finalSegments![i].segmentData;

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
                                    fontWeight: _currentSegmentIndex == i
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
                      onPressed: _currentSegmentIndex > 0
                          ? () => goToSegment(_currentSegmentIndex - 1)
                          : null,
                      icon: FontAwesomeIcons.leftLong,
                    ),
                    WholeButton(
                      onPressed: togglePlayPause,
                      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    WholeButton(
                      onPressed:
                          _currentSegmentIndex < widget.anchorPoint.finalSegments!.length - 1
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
