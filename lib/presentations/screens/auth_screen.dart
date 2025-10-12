import 'package:anchor_point_app/presentations/providers/auth_provider.dart';
import 'package:anchor_point_app/presentations/providers/settings_provider.dart';
import 'package:anchor_point_app/presentations/widgets/global/loading_indicator.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_scaffold_body.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignIn = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignIn) {
        await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check your email for confirmation!')),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'An unknown error occurred');
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (_emailController.text.isEmpty) {
      setState(
        () => _errorMessage = 'Please enter your email to reset password',
      );
      return;
    }

    try {
      await authProvider.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: WholeScaffoldBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Hero image ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/auth_gate.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Tabs for sign in / sign up ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: WholeButton(
                            suggested: _isSignIn,
                            onPressed: () {
                              setState(() {
                                _isSignIn = true;
                                _errorMessage = null;
                              });
                            },
                            wide: true,
                            text: 'Sign In',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: WholeButton(
                            suggested: !_isSignIn,
                            onPressed: () {
                              setState(() {
                                _isSignIn = false;
                                _errorMessage = null;
                              });
                            },
                            wide: true,
                            text: 'Sign Up',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- Auth Form ---
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: _icon(FontAwesomeIcons.envelope),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your email'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: _icon(FontAwesomeIcons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter your password';
                            if (!_isSignIn && value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        // Confirm Password (Sign Up only)
                        if (!_isSignIn) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: _icon(FontAwesomeIcons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please confirm your password';
                              if (value != _passwordController.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit button
                        _isLoading
                            ? const LoadingIndicator()
                            : WholeButton(
                                wide: true,
                                suggested: true,
                                icon: FontAwesomeIcons.arrowRightFromBracket,
                                onPressed: _isLoading
                                    ? null
                                    : () => _handleAuth(context),
                                text: _isSignIn ? 'Sign In' : 'Sign Up',
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot password
                if (_isSignIn)
                  WholeButton(
                    onPressed: () => _handlePasswordReset(context),
                    wide: true,
                    suggested: false,
                    text: 'Forgot Password?',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData icon) {
    return SizedBox(
      height: 50,
      width: 50,
      child: Center(child: FaIcon(icon, color: AppColors.sageGreen)),
    );
  }
}
