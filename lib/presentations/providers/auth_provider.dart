import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      user = res.user;
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await supabase.auth.signUp(email: email, password: password);
      user = res.user;
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  /// 🔁 Reset password by sending a reset email
  Future<void> resetPassword(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Unexpected error: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    user = null;
    notifyListeners();
  }

  bool get isAuthenticated => user != null;
}
