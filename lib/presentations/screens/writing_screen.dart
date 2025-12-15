import 'package:action_slider/action_slider.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/segment_prompt_model.dart';
import 'package:anchor_point_app/data/models/writing_state.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WritingScreen extends StatefulWidget {
  final int anchorPointId;
  final String supabaseBucket;
  final int minWordCount;

  const WritingScreen({
    Key? key,
    required this.anchorPointId,
    this.supabaseBucket = 'text-segments',
    this.minWordCount = 50,
  }) : super(key: key);

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  late PageController _pageController;

  late AnchorPoint anchorPoint;
  List<SegmentPrompt> segments = [];

  int _currentPage = 0;
  bool _isSubmitting = false;

  bool _loading = false;

  Map<int, WritingState> _writingStates = {};
  Map<int, TextEditingController> _textControllers = {};
  Map<int, FocusNode> _focusNodes = {};

  // Simple placeholder for localization logic
  String getText(text) {
    return AppLocalizations.of(context).translate(text);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _initializeWritingStates();
  }

  Future<void> _fetchAnchorPoint() async {
    setState(() {
      _loading = true;
    });

    final AnchorPoint ap = await AnchorPoint.fromJsonAsync(
      await SupabaseAnchorPointSource().getAnchorPoint(widget.anchorPointId),
    );

    setState(() {
      anchorPoint = ap;
      segments = ap.segmentPrompts ?? [];
      _loading = false;
    });
  }

  void _initializeWritingStates() async {
    await _fetchAnchorPoint();
    for (int i = 0; i < segments.length; i++) {
      _writingStates[i] = WritingState();
      _textControllers[i] = TextEditingController();
      _focusNodes[i] = FocusNode();

      _textControllers[i]!.addListener(() {
        _updateWritingState(i);
      });
    }
  }

  void _updateWritingState(int index) {
    final text = _textControllers[index]!.text;
    final wordCount = _countWords(text);

    final isComplete =
        wordCount >= widget.minWordCount && text.trim().isNotEmpty;

    setState(() {
      _writingStates[index] = WritingState(
        text: text,
        isComplete: isComplete,
        wordCount: wordCount,
      );
    });
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  bool _canSubmit() {
    return _writingStates.values.every((state) => state.isComplete);
  }

  int _getCompletedCount() {
    return _writingStates.values.where((state) => state.isComplete).length;
  }

  Future<void> _submitWritings() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;

      // TODO upload to supabase as text

      await Future.delayed(Durations.medium1);

      if (mounted) {
        Navigator.of(context).pop({
          'completed': true,
          'segments': segments.length,
          'totalWords': _writingStates.values.fold(
            0,
            (sum, state) => sum + state.wordCount,
          ),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getText('snackbarUploadSuccess'))),
        );
      }
    } catch (e) {
      _showError(getText('errorUploadFailed'));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearCurrentText() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getText('dialogClearTitle')),
        content: Text(getText('dialogClearContent')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getText('dialogClearActionCancel')),
          ),
          TextButton(
            onPressed: () {
              _textControllers[_currentPage]!.clear();
              Navigator.pop(context);
            },
            child: Text(
              getText('dialogClearActionClear'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    DataProvider appData = context.watch<DataProvider>();
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
            Text(getText("writing_screen_title")),
          ],
        ),
      ),
      body: _loading
          ? Center(child: LoadingIndicator())
          : Column(
              children: [
                // Page indicator with status
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    spacing: 10,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(getText('segments') + ": "),
                          Text('${_currentPage + 1}/${segments.length}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(segments.length + 1, (index) {
                          if (index == segments.length) {
                            // Submit page arrow
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: FaIcon(
                                FontAwesomeIcons.paperPlane,
                                size: 12,
                                color: _currentPage == index
                                    ? colorScheme.onSurface
                                    : _canSubmit()
                                    ? colorScheme.secondary
                                    : colorScheme.tertiary,
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
                                color: _writingStates[index]?.isComplete == true
                                    ? colorScheme.secondary
                                    : index == _currentPage
                                    ? colorScheme.onSurface
                                    : colorScheme.primary,
                              ),
                            );
                          }
                        }),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: segments.length + 1, // +1 for submit page
                    onPageChanged: (index) {
                      // Unfocus previous page if it's a writing page
                      if (_currentPage < segments.length) {
                        _focusNodes[_currentPage]?.unfocus();
                      }
                      setState(() => _currentPage = index);
                      // Focus new page after a brief delay if it's a writing page
                      if (index < segments.length) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _focusNodes[index]?.requestFocus();
                        });
                      }
                    },
                    itemBuilder: (context, index) {
                      if (index == segments.length) {
                        return _buildSubmitPage();
                      }
                      return _buildSegmentPage(segments[index], index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubmitPage() {
    final totalWords = _writingStates.values.fold(
      0,
      (sum, state) => sum + state.wordCount,
    );

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
            _canSubmit()
                ? getText('submitPageTitleReady')
                : getText('submitPageTitleNotReady'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            _canSubmit()
                ? getText('submitPageDescriptionReady')
                : getText('submitPageDescriptionNotReady'),
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
                    getText('submitPageSummaryTitle'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    Icons.article,
                    getText('submitPageSegmentsLabel'),
                    '${segments.length}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.check_circle,
                    getText('submitPageCompletedLabel'),
                    '${_getCompletedCount()}/${segments.length}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.text_fields,
                    getText('submitPageTotalWordsLabel'),
                    '$totalWords',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          ActionSlider.standard(),

          // Submit button
          if (_canSubmit())
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWritings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const LoadingIndicator()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send),
                          const SizedBox(width: 8),
                          Text(
                            getText('submitPageSubmitButton'),
                            style: const TextStyle(
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
                  // Navigate back to first incomplete segment
                  for (int i = 0; i < segments.length; i++) {
                    if (!(_writingStates[i]?.isComplete ?? false)) {
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
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 8),
                    Text(
                      getText('submitPageContinueButton'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildSegmentPage(SegmentPrompt segment, int index) {
    final state = _writingStates[index]!;
    final isComplete = state.isComplete;
    final wordsNeeded = widget.minWordCount - state.wordCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segment info header
          Row(
            children: [
              WholeSymbol(symbol: segment.segmentData.symbol, selected: false),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      segment.segmentData.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isComplete ? Icons.check_circle : Icons.edit,
                          color: isComplete ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          getText('segmentWordCount'),
                          style: TextStyle(
                            color: isComplete ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isComplete && state.wordCount > 0) ...[
                          Text(
                            getText('segmentWordsNeeded'),
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Prompt card
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    SizedBox(width: 10),
                    Text(
                      getText('writing_prompts'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(segment.prompt),
                ),

                const SizedBox(height: 24),

                // Text editor
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getText('textFieldTitle'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (state.text.isNotEmpty)
                          TextButton.icon(
                            onPressed: _clearCurrentText,
                            icon: const Icon(Icons.clear, size: 18),
                            label: Text(getText('textFieldClearButton')),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isComplete
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _textControllers[index],
                        focusNode: _focusNodes[index],
                        maxLines: null,
                        minLines: 12,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                        decoration: InputDecoration(
                          hintText: getText('textFieldHint'),
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    if (state.wordCount > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: (state.wordCount / widget.minWordCount)
                                .clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade200,
                            color: isComplete
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isComplete
                                ? getText('progressComplete')
                                : getText('progressMinRequired'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isComplete
                                  ? Colors.green
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
