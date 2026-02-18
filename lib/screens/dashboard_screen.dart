import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isEditingGrid = false;

  // Default quick action order
  static const List<Map<String, dynamic>> _defaultActions = [
    {'icon': 'account_balance_wallet', 'label': 'Assets', 'route': '/assets'},
    {'icon': 'calculate', 'label': 'Zakat', 'route': '/zakat'},
    {'icon': 'trending_up', 'label': 'Prices', 'route': '/prices'},
    {'icon': 'receipt_long', 'label': 'Transactions', 'route': '/transactions'},
    {'icon': 'mosque', 'label': 'Prayers', 'route': '/prayers'},
    {'icon': 'picture_as_pdf', 'label': 'Reports', 'route': '/reports'},
    {'icon': 'verified', 'label': 'Halal', 'route': '/halal'},
    {'icon': 'bar_chart', 'label': 'Analytics', 'route': '/analytics'},
    {'icon': 'settings', 'label': 'Settings', 'route': '/settings'},
    {'icon': 'flag', 'label': 'Goals', 'route': '/savings'},
    {'icon': 'pie_chart', 'label': 'Budget', 'route': '/budget'},
    {'icon': 'credit_card_off', 'label': 'Debts', 'route': '/debts'},
    {'icon': 'notifications_active', 'label': 'Bills', 'route': '/bills'},
    {'icon': 'access_time', 'label': 'Hawl', 'route': '/hawl'},
    {'icon': 'volunteer_activism', 'label': 'Sadaqah', 'route': '/sadaqah'},
    {'icon': 'description', 'label': 'Wasiyyah', 'route': '/wasiyyah'},
    {'icon': 'account_balance', 'label': 'Waqf', 'route': '/waqf'},
    {'icon': 'shield', 'label': 'Riba Check', 'route': '/riba'},
    {'icon': 'auto_fix_high', 'label': 'Auto-Cat', 'route': '/auto-categorize'},
    {'icon': 'show_chart', 'label': 'Net Worth', 'route': '/net-worth'},
    {'icon': 'family_restroom', 'label': 'Shared', 'route': '/shared-finances'},
    {'icon': 'trending_up_2', 'label': 'Investments', 'route': '/investments'},
    {'icon': 'speed', 'label': 'Credit Score', 'route': '/credit-score'},
  ];

  List<Map<String, dynamic>> _quickActions = [];

  static IconData _getIcon(String name) {
    switch (name) {
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'calculate': return Icons.calculate;
      case 'trending_up': return Icons.trending_up;
      case 'receipt_long': return Icons.receipt_long;
      case 'mosque': return Icons.mosque;
      case 'picture_as_pdf': return Icons.picture_as_pdf;
      case 'verified': return Icons.verified;
      case 'bar_chart': return Icons.bar_chart;
      case 'settings': return Icons.settings;
      case 'flag': return Icons.flag;
      case 'pie_chart': return Icons.pie_chart;
      case 'credit_card_off': return Icons.credit_card_off;
      case 'notifications_active': return Icons.notifications_active;
      case 'access_time': return Icons.access_time;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'description': return Icons.description;
      case 'account_balance': return Icons.account_balance;
      case 'shield': return Icons.shield;
      case 'auto_fix_high': return Icons.auto_fix_high;
      case 'show_chart': return Icons.show_chart;
      case 'family_restroom': return Icons.family_restroom;
      case 'trending_up_2': return Icons.trending_up;
      case 'speed': return Icons.speed;
      default: return Icons.apps;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuickActionOrder();
    _loadData();
  }

  Future<void> _loadQuickActionOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('quick_action_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      // Rebuild list in saved order, then append any new actions not in saved order
      final ordered = <Map<String, dynamic>>[];
      for (final route in savedOrder) {
        final action = _defaultActions.firstWhere(
          (a) => a['route'] == route,
          orElse: () => <String, dynamic>{},
        );
        if (action.isNotEmpty) ordered.add(action);
      }
      // Add any new actions that weren't in saved order
      for (final action in _defaultActions) {
        if (!ordered.any((a) => a['route'] == action['route'])) {
          ordered.add(action);
        }
      }
      setState(() => _quickActions = ordered);
    } else {
      setState(() => _quickActions = List.from(_defaultActions));
    }
  }

  Future<void> _saveQuickActionOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = _quickActions.map((a) => a['route'] as String).toList();
    await prefs.setStringList('quick_action_order', order);
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

                      // Quick Actions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepGreen,
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(
                              _isEditingGrid ? Icons.check : Icons.swap_vert,
                              size: 18,
                              color: AppTheme.deepGreen,
                            ),
                            label: Text(
                              _isEditingGrid ? 'Done' : 'Reorder',
                              style: const TextStyle(color: AppTheme.deepGreen, fontSize: 13),
                            ),
                            onPressed: () {
                              setState(() => _isEditingGrid = !_isEditingGrid);
                              if (!_isEditingGrid) _saveQuickActionOrder();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dynamic Quick Actions Grid
                      if (_isEditingGrid)
                        _buildReorderableGrid()
                      else
                        _buildQuickActionsGrid(),

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

  Widget _buildQuickActionsGrid() {
    final rows = <Widget>[];
    for (var i = 0; i < _quickActions.length; i += 3) {
      final rowChildren = <Widget>[];
      for (var j = i; j < i + 3; j++) {
        if (j < _quickActions.length) {
          final action = _quickActions[j];
          if (j > i) rowChildren.add(const SizedBox(width: 12));
          rowChildren.add(
            Expanded(
              child: _QuickActionCard(
                icon: _getIcon(action['icon'] as String),
                label: action['label'] as String,
                onTap: () => Navigator.pushNamed(context, action['route'] as String),
              ),
            ),
          );
        } else {
          if (j > i) rowChildren.add(const SizedBox(width: 12));
          rowChildren.add(const Expanded(child: SizedBox()));
        }
      }
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(Row(children: rowChildren));
    }
    return Column(children: rows);
  }

  Widget _buildReorderableGrid() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _quickActions.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _quickActions.removeAt(oldIndex);
          _quickActions.insert(newIndex, item);
        });
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final action = _quickActions[index];
        return Container(
          key: ValueKey(action['route']),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withAlpha(50)),
          ),
          child: ListTile(
            leading: Icon(_getIcon(action['icon'] as String), color: AppTheme.deepGreen),
            title: Text(action['label'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.drag_handle, color: Colors.grey),
            dense: true,
          ),
        );
      },
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
