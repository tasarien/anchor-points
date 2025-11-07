import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/presentations/widgets/global/section_tab.dart';
import 'package:anchor_point_app/presentations/widgets/global/share_invitation.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PickCompanionBottomSheet extends StatefulWidget {
  final UserProfile? profile;
  const PickCompanionBottomSheet({Key? key, this.profile}) : super(key: key);

  @override
  State<PickCompanionBottomSheet> createState() =>
      _PickCompanionBottomSheetState();
}

class _PickCompanionBottomSheetState extends State<PickCompanionBottomSheet> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _profiles = [];
  bool _isLoading = false;
  UserProfile? _selectedCompanion;

  Future<void> pickCompanion(String query) async {
    setState(() => _isLoading = true);
    if (query.isEmpty) {
      final response = await supabase
          .from('profiles')
          .select('user_id, username')
          .limit(10);
      setState(() {
        _profiles = response
            .map((profile) => UserProfile.fromJson(profile))
            .toList();
        _isLoading = false;
      });
    } else {
      final response = await supabase
          .from('profiles')
          .select('user_id, username')
          .ilike('username', '%$query%');

      setState(() {
        _profiles = response
            .map((profile) => UserProfile.fromJson(profile))
            .toList();
        _isLoading = false;
      });
    }
  }

  void _selectCompanion(UserProfile profile) {
    Navigator.pop(context, {true, profile});
  }

  void _inviteSomeoneNew() {
    Navigator.pop(context, {false, null});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Text(
              'Pick a Companion',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            WholeButton(
              text: "Invite someone new",
              wide: true,
              icon: FontAwesomeIcons.envelope,
              onPressed: () {
                _inviteSomeoneNew();
              },
            ),
            const SizedBox(height: 12),
            SectionTab(text: "or"),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => pickCompanion(_searchController.text),
                ),
              ),
              onSubmitted: pickCompanion,
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_profiles.isEmpty)
              const Text("No companions found.")
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    final isSelected = _selectedCompanion?.id == profile.id;

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(profile!.username!),
                      selected: isSelected,
                      selectedTileColor: theme.colorScheme.primaryContainer,
                      onTap: () => _selectCompanion(profile),
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
