import 'package:anchor_point_app/data/models/person_invitation.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/utilities/list_of_invitations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

class InvitationCreatorWidget extends StatefulWidget {
  const InvitationCreatorWidget({Key? key}) : super(key: key);

  @override
  State<InvitationCreatorWidget> createState() =>
      _InvitationCreatorWidgetState();
}

class _InvitationCreatorWidgetState extends State<InvitationCreatorWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  PersonInvitation? _createdInvitation = null;

  bool _isLoading = false;

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
        'invitator_id': _supabase.auth.currentUser!.id,
      };

      final response = await _supabase
          .from('invitations')
          .insert(invitation)
          .select()
          .single();

      setState(() {
        _createdInvitation = PersonInvitation.fromJson(response);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _shareInvitation() {
    if (_createdInvitation == null) return;

    final name = _createdInvitation!.name;
    final message = _createdInvitation!.message;
    final token = _createdInvitation!.token;
    final expireDate = _createdInvitation!.expireDate;
    final formattedDate =
        '${expireDate.day}/${expireDate.month}/${expireDate.year}';

    final shareText =
        '''
🎉 You're Invited! 🎉

From: $name

$message

Invitation Code: $token
Valid until: $formattedDate
''';

    SharePlus.instance.share(
      ShareParams(text: shareText, subject: 'Invitation from $name'),
    );
  }

  void _resetForm() {
    setState(() {
      _createdInvitation = null;
      _nameController.clear();
      _messageController.clear();
    });
  }

  void _selectInvitation() {
    Navigator.of(context).pop(_createdInvitation);
  }

  @override
  Widget build(BuildContext context) {
    if (_createdInvitation != null) {
      return _buildInvitationCard();
    }

    return _buildForm();
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListOfInvitations(
              maxHeight: 200,
              onSelected: (invitation) {
                _resetForm();
                setState(() {
                  _createdInvitation = invitation;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              'Create New Invitation',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Invitation for',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter name of invited person';
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
    );
  }

  Widget _buildInvitationCard() {
    final name = _createdInvitation!.name;
    final message = _createdInvitation!.message;
    final token = _createdInvitation!.token;
    final expireDate = _createdInvitation!.expireDate;
    final formattedDate =
        '${expireDate.day}/${expireDate.month}/${expireDate.year}';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FontAwesomeIcons.envelopeOpen, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'You\'re Invited!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For: $name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message ?? "You are invited.",
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          token!,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Valid until: $formattedDate'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: WholeButton(
                          onPressed: _shareInvitation,
                          icon: FontAwesomeIcons.share,
                          text: 'Share',
                          wide: true,
                          suggested: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: WholeButton(
                          onPressed: _selectInvitation,
                          icon: FontAwesomeIcons.person,
                          text: "Pick ${name}",
                          suggested: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsetsGeometry.all(8),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _createdInvitation = null;
                    });
                  },
                  icon: FaIcon(FontAwesomeIcons.chevronLeft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
