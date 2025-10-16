import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/presentations/providers/auth_provider.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/main_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetUpScreen extends StatefulWidget {
  final UserProfile profile;
  const SetUpScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<SetUpScreen> createState() => _SetUpScreenState();
}

class _SetUpScreenState extends State<SetUpScreen> {
  late TextEditingController _nameController;
  String? _errorText;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final String? displayName = user?.userMetadata?['full_name'];
    _nameController = TextEditingController(text: displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit(DataProvider appData) async {
    final name = _nameController.text.trim();
    if (name.length < 3) {
      setState(() {
        _errorText = 'Name must be at least 3 letters';
      });
      return;
    }
    setState(() {
      _errorText = null;
    });
    try {
      setState(() {
        loading = true;
      });
      var response = await Supabase.instance.client
          .from('profiles')
          .update({"username": name})
          .eq("user_id", Supabase.instance.client.auth.currentUser!.id)
          .select('username')
          .single();
      if (response['username'] == name) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
      setState(() {
        loading = false;
      });
      appData.loadAllData();
    } catch (e) {
      setState(() {
        _errorText = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = context.watch<AuthProvider>();
    DataProvider appData = Provider.of<DataProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up'),
        toolbarHeight: 65,
        actions: [
          WholeButton(
            icon: FontAwesomeIcons.doorOpen,
            text: "logout",
            onPressed: () {
              auth.signOut(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 64),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submit(appData),
              child: loading
                  ? CircularProgressIndicator()
                  : Text('Finish Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
