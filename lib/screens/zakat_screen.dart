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

  List<Asset> _assets = [];
  double _totalValue = 0;
  double _zakatableWealth = 0;
  double _nonZakatableWealth = 0;
  double _zakatAmount = 0;
  bool _zakatDue = false;
  bool _isLoading = true;
  List<dynamic> _breakdown = [];

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
        _zakatableWealth = (totals['zakatableWealth'] as num?)?.toDouble() ?? 0;
        _nonZakatableWealth = (totals['nonZakatableWealth'] as num?)?.toDouble() ?? 0;
        _zakatAmount = (totals['zakatDue'] as num?)?.toDouble() ?? 0;
        _zakatDue = totals['zakatEligible'] as bool? ?? false;
        _breakdown = totals['breakdown'] as List<dynamic>? ?? [];
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
    final percentOfNisab = (_zakatableWealth / _nisabThreshold).clamp(0.0, 1.0);

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
                              ? 'Your eligible wealth has reached the nisab. May Allah bless your generosity.'
                              : 'Your zakatable wealth has not yet reached the nisab threshold.',
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
                                  'Zakat Amount (2.5%)',
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

                  // Wealth Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Wealth',
                          currencyFormat.format(_totalValue),
                          Icons.account_balance_wallet,
                          Colors.blue,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Zakatable',
                          currencyFormat.format(_zakatableWealth),
                          Icons.check_circle,
                          AppTheme.deepGreen,
                          theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_nonZakatableWealth > 0)
                    _buildSummaryCard(
                      'Exempt from Zakat',
                      currencyFormat.format(_nonZakatableWealth),
                      Icons.block,
                      Colors.orange,
                      theme,
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
                          'Nisab Progress (Zakatable Wealth)',
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
                              'Zakatable: ${currencyFormat.format(_zakatableWealth)}',
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

                  // Detailed Breakdown
                  if (_breakdown.isNotEmpty)
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
                          'Zakat Breakdown by Asset',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._breakdown.map((item) {
                          final bool isZakatable = item['zakatable'] == true;
                          final double value = (item['value'] as num).toDouble();
                          final double zakatableValue = (item['zakatableValue'] as num).toDouble();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isZakatable
                                  ? AppTheme.deepGreen.withAlpha(15)
                                  : Colors.orange.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isZakatable
                                    ? AppTheme.deepGreen.withAlpha(50)
                                    : Colors.orange.withAlpha(50),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isZakatable
                                            ? AppTheme.deepGreen.withAlpha(30)
                                            : Colors.orange.withAlpha(30),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _typeIcon(item['type'] ?? ''),
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            (item['type'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormat.format(value),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          isZakatable
                                              ? (zakatableValue == value
                                                  ? '✓ Fully zakatable'
                                                  : '✓ ${currencyFormat.format(zakatableValue)} zakatable')
                                              : '✗ Exempt',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isZakatable ? AppTheme.deepGreen : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['reason'] ?? '',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
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
                          '• Zakat is 2.5% of your eligible (zakatable) wealth\n'
                          '• The Nisab threshold is approximately \$5,686.20 (85g of gold)\n'
                          '• Personal residence, vehicles & belongings are NOT zakatable\n'
                          '• Retirement accounts (401k/IRA) are adjusted for early withdrawal penalties & taxes\n'
                          '• Cash, gold, silver, stocks, crypto, and business assets ARE zakatable\n'
                          '• Zakat is due when zakatable wealth exceeds Nisab for one lunar year\n'
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

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
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
      case 'property':
      case 'house':
      case 'home':
      case 'residence':
        return '🏠';
      case 'vehicle':
      case 'car':
        return '🚗';
      case '401k':
      case 'retirement_401k':
      case 'ira':
      case 'roth_ira':
      case 'pension':
      case 'retirement':
        return '🏦';
      case 'silver':
        return '🥈';
      case 'business':
        return '🏪';
      default:
        return '💰';
    }
  }
}
