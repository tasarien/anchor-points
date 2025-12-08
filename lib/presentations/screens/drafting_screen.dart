import 'package:action_slider/action_slider.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/segment_data.dart';
import 'package:anchor_point_app/data/models/segment_prompt_model.dart';
import 'package:anchor_point_app/data/sources/anchor_point_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/providers/settings_provider.dart';
import 'package:anchor_point_app/presentations/screens/segment_prompt_template_picker.dart';
import 'package:anchor_point_app/presentations/widgets/drawers/emoji_picker.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_popup.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_scaffold_body.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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

  void _addSegment({int? index}) {
    setState(() {
      final newSegment = SegmentPrompt(
        segmentData: SegmentData(name: "", symbol: "✨"),
        prompt: "",
      );
      if (index != null && index >= 0 && index < _segmentPrompts.length) {
        _segmentPrompts.insert(index + 1, newSegment);
      } else {
        _segmentPrompts.add(newSegment);
      }
    });
  }

  void _addSelectedSegments(List<SegmentPrompt> segments) {
    for (SegmentPrompt segment in segments) {
      _segmentPrompts.add(segment);
    }
    setState(() {});
    if (_segmentPrompts.length > 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getText("use_only_seven_segments"))),
      );
    }
  }

  void _removeSegment(int index) {
    setState(() => _segmentPrompts.removeAt(index));
  }

  Future<void> _updateSegmentPromptsInSupabase(
    bool finalSave,
    DataProvider appData,
  ) async {
    List<Map<String, dynamic>> segments = _segmentPrompts
        .map((segment) => segment.toJson())
        .toList();
    if (segments.length > 7) {
      segments = segments.sublist(0, 6);
    }
    String updatedStatus = finalSave ? 'drafted' : 'created';
    await SupabaseAnchorPointSource().updateAnchorPoint(widget.anchorPoint.id, {
      'segment_prompts': segments,
      'status': updatedStatus,
    });
    appData.loadOwnedAnchorPoints();
  }

  void _updateSegment(int index, String field, String value) {
    setState(() {
      final seg = _segmentPrompts[index];
      switch (field) {
        case 'name':
          seg.segmentData.name = value;
          break;
        case 'prompt':
          seg.prompt = value;
          break;
        case 'symbol':
          seg.segmentData.symbol = value;
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
    bool excluded = index > 6;
    final segment = _segmentPrompts[index];
    final nameController = TextEditingController(
      text: segment.segmentData.name,
    );
    final symbolController = TextEditingController(
      text: segment.segmentData.symbol,
    );
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

    return Expanded(
      child: Column(
        children: [
          Card(
            key: ValueKey("segment_card_$index"),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ReorderableDragStartListener(
                    child: Center(child: FaIcon(FontAwesomeIcons.list)),
                    enabled: true,
                    index: index,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (excluded) Text(getText("segment_excluded")),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: GestureDetector(
                                onTap: () async {
                                  String? newSymbol = await openEmojiPicker(
                                    context,
                                  );
                                  if (newSymbol != symbolController.text &&
                                      newSymbol != null) {
                                    _updateSegment(index, 'symbol', newSymbol);
                                  }
                                },
                                child: WholeSymbol(
                                  symbol: symbolController.text,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: getText("segment_name"),
                                ),
                                controller: nameController,
                                onChanged: (val) =>
                                    _updateSegment(index, 'name', val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            WholePopup(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  WholeButton(
                                    icon: FontAwesomeIcons.trash,
                                    circleColor: colorScheme.error,
                                    onPressed: () => {
                                      Navigator.of(context).pop(),
                                      _removeSegment(index),
                                    },
                                  ),
                                  WholeButton(),
                                ],
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.ellipsisVertical,
                                  ),
                                ),
                              ),
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
                          onChanged: (val) =>
                              _updateSegment(index, 'prompt', val),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          _buildAddButton(index: index),
        ],
      ),
    );
  }

  WholeButton _buildGoToTemplateButton(String localeCode, bool inPopup) {
    return WholeButton(
      icon: FontAwesomeIcons.list,
      text: getText('use_templates'),
      wide: true,
      onPressed: () async {
        inPopup ? Navigator.pop(context) : null;
        final selectedPrompts = await Navigator.push<List<SegmentPrompt>>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SegmentPromptsTemplateScreen(localeCode: localeCode),
          ),
        );

        if (selectedPrompts != null && selectedPrompts.isNotEmpty) {
          _addSelectedSegments(selectedPrompts);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider settings = context.watch<SettingsProvider>();
    DataProvider appData = context.watch<DataProvider>();
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    String localeCode = settings.locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(getText("drafting_screen_title")),
        actions: [
          WholePopup(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildGoToTemplateButton(localeCode, true)],
            ),
            child: Padding(
              padding: EdgeInsetsGeometry.all(8),
              child: FaIcon(FontAwesomeIcons.ellipsisVertical),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _segmentPrompts.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    children: [
                      SizedBox(height: 50),
                      Text(
                        getText("no_segments_yet"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        getText("you_can_use_template"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      _buildGoToTemplateButton(localeCode, false),
                      Text(
                        getText("or"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        getText("add_first_segment"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      _buildAddButton(index: 0),
                    ],
                  )
                : Expanded(
                    child: ReorderableListView(
                      onReorder: _reorderSegments,

                      children: [
                        for (int i = 0; i < _segmentPrompts.length; i++) ...[
                          // Each segment card
                          ReorderableDragStartListener(
                            key: ValueKey("segment_item_$i"),
                            enabled: false,
                            index: i,
                            child: _buildSegmentCard(i),
                          ),
                        ],
                      ],
                    ),
                  ),
            ActionSlider.standard(
              child: Text(getText("save_segments")),
              loadingIcon: CircularProgressIndicator(),
              toggleColor: colorScheme.tertiary,
              rolling: true,
              icon: FaIcon(
                AnchorPointIcons.anchor_point_step1,
                color: colorScheme.onSurface,
                size: 40,
              ),
              successIcon: FaIcon(FontAwesomeIcons.check),
              failureIcon: FaIcon(FontAwesomeIcons.xmark),
              action: (controller) async {
                controller.loading();

                try {
                  await _updateSegmentPromptsInSupabase(true, appData);

                  controller.success();
                  await Future.delayed(Durations.extralong1);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getText("succes_in_updating_prompts")),
                    ),
                  );
                } catch (e) {
                  controller.failure();
                  await Future.delayed(Durations.extralong1);

                  print(e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
