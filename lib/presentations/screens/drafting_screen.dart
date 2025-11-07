import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/segment_prompt_model.dart';
import 'package:anchor_point_app/presentations/widgets/drawers/emoji_picker.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_scaffold_body.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DraftingScreen extends StatefulWidget {
  final AnchorPoint anchorPoint;
  const DraftingScreen({Key? key, required this.anchorPoint}) : super(key: key);

  @override
  _DraftingScreenState createState() => _DraftingScreenState();
}

class _DraftingScreenState extends State<DraftingScreen> {
  late List<SegmentPrompt> _segmentPrompts;

  String getText(String text) => AppLocalizations.of(context).translate(text);

  @override
  void initState() {
    super.initState();
    _segmentPrompts =
        (widget.anchorPoint.segmentPrompts != null &&
            widget.anchorPoint.segmentPrompts!.isNotEmpty)
        ? List<SegmentPrompt>.from(widget.anchorPoint.segmentPrompts!)
        : [];
  }

  // --- Logic ---
  void _addSegment({int? index}) {
    setState(() {
      final newSegment = SegmentPrompt(name: "", prompt: "", symbol: "✨");
      if (index != null && index >= 0 && index < _segmentPrompts.length) {
        _segmentPrompts.insert(index + 1, newSegment);
      } else {
        _segmentPrompts.add(newSegment);
      }
    });
  }

  void _removeSegment(int index) {
    setState(() => _segmentPrompts.removeAt(index));
  }

  void _updateSegment(int index, String field, String value) {
    setState(() {
      final seg = _segmentPrompts[index];
      switch (field) {
        case 'name':
          seg.name = value;
          break;
        case 'prompt':
          seg.prompt = value;
          break;
        case 'symbol':
          seg.symbol = value;
          break;
      }
    });
  }

  void _reorderSegments(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _segmentPrompts.removeAt(oldIndex);
      _segmentPrompts.insert(newIndex, item);
    });
  }

  // --- Widgets ---
  Widget _buildAddButton({required int index}) {
    return WholeButton(
      key: ValueKey("add_button_$index"),

      onPressed: () => _addSegment(index: index),
      icon: FontAwesomeIcons.circlePlus,
      text: getText("add_segment"),
      wide: true,
      suggested: false,
    );
  }

  Widget _buildSegmentCard(int index) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final segment = _segmentPrompts[index];
    final nameController = TextEditingController(text: segment.name);
    final symbolController = TextEditingController(text: segment.symbol);
    final promptController = TextEditingController(text: segment.prompt);

    nameController.selection = TextSelection.collapsed(
      offset: nameController.text.length,
    );
    symbolController.selection = TextSelection.collapsed(
      offset: symbolController.text.length,
    );
    promptController.selection = TextSelection.collapsed(
      offset: promptController.text.length,
    );

    return Card(
      key: ValueKey("segment_card_$index"),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: GestureDetector(
                    onTap: () async {
                      String? newSymbol = await openEmojiPicker(context);
                      if (newSymbol != symbolController.text &&
                          newSymbol != null) {
                        _updateSegment(index, 'symbol', newSymbol);
                      }
                    },
                    child: WholeSymbol(symbol: symbolController.text),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: getText("segment_name"),
                      border: const OutlineInputBorder(),
                    ),
                    controller: nameController,
                    onChanged: (val) => _updateSegment(index, 'name', val),
                  ),
                ),
                const SizedBox(width: 8),

                IconButton(
                  onPressed: () => _removeSegment(index),
                  icon: const FaIcon(FontAwesomeIcons.trash),
                  color: colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: getText("segment_prompt"),
                border: const OutlineInputBorder(),
              ),
              controller: promptController,
              onChanged: (val) => _updateSegment(index, 'prompt', val),
            ),
            SizedBox(height: 8),
            _buildAddButton(index: index),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText("drafting_screen_title"))),
      body: WholeScaffoldBody(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: _segmentPrompts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getText("no_segments_yet"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAddButton(index: 0),
                    ],
                  ),
                )
              : ReorderableListView(
                  onReorder: _reorderSegments,
                  proxyDecorator: (child, index, animation) =>
                      Material(color: Colors.transparent, child: child),
                  children: [
                    for (int i = 0; i < _segmentPrompts.length; i++) ...[
                      // Each segment card
                      ReorderableDragStartListener(
                        key: ValueKey("segment_item_$i"),
                        index: i,
                        child: _buildSegmentCard(i),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
