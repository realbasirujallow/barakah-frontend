import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> with SingleTickerProviderStateMixin {
  double _nisabThreshold = 5686.20; // fallback; overwritten by live API value
  static const int _currentLunarYear = 1446; // Update yearly

  double _totalValue = 0;
  double _zakatableWealth = 0;
  double _nonZakatableWealth = 0;
  double _zakatAmount = 0;
  bool _zakatDue = false;
  bool _isLoading = true;
  List<dynamic> _breakdown = [];
  List<dynamic> _payments = [];
  double _totalPaid = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      final results = await Future.wait([
        apiService.getAssets(),
        apiService.getAssetTotal(),
        apiService.getZakatPayments(lunarYear: _currentLunarYear),
      ]);

      final totals = results[1] as Map<String, dynamic>;
      final paymentsData = results[2] as Map<String, dynamic>;

      setState(() {
        _nisabThreshold = (totals['nisab'] as num?)?.toDouble() ?? 5686.20;
        _totalValue = (totals['netWorth'] as num?)?.toDouble() ?? (totals['totalWealth'] as num?)?.toDouble() ?? 0;
        _zakatableWealth = (totals['zakatableWealth'] as num?)?.toDouble() ?? 0;
        _nonZakatableWealth = (totals['nonZakatableWealth'] as num?)?.toDouble() ?? 0;
        _zakatAmount = (totals['zakatDue'] as num?)?.toDouble() ?? 0;
        _zakatDue = totals['zakatEligible'] as bool? ?? false;
        _breakdown = totals['breakdown'] as List<dynamic>? ?? [];
        _payments = paymentsData['payments'] as List<dynamic>? ?? [];
        _totalPaid = (paymentsData['totalPaid'] as num?)?.toDouble() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool get _zakatFulfilled => _zakatDue && _totalPaid >= _zakatAmount;

  void _showAddPaymentDialog() {
    final amountCtrl = TextEditingController();
    final recipientCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Record Zakat Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (USD)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: recipientCtrl,
              decoration: const InputDecoration(labelText: 'Recipient (optional)', hintText: 'e.g. Local Masjid, Islamic Relief', prefixIcon: Icon(Icons.mosque), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (amount == null || amount <= 0) return;
                  try {
                    final api = ApiService(context.read<AuthService>());
                    await api.addZakatPayment(
                      amount: amount,
                      recipient: recipientCtrl.text.trim().isNotEmpty ? recipientCtrl.text.trim() : null,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      lunarYear: _currentLunarYear,
                    );
                    if (mounted) Navigator.pop(ctx);
                    _loadData();
                    if (mounted && _zakatFulfilled) _showMabrukDialog();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Record Payment', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMabrukDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Mabrook!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
              const SizedBox(height: 8),
              const Text('مبروك', style: TextStyle(fontSize: 22, color: AppTheme.gold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'You have fulfilled your Zakat obligation for this lunar year. May Allah accept it from you and bless your wealth.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 8),
              Text(
                'تقبل الله منك',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Jazakallah Khayran'),
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
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final percentOfNisab = (_zakatableWealth / _nisabThreshold).clamp(0.0, 1.0);
    final remainingZakat = (_zakatAmount - _totalPaid).clamp(0.0, double.infinity);
    final fulfillmentPct = _zakatAmount > 0 ? (_totalPaid / _zakatAmount).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Zakat Calculator'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Calculator', icon: Icon(Icons.calculate)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                // ── Calculator Tab ──
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _zakatFulfilled
                                ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
                                : _zakatDue
                                    ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                                    : [Colors.grey[700]!, Colors.grey[600]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _zakatFulfilled ? '🌟' : _zakatDue ? '✅' : 'ℹ️',
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _zakatFulfilled ? 'Zakat Fulfilled!' : _zakatDue ? 'Zakat is Due' : 'Below Nisab Threshold',
                              style: TextStyle(color: _zakatDue ? AppTheme.gold : Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _zakatFulfilled
                                  ? 'Mabrook! May Allah accept your Zakat. تقبل الله منك'
                                  : _zakatDue
                                      ? 'Your eligible wealth has reached the nisab.'
                                      : 'Your zakatable wealth has not yet reached the nisab threshold.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14),
                            ),
                            if (_zakatDue) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  children: [
                                    const Text('Zakat Amount (2.5%)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(fmt.format(_zakatAmount), style: const TextStyle(color: AppTheme.gold, fontSize: 32, fontWeight: FontWeight.bold)),
                                    if (_totalPaid > 0) ...[
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: fulfillmentPct,
                                        backgroundColor: Colors.white.withAlpha(40),
                                        valueColor: AlwaysStoppedAnimation(_zakatFulfilled ? Colors.lightBlueAccent : AppTheme.gold),
                                        minHeight: 6,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _zakatFulfilled ? 'Fully paid! ✓' : 'Paid: ${fmt.format(_totalPaid)} • Remaining: ${fmt.format(remainingZakat)}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Summary cards
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard('Net Worth', fmt.format(_totalValue), Icons.account_balance_wallet, Colors.blue, theme)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSummaryCard('Zakatable', fmt.format(_zakatableWealth), Icons.check_circle, AppTheme.deepGreen, theme)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_nonZakatableWealth > 0)
                        _buildSummaryCard('Exempt from Zakat', fmt.format(_nonZakatableWealth), Icons.block, Colors.orange, theme),
                      const SizedBox(height: 24),

                      // Nisab progress
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nisab Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percentOfNisab, minHeight: 12,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(_zakatDue ? AppTheme.deepGreen : Colors.orange),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Zakatable: ${fmt.format(_zakatableWealth)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('${(percentOfNisab * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: _zakatDue ? AppTheme.deepGreen : Colors.orange)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Nisab: ${fmt.format(_nisabThreshold)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Breakdown
                      if (_breakdown.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Breakdown by Asset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
                              const SizedBox(height: 16),
                              ..._breakdown.map((item) {
                                final bool isZakatable = item['zakatable'] == true;
                                final double value = (item['value'] as num).toDouble();
                                final double zakatableValue = (item['zakatableValue'] as num).toDouble();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isZakatable ? AppTheme.deepGreen.withAlpha(15) : Colors.orange.withAlpha(15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isZakatable ? AppTheme.deepGreen.withAlpha(50) : Colors.orange.withAlpha(50)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(_typeIcon(item['type'] ?? ''), style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 10),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(item['reason'] ?? '', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontStyle: FontStyle.italic)),
                                        ],
                                      )),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        Text(fmt.format(value), style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(
                                          isZakatable ? '✓ ${fmt.format(zakatableValue)}' : '✗ Exempt',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isZakatable ? AppTheme.deepGreen : Colors.orange),
                                        ),
                                      ]),
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
                                Text('About Zakat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Zakat is 2.5% of your eligible (zakatable) wealth\n'
                              '• The Nisab threshold is approximately \$5,686.20 (85g of gold)\n'
                              '• Personal residence, vehicles & belongings are NOT zakatable\n'
                              '• Retirement accounts (401k/IRA/HSA) are adjusted for penalties & taxes\n'
                              '• Cash, gold, silver, stocks, crypto, and business assets ARE zakatable\n'
                              '• Consult a scholar for specific rulings on your situation',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Payments Tab ──
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Payment summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _zakatFulfilled
                              ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
                              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(_zakatFulfilled ? '🌟 Zakat Fulfilled' : '📊 Zakat Progress',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _paymentStat('Due', fmt.format(_zakatAmount), Colors.white),
                                _paymentStat('Paid', fmt.format(_totalPaid), AppTheme.gold),
                                _paymentStat('Remaining', fmt.format(remainingZakat), Colors.white70),
                              ],
                            ),
                            if (_zakatAmount > 0) ...[
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: fulfillmentPct, minHeight: 10,
                                  backgroundColor: Colors.white.withAlpha(30),
                                  valueColor: AlwaysStoppedAnimation(_zakatFulfilled ? Colors.lightBlueAccent : AppTheme.gold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('${(fulfillmentPct * 100).toStringAsFixed(0)}% of zakat paid for $_currentLunarYear AH',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.deepGreen)),
                          ElevatedButton.icon(
                            onPressed: _showAddPaymentDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Record'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_payments.isEmpty)
                        Center(
                          child: Column(children: [
                            const SizedBox(height: 40),
                            const Text('🕌', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No payments recorded yet', style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Tap "Record" to add a zakat payment', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ]),
                        )
                      else
                        ..._payments.map((p) {
                          final payment = p as Map<String, dynamic>;
                          final amount = (payment['amount'] as num).toDouble();
                          final recipient = payment['recipient'] as String? ?? '';
                          final notes = payment['notes'] as String? ?? '';
                          final paidAt = payment['paidAt'] as int? ?? 0;
                          final date = DateTime.fromMillisecondsSinceEpoch(paidAt);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: AppTheme.deepGreen.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                                  child: const Center(child: Text('🕌', style: TextStyle(fontSize: 22))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fmt.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.deepGreen)),
                                    if (recipient.isNotEmpty) Text(recipient, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    if (notes.isNotEmpty) Text(notes, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                  ],
                                )),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () async {
                                    final api = ApiService(context.read<AuthService>());
                                    await api.deleteZakatPayment(payment['id'] as int);
                                    _loadData();
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showAddPaymentDialog,
              backgroundColor: AppTheme.deepGreen,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _paymentStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]);
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 6), Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ]),
    );
  }

  String _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'crypto': return '₿';
      case 'stock': return '📈';
      case 'gold': return '🥇';
      case 'cash': case 'savings_account': case 'checking_account': return '💵';
      case 'primary_home': case 'real_estate': case 'property': return '🏠';
      case 'investment_property': case 'investment_property_resale': case 'rental_property': return '🏢';
      case 'vehicle': case 'car': return '🚗';
      case '401k': case 'roth_ira': case 'ira': case 'hsa': case '403b': case 'pension': return '🏦';
      case '529': return '🎓';
      case 'silver': return '🥈';
      case 'business': return '🏪';
      default: return '💰';
    }
  }
}
