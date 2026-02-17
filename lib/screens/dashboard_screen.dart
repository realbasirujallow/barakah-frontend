import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/services/cache_service.dart';
import 'package:barakah_app/services/notification_service.dart';
import 'package:barakah_app/models/asset.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:barakah_app/widgets/asset_card.dart';
import 'package:barakah_app/widgets/zakat_indicator.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Asset> _assets = [];
  double _totalValue = 0;
  double _zakatAmount = 0;
  bool _zakatDue = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);

      final results = await Future.wait([
        apiService.getAssets(),
        apiService.getAssetTotal(),
      ]);

      final assets = results[0] as List<Asset>;
      final totals = results[1] as Map<String, dynamic>;

      // Cache for offline use
      final cache = CacheService();
      await cache.cacheAssets(assets);
      await cache.cacheAssetTotal(totals);

      setState(() {
        _assets = assets;
        _totalValue = (totals['totalWealth'] as num?)?.toDouble() ?? 0;
        _zakatAmount = (totals['zakatDue'] as num?)?.toDouble() ?? 0;
        _zakatDue = totals['zakatEligible'] as bool? ?? false;
        _isLoading = false;
      });

      // Trigger zakat notification if due
      if (_zakatDue && _zakatAmount > 0) {
        NotificationService().showZakatReminder(_zakatAmount);
      }
    } catch (e) {
      // Try loading from cache
      final cache = CacheService();
      final cachedAssets = await cache.getCachedAssets();
      final cachedTotal = await cache.getCachedAssetTotal();
      if (cachedAssets.isNotEmpty || cachedTotal != null) {
        setState(() {
          _assets = cachedAssets;
          _totalValue = (cachedTotal?['totalWealth'] as num?)?.toDouble() ?? 0;
          _zakatAmount = (cachedTotal?['zakatDue'] as num?)?.toDouble() ?? 0;
          _zakatDue = cachedTotal?['zakatEligible'] as bool? ?? false;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assalamu Alaikum',
              style: TextStyle(fontSize: 14, color: Colors.green[100]),
            ),
            Text(
              authService.userName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.red[700])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.deepGreen,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Total Portfolio Value Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.deepGreen, Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.deepGreen.withAlpha(80),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Portfolio',
                              style: TextStyle(
                                color: Colors.green[100],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(_totalValue),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(50),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_assets.length} Assets',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_zakatDue)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold.withAlpha(60),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, color: AppTheme.gold, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Zakat Due',
                                          style: TextStyle(color: AppTheme.gold),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Zakat Indicator
                      ZakatIndicator(
                        totalValue: _totalValue,
                        zakatAmount: _zakatAmount,
                        zakatDue: _zakatDue,
                      ),
                      const SizedBox(height: 20),

                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.account_balance_wallet,
                              label: 'Assets',
                              onTap: () => Navigator.pushNamed(context, '/assets'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.calculate,
                              label: 'Zakat',
                              onTap: () => Navigator.pushNamed(context, '/zakat'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.trending_up,
                              label: 'Prices',
                              onTap: () => Navigator.pushNamed(context, '/prices'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.receipt_long,
                              label: 'Transactions',
                              onTap: () => Navigator.pushNamed(context, '/transactions'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.mosque,
                              label: 'Prayers',
                              onTap: () => Navigator.pushNamed(context, '/prayers'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.picture_as_pdf,
                              label: 'Reports',
                              onTap: () => Navigator.pushNamed(context, '/reports'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.verified,
                              label: 'Halal',
                              onTap: () => Navigator.pushNamed(context, '/halal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.bar_chart,
                              label: 'Analytics',
                              onTap: () => Navigator.pushNamed(context, '/analytics'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.settings,
                              label: 'Settings',
                              onTap: () => Navigator.pushNamed(context, '/settings'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.savings,
                              label: 'Goals',
                              onTap: () => Navigator.pushNamed(context, '/savings'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.pie_chart,
                              label: 'Budget',
                              onTap: () => Navigator.pushNamed(context, '/budget'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.credit_card_off,
                              label: 'Debts',
                              onTap: () => Navigator.pushNamed(context, '/debts'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.notifications_active,
                              label: 'Bills',
                              onTap: () => Navigator.pushNamed(context, '/bills'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.access_time,
                              label: 'Hawl',
                              onTap: () => Navigator.pushNamed(context, '/hawl'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.volunteer_activism,
                              label: 'Sadaqah',
                              onTap: () => Navigator.pushNamed(context, '/sadaqah'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.description,
                              label: 'Wasiyyah',
                              onTap: () => Navigator.pushNamed(context, '/wasiyyah'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.account_balance,
                              label: 'Waqf',
                              onTap: () => Navigator.pushNamed(context, '/waqf'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.shield,
                              label: 'Riba Check',
                              onTap: () => Navigator.pushNamed(context, '/riba'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.auto_fix_high,
                              label: 'Auto-Cat',
                              onTap: () => Navigator.pushNamed(context, '/auto-categorize'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Assets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Assets',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepGreen,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/assets'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_assets.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  size: 64, color: theme.dividerColor),
                              const SizedBox(height: 16),
                              Text(
                                'No assets yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first asset to start tracking',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/assets'),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Asset'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.deepGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...(_assets.take(5).map((asset) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AssetCard(asset: asset),
                            ))),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppTheme.deepGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/assets');
              break;
            case 2:
              Navigator.pushNamed(context, '/transactions');
              break;
            case 3:
              Navigator.pushNamed(context, '/prayers');
              break;
            case 4:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Prayers'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.deepGreen, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.deepGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
