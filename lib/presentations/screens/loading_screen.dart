import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/presentations/providers/auth_provider.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/auth_screen.dart';
import 'package:anchor_point_app/presentations/screens/main_screen.dart';
import 'package:anchor_point_app/presentations/screens/set_up_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final bool guid = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
      return;
    }

    Future<bool> checkIfIsProfile() async {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      List<Map<String, dynamic>>? response = await supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id);

      if (response.isEmpty) {
        await supabase.from('profiles').insert({"user_id": user.id});
        return true;
      }

      return true;
    }

    Future<UserProfile?> fetchProfile() async {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      List<Map<String, dynamic>>? response = await supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id);

      return UserProfile.fromJson(response.first);
    }

    bool isProfileComplete(UserProfile? profile) {
      return profile?.username != null && profile!.username!.isNotEmpty;
    }

    late UserProfile? profile;
    if (await checkIfIsProfile()) {
      profile = await fetchProfile();
    }

    if (!isProfileComplete(profile)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetUpScreen(profile: profile!)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: LoadingIndicator()));
  }
}
