import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/auth_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient supabase;
  User? user;
  bool isLoading = false;
  String? errorMessage;

  AuthProvider(this.supabase) {
    user = supabase.auth.currentUser;
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    supabase.auth.onAuthStateChange.listen((data) {
      user = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> signIn(
    String email,
    String password,
    BuildContext context,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    user = res.user;

    isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final res = await supabase.auth.signUp(email: email, password: password);
    user = res.user;

    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    DataProvider appData = Provider.of<DataProvider>(context, listen: false);
    appData.clearData();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

  Future<void> resetPassword(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await supabase.auth.resetPasswordForEmail(email);

    isLoading = false;
    notifyListeners();
  }

  bool get isAuthenticated => user != null;
}
