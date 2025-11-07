import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

class InvitationCreatorWidget extends StatefulWidget {
  const InvitationCreatorWidget({Key? key}) : super(key: key);

  @override
  State<InvitationCreatorWidget> createState() => _InvitationCreatorWidgetState();
}

class _InvitationCreatorWidgetState extends State<InvitationCreatorWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  Map<String, dynamic>? _createdInvitation;

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<String> _generateUniqueToken() async {
    final random = Random();
    String token;
    bool exists = true;

    while (exists) {
      token = (1000 + random.nextInt(9000)).toString();
      
      final response = await _supabase
          .from('invitations')
          .select('token')
          .eq('token', token)
          .maybeSingle();
      
      exists = response != null;
      
      if (!exists) return token;
    }
    
    return '';
  }

  Future<void> _createInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _generateUniqueToken();
      final expireDate = DateTime.now().add(const Duration(days: 7));

      final invitation = {
        'name': _nameController.text.trim(),
        'message': _messageController.text.trim(),
        'token': token,
        'expire_date': expireDate.toIso8601String(),
        'invitator_id' : _supabase.auth.currentUser!.id
      };

      final response = await _supabase
          .from('invitations')
          .insert(invitation)
          .select()
          .single();

      setState(() {
        _createdInvitation = response;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation created successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _shareInvitation() {
    if (_createdInvitation == null) return;

    final name = _createdInvitation!['name'];
    final message = _createdInvitation!['message'];
    final token = _createdInvitation!['token'];
    final expireDate = DateTime.parse(_createdInvitation!['expire_date']);
    final formattedDate = '${expireDate.day}/${expireDate.month}/${expireDate.year}';

    final shareText = '''
🎉 You're Invited! 🎉

From: $name

$message

Invitation Code: $token
Valid until: $formattedDate
''';

    Share.share(shareText, subject: 'Invitation from $name');
  }

  void _resetForm() {
    setState(() {
      _createdInvitation = null;
      _nameController.clear();
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_createdInvitation != null) {
      return _buildInvitationCard();
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Invitation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Invitation Message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  helperText: 'Max 300 characters',
                ),
                maxLines: 4,
                maxLength: 300,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an invitation message';
                  }
                  if (value.trim().length > 300) {
                    return 'Message must be 300 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createInvitation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Invitation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard() {
    final name = _createdInvitation!['name'];
    final message = _createdInvitation!['message'];
    final token = _createdInvitation!['token'];
    final expireDate = DateTime.parse(_createdInvitation!['expire_date']);
    final formattedDate = '${expireDate.day}/${expireDate.month}/${expireDate.year}';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade400,
              Colors.blue.shade400,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'You\'re Invited!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'From: $name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'INVITATION CODE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      token,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Valid until: $formattedDate',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareInvitation,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

