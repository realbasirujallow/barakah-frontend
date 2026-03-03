import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  // 0 = enter email, 1 = email sent (check inbox), 2 = enter token + new password
  int _step = 0;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_emailController.text.isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService(Provider.of<AuthService>(context, listen: false));
      await api.forgotPassword(_emailController.text.trim());
      setState(() => _step = 1);
    } catch (e) {
      setState(() => _error = 'Failed to send reset request. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_tokenController.text.isEmpty) {
      setState(() => _error = 'Please enter the reset token from your email');
      return;
    }
    if (_newPasswordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService(Provider.of<AuthService>(context, listen: false));
      await api.resetPassword(_tokenController.text.trim(), _newPasswordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully! Please log in.'), backgroundColor: AppTheme.deepGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Invalid or expired reset token. Please request a new one.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _step == 1 ? Icons.mark_email_read_outlined : Icons.lock_reset,
              size: 80,
              color: AppTheme.deepGreen.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              _step == 0 ? 'Forgot Password?' : _step == 1 ? 'Check Your Email' : 'Create New Password',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? 'Enter your email and we\'ll send you a reset link.'
                  : _step == 1
                      ? 'We sent a password reset link to ${_emailController.text}. Check your inbox and spam folder.'
                      : 'Enter the token from your email and your new password.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // Step 0: Enter email
            if (_step == 0) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _requestReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Reset Link', style: TextStyle(fontSize: 16)),
              ),
            ],

            // Step 1: Email sent — check inbox
            if (_step == 1) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.deepGreen.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.deepGreen.withAlpha(40)),
                ),
                child: const Column(
                  children: [
                    Text('The reset link expires in 30 minutes.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() { _step = 2; _error = null; }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('I Have the Token', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : _requestReset,
                child: const Text('Resend Email'),
              ),
            ],

            // Step 2: Enter token + new password
            if (_step == 2) ...[
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Reset Token (from email)',
                  hintText: 'Paste the token from your email',
                  prefixIcon: const Icon(Icons.key),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'At least 8 characters',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Reset Password', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() { _step = 0; _error = null; }),
                child: const Text('Request a new token'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
