import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/localizations/suggestions.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/providers/settings_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/section_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateAnchorPointScreen extends StatefulWidget {
  const CreateAnchorPointScreen({Key? key}) : super(key: key);

  @override
  State<CreateAnchorPointScreen> createState() =>
      _CreateAnchorPointScreenState();
}

class _CreateAnchorPointScreenState extends State<CreateAnchorPointScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit(DataProvider appData) async {
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getText('create_anchor_point_screen_message_empty_name'),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('anchorPoints').insert({
        'name': name,
        'description': description.isEmpty ? null : description,
      });

      setState(() {
        _isLoading = false;
      });

      appData.loadAllData();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(getText('anchor_point_created'))));
      _nameController.clear();
      _descriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    DataProvider appData = context.watch<DataProvider>();
    SettingsProvider settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(getText("create_anchor_point_screen_title"))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                height: 100,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                width: double.infinity,
                child: Image.asset(
                  'assets/images/empty_landscape.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      Text(getText('title_field_description')),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: getText('title'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      SectionTab(
                        text: getText(
                          'create_anchor_point_screen_suggestions_section',
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          // Example array of strings
                          ...suggestions[settings.locale]!['title_suggestions']!
                              .map(
                                (chipText) => GestureDetector(
                                  onTap: () {
                                    _nameController.text = chipText;
                                  },
                                  child: Chip(label: Text(chipText)),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      Text(getText('description_field_description')),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: getText(
                            'create_anchor_point_screen_description_optional',
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _submit(appData),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(getText('create_anchor_point_screen_create_button')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
