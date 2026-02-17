import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/models/asset.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  static const double _nisabThreshold = 5686.20;
  // Zakat rate: 2.5% of total eligible wealth

  List<Asset> _assets = [];
  double _totalValue = 0;
  double _zakatAmount = 0;
  bool _zakatDue = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);

      final results = await Future.wait([
        apiService.getAssets(),
        apiService.getAssetTotal(),
      ]);

      final assets = results[0] as List<Asset>;
      final totals = results[1] as Map<String, dynamic>;

      setState(() {
        _assets = assets;
        _totalValue = (totals['totalWealth'] as num?)?.toDouble() ?? 0;
        _zakatAmount = (totals['zakatDue'] as num?)?.toDouble() ?? 0;
        _zakatDue = totals['zakatEligible'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final percentOfNisab = (_totalValue / _nisabThreshold).clamp(0.0, 1.0);

    // Group assets by type
    final assetsByType = <String, double>{};
    for (final asset in _assets) {
      assetsByType[asset.type] = (assetsByType[asset.type] ?? 0) + asset.value;
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Zakat Calculator'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Zakat Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _zakatDue
                            ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                            : [Colors.grey[700]!, Colors.grey[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_zakatDue ? AppTheme.deepGreen : Colors.grey).withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _zakatDue ? Icons.check_circle : Icons.info_outline,
                          color: _zakatDue ? AppTheme.gold : Colors.white70,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _zakatDue ? 'Zakat is Due' : 'Below Nisab Threshold',
                          style: TextStyle(
                            color: _zakatDue ? AppTheme.gold : Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _zakatDue
                              ? 'Your wealth has reached the nisab. May Allah bless your generosity.'
                              : 'Your wealth has not yet reached the nisab threshold.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 14,
                          ),
                        ),
                        if (_zakatDue) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Zakat Amount',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(_zakatAmount),
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nisab Progress
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nisab Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentOfNisab,
                            minHeight: 12,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              _zakatDue ? AppTheme.deepGreen : Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Wealth: ${currencyFormat.format(_totalValue)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${(percentOfNisab * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _zakatDue ? AppTheme.deepGreen : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nisab Threshold: ${currencyFormat.format(_nisabThreshold)}',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Breakdown by Type
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wealth Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (assetsByType.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No assets to display'),
                            ),
                          )
                        else
                          ...assetsByType.entries.map((entry) {
                            final percentage = _totalValue > 0
                                ? (entry.value / _totalValue * 100)
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.deepGreen.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _typeIcon(entry.key),
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key.replaceAll('_', ' ').toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          currencyFormat.format(entry.value),
                                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.deepGreen,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.gold.withAlpha(100)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.deepGreen),
                            SizedBox(width: 8),
                            Text(
                              'About Zakat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Zakat is 2.5% of your total eligible wealth\n'
                          '• The Nisab threshold is approximately \$5,686.20 (85g of gold)\n'
                          '• Zakat is due when your wealth exceeds the Nisab for one lunar year\n'
                          '• Consult a scholar for specific rulings on your situation',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'crypto':
        return '₿';
      case 'stock':
        return '📈';
      case 'gold':
        return '🥇';
      case 'cash':
        return '💵';
      case 'real_estate':
        return '🏠';
      default:
        return '💰';
    }
  }
}
