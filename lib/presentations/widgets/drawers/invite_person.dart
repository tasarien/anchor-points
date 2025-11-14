import 'package:anchor_point_app/data/models/person_invitation.dart';
import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/presentations/widgets/global/section_tab.dart';
import 'package:anchor_point_app/presentations/widgets/global/share_invitation.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/utilities/invitation_creation_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvitePersonBottomSheet extends StatefulWidget {
  final UserProfile? profile;
  const InvitePersonBottomSheet({Key? key, this.profile}) : super(key: key);

  @override
  State<InvitePersonBottomSheet> createState() =>
      _InvitePersonBottomSheetState();
}

class _InvitePersonBottomSheetState extends State<InvitePersonBottomSheet> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  void _selectInvitation(PersonInvitation? invitation) {
    Navigator.pop(context, invitation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [InvitationCreatorWidget()],
        ),
      ),
    );
  }
}
