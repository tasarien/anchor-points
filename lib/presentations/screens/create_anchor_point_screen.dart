import 'package:anchor_point_app/presentations/providers/data_provider.dart';
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
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) return;

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

      appData.reloadAnchorPoints();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anchor point created!')));
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
    DataProvider appData = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Anchor Point')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _submit(appData),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
