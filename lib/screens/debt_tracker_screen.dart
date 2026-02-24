import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class DebtTrackerScreen extends StatefulWidget {
  const DebtTrackerScreen({super.key});

  @override
  State<DebtTrackerScreen> createState() => _DebtTrackerScreenState();
}

class _DebtTrackerScreenState extends State<DebtTrackerScreen> {
  List<dynamic> _debts = [];
  double _totalDebt = 0;
  double _totalMonthly = 0;
  int _ribaCount = 0;
  bool _isLoading = true;

  final _types = [
    'islamic_mortgage', 'conventional_mortgage', 'personal_loan',
    'car_loan', 'student_loan', 'credit_card', 'other'
  ];

  final _typeLabels = {
    'islamic_mortgage': 'Islamic Mortgage',
    'conventional_mortgage': 'Conventional Mortgage',
    'personal_loan': 'Personal Loan',
    'car_loan': 'Car Loan',
    'student_loan': 'Student Loan',
    'credit_card': 'Credit Card',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.getDebts();
      setState(() {
        _debts = data['debts'] as List<dynamic>? ?? [];
        _totalDebt = (data['totalDebt'] as num?)?.toDouble() ?? 0;
        _totalMonthly = (data['totalMonthlyPayment'] as num?)?.toDouble() ?? 0;
        _ribaCount = (data['ribaDebtsCount'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddDebt() {
    String selectedType = _types.first;
    final nameCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final lenderCtrl = TextEditingController();
    bool isRibaFree = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Debt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: _types.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_typeLabels[t] ?? t),
                  )).toList(),
                  onChanged: (v) => setSheetState(() {
  selectedType = v!;
  final rate = double.tryParse(rateCtrl.text) ?? 0;
  isRibaFree = rate == 0 || selectedType == 'islamic_mortgage';
}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Amount', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monthly Payment', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Interest Rate %', border: OutlineInputBorder()),
                        onChanged: (v) {
                          final rate = double.tryParse(v) ?? 0;
                          setSheetState(() => isRibaFree = rate == 0 || selectedType == 'islamic_mortgage');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Icon(
                          isRibaFree ? Icons.check_circle : Icons.warning,
                          color: isRibaFree ? Colors.green : Colors.red,
                          size: 28,
                        ),
                        Text(
                          isRibaFree ? 'Halal' : 'Riba!',
                          style: TextStyle(
                            color: isRibaFree ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lenderCtrl,
                  decoration: const InputDecoration(labelText: 'Lender (optional)', border: OutlineInputBorder()),
                ),
                if (!isRibaFree) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This debt involves Riba (interest), which is prohibited in Islam. Consider refinancing with an Islamic alternative.',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || totalCtrl.text.isEmpty) return;
                      try {
                        final api = ApiService(context.read<AuthService>());
                        await api.addDebt(
                          name: nameCtrl.text,
                          type: selectedType,
                          totalAmount: double.parse(totalCtrl.text),
                          monthlyPayment: monthlyCtrl.text.isNotEmpty ? double.parse(monthlyCtrl.text) : null,
                          interestRate: rateCtrl.text.isNotEmpty ? double.parse(rateCtrl.text) : null,
                          ribaFree: isRibaFree,
                          lender: lenderCtrl.text.isNotEmpty ? lenderCtrl.text : null,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _loadDebts();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add Debt'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> debt) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment for ${debt['name']}'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Payment Amount',
            prefixIcon: Icon(Icons.payment),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isEmpty) return;
              try {
                final api = ApiService(context.read<AuthService>());
                await api.makeDebtPayment(debt['id'] as int, double.parse(amountCtrl.text));
                if (mounted) Navigator.pop(ctx);
                _loadDebts();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepGreen, foregroundColor: Colors.white),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadDebts,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Total Debt',
                          value: fmt.format(_totalDebt),
                          icon: Icons.account_balance,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Monthly',
                          value: fmt.format(_totalMonthly),
                          icon: Icons.calendar_month,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (_ribaCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_ribaCount debt(s) involve Riba (interest). Consider Islamic alternatives.',
                              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  if (_debts.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.money_off, size: 64, color: theme.dividerColor),
                          const SizedBox(height: 16),
                          Text('No debts tracked', style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text('Alhamdulillah!', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    ...(_debts.map((d) {
                      final debt = d as Map<String, dynamic>;
                      final ribaFree = debt['ribaFree'] as bool? ?? true;
                      final paidPct = (debt['paidPercentage'] as num?)?.toDouble() ?? 0;
                      final status = debt['status'] as String? ?? 'active';
                      final remaining = (debt['remainingAmount'] as num?)?.toDouble() ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: !ribaFree ? Border.all(color: Colors.red.shade300) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  ribaFree ? Icons.check_circle : Icons.warning,
                                  color: ribaFree ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    debt['name'] as String? ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                if (status == 'paid_off')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Paid Off', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'pay') {
                                      _showPaymentDialog(debt);
                                    } else if (v == 'delete') {
                                      final api = ApiService(context.read<AuthService>());
                                      await api.deleteDebt(debt['id'] as int);
                                      _loadDebts();
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (status == 'active')
                                      const PopupMenuItem(value: 'pay', child: Text('Make Payment')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _typeLabels[debt['type']] ?? debt['type'] as String? ?? '',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                            ),
                            if (debt['lender'] != null && (debt['lender'] as String).isNotEmpty)
                              Text('Lender: ${debt['lender']}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (paidPct / 100).clamp(0, 1),
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  status == 'paid_off' ? Colors.green : AppTheme.deepGreen,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Remaining: ${fmt.format(remaining)}',
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                                Text('${paidPct.toStringAsFixed(0)}% paid',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (!ribaFree && (debt['interestRate'] as num? ?? 0) > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Interest: ${(debt['interestRate'] as num).toStringAsFixed(1)}% (Riba)',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      );
                    })),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDebt,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
