import 'package:anchor_point_app/data/models/segment_prompt_model.dart';
import 'package:anchor_point_app/data/models/writing_state.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// NOTE: In a real app, this would use an internationalization package (e.g., flutter_gen/l10n).
// For this example, we use a simple getText method.

class WritingScreen extends StatefulWidget {
  final List<SegmentPrompt> segments;
  final String supabaseBucket;
  final int minWordCount;

  const WritingScreen({
    Key? key,
    required this.segments,
    this.supabaseBucket = 'text-segments',
    this.minWordCount = 50,
  }) : super(key: key);

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  late PageController _pageController;

  int _currentPage = 0;
  bool _isSubmitting = false;

  Map<int, WritingState> _writingStates = {};
  Map<int, TextEditingController> _textControllers = {};
  Map<int, FocusNode> _focusNodes = {};

  // Simple placeholder for localization logic
  String _getText(String key, {Map<String, dynamic>? args}) {
    // In a real app, you would look up the key in a map based on the current locale
    // and replace any placeholders with values from 'args'.
    switch (key) {
      case 'appBarTitle':
        return 'Write Segments';
      case 'submitTooltip':
        return 'Submit All';
      case 'snackbarUploadSuccess':
        return 'All writings uploaded successfully!';
      case 'errorUploadFailed':
        return 'Failed to upload writings: ${args?['error']}';
      case 'dialogClearTitle':
        return 'Clear Text';
      case 'dialogClearContent':
        return 'Are you sure you want to clear all text for this segment?';
      case 'dialogClearActionCancel':
        return 'Cancel';
      case 'dialogClearActionClear':
        return 'Clear';
      case 'segmentWordCount':
        return '${args?['count']} words';
      case 'segmentWordsNeeded':
        return ' (${args?['needed']} more needed)';
      case 'promptCardTitle':
        return 'Writing Prompt';
      case 'textFieldTitle':
        return 'Your Writing';
      case 'textFieldClearButton':
        return 'Clear';
      case 'textFieldHint':
        return 'Start writing here...';
      case 'progressMinRequired':
        return 'Minimum ${widget.minWordCount} words required';
      case 'progressComplete':
        return 'Complete! Great work!';
      default:
        return 'Missing Text for key: $key';
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeWritingStates();
  }

  void _initializeWritingStates() {
    for (int i = 0; i < widget.segments.length; i++) {
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
    final isComplete = wordCount >= widget.minWordCount && text.trim().isNotEmpty;

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
          'segments': widget.segments.length,
          'totalWords': _writingStates.values.fold(0, (sum, state) => sum + state.wordCount),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getText('snackbarUploadSuccess'))),
        );
      }
    } catch (e) {
      _showError(_getText('errorUploadFailed', args: {'error': e.toString()}));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearCurrentText() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('dialogClearTitle')),
        content: Text(_getText('dialogClearContent')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('dialogClearActionCancel')),
          ),
          TextButton(
            onPressed: () {
              _textControllers[_currentPage]!.clear();
              Navigator.pop(context);
            },
            child: Text(_getText('dialogClearActionClear'), style: const TextStyle(color: Colors.red)),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_getText('appBarTitle')),
        actions: [
          // Progress indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_getCompletedCount()}/${widget.segments.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Submit button
          if (_canSubmit())
            _isSubmitting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _submitWritings,
                    tooltip: _getText('submitTooltip'),
                  ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator with status
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
                    color: _writingStates[index]?.isComplete == true
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
                // Unfocus previous page
                _focusNodes[_currentPage]?.unfocus();
                setState(() => _currentPage = index);
                // Focus new page after a brief delay
                Future.delayed(const Duration(milliseconds: 300), () {
                  _focusNodes[index]?.requestFocus();
                });
              },
              itemBuilder: (context, index) {
                return _buildSegmentPage(widget.segments[index], index);
              },
            ),
          ),
        ],
      ),
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
                          _getText('segmentWordCount', args: {'count': state.wordCount}),
                          style: TextStyle(
                            color: isComplete ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isComplete && state.wordCount > 0) ...[
                          Text(
                            _getText('segmentWordsNeeded', args: {'needed': wordsNeeded}),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getText('promptCardTitle'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  segment.prompt,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
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
                    _getText('textFieldTitle'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (state.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearCurrentText,
                      icon: const Icon(Icons.clear, size: 18),
                      label: Text(_getText('textFieldClearButton')),
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
                    color: isComplete ? Colors.green : Colors.grey.shade300,
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
                    hintText: _getText('textFieldHint'),
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
                      value: (state.wordCount / widget.minWordCount).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      color: isComplete ? Colors.green : Theme.of(context).primaryColor,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete
                          ? _getText('progressComplete')
                          : _getText('progressMinRequired'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isComplete ? Colors.green : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}