import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/services/api_service.dart';
import 'package:barakah_app/services/notification_service.dart';
import 'package:barakah_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _bills = [];
  double _totalMonthly = 0;
  int _upcomingCount = 0;
  int _overdueCount = 0;
  bool _isLoading = true;
  late TabController _tabController;

  final _categories = ['utilities', 'rent', 'insurance', 'subscription', 'phone', 'internet', 'other'];

  final _categoryIcons = {
    'utilities': Icons.bolt,
    'rent': Icons.home,
    'insurance': Icons.shield,
    'subscription': Icons.subscriptions,
    'phone': Icons.phone_android,
    'internet': Icons.wifi,
    'other': Icons.receipt,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService(context.read<AuthService>());
      final data = await api.getBills();
      setState(() {
        _bills = data['bills'] as List<dynamic>? ?? [];
        _totalMonthly = (data['totalMonthlyBills'] as num?)?.toDouble() ?? 0;
        _upcomingCount = (data['upcomingCount'] as num?)?.toInt() ?? 0;
        _overdueCount = (data['overdueCount'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
      // Schedule bill reminders
      NotificationService().scheduleAllBillReminders(_bills);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddBill() {
    String selectedCategory = 'other';
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dueDayCtrl = TextEditingController();
    String frequency = 'monthly';

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
                const Text('Add Bill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Bill Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
                const SizedBox(height: 12),
                TextField(controller: dueDayCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Due Day (1-31)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Icon(_categoryIcons[c], size: 20),
                      const SizedBox(width: 8),
                      Text(c[0].toUpperCase() + c.substring(1)),
                    ]),
                  )).toList(),
                  onChanged: (v) => setSheetState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                  items: ['monthly', 'weekly', 'yearly', 'one_time'].map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')),
                  )).toList(),
                  onChanged: (v) => setSheetState(() => frequency = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty || dueDayCtrl.text.isEmpty) return;
                      try {
                        final api = ApiService(context.read<AuthService>());
                        await api.addBill(
                          name: nameCtrl.text,
                          amount: double.parse(amountCtrl.text),
                          dueDay: int.parse(dueDayCtrl.text),
                          category: selectedCategory,
                          frequency: frequency,
                        );
                        if (mounted) Navigator.pop(ctx);
                        _loadBills();
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
                    child: const Text('Add Bill'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _filterBills(String tab) {
    switch (tab) {
      case 'upcoming':
        return _bills.where((b) => !(b['paid'] as bool? ?? false)).toList();
      case 'overdue':
        return _bills.where((b) => (b['overdue'] as bool? ?? false)).toList();
      case 'paid':
        return _bills.where((b) => (b['paid'] as bool? ?? false)).toList();
      default:
        return _bills;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Bills & Reminders'),
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Upcoming ($_upcomingCount)'),
            Tab(text: 'Overdue ($_overdueCount)'),
            const Tab(text: 'Paid'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.deepGreen))
          : Column(
              children: [
                // Summary
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        Text('Monthly Bills', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(fmt.format(_totalMonthly), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ]),
                      Container(width: 1, height: 40, color: theme.dividerColor),
                      Column(children: [
                        Text('Overdue', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$_overdueCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _overdueCount > 0 ? Colors.red : Colors.green)),
                      ]),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBillList('upcoming', fmt),
                      _buildBillList('overdue', fmt),
                      _buildBillList('paid', fmt),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBill,
        backgroundColor: AppTheme.deepGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBillList(String tab, NumberFormat fmt) {
    final theme = Theme.of(context);
    final bills = _filterBills(tab);
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(tab == 'paid' ? 'No paid bills' : 'No ${tab} bills',
                style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBills,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: bills.length,
        itemBuilder: (ctx, i) {
          final bill = bills[i] as Map<String, dynamic>;
          final overdue = bill['overdue'] as bool? ?? false;
          final paid = bill['paid'] as bool? ?? false;
          final category = bill['category'] as String? ?? 'other';
          final dueInDays = bill['dueInDays'] as int? ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: overdue ? Border.all(color: Colors.red, width: 1.5) : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (overdue ? Colors.red : AppTheme.deepGreen).withAlpha(20),
                  child: Icon(_categoryIcons[category] ?? Icons.receipt,
                      color: overdue ? Colors.red : AppTheme.deepGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${fmt.format(bill['amount'])} • ${bill['frequency']}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      if (!paid)
                        Text(
                          overdue ? 'OVERDUE' : 'Due in $dueInDays days',
                          style: TextStyle(
                            color: overdue ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!paid)
                  IconButton(
                    onPressed: () async {
                      final api = ApiService(context.read<AuthService>());
                      await api.markBillPaid(bill['id'] as int);
                      _loadBills();
                    },
                    icon: const Icon(Icons.check_circle_outline, color: AppTheme.deepGreen),
                    tooltip: 'Mark Paid',
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final api = ApiService(context.read<AuthService>());
                      await api.deleteBill(bill['id'] as int);
                      _loadBills();
                    }
                  },
                  itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Delete'))],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
