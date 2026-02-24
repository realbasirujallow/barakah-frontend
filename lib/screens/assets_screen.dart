import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/models/asset.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:barakah_app/widgets/asset_card.dart';
import 'package:intl/intl.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  List<Asset> _assets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      final assets = await apiService.getAssets();
      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load assets';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAsset(Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Are you sure you want to delete "${asset.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      await apiService.deleteAsset(asset.id!);
      _loadAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted'), backgroundColor: AppTheme.deepGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete asset'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updatePrice(Asset asset) async {
    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      final source = asset.type.toLowerCase() == 'stock' ? 'stock' : 'crypto';
      await apiService.updateAssetPrice(asset.id!, symbol: asset.name.toUpperCase(), source: source);
      _loadAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price updated!'), backgroundColor: AppTheme.deepGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update price. Only crypto/stock assets supported.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showAddAssetDialog() {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    String selectedType = 'cash';

    final types = {
      '💵 Cash & Savings': ['cash', 'savings_account', 'checking_account'],
      '🏠 Real Estate': ['primary_home', 'investment_property'],
      '📈 Investments': ['stock', 'crypto', 'business', 'individual_brokerage'], // Added individual brokerage
      '🏦 Retirement': ['401k', 'roth_ira', 'ira', 'hsa', '403b', 'pension', '529'],
      '🥇 Precious Metals': ['gold', 'silver'],
      '🚗 Other': ['vehicle', 'other'],
    };

    String displayName(String type) {
      const labels = {
        'cash': 'Cash',
        'savings_account': 'Savings Account',
        'checking_account': 'Checking Account',
        'primary_home': 'Primary Home',
        'investment_property': 'Investment Property',
        'stock': 'Stocks / ETFs',
        'crypto': 'Cryptocurrency',
        'business': 'Business',
        'individual_brokerage': 'Individual Brokerage Account', // Added label
        '401k': '401(k)',
        'roth_ira': 'Roth IRA',
        'ira': 'Traditional IRA',
        'hsa': 'HSA',
        '403b': '403(b)',
        'pension': 'Pension',
        '529': '529 Plan',
        'gold': 'Gold',
        'silver': 'Silver',
        'vehicle': 'Vehicle',
        'other': 'Other',
      };
      return labels[type] ?? type.replaceAll('_', ' ');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add New Asset',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepGreen,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Asset Name',
                  hintText: 'e.g. Bitcoin, AAPL, Gold Ring',
                  prefixIcon: const Icon(Icons.label_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: 'Asset Type',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                ),
                items: types.entries.expand((group) => [
                  DropdownMenuItem<String>(
                    enabled: false,
                    child: Text(
                      group.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepGreen.withOpacity(0.7),
                      ),
                    ),
                  ),
                  ...group.value.map((type) => DropdownMenuItem(
                    value: type,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(displayName(type)),
                    ),
                  )),
                ]).toList(),
                onChanged: (value) {
                  if (value != null) setModalState(() => selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Value (USD)',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final value = double.tryParse(valueController.text.trim());

                    if (name.isEmpty || value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields correctly')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);

                    try {
                      final authService = context.read<AuthService>();
                      final apiService = ApiService(authService);
                      await apiService.addAsset(Asset(
                        name: name,
                        type: selectedType,
                        value: value,
                      ));
                      _loadAssets();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Asset added!'),
                            backgroundColor: AppTheme.deepGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to add asset'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Asset', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final totalValue = _assets.fold<double>(0, (sum, a) => sum + a.value);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('My Assets'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: Colors.red[700])),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadAssets, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAssets,
                  color: AppTheme.deepGreen,
                  child: _assets.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined,
                                      size: 80, color: theme.dividerColor),
                                  const SizedBox(height: 16),
                                  Text('No assets yet',
                                      style: TextStyle(fontSize: 20, color: theme.colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 8),
                                  Text('Tap + to add your first asset',
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Summary bar
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.deepGreen,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Net Worth',
                                          style: TextStyle(color: Colors.green[100], fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormat.format(totalValue),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(50),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_assets.length} assets',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Asset list
                            ..._assets.map((asset) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AssetCard(
                                    asset: asset,
                                    onDelete: () => _deleteAsset(asset),
                                    onUpdatePrice: (asset.type.toLowerCase() == 'crypto' ||
                                            asset.type.toLowerCase() == 'stock')
                                        ? () => _updatePrice(asset)
                                        : null,
                                  ),
                                )),
                          ],
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
