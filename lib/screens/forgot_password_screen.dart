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
  bool _tokenSent = false;
  String? _error;
  String? _success;

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
      final result = await api.forgotPassword(_emailController.text.trim());
      setState(() {
        _tokenSent = true;
        _success = 'Reset token sent! Check the response below.';
        // In production this would come via email
        if (result['resetToken'] != null) {
          _tokenController.text = result['resetToken'].toString();
        }
      });
    } catch (e) {
      setState(() => _error = 'Failed to send reset request');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_tokenController.text.isEmpty) {
      setState(() => _error = 'Please enter the reset token');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
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
      setState(() => _error = 'Invalid or expired reset token');
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
              Icons.lock_reset,
              size: 80,
              color: AppTheme.deepGreen.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              _tokenSent ? 'Enter Reset Token' : 'Forgot Password?',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _tokenSent
                  ? 'Enter the token and your new password below.'
                  : 'Enter your email to receive a password reset token.',
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

            if (_success != null && !_tokenSent == false)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.deepGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_success!, style: const TextStyle(color: AppTheme.deepGreen)),
              ),

            if (!_tokenSent) ...[
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
                    : const Text('Send Reset Token', style: TextStyle(fontSize: 16)),
              ),
            ] else ...[
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Reset Token',
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
                onPressed: () => setState(() { _tokenSent = false; _error = null; }),
                child: const Text('Request a new token'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
