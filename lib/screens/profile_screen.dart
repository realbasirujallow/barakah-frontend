import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final api = ApiService(authService);
      final data = await api.getProfile();
      setState(() {
        _nameController.text = data['fullName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _loading = false;
      });
    } catch (e) {
      // Fallback to local data
      setState(() {
        _nameController.text = authService.userName ?? '';
        _emailController.text = authService.userEmail ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth);

      final result = await api.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        currentPassword: _changingPassword ? _currentPasswordController.text : null,
        newPassword: _changingPassword ? _newPasswordController.text : null,
      );

      // Update local session
      await auth.saveSession(
        token: auth.token!,
        userId: auth.userId!,
        userName: result['fullName'] ?? auth.userName!,
        userEmail: result['email'] ?? auth.userEmail!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: AppTheme.deepGreen),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        setState(() => _changingPassword = false);
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to update profile';
        if (e.toString().contains('409')) msg = 'Email already in use';
        if (e.toString().contains('400')) msg = 'Current password is incorrect';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.deepGreen,
                      child: Text(
                        (_nameController.text.isNotEmpty ? _nameController.text[0] : 'U').toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Change Password Toggle
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppTheme.deepGreen),
                      const SizedBox(width: 8),
                      const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch(
                        value: _changingPassword,
                        onChanged: (v) => setState(() => _changingPassword = v),
                        activeTrackColor: AppTheme.deepGreen,
                      ),
                    ],
                  ),

                  if (_changingPassword) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        helperText: 'At least 6 characters',
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
