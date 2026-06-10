import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Converts a username to a deterministic internal email for Supabase auth.
  String _toEmail(String username) {
    final sanitized = username
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9._\-]'), '');
    return '$sanitized@fittrack.local';
  }

  /// Looks up the stored `login_email` for a display name in the profiles
  /// table. Returns null if not found or if the column doesn't exist yet
  /// (user must run: ALTER TABLE profiles ADD COLUMN IF NOT EXISTS login_email TEXT).
  Future<String?> _lookupEmailByName(String name) async {
    try {
      final row = await SupabaseService.client
          .from('profiles')
          .select('login_email')
          .ilike('name', name)
          .limit(1)
          .maybeSingle();
      final v = row?['login_email'];
      return (v is String && v.isNotEmpty) ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// After a successful sign-up, persist the auth email in the profiles table
  /// so future logins can look it up by display name.
  Future<void> _saveLoginEmail(String authEmail) async {
    try {
      await SupabaseService.client.from('profiles').upsert(
        {'id': SupabaseService.userId, 'login_email': authEmail},
        onConflict: 'id',
      );
    } catch (_) {}
  }

  Future<void> _submit() async {
    final input = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (input.isEmpty) {
      setState(() => _error = _isLogin
          ? 'Please enter your username or email.'
          : 'Please enter a username.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    if (!_isLogin && input.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        // Resolve the email to use:
        // 1. Real email input → use as-is
        // 2. Username/display-name → look up stored login_email first, then
        //    fall back to the deterministic _toEmail() mapping.
        final String email;
        if (input.contains('@')) {
          email = input;
        } else {
          email = await _lookupEmailByName(input) ?? _toEmail(input);
        }

        await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // Sign-up: always username-based.
        final email = _toEmail(input);
        final res = await SupabaseService.client.auth.signUp(
          email: email,
          password: password,
          data: {'username': input},
        );
        if (res.session == null) {
          setState(() => _error =
              'Account created, but email confirmation is required. '
              'Disable it in Supabase → Authentication → Email, then sign in.');
          return;
        }
        // Persist login_email so the user can log in with their display name
        // even after changing it in profile.
        await _saveLoginEmail(email);
      }
      widget.onAuthenticated();
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login credentials')) {
        msg = 'Wrong username / email or password. Please try again.';
      } else if (msg.contains('User already registered')) {
        msg = 'That username is already taken. Try a different one.';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const Icon(Icons.fitness_center_rounded,
                    size: 64, color: AppColors.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'FitTrack',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back' : 'Create your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.mediumGray),
                ),
                const SizedBox(height: 40),

                // Username / email field
                TextField(
                  controller: _usernameCtrl,
                  keyboardType: _isLogin
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    _isLogin ? 'Username or email' : 'Choose a username',
                    _isLogin
                        ? Icons.alternate_email_rounded
                        : Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Password',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.mediumGray,
                        size: 20,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),

                // Error text
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // Submit button
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isLogin ? 'Sign In' : 'Create Account',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 16),

                // Toggle sign-in / sign-up
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _error = null;
                  }),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Sign in',
                    style: const TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.mediumGray),
        prefixIcon: Icon(icon, color: AppColors.mediumGray, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      );
}
