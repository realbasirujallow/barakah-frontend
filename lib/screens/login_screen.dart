import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/services/biometric_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final bio = BiometricService();
    final available = await bio.isAvailable();
    final enabled = await bio.isEnabled();
    final authService = Provider.of<AuthService>(context, listen: false);
    if (available && enabled && authService.isLoggedIn) {
      setState(() => _biometricAvailable = true);
      _tryBiometricLogin();
    } else if (available && enabled) {
      setState(() => _biometricAvailable = true);
    }
  }

  Future<void> _tryBiometricLogin() async {
    final bio = BiometricService();
    final authenticated = await bio.authenticate();
    if (authenticated && mounted) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);

      final response = await apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      await authService.saveSession(
        token: response['token'] as String,
        userId: response['userId'].toString(),
        userName: response['fullName'] as String? ?? '',
        userEmail: _emailController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('401') || e.toString().contains('403')) {
      return 'Invalid email or password';
    }
    if (e.toString().contains('SocketException') || e.toString().contains('timeout')) {
      return 'Network error. Please check your connection.';
    }
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Title
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.deepGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text(
                        '☪',
                        style: TextStyle(fontSize: 48, color: AppTheme.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Barakah',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme.deepGreen,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Islamic Finance Tracker',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Biometric login
                  if (_biometricAvailable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed: _tryBiometricLogin,
                        icon: const Icon(Icons.fingerprint, color: AppTheme.deepGreen),
                        label: const Text('Login with Biometrics'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.deepGreen,
                          side: const BorderSide(color: AppTheme.deepGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  // Forgot password
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),

                  // Signup link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        children: const [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: AppTheme.deepGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
