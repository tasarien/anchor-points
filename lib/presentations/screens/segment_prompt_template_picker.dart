import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/segment_prompts_template.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_symbol.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:anchor_point_app/data/models/segment_prompt_model.dart';

class SegmentPromptsTemplateScreen extends StatefulWidget {
  final String localeCode;
  const SegmentPromptsTemplateScreen({Key? key, required this.localeCode})
    : super(key: key);

  @override
  State<SegmentPromptsTemplateScreen> createState() =>
      _SegmentPromptsTemplateScreenState();
}

class _SegmentPromptsTemplateScreenState
    extends State<SegmentPromptsTemplateScreen> {
  final supabase = Supabase.instance.client;

  late Future<List<SegmentPromptsTemplate>> _templatesFuture;

  /// Store selected segments
  final List<SegmentPrompt> _selectedPrompts = [];

  @override
  void initState() {
    super.initState();
    _templatesFuture = _fetchTemplates();
  }

  Future<List<SegmentPromptsTemplate>> _fetchTemplates() async {
    final response = await supabase
        .from('segmentPromptsTemplates')
        .select()
        .eq('locale', widget.localeCode);
    final data = response as List<dynamic>;
    return data
        .map(
          (e) => SegmentPromptsTemplate.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  bool _isSegmentSelected(SegmentPrompt segment) {
    return _selectedPrompts.any(
      (s) => s.name == segment.name && s.prompt == segment.prompt,
    );
  }

  void _toggleSegment(SegmentPrompt segment) {
    setState(() {
      if (_isSegmentSelected(segment)) {
        _selectedPrompts.removeWhere(
          (s) => s.name == segment.name && s.prompt == segment.prompt,
        );
      } else {
        _selectedPrompts.add(segment);
      }
    });
  }

  bool _isTemplateSelected(SegmentPromptsTemplate template) {
    return template.template.every(_isSegmentSelected);
  }

  void _toggleTemplate(SegmentPromptsTemplate template) {
    setState(() {
      if (_isTemplateSelected(template)) {
        _selectedPrompts.removeWhere(
          (s) => template.template.any(
            (seg) => seg.name == s.name && seg.prompt == s.prompt,
          ),
        );
      } else {
        for (var seg in template.template) {
          if (!_isSegmentSelected(seg)) _selectedPrompts.add(seg);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Segment Prompts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedPrompts);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SegmentPromptsTemplate>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final templates = snapshot.data ?? [];
          if (templates.isEmpty) {
            return const Center(child: Text('No templates found.'));
          }

          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isTemplateSelected = _isTemplateSelected(template);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  leading: Checkbox(
                    value: isTemplateSelected,
                    onChanged: (_) => _toggleTemplate(template),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        if (template.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              template.imageUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Wrap(
                    spacing: 2,
                    runSpacing: 2,

                    children: template.template
                        .map(
                          (seg) => WholeSymbol(
                            symbol: seg.symbol,
                            size: Size(35, 35),
                          ),
                        )
                        .toList(),
                  ),
                  children: template.template.map((segment) {
                    final isSelected = _isSegmentSelected(segment);
                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSegment(segment),
                      ),
                      title: Text(segment.name),
                      subtitle: Text(
                        segment.prompt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: WholeSymbol(symbol: segment.symbol),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
