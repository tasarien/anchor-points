import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Opens a modal bottom sheet to pick or upload an image.
/// Returns the public URL of the selected image, or null if cancelled.
Future<String?> showSupabaseImagePickerModal(BuildContext context) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _SupabaseImagePickerSheet(),
  );
}

class _SupabaseImagePickerSheet extends StatefulWidget {
  const _SupabaseImagePickerSheet({Key? key}) : super(key: key);

  @override
  State<_SupabaseImagePickerSheet> createState() =>
      _SupabaseImagePickerSheetState();
}

class _SupabaseImagePickerSheetState extends State<_SupabaseImagePickerSheet> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();
  bool _loading = false;
  List<String> _defaultImageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadDefaultImages();
  }

  Future<void> _loadDefaultImages() async {
    setState(() => _loading = true);
    try {
      final files = await supabase.storage.from('images').list();
      debugPrint(files.toString());
      final urls = files
          .map(
            (file) => supabase.storage.from('images').getPublicUrl(file.name),
          )
          .toList();
      setState(() {
        _defaultImageUrls = urls;
      });
    } catch (e) {
      _showSnackBar('Failed to load images: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadNewImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _loading = true);

      final file = File(picked.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name.replaceAll(' ', '_')}';

      // Upload file to Supabase
      await supabase.storage.from('user-images').upload(fileName, file);

      // Get public URL
      final publicUrl = supabase.storage
          .from('user-images')
          .getPublicUrl(fileName);

      if (mounted) Navigator.pop(context, publicUrl);
    } on StorageException catch (e) {
      _showSnackBar('Upload failed: ${e.message}');
    } catch (e) {
      _showSnackBar('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Select or Upload Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _loadDefaultImages,
                        tooltip: 'Refresh',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: _uploadNewImage,
                        tooltip: 'Upload New Image',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid of existing images
                  Expanded(
                    child: _defaultImageUrls.isEmpty
                        ? const Center(
                            child: Text(
                              'No default images found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _defaultImageUrls.length,
                            itemBuilder: (context, index) {
                              final url = _defaultImageUrls[index];
                              return GestureDetector(
                                onTap: () => Navigator.pop(context, url),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                              child: Icon(Icons.broken_image),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
