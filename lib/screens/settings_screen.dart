import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/currency_service.dart';
import 'package:barakah_app/services/biometric_service.dart';
import 'package:barakah_app/services/notification_service.dart';
import 'package:barakah_app/services/cache_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
    bool _hideNetWorth = false;
  String _selectedCurrency = 'USD';
  int _prayerMethod = 4;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _prayerNotifications = true;
  bool _zakatNotifications = true;
  bool _billNotifications = true;
  bool _budgetNotifications = true;

  final Map<int, String> _prayerMethods = {
    1: 'University of Islamic Sciences, Karachi',
    2: 'Islamic Society of North America (ISNA)',
    3: 'Muslim World League',
    4: 'Umm Al-Qura University, Makkah',
    5: 'Egyptian General Authority of Survey',
    7: 'Institute of Geophysics, University of Tehran',
    8: 'Gulf Region',
    9: 'Kuwait',
    10: 'Qatar',
    11: 'Majlis Ugama Islam Singapura',
    12: 'UOIF (France)',
    13: 'Diyanet İşleri Başkanlığı (Turkey)',
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _hideNetWorth = prefs.getBool('hide_net_worth') ?? false;
    final bio = BiometricService();
    final bioAvailable = await bio.isAvailable();
    final bioEnabled = await bio.isEnabled();
    final notifEnabled = await NotificationService.isEnabled();
    final prayerNotif = await NotificationService.isPrayerEnabled();
    final zakatNotif = await NotificationService.isZakatEnabled();
    final billNotif = await NotificationService.isBillEnabled();
    final budgetNotif = await NotificationService.isBudgetEnabled();
    setState(() {
      _selectedCurrency = prefs.getString('currency') ?? 'USD';
      _prayerMethod = prefs.getInt('prayer_method') ?? 4;
      _biometricAvailable = bioAvailable;
      _biometricEnabled = bioEnabled;
      _notificationsEnabled = notifEnabled;
      _prayerNotifications = prayerNotif;
      _zakatNotifications = zakatNotif;
      _billNotifications = billNotif;
      _budgetNotifications = budgetNotif;
    });
  }

  Future<void> _setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    setState(() => _selectedCurrency = currency);
  }

  Future<void> _setPrayerMethod(int method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prayer_method', method);
    setState(() => _prayerMethod = method);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.deepGreen, Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.gold.withAlpha(40),
                  child: Text(
                    (authService.userName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authService.userName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        authService.userEmail ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account
          _sectionHeader('Account'),
          _settingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Name, email, password',
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(height: 16),

          // Appearance
          _sectionHeader('Appearance'),
          _settingsTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Dark Mode',
            subtitle: isDark ? 'On' : 'Off',
            trailing: Switch(
              value: isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeTrackColor: AppTheme.deepGreen,
            ),
          ),
          const SizedBox(height: 16),

          // Security
          _sectionHeader('Security'),
          if (_biometricAvailable)
            _settingsTile(
              icon: Icons.fingerprint,
              title: 'Biometric Login',
              subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (v) async {
                  if (v) {
                    final bio = BiometricService();
                    final authenticated = await bio.authenticate(reason: 'Verify to enable biometric login');
                    if (authenticated) {
                      await bio.setEnabled(true);
                      setState(() => _biometricEnabled = true);
                    }
                  } else {
                    await BiometricService().setEnabled(false);
                    setState(() => _biometricEnabled = false);
                  }
                },
                activeTrackColor: AppTheme.deepGreen,
              ),
            ),
          const SizedBox(height: 16),

          // Notifications
          _sectionHeader('Notifications'),
          _settingsTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: _notificationsEnabled ? 'On' : 'Off',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) async {
                await NotificationService.setEnabled(v);
                setState(() => _notificationsEnabled = v);
              },
              activeTrackColor: AppTheme.deepGreen,
            ),
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 4),
            _settingsTile(
              icon: Icons.mosque,
              title: 'Prayer Reminders',
              subtitle: _prayerNotifications ? 'On' : 'Off',
              trailing: Switch(
                value: _prayerNotifications,
                onChanged: (v) async {
                  await NotificationService.setPrayerEnabled(v);
                  setState(() => _prayerNotifications = v);
                },
                activeTrackColor: AppTheme.deepGreen,
              ),
            ),
            const SizedBox(height: 4),
            _settingsTile(
              icon: Icons.calculate,
              title: 'Zakat Reminders',
              subtitle: _zakatNotifications ? 'On' : 'Off',
              trailing: Switch(
                value: _zakatNotifications,
                onChanged: (v) async {
                  await NotificationService.setZakatEnabled(v);
                  setState(() => _zakatNotifications = v);
                },
                activeTrackColor: AppTheme.deepGreen,
              ),
            ),
            const SizedBox(height: 4),
            _settingsTile(
              icon: Icons.receipt_long,
              title: 'Bill Reminders',
              subtitle: _billNotifications ? 'On' : 'Off',
              trailing: Switch(
                value: _billNotifications,
                onChanged: (v) async {
                  await NotificationService.setBillEnabled(v);
                  setState(() => _billNotifications = v);
                },
                activeTrackColor: AppTheme.deepGreen,
              ),
            ),
            const SizedBox(height: 4),
            _settingsTile(
              icon: Icons.pie_chart,
              title: 'Budget Alerts',
              subtitle: _budgetNotifications ? 'On' : 'Off',
              trailing: Switch(
                value: _budgetNotifications,
                onChanged: (v) async {
                  await NotificationService.setBudgetEnabled(v);
                  setState(() => _budgetNotifications = v);
                },
                activeTrackColor: AppTheme.deepGreen,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Finance
          _sectionHeader('Finance'),
          _settingsTile(
            icon: Icons.currency_exchange,
            title: 'Default Currency',
            subtitle: '$_selectedCurrency - ${CurrencyService().getName(_selectedCurrency)}',
            onTap: () => _showCurrencyPicker(),
          ),
          const SizedBox(height: 16),

          // Islamic
          _sectionHeader('Islamic Settings'),
          _settingsTile(
            icon: Icons.mosque,
            title: 'Prayer Calculation Method',
            subtitle: _prayerMethods[_prayerMethod] ?? 'Unknown',
            onTap: () => _showPrayerMethodPicker(),
          ),
          const SizedBox(height: 16),

          // Navigation
          _sectionHeader('Quick Access'),
          _navTile(Icons.savings, 'Savings Goals', '/savings'),
          _navTile(Icons.calculate, 'Zakat Calculator', '/zakat'),
          _navTile(Icons.trending_up, 'Market Prices', '/prices'),
          _navTile(Icons.picture_as_pdf, 'PDF Reports', '/reports'),
          const SizedBox(height: 16),

          // Privacy
          _sectionHeader('Privacy'),
          _settingsTile(
            icon: Icons.visibility_off,
            title: 'Hide Net Worth',
            subtitle: _hideNetWorth ? 'Hidden on Dashboard' : 'Visible on Dashboard',
            trailing: Switch(
              value: _hideNetWorth,
              onChanged: (v) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hide_net_worth', v);
                setState(() => _hideNetWorth = v);
              },
              activeTrackColor: AppTheme.deepGreen,
            ),
          ),
          const SizedBox(height: 16),

          // Data
          _sectionHeader('Data'),
          _settingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove offline data',
            onTap: () async {
              await CacheService().clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared'), backgroundColor: AppTheme.deepGreen),
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Danger Zone
          _sectionHeader('Danger Zone'),
          _settingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: () => _showDeleteAccountDialog(authService),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Version
          Center(
            child: Text(
              'Barakah v1.0.0\nMay your wealth be blessed',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.deepGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Theme.of(context).cardTheme.color ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.deepGreen.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.deepGreen),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _navTile(IconData icon, String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: () => Navigator.pushNamed(context, route),
          leading: Icon(icon, color: AppTheme.deepGreen),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencies = CurrencyService.supportedCurrencies;
    final symbols = CurrencyService.currencySymbols;
    final entries = currencies.entries.toList();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final code = entries[i].key;
                final name = entries[i].value;
                final symbol = symbols[code] ?? code;
                return ListTile(
                  leading: Text(symbol, style: const TextStyle(fontSize: 20)),
                  title: Text(code),
                  subtitle: Text(name),
                  trailing: _selectedCurrency == code
                      ? const Icon(Icons.check_circle, color: AppTheme.deepGreen)
                      : null,
                  onTap: () {
                    _setCurrency(code);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPrayerMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Prayer Calculation Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: _prayerMethods.entries.map((e) => ListTile(
                title: Text(e.value, style: const TextStyle(fontSize: 14)),
                trailing: _prayerMethod == e.key
                    ? const Icon(Icons.check_circle, color: AppTheme.deepGreen)
                    : null,
                onTap: () {
                  _setPrayerMethod(e.key);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AuthService authService) {
    final passwordController = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Delete Account', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account and all data. This cannot be undone.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Enter your password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  setDialogState(() => errorMsg = 'Please enter your password');
                  return;
                }
                try {
                  final api = ApiService(authService);
                  await api.deleteAccount(password);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await authService.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                } catch (e) {
                  String msg = 'Failed to delete account';
                  if (e is DioException && e.response?.data != null) {
                    final data = e.response!.data;
                    if (data is Map && data['error'] != null) {
                      msg = data['error'];
                    }
                  } else if (e is Exception) {
                    msg = e.toString().replaceFirst('Exception: ', '');
                  }
                  setDialogState(() => errorMsg = msg);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
