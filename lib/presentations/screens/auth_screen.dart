import 'package:anchor_point_app/core/localizations/app_localizations.dart';
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

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isSignIn = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(BuildContext context) async {
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

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
          context,
        );
      } else {
        await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(getText('auth_check_confirmation_message'))),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _mapAuthError(e, context);
        _isLoading = false;
      });

      // UX: focus password on wrong credentials
      FocusScope.of(context).requestFocus(_passwordFocus);
    }
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

    if (_emailController.text.isEmpty) {
      setState(
        () =>
            _errorMessage = getText('auth_please_look_into_confirmation_email'),
      );
      return;
    }

    try {
      await authProvider.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getText('auth_password_reset_sent'))),
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
    final authProvider = context.read<AuthProvider>();
    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

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
                                _passwordController.clear();
                                _confirmPasswordController.clear();
                              });
                            },
                            wide: true,
                            text: getText('auth_sign_in'),
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
                                _passwordController.clear();
                                _confirmPasswordController.clear();
                              });
                            },
                            wide: true,
                            text: getText('auth_sign_up'),
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
                        // Error indicator
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: getText('auth_email'),
                            prefixIcon: _icon(FontAwesomeIcons.envelope),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return getText('auth_enter_email');
                            }
                            if (!value.contains('@')) {
                              return getText('auth_invalid_email');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          textInputAction: _isSignIn
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onFieldSubmitted: (_) {
                            if (_isSignIn) {
                              _handleAuth(context);
                            } else {
                              FocusScope.of(
                                context,
                              ).requestFocus(_confirmPasswordFocus);
                            }
                          },
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: getText('auth_password'),
                            prefixIcon: _icon(FontAwesomeIcons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return getText('auth_enter_password');
                            }
                            if (!_isSignIn && value.length < 6) {
                              return getText('auth_password_six_char');
                            }
                            return null;
                          },
                        ),

                        // Confirm Password (Sign Up only)
                        if (!_isSignIn) ...[
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleAuth(context),
                            decoration: InputDecoration(
                              labelText: getText('auth_confirm_password'),
                              prefixIcon: _icon(FontAwesomeIcons.lock),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return getText('auth_please_confirm_password');
                              }
                              if (value != _passwordController.text) {
                                return getText('auth_password_not_match');
                              }
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
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        _handleAuth(context);
                                      },
                                text: _isSignIn
                                    ? getText('auth_sign_in')
                                    : getText('auth_sign_up'),
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot password
                if (_isSignIn)
                  TextButton(
                    onPressed: () => _handlePasswordReset(context),

                    child: Text(getText('auth_forgot_password')),
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

  String _mapAuthError(AuthException e, BuildContext context) {
    String t(String k) => AppLocalizations.of(context).translate(k);

    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials')) {
      return t('auth_invalid_credentials');
    }
    if (msg.contains('email not confirmed')) {
      return t('auth_email_not_confirmed');
    }
    if (msg.contains('user not found')) {
      return t('auth_user_not_found');
    }
    if (msg.contains('password')) {
      return t('auth_wrong_password');
    }

    if (msg.contains('user already registered') ||
        msg.contains('already exists')) {
      return t('auth_email_already_in_use');
    }

    if (msg.contains('signup is disabled')) {
      return t('auth_signup_disabled');
    }

    if (msg.contains('rate limit')) {
      return t('auth_too_many_requests');
    }

    if (msg.contains('weak password') || msg.contains('password should be')) {
      return t('auth_weak_password');
    }

    if (msg.contains('invalid email')) {
      return t('auth_invalid_email');
    }

    return t('auth_uknown_error');
  }
}
