import 'package:anchor_point_app/data/models/person_invitation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListOfInvitations extends StatefulWidget {
  // Optional callback; also widget will Navigator.pop(context, InvitePerson) when an item is tapped.
  final void Function(PersonInvitation)? onSelected;
  final double? maxHeight;

  const ListOfInvitations({super.key, this.onSelected, this.maxHeight});

  @override
  State<ListOfInvitations> createState() => _ListOfInvitationsState();
}

class _ListOfInvitationsState extends State<ListOfInvitations> {
  late final SupabaseClient _supabase;
  late Future<List<PersonInvitation>> _invitationsFuture;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _invitationsFuture = _fetchInvitations();
  }

  Future<List<PersonInvitation>> _fetchInvitations() async {
    final response = await _supabase
        .from('invitations')
        .select()
        .eq("invitator_id", _supabase.auth.currentUser!.id);

    return response.map((item) => PersonInvitation.fromJson(item)).toList();
  }

  void _handlePick(PersonInvitation invite) {
    widget.onSelected?.call(invite);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PersonInvitation>>(
      future: _invitationsFuture,
      builder: (context, snapshot) {
        final invites = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight ?? double.infinity,
          ),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: kElevationToShadow[1],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Active Invitations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),

              if (snapshot.hasError)
                Center(child: Text('Error: ${snapshot.error}')),

              if (invites.isEmpty)
                const Center(child: Text('No active invitations.')),

              if (invites.isNotEmpty &&
                  snapshot.connectionState == ConnectionState.done)
                Expanded(
                  child: ListView.separated(
                    itemCount: invites.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final invite = invites[index];
                      return ListTile(
                        title: Text(invite.name ?? 'Unknown'),
                        subtitle: invite.message != null
                            ? Text(invite.message!)
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _handlePick(invite),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
