import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_ios/google_sign_in_ios.dart';
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

  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    DataProvider appData = Provider.of<DataProvider>(context, listen: false);
    appData.clearData();
    Navigator.of(context).pop();
  }

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

  Future<AuthResponse> googleSignIn(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    const webClientId =
        '570438305235-bq3saaseg8fbg07kmk3gbib8vcsu10nd.apps.googleusercontent.com';

    const iosClientId =
        '570438305235-48lj77plr3qbbgfspdl8mh4lrkam0lbb.apps.googleusercontent.com';

    final GoogleSignIn signIn = GoogleSignIn.instance;

    signIn.initialize(clientId: iosClientId);

    // Perform the sign in
    final googleAccount = await signIn.authenticate();
    final googleAuthorization = await googleAccount.authorizationClient
        .authorizationForScopes([]);
    final googleAuthentication = googleAccount!.authentication;
    final idToken = googleAuthentication.idToken;
    final accessToken = googleAuthorization!.accessToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    isLoading = false;
    notifyListeners();
    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  bool get isAuthenticated => user != null;
}
